import QtQuick
import Quickshell
import Quickshell.Bluetooth

// One device in the Bluetooth panel
Rectangle {
  id: root

  required property var device
  property bool known: false     // already paired: shows Connect / Forget, otherwise Pair
  signal pairRequested()

  readonly property bool connecting: device.state === BluetoothDeviceState.Connecting
  readonly property bool busy: connecting || device.pairing
                               || device.state === BluetoothDeviceState.Disconnecting

  readonly property string statusText: {
    if (device.pairing) return "Pairing..."
    if (connecting) return "Connecting..."
    if (device.connected) {
      return device.batteryAvailable ? "Connected - " + Math.round(device.battery * 100) + "%"
                                     : "Connected"
    }
    return known ? "Not connected" : ""
  }

  height: 52
  radius: 10
  color: device.connected ? Theme.overlay : hover.hovered ? Theme.surface : "transparent"

  HoverHandler { id: hover }

  // Device icon (falls back to the Bluetooth symbol)
  Item {
    id: iconBox
    anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
    width: 28; height: 28

    Image {
      id: deviceIcon
      anchors.fill: parent
      source: root.device.icon !== "" ? Quickshell.iconPath(root.device.icon, true) : ""
      sourceSize: Qt.size(56, 56)
      asynchronous: true
      visible: status === Image.Ready
    }
    Text {
      anchors.centerIn: parent
      visible: deviceIcon.status !== Image.Ready
      text: Icons.bluetooth
      color: root.device.connected ? Theme.accent : Theme.muted
      font.pixelSize: 20
    }
  }

  Column {
    anchors {
      left: iconBox.right; leftMargin: 12
      right: actions.left; rightMargin: 8
      verticalCenter: parent.verticalCenter
    }

    Text {
      width: parent.width
      text: root.device.name
      color: Theme.text
      font.pixelSize: 14
      font.bold: root.device.connected
      elide: Text.ElideRight
    }
    Text {
      width: parent.width
      visible: text !== ""
      text: root.statusText
      color: Theme.subtext
      font.pixelSize: 12
      elide: Text.ElideRight
    }
  }

  Row {
    id: actions
    anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
    spacing: 8

    SmallButton {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.known
      enabled: !root.busy
      accent: !root.device.connected
      text: root.device.connected ? "Disconnect" : "Connect"
      onClicked: {
        if (root.device.connected) root.device.disconnect()
        else root.device.connect()
      }
    }
    SmallButton {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.known
      text: "Forget"
      onClicked: root.device.forget()
    }
    SmallButton {
      anchors.verticalCenter: parent.verticalCenter
      visible: !root.known
      enabled: !root.busy
      accent: true
      text: root.device.pairing ? "Pairing..." : "Pair"
      onClicked: root.pairRequested()
    }
  }
}
