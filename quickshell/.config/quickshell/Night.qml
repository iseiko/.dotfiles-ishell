pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// The night light (blue light filter), made by hyprsunset. It is controlled through `hyprctl hyprsunset`.
// If hyprsunset is not running when you turn it on, it is started.
Singleton {
  id: root

  property bool installed: false
  property bool active: false          // the filter is on
  property int temperature: 4500       // in Kelvin, while it is on (lower = warmer)
  property int lastTemperature: 4500   // what "on" goes back to

  // Where the last temperature is remembered (it is read again when the shell starts)
  readonly property string stateFile:
    (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/quickshell/night-light.json"

  readonly property int warmest: 2500
  readonly property int neutral: 6500  // no filter
  readonly property bool available: installed

  // 0 = off, 1 = the warmest
  readonly property real warmth: active ? (neutral - temperature) / (neutral - warmest) : 0

  Process {
    running: true
    command: ["sh", "-c", "command -v hyprsunset"]
    onExited: (exitCode, exitStatus) => root.installed = exitCode === 0
  }

  // If it is already running, find out what it is doing
  onInstalledChanged: if (installed) stateProc.running = true

  // ---- Remembering the last temperature ---------------------------------------------
  // The state is saved in a file whenever it changes. When the shell starts, a moment after
  // hyprsunset had time to start by itself, the saved state is applied again.

  property var saved: null        // what the file says: { active, temperature }
  property bool restored: false   // before this, nothing is saved (it would overwrite the file)

  FileView {
    path: root.stateFile
    onLoaded: {
      try { root.saved = JSON.parse(text()) }
      catch (e) { root.saved = null }
    }
  }

  Timer {
    interval: 1500
    running: root.installed
    onTriggered: root.restore()
  }

  function restore() {
    if (restored) return
    const s = saved
    if (s && typeof s.temperature === "number") {
      lastTemperature = Math.max(warmest, Math.min(neutral, s.temperature))
      if (s.active === true) setTemperature(s.temperature)
      else if (s.active === false) turnOff()
    }
    restored = true
  }

  function save() {
    if (!restored) return
    const json = JSON.stringify({ active: active, temperature: lastTemperature })
    Quickshell.execDetached([
      "sh", "-c", 'mkdir -p "$(dirname "$0")" && printf "%s\\n" "$1" > "$0"',
      stateFile, json
    ])
  }

  Timer {
    id: saveTimer
    interval: 600   // a slider changes the temperature many times a second
    onTriggered: root.save()
  }

  onActiveChanged: {
    saveTimer.restart()
    Osd.notify("brightness")   // it shows the brightness panel, where the night light is
  }
  onLastTemperatureChanged: saveTimer.restart()
  onTemperatureChanged: Osd.notify("brightness")

  Process {
    id: stateProc
    command: ["hyprctl", "hyprsunset", "profile"]
    stdout: StdioCollector {
      onStreamFinished: {
        const m = text.match(/temperature\D*(\d{4})/i)
        if (m && !/identity\D*true/i.test(text)) {
          const k = parseInt(m[1])
          if (k < root.neutral) {
            root.temperature = k
            root.lastTemperature = k
            root.active = true
          }
        }
      }
    }
  }

  // Sliders send many values while dragging: only the latest one is sent
  property int pendingTemperature: 0
  property bool pendingReset: false

  Timer {
    id: apply
    interval: 80
    onTriggered: root.flush()
  }

  function flush() {
    if (pendingTemperature <= 0) return
    const t = pendingTemperature
    const reset = pendingReset
    pendingTemperature = 0
    pendingReset = false

    // running: change it. Not running: start it with this temperature.
    const script = [
      'if pgrep -x hyprsunset >/dev/null; then',
      '  [ "$1" = 1 ] && hyprctl hyprsunset reset identity >/dev/null 2>&1',
      '  hyprctl hyprsunset temperature "$0"',
      'else',
      '  setsid hyprsunset -t "$0" >/dev/null 2>&1 &',
      'fi'
    ].join("\n")
    Quickshell.execDetached(["sh", "-c", script, String(t), reset ? "1" : "0"])
  }

  function setTemperature(kelvin) {
    const t = Math.max(warmest, Math.min(neutral, Math.round(kelvin / 50) * 50))
    if (t >= neutral) {
      turnOff()
      return
    }
    // coming from "off", the filter has to be switched back on first
    pendingReset = pendingReset || !active
    temperature = t
    lastTemperature = t
    active = true
    pendingTemperature = t
    if (!apply.running) apply.start()
  }

  // v: 0 (off) to 1 (the warmest)
  function setWarmth(v) {
    setTemperature(neutral - v * (neutral - warmest))
  }

  function turnOff() {
    active = false
    pendingTemperature = 0
    Quickshell.execDetached(["sh", "-c", "pgrep -x hyprsunset >/dev/null && hyprctl hyprsunset identity"])
  }

  function toggle() {
    if (active) turnOff()
    else setTemperature(lastTemperature)
  }
}
