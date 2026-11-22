pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Night light (a warmer screen color), through hyprsunset:
//   hyprctl hyprsunset temperature 4500     warmer, the lower the number
//   hyprctl hyprsunset identity             back to normal
// If hyprsunset is installed but not running, it is started the first time you change it.
Singleton {
  id: root

  readonly property int neutral: 6500   // no filter
  readonly property int warmest: 2500

  property bool installed: false
  property int temperature: neutral
  property int lastWarm: 4500           // what "on" goes back to

  readonly property bool active: temperature < neutral
  // 0 = off, 1 = the warmest: this is what the slider shows
  readonly property real level: (neutral - temperature) / (neutral - warmest)

  onLevelChanged: Osd.notify()

  Process {
    running: true
    command: ["sh", "-c", "command -v hyprsunset >/dev/null && echo yes"]
    stdout: StdioCollector {
      onStreamFinished: root.installed = text.trim() === "yes"
    }
  }

  // If hyprsunset is already running (a night schedule, say), show what it is doing.
  // The format of this output is not documented, so this only reads a temperature when it is there.
  Process {
    running: true
    command: ["hyprctl", "hyprsunset", "profile"]
    stdout: StdioCollector {
      onStreamFinished: {
        const m = text.match(/temperature\D*(\d{4})/i)
        if (m && !/identity\D*true/i.test(text)) root.temperature = Math.min(root.neutral, parseInt(m[1]))
      }
    }
  }

  // The slider sends many values, so the latest one is applied after a short pause
  Timer {
    id: apply
    interval: 150
    onTriggered: root.flush()
  }

  // Is hyprsunset running? Then talk to it, otherwise start it.
  Process {
    id: checkProc
    command: ["pgrep", "-x", "hyprsunset"]
    onExited: (exitCode, exitStatus) => {
      if (exitCode === 0) {
        if (root.active) Quickshell.execDetached(["hyprctl", "hyprsunset", "temperature", String(root.temperature)])
        else Quickshell.execDetached(["hyprctl", "hyprsunset", "identity"])
      } else if (root.active) {
        Quickshell.execDetached(["hyprsunset", "--temperature", String(root.temperature)])
      }
    }
  }

  function flush() {
    if (checkProc.running) {
      apply.start()
      return
    }
    checkProc.running = true
  }

  function setTemperature(kelvin) {
    temperature = Math.max(warmest, Math.min(neutral, Math.round(kelvin / 50) * 50))
    if (active) lastWarm = temperature
    apply.restart()
  }

  // v: 0 (off) to 1 (the warmest)
   function setLevel(v) {
    if (v < 0.03) setTemperature(neutral)
    else setTemperature(neutral - v * (neutral - warmest))
  }

  // On or off
  function toggle() {
    setTemperature(active ? neutral : lastWarm)
  }
}
