import QtQuick
import Quickshell
import Quickshell.Bluetooth

// The Bluetooth panel (content of its popout)
Item {
  id: root

  readonly property var adapter: Bluetooth.defaultAdapter

  // Devices saved on this machine, connected ones first
  readonly property var saved: Bluetooth.devices.values
    .filter(d => d.paired || d.bonded)
    .sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))

  // Devices found nearby that are not saved. Ones without a name (just an address) are hidden.
  readonly property var nearby: Bluetooth.devices.values
    .filter(d => !(d.paired || d.bonded) && d.name !== "" && !/^([0-9a-f]{2}[:-]){5}[0-9a-f]{2}$/i.test(d.name))
    .sort((a, b) => a.name.localeCompare(b.name))

  // Addresses of the devices we are pairing and want to connect to as soon as that works
  property var pending: []

  implicitWidth: 380
  implicitHeight: column.implicitHeight + 40

  Keys.onEscapePressed: Visibilities.closeAll()

  // Search for devices only while the panel is open
  Connections {
    target: Visibilities
    function onBluetoothChanged() {
      if (root.adapter) root.adapter.discovering = Visibilities.bluetooth && root.adapter.enabled
      if (Visibilities.bluetooth) Qt.callLater(() => root.forceActiveFocus())
    }
  }
  Connections {
    target: root.adapter
    function onEnabledChanged() {
      if (Visibilities.bluetooth && root.adapter.enabled) root.adapter.discovering = true
    }
  }

  // After a device is paired: trust it and connect (the row itself moves to the other list
  // when pairing finishes, so this is done here)
  Repeater {
    model: Bluetooth.devices
    delegate: Item {
      required property var modelData
      Connections {
        target: modelData
        function onPairedChanged() {
          if (!modelData.paired || root.pending.indexOf(modelData.address) < 0) return
          root.pending = root.pending.filter(a => a !== modelData.address)
          modelData.trusted = true
          modelData.connect()
        }
      }
    }
  }

  Column {
    id: column
    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
    spacing: 12

    // Title, scan button and the on/off switch
    Item {
      width: parent.width
      height: 30

      Text {
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        text: "Bluetooth"
        color: Theme.text
        font.pixelSize: 18
        font.bold: true
      }

      Row {
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        spacing: 10

        SmallButton {
          anchors.verticalCenter: parent.verticalCenter
          visible: root.adapter && root.adapter.enabled
          text: root.adapter && root.adapter.discovering ? "Stop" : "Scan"
          onClicked: root.adapter.discovering = !root.adapter.discovering
        }
        SwitchButton {
          anchors.verticalCenter: parent.verticalCenter
          checked: root.adapter ? root.adapter.enabled : false
          onToggled: root.adapter.enabled = !root.adapter.enabled
        }
      }
    }

    Text {
      width: parent.width
      visible: root.adapter && !root.adapter.enabled
      text: "Bluetooth is turned off"
      color: Theme.muted
      font.pixelSize: 14
    }

    // Saved devices
    Text {
      visible: root.adapter && root.adapter.enabled && root.saved.length > 0
      text: "My devices"
      color: Theme.muted
      font.pixelSize: 12
      font.bold: true
    }
    ListView {
      width: parent.width
      height: Math.min(contentHeight, 208)
      visible: root.adapter && root.adapter.enabled
      clip: true
      spacing: 4
      boundsBehavior: Flickable.StopAtBounds
      model: ScriptModel { values: root.saved }
      delegate: BluetoothRow {
        required property var modelData
        width: ListView.view.width
        device: modelData
        known: true
      }
    }

    // Devices around you
    Text {
      visible: root.adapter && root.adapter.enabled
      text: root.adapter && root.adapter.discovering ? "Available devices - searching..." : "Available devices"
      color: Theme.muted
      font.pixelSize: 12
      font.bold: true
    }
    Text {
      width: parent.width
      visible: root.adapter && root.adapter.enabled && root.nearby.length === 0
      text: "Nothing found yet. Put your device in pairing mode."
      color: Theme.muted
      font.pixelSize: 13
      wrapMode: Text.Wrap
    }
    ListView {
      width: parent.width
      height: Math.min(contentHeight, 208)
      visible: root.adapter && root.adapter.enabled
      clip: true
      spacing: 4
      boundsBehavior: Flickable.StopAtBounds
      model: ScriptModel { values: root.nearby }
      delegate: BluetoothRow {
        required property var modelData
        width: ListView.view.width
        device: modelData
        onPairRequested: {
          root.pending = root.pending.concat([modelData.address])
          modelData.pair()
        }
      }
    }
  }
}
