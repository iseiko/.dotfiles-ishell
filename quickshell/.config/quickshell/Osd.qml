pragma Singleton

import Quickshell
import QtQuick

// Decides when the volume/brightness panel pops out and when it goes away again
Singleton {
  id: root

  property bool hovered: false   // the mouse is over the panel, so keep it open
  property bool ready: false

  // Volume and brightness change while the shell is starting, don't pop out for that
  Timer {
    interval: 3000
    running: true
    onTriggered: root.ready = true
  }

  Timer {
    id: hideTimer
    interval: 2200
    onTriggered: if (!root.hovered) Visibilities.osd = false
  }

  onHoveredChanged: if (!hovered) hideTimer.restart()

  // Called when volume or brightness changed by itself (your keybinds...). It stays out of the way
  // of the panels in the same corner, so it never interrupts a Wi-Fi password, for example.
  function notify() { if (ready) show() }

  function show() {
    if (Visibilities.power || Visibilities.wifi || Visibilities.bluetooth
        || Visibilities.keybinds) return
    Visibilities.osd = true
    hideTimer.restart()
  }

  // You asked for it (clicked the module): it takes the place of whatever is open
  function open() {
    Visibilities.open("osd")
    hideTimer.restart()
  }

  function toggle() {
    if (Visibilities.osd) Visibilities.osd = false
    else open()
  }
}
