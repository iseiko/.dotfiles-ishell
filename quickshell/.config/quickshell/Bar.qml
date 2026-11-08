import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower
import QtQuick

// The bar: the bottom side of the frame. It has no background, the frame draws it.
Item {
  id: root

  readonly property var battery: UPower.displayDevice

  readonly property bool charging: battery.state === UPowerDeviceState.Charging
                                || battery.state === UPowerDeviceState.FullyCharged
  readonly property int batteryPercent: Math.round(battery.percentage * 100)
  readonly property string batteryLabel: {
    if (battery.state === UPowerDeviceState.FullyCharged) return "Battery - full"
    if (charging) return "Battery - charging"
    return "Battery - discharging"
  }

  // X position of the middle of the music chip, used to open the music popup right above it
  function musicCenter() {
    return musicChip.mapToItem(root, musicChip.width / 2, 0).x
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  // LEFT: launcher button + workspaces + music
  Row {
    anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 12 }
    spacing: 8

    Rectangle {
      width: 32; height: 28; radius: 8
      color: appMouse.containsMouse || Visibilities.launcher ? Theme.overlay : Theme.surface

      Text {
        anchors.centerIn: parent
        text: Icons.apps
        color: Theme.accent
        font.pixelSize: 16
      }

      MouseArea {
        id: appMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Visibilities.toggle("launcher")
      }
    }

    // Workspace row (NEED TO ADD CLICKABLE WORKSPACE BUTTON)
    Row {
      anchors.verticalCenter: parent.verticalCenter
      spacing: 4

      Repeater {
        model: 5   // workspaces 1-5

        delegate: Rectangle {
          required property int index
          readonly property int wsId: index + 1
          readonly property bool active: Hyprland.focusedWorkspace
                                      && Hyprland.focusedWorkspace.id === wsId

          width: 28; height: 28; radius: 8
          color: active ? Theme.accent : wsMouse.containsMouse ? Theme.overlay : Theme.surface

          Text {
            anchors.centerIn: parent
            text: parent.wsId
            color: parent.active ? Theme.base : Theme.text
            font.pixelSize: 14
            font.bold: parent.active
          }

          MouseArea {
            id: wsMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Quickshell.execDetached(["hyprctl", "dispatch",
                                                'hl.dsp.focus({ workspace = "' + parent.wsId + '" })'])
          }
        }
      }
    }

    // Music chip: only visible while a media player exists, click opens the music popup
    Rectangle {
      id: musicChip
      visible: Media.player !== null
      height: 28; radius: 8
      width: chipRow.implicitWidth + 16
      color: musicMouse.containsMouse || Visibilities.music ? Theme.overlay : Theme.surface

      Row {
        id: chipRow
        anchors.centerIn: parent
        spacing: 8

        // Album art thumbnail (falls back to a note icon)
        Item {
          anchors.verticalCenter: parent.verticalCenter
          width: 20; height: 20

          RoundedImage {
            anchors.fill: parent
            radius: 6
            source: Media.artUrl
            visible: status === Image.Ready
          }
          Text {
            anchors.centerIn: parent
            visible: Media.artUrl === ""
            text: Icons.music
            color: Theme.accent
            font.pixelSize: 16
          }
        }

        // Little equalizer, moves while playing
        Row {
          anchors.verticalCenter: parent.verticalCenter
          spacing: 2
          height: 14

          Repeater {
            model: 3
            delegate: Rectangle {
              required property int index
              anchors.bottom: parent.bottom
              width: 3; radius: 1.5
              height: 4
              color: Theme.accent

              SequentialAnimation on height {
                running: Media.playing
                loops: Animation.Infinite
                NumberAnimation { to: 14; duration: 380 + index * 110; easing.type: Easing.InOutSine }
                NumberAnimation { to: 4;  duration: 380 + index * 110; easing.type: Easing.InOutSine }
              }
            }
          }
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          width: Math.min(implicitWidth, 220)
          text: Media.artist !== "" ? Media.title + " - " + Media.artist : Media.title
          color: Theme.text
          font.pixelSize: 14
          elide: Text.ElideRight
        }
      }

      MouseArea {
        id: musicMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Visibilities.toggle("music")
      }
    }
  }

  // CENTER: time and date
  Row {
    anchors.centerIn: parent
    spacing: 12

    Text {
      text: Qt.formatDateTime(clock.date, "HH:mm")
      color: Theme.text
      font.pixelSize: 15
      font.bold: true
    }
    Text {
      text: Qt.formatDateTime(clock.date, "ddd, dd MMM yyyy")
      color: Theme.subtext
      font.pixelSize: 15
    }
  }

  // RIGHT: volume, battery and the logout button
  Row {
    anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 12 }
    spacing: 16

    // Volume: click = open the panel, right click = mute, scroll = change
    BarModule {
      icon: Icons.volume(Audio.volume, Audio.muted)
      iconColor: Audio.muted ? Theme.muted : Theme.accent
      value: Audio.muted ? "" : Math.round(Audio.volume * 100) + "%"
      label: Audio.muted ? "Volume - muted" : "Volume"
      active: Visibilities.osd
      onClicked: button => {
        if (button === Qt.RightButton) Audio.toggleMute()
        else Osd.toggle()
      }
      onScrolled: delta => Audio.changeVolume(delta > 0 ? 0.05 : -0.05)
    }

    // Brightness: click = open the panel, scroll = change. Hidden when there is no backlight.
    BarModule {
      visible: Brightness.available
      icon: Icons.brightness(Brightness.value)
      value: Math.round(Brightness.value * 100) + "%"
      label: "Brightness"
      active: Visibilities.osd
      onClicked: Osd.toggle()
      onScrolled: delta => Brightness.change(delta > 0 ? 5 : -5)
    }

    // Battery: only shows its label on hover
    BarModule {
      visible: root.battery.isPresent
      clickable: false
      icon: Icons.battery(root.batteryPercent, root.charging)
      iconColor: !root.charging && root.batteryPercent <= 20 ? Theme.danger
               : root.charging ? Theme.success : Theme.accent
      value: root.batteryPercent + "%"
      valueColor: !root.charging && root.batteryPercent <= 20 ? Theme.danger : Theme.text
      label: root.batteryLabel
    }

    // Logout menu button
    Rectangle {
      width: 28; height: 28; radius: 8
      color: pwrMouse.containsMouse || Visibilities.power ? Theme.overlay : Theme.surface

      Text {
        anchors.centerIn: parent
        text: Icons.power
        color: Theme.danger
        font.pixelSize: 16
      }

      MouseArea {
        id: pwrMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Visibilities.toggle("power")
      }
    }
  }
}
