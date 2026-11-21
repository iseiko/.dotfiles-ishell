pragma Singleton

import Quickshell
import QtQuick

// A screenshot waiting for you to choose what to do with it.
// scripts/screenshot.sh takes the picture, then calls `qs ipc call screenshot show <file> <mode>`.
Singleton {
  id: root

  property string path: ""          // the temporary picture
  property string mode: "region"    // how it was taken, used by "Retake"
  property bool pending: false

  readonly property string scripts: Quickshell.env("HOME") + "/.config/quickshell/scripts"

  function show(file, captureMode) {
    if (pending && path !== "") Quickshell.execDetached(["rm", "-f", path])
    path = file
    mode = captureMode || "region"
    pending = true
    Visibilities.closeAll()
    Visibilities.screenshot = true
  }

  // Save and/or copy the picture, then close the panel
  function finish(save, copy) {
    if (!pending) return
    pending = false
    Quickshell.execDetached(["bash", scripts + "/screenshot-finish.sh", path, save ? "1" : "0", copy ? "1" : "0"])
    Visibilities.closeAll()
  }

  function discard() {
    if (pending) Quickshell.execDetached(["rm", "-f", path])
    pending = false
    Visibilities.closeAll()
  }

  // Throw this one away and select an area again
  function retake() {
    const again = mode
    discard()
    Quickshell.execDetached(["bash", scripts + "/screenshot.sh", again, "ask"])
  }

  // Closing the panel any other way (clicking outside of it) also throws the picture away
  Connections {
    target: Visibilities
    function onScreenshotChanged() {
      if (!Visibilities.screenshot && root.pending) {
        Quickshell.execDetached(["rm", "-f", root.path])
        root.pending = false
      }
    }
  }
}
