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
    function show(): void { Osd.show() }
    function volumeUp(): void { Audio.changeVolume(0.05) }
    function volumeDown(): void { Audio.changeVolume(-0.05) }
    function volumeMute(): void { Audio.toggleMute() }
    function brightnessUp(): void { Brightness.change(5) }
    function brightnessDown(): void { Brightness.change(-5) }
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
      Region { item: launcherPopout },
      Region { item: pickerPopout },
      Region { item: powerPopout },
      Region { item: musicPopout },
      Region { item: notifPopout },
      Region { item: osdPopout },
      Region { item: wifiPopout },
      Region { item: bluetoothPopout }
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

      // ---- Popups (they are drawn under the bar so the bar's buttons stay visible) ----

      Popout {
        id: launcherPopout
        attachY: scene.barTop
        shown: Visibilities.launcher
        fullWidth: 600
        fullHeight: Math.min(650, scene.barTop - Theme.border - 24)
        x: (scene.width - width) / 2

        LauncherPopup { anchors.fill: parent }
      }

      Popout {
        id: pickerPopout
        attachY: scene.barTop
        shown: Visibilities.picker
        fullWidth: Math.min(1100, scene.width - scene.inset * 2)
        fullHeight: 200
        x: (scene.width - width) / 2

        WallpaperPopup { anchors.fill: parent }
      }

      Popout {
        id: powerPopout
        attachY: scene.barTop
        shown: Visibilities.power
        fullWidth: powerContent.implicitWidth
        fullHeight: powerContent.implicitHeight
        attachRight: true                           // touches the right border and the bar
        x: scene.width - Theme.border - width

        PowerPopup { id: powerContent; anchors.fill: parent }
      }

      Popout {
        id: musicPopout
        attachY: scene.barTop
        shown: Visibilities.music
        fullWidth: musicContent.implicitWidth
        fullHeight: musicContent.implicitHeight
        x: Math.max(scene.inset, Math.min(Visibilities.musicAnchorX - width / 2,
                                          scene.width - width - scene.inset))

        MusicPopup { id: musicContent; anchors.fill: parent }
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

      // Volume and brightness: bottom-right corner, same place as the power menu
      Popout {
        id: osdPopout
        attachY: scene.barTop
        attachRight: true
        shown: Visibilities.osd
        fullWidth: osdContent.implicitWidth
        fullHeight: osdContent.implicitHeight
        x: scene.width - Theme.border - width

        OsdPopup { id: osdContent; anchors.fill: parent }
      }

      // Wi-Fi and Bluetooth: bottom-right corner, same place as the power menu
      Popout {
        id: wifiPopout
        attachY: scene.barTop
        attachRight: true
        shown: Visibilities.wifi
        fullWidth: wifiContent.implicitWidth
        fullHeight: Math.min(wifiContent.implicitHeight, scene.barTop - Theme.border - 24)
        x: scene.width - Theme.border - width

        WifiPopup { id: wifiContent; anchors.fill: parent }
      }

      Popout {
        id: bluetoothPopout
        attachY: scene.barTop
        attachRight: true
        shown: Visibilities.bluetooth
        fullWidth: bluetoothContent.implicitWidth
        fullHeight: Math.min(bluetoothContent.implicitHeight, scene.barTop - Theme.border - 24)
        x: scene.width - Theme.border - width

        BluetoothPopup { id: bluetoothContent; anchors.fill: parent }
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
