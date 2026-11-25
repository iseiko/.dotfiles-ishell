pragma Singleton

import Quickshell
import QtQuick

// Decides when the volume panel and the brightness panel pop out, and when they go away again.
// `kind` is always "volume" or "brightness".
Singleton {
  id: root

  // The mouse is over one of the panels, so it stays open
  property bool hoveredVolume: false
  property bool hoveredBrightness: false
  readonly property bool hovered: hoveredVolume || hoveredBrightness

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
    onTriggered: {
      if (root.hovered) return
      Visibilities.volume = false
      Visibilities.brightness = false
    }
  }

  onHoveredChanged: if (!hovered) hideTimer.restart()

  // Called when the volume or the brightness changed by itself (your keybinds, the night light...).
  // It stays out of the way of the panels in the same corner, so it never interrupts a Wi-Fi
  // password, for example.
  function notify(kind) { if (ready) show(kind) }

  function show(kind) {
    if (Visibilities.power || Visibilities.wifi || Visibilities.bluetooth
        || Visibilities.keybinds || Visibilities.traymenu) return

    // If the other one is showing, change into this one (the new one is turned on first)
    const other = kind === "volume" ? "brightness" : "volume"
    Visibilities[kind] = true
    Visibilities[other] = false
    hideTimer.restart()
  }

  // You asked for it (clicked the module): it takes the place of whatever is open
  function open(kind) {
    Visibilities.open(kind)
    hideTimer.restart()
  }

  function toggle(kind) {
    if (Visibilities[kind]) Visibilities[kind] = false
    else open(kind)
  }
}
