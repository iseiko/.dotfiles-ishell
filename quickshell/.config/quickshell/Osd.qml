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

  // Called when volume or brightness changed
  function notify() { if (ready) show() }

  function show() {
    if (Visibilities.power) return   // the power menu uses the same corner
    Visibilities.osd = true
    hideTimer.restart()
  }

  function toggle() {
    if (Visibilities.osd) Visibilities.osd = false
    else show()
  }
}
