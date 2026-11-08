pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Screen brightness. It reads the backlight from /sys and changes it with `brightnessctl`.
// If there is no backlight (a desktop PC) `available` is false and the brightness UI hides itself.
Singleton {
  id: root

  property string device: ""
  property real current: 0
  property real maximum: 1

  readonly property bool available: device !== "" && maximum > 1
  readonly property real value: maximum > 0 ? current / maximum : 0   // 0 to 1

  onValueChanged: Osd.notify()

  // Find the backlight device once, at startup
  Process {
    running: true
    command: ["sh", "-c", "ls /sys/class/backlight 2>/dev/null | head -n 1"]
    stdout: StdioCollector {
      onStreamFinished: root.device = text.trim()
    }
  }

  FileView {
    path: root.device !== "" ? "/sys/class/backlight/" + root.device + "/max_brightness" : ""
    onLoaded: root.maximum = parseInt(text()) || 1
  }

  FileView {
    id: currentFile
    path: root.device !== "" ? "/sys/class/backlight/" + root.device + "/brightness" : ""
    onLoaded: root.current = parseInt(text()) || 0
  }

  // Read the value again now and then, so changes made by your keybinds are noticed
  Timer {
    interval: 400
    repeat: true
    running: root.device !== ""
    onTriggered: currentFile.reload()
  }

  // Sliders send many values while dragging, so only apply the latest one every 60ms
  property real pending: -1
  Timer {
    id: apply
    interval: 60
    onTriggered: {
      if (root.pending < 0) return
      Quickshell.execDetached(["brightnessctl", "set", Math.round(root.pending) + "%"])
      root.pending = -1
    }
  }

  function setPercent(percent) {
    const p = Math.max(1, Math.min(100, percent))   // never go fully black
    current = p / 100 * maximum                      // update the UI right away
    pending = p
    if (!apply.running) apply.start()
  }
  function change(delta) { setPercent(value * 100 + delta) }
}
