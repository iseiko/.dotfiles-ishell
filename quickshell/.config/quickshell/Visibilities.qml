pragma Singleton

import Quickshell
import QtQuick

// Which popup is open. Only one can be open at a time.
Singleton {
  id: root

  property bool launcher: false
  property bool power: false
  property bool picker: false
  property bool music: false
  property bool wifi: false
  property bool bluetooth: false
  property bool menu: false
  property bool keybinds: false
  property bool clipboard: false
  property bool screenshot: false
  property bool calendar: false
  property bool traymenu: false

  // The volume/brightness panel. It pops out and hides by itself (see Osd.qml), so it is NOT part
  // of `any`: it never takes the whole screen's input.
  property bool osd: false

  readonly property var names: [
    "launcher", "power", "picker", "music", "wifi", "bluetooth",
    "menu", "keybinds", "clipboard", "screenshot", "calendar", "traymenu", "osd"
  ]

  // All the popups are pages of ONE panel (see MorphPopout.qml). This is the page that is open
  // ("" = closed). The new popup is always turned on before the old one is turned off, so the
  // panel never goes through "closed" on its way from one page to another.
  readonly property string page: wifi ? "wifi" : bluetooth ? "bluetooth"
                               : osd ? "osd" : power ? "power" : traymenu ? "traymenu"
                               : launcher ? "launcher" : menu ? "menu" : clipboard ? "clipboard"
                               : keybinds ? "keybinds" : screenshot ? "screenshot"
                               : calendar ? "calendar" : music ? "music" : picker ? "picker" : ""

  // X position (in screen pixels) of the music chip, so the music popup opens right above it
  property real musicAnchorX: 0
  // Same for the options of a background app: they open above its icon
  property real trayAnchorX: 0

  readonly property bool any: launcher || power || picker || music || wifi || bluetooth || menu || keybinds || clipboard || screenshot || calendar || traymenu
  // These popups have text input or key navigation
  readonly property bool wantsKeyboard: launcher || power || picker || wifi || menu || keybinds || clipboard || screenshot || calendar || traymenu

  function closeAll() {
    launcher = false
    power = false
    picker = false
    music = false
    wifi = false
    bluetooth = false
    menu = false
    keybinds = false
    clipboard = false
    screenshot = false
    calendar = false
    traymenu = false
    fromMenu = false
    osd = false
  }

  // True while a panel that was opened from the main menu is on screen: Esc then goes back to the
  // menu (like a tab inside it) instead of closing everything.
  property bool fromMenu: false
  // The menu is being shown again by "back", so it keeps the submenu you were in
  property bool returningToMenu: false

  // Esc in a panel
  function back() {
    if (fromMenu) {
      returningToMenu = true
      open("menu")
    } else {
      closeAll()
    }
  }

  // Opens one popup and closes the others. The new one is turned on FIRST, so a panel that
  // changes page never goes through "closed" on the way (that is what lets it morph).
  function open(name) {
    fromMenu = false
    root[name] = true
    for (const other of names) {
      if (other !== name) root[other] = false
    }
  }

  // Opens a popup, or closes everything if that popup is already open
  function toggle(name) {
    if (root[name]) closeAll()
    else open(name)
  }
}
