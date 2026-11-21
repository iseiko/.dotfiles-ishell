pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Your keybinds, read from ~/.config/quickshell/keybinds.json (it reloads when you save the file).
//
//   { "categories": [
//       { "name": "Windows", "binds": [ { "keys": ["SUPER", "Q"], "desc": "Close window" } ] }
//   ] }
Singleton {
  id: root

  property var categories: []
  property string error: ""

  FileView {
    path: Quickshell.env("HOME") + "/.config/quickshell/keybinds.json"
    watchChanges: true
    onFileChanged: reload()

    onLoaded: {
      try {
        const data = JSON.parse(text())
        root.categories = data.categories || []
        root.error = ""
      } catch (e) {
        root.error = "keybinds.json has a mistake: " + e.message
      }
    }
    onLoadFailed: root.error = "Could not read ~/.config/quickshell/keybinds.json"
  }

  // A flat list for the panel: a header row for each category, then its keybinds.
  // Only keybinds that contain `query` (in their keys, description or category) are kept.
  function flatten(query) {
    const q = (query || "").toLowerCase().trim()
    const rows = []

    for (const category of categories) {
      const categoryName = category.name || ""
      const binds = (category.binds || []).filter(b =>
        q === ""
        || (b.desc || "").toLowerCase().includes(q)
        || (b.keys || []).join(" ").toLowerCase().includes(q)
        || categoryName.toLowerCase().includes(q))

      if (binds.length === 0) continue

      rows.push({ header: true, name: categoryName })
      for (const b of binds) {
        rows.push({ header: false, name: categoryName, keys: b.keys || [], desc: b.desc || "" })
      }
    }
    return rows
  }
}
