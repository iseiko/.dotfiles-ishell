pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Apps running in the background (the ones with an icon in the system tray): finding their windows,
// going to them, and closing or killing them. Windows come from `hyprctl clients -j`.
//
// If an app is not matched with its window, add it to ~/.config/quickshell/tray.json (optional):
//   { "overrides": { "<tray id>": { "class": "<window class>" } } }
// `hyprctl clients` shows the class of each window.
Singleton {
  id: root

  property var current: null     // the tray item whose options are open
  property var allClients: []    // every window, from hyprctl
  property var overrides: ({})
  property var pending: null     // what to do once the window list is fresh

  FileView {
    path: Quickshell.env("HOME") + "/.config/quickshell/tray.json"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      try { root.overrides = JSON.parse(text()).overrides || {} }
      catch (e) { root.overrides = {} }
    }
    onLoadFailed: root.overrides = {}
  }

  // ---- Finding the windows of an app ----------------------------------------

  function norm(s) {
    return (s || "").toLowerCase().replace(/[^a-z0-9]/g, "")
  }

  // Names the app may use for its windows: the tray id and title, plus your overrides
  function keysFor(item) {
    const keys = [norm(item.id), norm(item.title)]
    const o = overrides[item.id]
    if (o && o["class"]) keys.push(norm(o["class"]))
    return keys.filter(k => k.length >= 3)
  }

  // The windows that belong to a tray item, the most recently used first
  function clientsFor(item) {
    if (!item) return []
    const keys = keysFor(item)
    const exact = []
    const loose = []

    for (const c of allClients) {
      const names = [norm(c["class"]), norm(c.initialClass)].filter(n => n.length >= 3)
      if (names.some(n => keys.indexOf(n) >= 0)) exact.push(c)
      else if (names.some(n => keys.some(k => n.indexOf(k) >= 0 || k.indexOf(n) >= 0))) loose.push(c)
    }

    const found = exact.length > 0 ? exact : loose
    found.sort((a, b) => (a.focusHistoryID ?? 99) - (b.focusHistoryID ?? 99))
    return found
  }

  Process {
    id: clientsProc
    command: ["hyprctl", "clients", "-j"]
    stdout: StdioCollector {
      onStreamFinished: {
        try { root.allClients = JSON.parse(text).filter(c => c.mapped !== false) }
        catch (e) { root.allClients = [] }
        root.runPending()
      }
    }
  }

  function refresh() {
    if (!clientsProc.running) clientsProc.running = true
  }

  // ---- Talking to Hyprland (Lua syntax) -------------------------------------

  function dispatch(expression) {
    Quickshell.execDetached(["hyprctl", "dispatch", expression])
  }

  function focus(client) {
    dispatch('hl.dsp.focus({ window = "address:' + client.address + '" })')
  }

  // ---- Actions --------------------------------------------------------------

  // Left click: go to the app's window, wherever it is. Without a window, ask the app to open one.
  function open(item) {
    pending = { item: item }
    refresh()   // the window list is read again first, so it is never out of date
  }

  function runPending() {
    const p = pending
    pending = null
    if (!p) return

    const windows = clientsFor(p.item)
    Visibilities.closeAll()

    if (windows.length > 0) focus(windows[0])
    else if (p.item.onlyMenu) launch(p.item)
    else p.item.activate()
  }

  // Starts the app from its desktop entry (when it only has a menu and no window to show)
  function launch(item) {
    const keys = keysFor(item)
    let loose = null

    for (const e of DesktopEntries.applications.values) {
      const names = [norm(e.id), norm(e.name), norm(e.startupClass)].filter(n => n.length >= 3)
      if (names.some(n => keys.indexOf(n) >= 0)) { e.execute(); return }
      if (!loose && names.some(n => keys.some(k => n.indexOf(k) >= 0 || k.indexOf(n) >= 0))) loose = e
    }

    if (loose) loose.execute()
    else item.activate()
  }

  // Right click: the options panel, opening above the icon
  function openMenu(item, centerX) {
    current = item
    Visibilities.trayAnchorX = centerX
    refresh()
    Visibilities.open("traymenu")
  }

  // Ask the app's windows to close (a graceful close, many apps just hide in the tray)
  function closeWindows(item) {
    for (const c of clientsFor(item)) {
      dispatch('hl.dsp.window.close({ window = "address:' + c.address + '" })')
    }
  }

  // Kill the app (SIGKILL). With no window, the process is found by its tray name.
  function killApp(item) {
    const windows = clientsFor(item)
    if (windows.length > 0) {
      for (const c of windows) dispatch('hl.dsp.window.kill({ window = "address:' + c.address + '" })')
    } else {
      Quickshell.execDetached(["pkill", "-ix", item.id])
    }
  }
}
