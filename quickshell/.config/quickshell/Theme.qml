pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  // ---- Layout of the frame --------------------------------------------------
  readonly property int border: 10          // thickness of the frame on the top, left and right
  readonly property int barHeight: 40       // the bar is the bottom side of the frame
  readonly property int rounding: 24        // roundness of the screen's inner corners
  readonly property int popoutRounding: 20  // roundness of the popups' top corners
  readonly property int fillet: 20          // size of the concave curve where a popup meets the bar

  // ---- Colors, defined by matugen and read from colors.json -----------------
  readonly property color base:    adapter.base
  readonly property color surface: adapter.surface
  readonly property color overlay: adapter.overlay
  readonly property color text:    adapter.text
  readonly property color subtext: adapter.subtext
  readonly property color muted:   adapter.muted
  readonly property color accent:  adapter.accent
  readonly property color danger:  adapter.danger
  readonly property color success: adapter.success

  FileView {
    path: Quickshell.env("HOME") + "/.config/quickshell/colors.json"
    watchChanges: true
    onFileChanged: reload()

    adapter: JsonAdapter {
      id: adapter
      // These defaults are used if the file is missing or a key is absent
      property string base:    "#1e1e2e"
      property string surface: "#313244"
      property string overlay: "#45475a"
      property string text:    "#cdd6f4"
      property string subtext: "#a6adc8"
      property string muted:   "#6c7086"
      property string accent:  "#89b4fa"
      property string danger:  "#f38ba8"
      property string success: "#a6e3a1"
    }
  }
}
