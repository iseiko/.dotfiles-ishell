import QtQuick
import Quickshell

// The logout menu (content of its popout)
Item {
  id: root
  property int currentIndex: 0

  implicitWidth: row.implicitWidth + 40
  implicitHeight: row.implicitHeight + 40

  // The options you can choose when pressing the power button
  readonly property var actions: [
    { label: "Lock",      icon: Icons.lock,      cmd: ["qs", "ipc", "call", "lock", "lock"] },
    { label: "Suspend",   icon: Icons.suspend,   cmd: ["systemctl", "suspend"] },
    { label: "Hibernate", icon: Icons.hibernate, cmd: ["systemctl", "hibernate"] },
    { label: "Reboot",    icon: Icons.reboot,    cmd: ["systemctl", "soft-reboot"] },
    { label: "Shutdown",  icon: Icons.power,     cmd: ["systemctl", "poweroff"] }
  ]

  function run(action) {
    Visibilities.closeAll()
    Quickshell.execDetached(action.cmd)
  }

  Connections {
    target: Visibilities
    function onPowerChanged() {
      if (!Visibilities.power) return
      root.currentIndex = 0
      Qt.callLater(() => root.forceActiveFocus())
    }
  }

  Keys.onEscapePressed: Visibilities.closeAll()
  Keys.onLeftPressed:  currentIndex = Math.max(0, currentIndex - 1)
  Keys.onRightPressed: currentIndex = Math.min(actions.length - 1, currentIndex + 1)
  Keys.onReturnPressed: run(actions[currentIndex])
  Keys.onEnterPressed:  run(actions[currentIndex])

  Row {
    id: row
    anchors.centerIn: parent
    spacing: 12

    Repeater {
      model: root.actions

      delegate: Rectangle {
        required property var modelData
        required property int index

        width: 104; height: 104; radius: 16
        color: root.currentIndex === index ? Theme.overlay : Theme.surface
        border.width: root.currentIndex === index ? 2 : 0
        border.color: modelData.label === "Shutdown" ? Theme.danger : Theme.accent

        Column {
          anchors.centerIn: parent
          spacing: 8

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: modelData.icon
            color: Theme.text
            font.pixelSize: 34
          }
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: modelData.label
            color: Theme.text
            font.pixelSize: 14
          }
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: root.currentIndex = index
          onClicked: root.run(modelData)
        }
      }
    }
  }
}
