import QtQuick
import Quickshell

// The Wi-Fi panel (content of its popout)
Item {
  id: root

  implicitWidth: 360
  implicitHeight: column.implicitHeight + 40

  // Every time it opens: look for networks again
  Connections {
    target: Visibilities
    function onWifiChanged() {
      if (!Visibilities.wifi) return
      Wifi.error = ""
      Wifi.refresh()
      Wifi.refreshSaved()
      Wifi.rescan()
      Qt.callLater(() => root.forceActiveFocus())
    }
  }

  Keys.onEscapePressed: Visibilities.closeAll()

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
        text: "Wi-Fi"
        color: Theme.text
        font.pixelSize: 18
        font.bold: true
      }

      Row {
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        spacing: 10

        SmallButton {
          anchors.verticalCenter: parent.verticalCenter
          visible: Wifi.enabled
          enabled: !Wifi.scanning
          text: Wifi.scanning ? "Scanning..." : "Scan"
          onClicked: Wifi.rescan()
        }
        SwitchButton {
          anchors.verticalCenter: parent.verticalCenter
          checked: Wifi.enabled
          onToggled: Wifi.setEnabled(!Wifi.enabled)
        }
      }
    }

    // Why the last connection failed
    Text {
      width: parent.width
      visible: Wifi.error !== ""
      text: Wifi.error
      color: Theme.danger
      font.pixelSize: 13
      wrapMode: Text.Wrap
    }

    Text {
      width: parent.width
      visible: !Wifi.enabled
      text: "Wi-Fi is turned off"
      color: Theme.muted
      font.pixelSize: 14
    }

    Text {
      width: parent.width
      visible: Wifi.enabled && Wifi.networks.length === 0
      text: Wifi.scanning ? "Looking for networks..." : "No networks found"
      color: Theme.muted
      font.pixelSize: 14
    }

    ListView {
      id: list
      width: parent.width
      height: Math.min(contentHeight, 320)
      visible: Wifi.enabled
      clip: true
      spacing: 4
      boundsBehavior: Flickable.StopAtBounds

      // objectProp keeps the rows (and a half-typed password) when the list refreshes
      model: ScriptModel {
        values: Wifi.networks
        objectProp: "ssid"
      }

      delegate: Rectangle {
        id: row
        required property var modelData

        property bool asking: false   // the password box is open
        readonly property bool busy: Wifi.connecting && Wifi.connectingSsid === modelData.ssid

        width: ListView.view.width
        height: rowColumn.implicitHeight
        radius: 10
        color: modelData.active ? Theme.overlay : mouse.containsMouse ? Theme.surface : "transparent"

        function activate() {
          if (modelData.active) return
          if (modelData.saved || !modelData.secure) {
            asking = false
            Wifi.connect(modelData.ssid, "")
          } else {
            asking = !asking
            if (asking) Qt.callLater(() => password.forceActiveFocus())
          }
        }

        function submit() {
          if (password.text === "") return
          Wifi.connect(modelData.ssid, password.text)
          password.text = ""
          asking = false
        }

        Column {
          id: rowColumn
          width: parent.width

          // The network
          Item {
            width: parent.width
            height: 44

            MouseArea {
              id: mouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: row.activate()
            }

            Text {
              id: signalIcon
              anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
              text: Icons.wifi(row.modelData.strength)
              color: row.modelData.active ? Theme.accent : Theme.text
              font.pixelSize: 18
            }

            Text {
              anchors {
                left: signalIcon.right; leftMargin: 10
                right: actions.left; rightMargin: 8
                verticalCenter: parent.verticalCenter
              }
              text: row.modelData.ssid
              color: Theme.text
              font.pixelSize: 14
              font.bold: row.modelData.active
              elide: Text.ElideRight
            }

            Row {
              id: actions
              anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
              spacing: 8

              Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: row.modelData.secure && !row.modelData.active && !row.modelData.saved
                text: Icons.lock
                color: Theme.muted
                font.pixelSize: 14
              }
              Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: row.busy
                text: "Connecting..."
                color: Theme.subtext
                font.pixelSize: 12
              }
              Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: row.modelData.active && !row.busy
                text: "Connected"
                color: Theme.success
                font.pixelSize: 12
              }
              SmallButton {
                anchors.verticalCenter: parent.verticalCenter
                visible: row.modelData.active
                text: "Disconnect"
                onClicked: Wifi.disconnect(row.modelData.ssid)
              }
              SmallButton {
                anchors.verticalCenter: parent.verticalCenter
                visible: row.modelData.saved && !row.modelData.active
                text: "Forget"
                onClicked: Wifi.forget(row.modelData.ssid)
              }
            }
          }

          // The password box, for secured networks that are not saved yet
          Item {
            width: parent.width
            height: 44
            visible: row.asking

            Rectangle {
              anchors {
                left: parent.left; leftMargin: 12
                right: connectButton.left; rightMargin: 8
                verticalCenter: parent.verticalCenter
              }
              height: 32
              radius: 8
              color: Theme.surface

              TextInput {
                id: password
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                color: Theme.text
                font.pixelSize: 14
                clip: true
                onAccepted: row.submit()
                Keys.onEscapePressed: row.asking = false
              }

              Text {
                anchors.fill: password
                verticalAlignment: Text.AlignVCenter
                visible: password.text === ""
                text: "Password"
                color: Theme.muted
                font.pixelSize: 14
              }
            }

            SmallButton {
              id: connectButton
              anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
              accent: true
              text: "Connect"
              onClicked: row.submit()
            }
          }
        }
      }
    }
  }
}
