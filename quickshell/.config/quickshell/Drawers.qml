import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// Everything that lives on the screen: the frame, the bar and the popups.
// It is ONE transparent fullscreen window. The frame is drawn on it, and only the frame, the bar and
// the open popups take mouse input, everything else clicks through to your apps.
Scope {
  id: root

  // ---- Reserve space so your windows don't go under the frame ---------------
  component Zone: PanelWindow {
    exclusionMode: ExclusionMode.Normal
    color: "transparent"
    mask: Region {}        // no input at all
    implicitWidth: 1
    implicitHeight: 1
  }
  Zone { anchors.top: true;    exclusiveZone: Theme.border }
  Zone { anchors.left: true;   exclusiveZone: Theme.border }
  Zone { anchors.right: true;  exclusiveZone: Theme.border }
  Zone { anchors.bottom: true; exclusiveZone: Theme.barHeight }

  // ---- Keybinds: qs ipc call <target> <function> ----------------------------
  IpcHandler {
    target: "launcher"
    function toggle(): void { Visibilities.toggle("launcher") }
  }
  IpcHandler {
    target: "power"
    function toggle(): void { Visibilities.toggle("power") }
  }
  IpcHandler {
    target: "picker"
    function toggle(): void { Visibilities.toggle("picker") }
  }
  IpcHandler {
    target: "music"
    function toggle(): void { if (Media.player) Visibilities.toggle("music") }
    function playpause(): void { if (Media.player) Media.player.togglePlaying() }
    function next(): void { if (Media.player) Media.player.next() }
    function previous(): void { if (Media.player) Media.player.previous() }
  }

  // The main menu and the keybinds panel: `qs ipc call menu toggle`, `qs ipc call keybinds toggle`
  // Called by scripts/screenshot.sh once the picture is taken
  IpcHandler {
    target: "screenshot"
    function show(path: string, mode: string): void { Screenshot.show(path, mode) }
  }

  // The clipboard history: `qs ipc call clipboard toggle`
  IpcHandler {
    target: "clipboard"
    function toggle(): void { Visibilities.toggle("clipboard") }
  }
  // The calendar: `qs ipc call calendar toggle`
  IpcHandler {
    target: "calendar"
    function toggle(): void { Visibilities.toggle("calendar") }
  }
  IpcHandler {
    target: "menu"
    function toggle(): void { Visibilities.toggle("menu") }
  }
  IpcHandler {
    target: "keybinds"
    function toggle(): void { Visibilities.toggle("keybinds") }
  }
  IpcHandler {
    target: "wifi"
    function toggle(): void { Visibilities.toggle("wifi") }
  }
  IpcHandler {
    target: "bluetooth"
    function toggle(): void { Visibilities.toggle("bluetooth") }
  }

  // Volume and brightness. Keybinds can call these, e.g. `qs ipc call osd volumeUp`
  IpcHandler {
    target: "osd"
    function show(): void { Osd.open() }
    function volumeUp(): void { Audio.changeVolume(0.05) }
    function volumeDown(): void { Audio.changeVolume(-0.05) }
    function volumeMute(): void { Audio.toggleMute() }
    function brightnessUp(): void { Brightness.change(5) }
    function brightnessDown(): void { Brightness.change(-5) }
    function nightlight(): void { Hyprsunset.toggle() }
    function nightToggle(): void { Night.toggle() }
  }

  // Remember where the music chip is whenever the music popup opens
  Connections {
    target: Visibilities
    function onMusicChanged() {
      if (Visibilities.music) Visibilities.musicAnchorX = bar.musicCenter()
    }
  }

  // Input regions. Normally only the frame, the bar and the open popups catch the mouse.
  // While a popup is open the whole screen does, so a click anywhere outside the popup closes it.
  Region {
    id: fullMask
    x: 0; y: 0
    width: win.width
    height: win.height
  }
  Region {
    id: frameMask
    regions: [
      Region { x: 0; y: 0; width: win.width; height: Theme.border },
      Region { x: 0; y: 0; width: Theme.border; height: win.height },
      Region { x: win.width - Theme.border; y: 0; width: Theme.border; height: win.height },
      Region { x: 0; y: win.height - Theme.barHeight; width: win.width; height: Theme.barHeight },
      Region { item: mainPanel },
      Region { item: notifPopout }
    ]
  }

  // ---- The window ------------------------------------------------------------
  PanelWindow {
    id: win
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    // Keyboard only while a popup that needs it is open, so it never steals keys from your apps
    WlrLayershell.keyboardFocus: Visibilities.wantsKeyboard ? WlrKeyboardFocus.Exclusive
                                                            : WlrKeyboardFocus.None

    mask: Visibilities.any ? fullMask : frameMask

    Item {
      id: scene
      anchors.fill: parent

      // Y of the bar's top edge, and the closest a popup may get to the screen's rounded corners
      readonly property real barTop: height - Theme.barHeight
      readonly property real inset: Theme.border + Theme.rounding + Theme.fillet

      ScreenFrame { anchors.fill: parent }

      // Catches clicks outside the popups and closes them
      MouseArea {
        anchors.fill: parent
        enabled: Visibilities.any
        onClicked: Visibilities.closeAll()
      }

      // ---- Popups (drawn under the bar so the bar's buttons stay visible) ----
      //
      // Every popup is a page of ONE panel. Opening another popup makes the panel move and change
      // shape into it (wherever it is), instead of closing and opening again.
      MorphPopout {
        id: mainPanel
        current: Visibilities.page
        attachX: scene.width - Theme.border
        attachY: scene.barTop
        sceneWidth: scene.width
        inset: scene.inset
        maxHeight: scene.barTop - Theme.border - 24

        // In the bottom-right corner, against the frame
        MorphPage { panel: mainPanel; name: "wifi"; corner: true; WifiPopup { anchors.fill: parent } }
        MorphPage { panel: mainPanel; name: "bluetooth"; corner: true; BluetoothPopup { anchors.fill: parent } }
        MorphPage { panel: mainPanel; name: "osd"; corner: true; OsdPopup { anchors.fill: parent } }
        MorphPage { panel: mainPanel; name: "power"; corner: true; PowerPopup { anchors.fill: parent } }
        MorphPage { panel: mainPanel; name: "traymenu"; corner: true; TrayMenuPopup { anchors.fill: parent } }

        // Drawers from the bar, in the middle
        MorphPage {
          panel: mainPanel; name: "launcher"
          LauncherPopup { anchors.fill: parent; implicitWidth: 600; implicitHeight: 650 }
        }
        MorphPage { panel: mainPanel; name: "menu"; MenuPopup { anchors.fill: parent } }
        MorphPage { panel: mainPanel; name: "clipboard"; ClipboardPopup { anchors.fill: parent } }
        MorphPage {
          panel: mainPanel; name: "keybinds"
          KeybindsPopup { anchors.fill: parent; implicitHeight: 640 }
        }
        MorphPage { panel: mainPanel; name: "screenshot"; ScreenshotPopup { anchors.fill: parent } }
        MorphPage { panel: mainPanel; name: "calendar"; CalendarPopup { anchors.fill: parent } }
        MorphPage {
          panel: mainPanel; name: "picker"
          WallpaperPopup {
            anchors.fill: parent
            implicitWidth: Math.min(1100, scene.width - scene.inset * 2)
            implicitHeight: 200
          }
        }

        // Above its icon in the bar
        MorphPage {
          panel: mainPanel; name: "music"
          anchorX: Visibilities.musicAnchorX
          MusicPopup { anchors.fill: parent }
        }
      }

      // Notifications: hang from the top border in the top-right corner
      TopPopout {
        id: notifPopout
        attachY: Theme.border
        shown: notifs.count > 0
        fullWidth: notifs.implicitWidth
        fullHeight: Math.min(notifs.implicitHeight, scene.barTop - Theme.border - 40)
        x: scene.width - Theme.border - width

        NotificationsPopup { id: notifs; anchors.fill: parent }
      }

      // ---- The bar, on top of everything ----
      Bar {
        id: bar
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: Theme.barHeight
      }
    }
  }
}
