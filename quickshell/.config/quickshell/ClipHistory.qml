pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// The clipboard history, kept by `cliphist` (https://github.com/sentriz/cliphist).
// Something has to feed it, started with Hyprland:
//   wl-paste --type text  --watch cliphist store
//   wl-paste --type image --watch cliphist store
Singleton {
  id: root

  // { id, line, preview, image, mime, info }, newest first
  property var entries: []
  property bool loaded: false

  // Previews of copied images are saved here (it is in RAM, and cleaned when you log out)
  readonly property string thumbDir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/quickshell-clipboard"

  function thumbPath(id) {
    return thumbDir + "/" + id + ".img"
  }

  // `cliphist list` prints one entry per line: "ID<TAB>preview".
  // Images look like "[[ binary data 14 KiB png 1920x1080 ]]".
  function parse(text) {
    const list = []
    for (const line of text.split("\n")) {
      const tab = line.indexOf("\t")
      if (tab < 0) continue

      const preview = line.slice(tab + 1)
      const m = preview.match(/^\[\[ binary data (.+?) (\w+) (\d+)x(\d+) \]\]$/)

      list.push({
        id: line.slice(0, tab),
        line: line,
        preview: preview,
        image: m !== null,
        mime: m ? "image/" + (m[2] === "jpg" ? "jpeg" : m[2]) : "",
        info: m ? m[2].toUpperCase() + "  " + m[3] + "x" + m[4] + "  " + m[1] : ""
      })
    }
    entries = list
    loaded = true
  }

  Process {
    id: listProc
    command: ["cliphist", "list"]
    stdout: StdioCollector {
      onStreamFinished: root.parse(text)
    }
  }

  function refresh() {
    if (!listProc.running) listProc.running = true
  }

  // Puts an entry back in the clipboard
  function copy(entry) {
    if (entry.image) {
      Quickshell.execDetached(["sh", "-c", 'cliphist decode "$0" | wl-copy --type "$1"', entry.id, entry.mime])
    } else {
      Quickshell.execDetached(["sh", "-c", 'cliphist decode "$0" | wl-copy', entry.id])
    }
  }

  Process {
    id: removeProc
    onExited: root.refresh()
  }

  function remove(entry) {
    if (!entry || removeProc.running) return
    entries = entries.filter(e => e.id !== entry.id)   // disappears right away
    removeProc.command = ["sh", "-c", 'printf "%s\\n" "$0" | cliphist delete', entry.line]
    removeProc.running = true
  }

  Process {
    id: wipeProc
    onExited: root.refresh()
  }

  function wipe() {
    if (wipeProc.running) return
    entries = []
    wipeProc.command = ["sh", "-c", 'cliphist wipe; rm -rf "$0"', thumbDir]
    wipeProc.running = true
  }
}
