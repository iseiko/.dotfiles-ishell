import QtQuick

// A small button for the bar: an icon, an optional value, and a label that shows on hover
Rectangle {
  id: root

  property string icon: ""
  property string value: ""        // shown next to the icon, e.g. "45%"
  property string label: ""        // shown above the bar while the mouse is over it
  property color iconColor: Theme.accent
  property color valueColor: Theme.text
  property bool active: false      // draws it highlighted (e.g. while its popup is open)
  property bool clickable: true

  signal clicked(int button)       // Qt.LeftButton, Qt.RightButton...
  signal scrolled(real delta)      // positive = scrolled up

  height: 28
  radius: 8
  width: row.implicitWidth + 16
  color: area.containsMouse && clickable || active ? Theme.overlay : Theme.surface

  Row {
    id: row
    anchors.centerIn: parent
    spacing: 6

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.icon
      color: root.iconColor
      font.pixelSize: 16
    }
    Text {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.value !== ""
      text: root.value
      color: root.valueColor
      font.pixelSize: 14
    }
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: mouse => root.clicked(mouse.button)
    onWheel: wheel => root.scrolled(wheel.angleDelta.y)
  }

  // The hover label, drawn just above the bar
  Rectangle {
    visible: opacity > 0
    opacity: area.containsMouse && root.label !== "" ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 120 } }

    x: (root.width - width) / 2
    y: -height - 12
    width: tipText.implicitWidth + 20
    height: tipText.implicitHeight + 12
    radius: 8
    color: Theme.base
    border.width: 1
    border.color: Theme.overlay

    Text {
      id: tipText
      anchors.centerIn: parent
      text: root.label
      color: Theme.text
      font.pixelSize: 13
    }
  }
}
