pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Screen brightness.
//
//  - A laptop screen: read from /sys and changed with `brightnessctl`.
//  - Monitors of a desktop PC: read and changed with `ddcutil` (DDC/CI, over the monitor cable).
//
// If there is neither, `available` is false and the brightness UI hides itself.
Singleton {
  id: root

  property string backend: ""      // "backlight", "ddc" or "" (nothing found)
  property string device: ""       // backlight: the name of the device
  property var buses: []           // ddc: the I2C bus numbers of the monitors
  property real current: 0
  property real maximum: 1

  readonly property bool available: backend === "backlight" ? (device !== "" && maximum > 1)
                                  : backend === "ddc" ? (buses.length > 0 && maximum > 0)
                                  : false
  readonly property real value: maximum > 0 ? current / maximum : 0   // 0 to 1

  onValueChanged: Osd.notify()

  // ---- Finding what to control, once, at startup ----------------------------

  // A laptop screen first
  Process {
    running: true
    command: ["sh", "-c", "ls /sys/class/backlight 2>/dev/null | head -n 1"]
    stdout: StdioCollector {
      onStreamFinished: {
        const name = text.trim()
        if (name !== "") {
          root.device = name
          root.backend = "backlight"
        } else {
          detectProc.running = true   // no laptop screen: try the monitors
        }
      }
    }
  }

  // Monitors that answer to ddcutil. "ddcutil detect --brief" lists them like:
  //   Display 1
  //      I2C bus:  /dev/i2c-5
  Process {
    id: detectProc
    command: ["ddcutil", "detect", "--brief"]
    stdout: StdioCollector {
      onStreamFinished: {
        const found = []
        let valid = false
        for (const line of text.split("\n")) {
          if (/^Display\s+\d+/.test(line)) valid = true
          else if (/^(Invalid display|Phantom display)/i.test(line)) valid = false

          const m = line.match(/I2C bus:\s*\/dev\/i2c-(\d+)/)
          if (m && valid) found.push(m[1])
        }

        root.buses = found
        if (found.length > 0) {
          root.backend = "ddc"
          readProc.command = ["ddcutil", "--bus", found[0], "getvcp", "10", "--brief"]
          readProc.running = true
        } else {
          console.warn("Brightness: ddcutil found no monitor. Is i2c-dev loaded, and are you in the i2c group?")
        }
      }
    }
  }

  // The current brightness of the first monitor. In brief mode it looks like: "VCP 10 C 50 100"
  Process {
    id: readProc
    stdout: StdioCollector {
      onStreamFinished: {
        const m = text.match(/VCP\s+10\s+\w+\s+(\d+)\s+(\d+)/)
        if (m) {
          root.maximum = parseInt(m[2]) || 100
          root.current = parseInt(m[1]) || 0
        }
      }
    }
  }

  // ---- A laptop screen ------------------------------------------------------

  FileView {
    path: root.backend === "backlight" ? "/sys/class/backlight/" + root.device + "/max_brightness" : ""
    onLoaded: root.maximum = parseInt(text()) || 1
  }

  FileView {
    id: currentFile
    path: root.backend === "backlight" ? "/sys/class/backlight/" + root.device + "/brightness" : ""
    onLoaded: root.current = parseInt(text()) || 0
  }

  // Read the value again now and then, so changes made by your keybinds are noticed
  Timer {
    interval: 400
    repeat: true
    running: root.backend === "backlight"
    onTriggered: currentFile.reload()
  }

  // ---- Changing it ----------------------------------------------------------

  // Sliders send many values while dragging, so only the latest one is applied now and then.
  // ddcutil is slow (it talks to the monitor), so it waits longer and never runs twice at once.
  property real pending: -1

  Timer {
    id: apply
    interval: root.backend === "ddc" ? 300 : 60
    onTriggered: root.flush()
  }

  // Sets every monitor at the same time. $0 is the value, the rest are the bus numbers.
  Process {
    id: setProc
    onExited: if (root.pending >= 0) apply.start()
  }

  function flush() {
    if (pending < 0) return

    if (backend === "ddc") {
      if (setProc.running) {
        apply.start()
        return
      }
      const value = Math.round(pending / 100 * maximum)
      pending = -1
      setProc.command = [
        "sh", "-c",
        'v="$0"; for b in "$@"; do ddcutil --bus "$b" --noverify setvcp 10 "$v" & done; wait',
        String(value)
      ].concat(buses.map(b => String(b)))
      setProc.running = true
    } else {
      Quickshell.execDetached(["brightnessctl", "set", Math.round(pending) + "%"])
      pending = -1
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
