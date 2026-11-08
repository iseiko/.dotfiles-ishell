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

  // The volume/brightness panel. It pops out and hides by itself (see Osd.qml), so it is NOT part
  // of `any`: it never takes the whole screen's input.
  property bool osd: false

  // X position (in screen pixels) of the music chip, so the music popup opens right above it
  property real musicAnchorX: 0

  readonly property bool any: launcher || power || picker || music
  // These popups have text input or key navigation
  readonly property bool wantsKeyboard: launcher || power || picker

  function closeAll() {
    launcher = false
    power = false
    picker = false
    music = false
    osd = false
  }

  // Opens one popup (closing the others). Calling it for the popup that is already open closes it.
  function toggle(name) {
    const wasOpen = root[name]
    closeAll()
    root[name] = !wasOpen
  }
}
