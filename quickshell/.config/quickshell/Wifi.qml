pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Wi-Fi through NetworkManager's `nmcli` command (needs NetworkManager running).
Singleton {
  id: root

  property bool enabled: false        // the Wi-Fi radio is on
  property bool wired: false          // connected with a cable
  property string ssid: ""            // the network we are connected to ("" = none)
  property real strength: 0           // 0 to 1, of the connected network
  property bool scanning: false
  property bool connecting: false
  property string connectingSsid: ""
  property string error: ""

  readonly property bool connected: ssid !== ""

  // What nmcli told us, and the names of the networks saved on this machine
  property var rawNetworks: []
  property var savedNames: []
  property string lastSignature: ""

  // { ssid, strength, secure, active, saved }: the connected one first, then saved, then by signal
  readonly property var networks: build(rawNetworks, savedNames)

  function build(raw, saved) {
    const list = raw.map(n => ({
      ssid: n.ssid,
      strength: n.strength,
      secure: n.secure,
      active: n.active,
      saved: saved.indexOf(n.ssid) >= 0
    }))
    list.sort((a, b) => (b.active - a.active) || (b.saved - a.saved) || (b.strength - a.strength))
    return list
  }

  // nmcli's terse output separates fields with ":" and writes a ":" inside a field as "\:"
  function splitTerse(line) {
    const fields = []
    let current = ""
    for (let i = 0; i < line.length; i++) {
      const ch = line[i]
      if (ch === "\\" && i + 1 < line.length) {
        current += line[i + 1]
        i++
      } else if (ch === ":") {
        fields.push(current)
        current = ""
      } else {
        current += ch
      }
    }
    fields.push(current)
    return fields
  }

  function parseList(text) {
    const best = {}
    let active = ""

    for (const line of text.trim().split("\n")) {
      if (line === "") continue
      const f = splitTerse(line)
      const name = f[1]
      if (!name) continue                                   // hidden networks have no name

      const inUse = f[0].trim() === "*"
      // 0, 0.2, 0.4 ... 1: the icons only have a few levels, and it avoids needless updates
      const strength = Math.round((parseInt(f[2]) || 0) / 20) / 5
      const secure = f[3] !== "" && f[3] !== "--"

      if (inUse) active = name
      if (!best[name]) {
        best[name] = { ssid: name, strength: strength, secure: secure, active: inUse }
      } else {
        best[name].strength = Math.max(best[name].strength, strength)
        best[name].active = best[name].active || inUse
      }
    }

    ssid = active
    strength = active !== "" ? best[active].strength : 0

    const list = Object.values(best)
    const signature = JSON.stringify(list)
    if (signature !== lastSignature) {   // only touch the list when something really changed
      lastSignature = signature
      rawNetworks = list
    }
  }

  // ---- Reading the state ----------------------------------------------------

  Process {
    id: radioProc
    command: ["nmcli", "radio", "wifi"]
    stdout: StdioCollector {
      onStreamFinished: root.enabled = text.trim() === "enabled"
    }
  }

  Process {
    id: deviceProc
    command: ["nmcli", "-t", "-f", "TYPE,STATE", "device"]
    stdout: StdioCollector {
      onStreamFinished: {
        let cable = false
        for (const line of text.trim().split("\n")) {
          const f = root.splitTerse(line)
          if (f[0] === "ethernet" && f[1] === "connected") cable = true
        }
        root.wired = cable
      }
    }
  }

  Process {
    id: listProc
    command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "no"]
    stdout: StdioCollector {
      onStreamFinished: root.parseList(text)
    }
  }

  Process {
    id: savedProc
    command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
    stdout: StdioCollector {
      onStreamFinished: {
        const names = []
        for (const line of text.trim().split("\n")) {
          const f = root.splitTerse(line)
          if (f[1] === "802-11-wireless") names.push(f[0])
        }
        root.savedNames = names
      }
    }
  }

  function refresh() {
    if (!radioProc.running) radioProc.running = true
    if (!deviceProc.running) deviceProc.running = true
    if (!listProc.running) listProc.running = true
  }

  function refreshSaved() {
    if (!savedProc.running) savedProc.running = true
  }

  Component.onCompleted: {
    refresh()
    refreshSaved()
  }

  // NetworkManager prints a line whenever something changes, so we refresh right after
  Process {
    running: true
    command: ["nmcli", "monitor"]
    stdout: SplitParser {
      onRead: data => debounce.restart()
    }
  }
  Timer {
    id: debounce
    interval: 400
    onTriggered: root.refresh()
  }

  // Signal strength changes quietly, so also look now and then
  Timer {
    interval: 10000
    repeat: true
    running: true
    onTriggered: root.refresh()
  }

  // ---- Scanning -------------------------------------------------------------

  Process {
    id: rescanProc
    command: ["nmcli", "device", "wifi", "rescan"]
    onExited: scanDelay.start()
  }
  Timer {
    id: scanDelay
    interval: 2500   // the scan takes a moment
    onTriggered: {
      root.scanning = false
      root.refresh()
    }
  }

  function rescan() {
    if (!enabled || scanning || rescanProc.running) return
    scanning = true
    rescanProc.running = true
  }

  // ---- Connecting -----------------------------------------------------------

  Process {
    id: connectProc
    property int code: 0
    stdout: StdioCollector { id: connectOut }
    stderr: StdioCollector { id: connectErr }
    onExited: (exitCode, exitStatus) => {
      connectProc.code = exitCode
      finishConnect.restart()   // wait a moment so the output has been read
    }
  }
  Timer {
    id: finishConnect
    interval: 200
    onTriggered: {
      root.connecting = false
      if (connectProc.code === 0) {
        root.error = ""
      } else {
        const message = (connectErr.text + " " + connectOut.text).trim()
        root.error = /secrets/i.test(message) ? "Wrong password" : message.replace(/^Error:\s*/, "")
      }
      root.refresh()
      root.refreshSaved()
    }
  }

  // Connects to a network. `password` is only needed the first time for a secured network.
  function connect(name, password) {
    if (connectProc.running) return
    error = ""
    connecting = true
    connectingSsid = name

    if (password) {
      connectProc.command = ["nmcli", "device", "wifi", "connect", name, "password", password]
    } else if (savedNames.indexOf(name) >= 0) {
      connectProc.command = ["nmcli", "connection", "up", "id", name]
    } else {
      connectProc.command = ["nmcli", "device", "wifi", "connect", name]
    }
    connectProc.running = true
  }

  // ---- Other actions --------------------------------------------------------

  Process {
    id: actionProc
    onExited: {
      root.refresh()
      root.refreshSaved()
    }
  }

  function run(command) {
    if (actionProc.running) return
    actionProc.command = command
    actionProc.running = true
  }

  function disconnect(name) { run(["nmcli", "connection", "down", "id", name]) }
  function forget(name) { run(["nmcli", "connection", "delete", "id", name]) }

  function setEnabled(on) {
    enabled = on
    run(["nmcli", "radio", "wifi", on ? "on" : "off"])
  }
}
