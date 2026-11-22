import QtQuick

// A row in a panel's list: a line of text, an optional smaller line under it, and a click
Rectangle {
  id: root

  property string text: ""
  property string subtitle: ""
  property bool danger: false
  signal triggered()

  height: subtitle !== "" ? 50 : 40
  radius: 8
  opacity: enabled ? 1 : 0.45
  color: area.containsMouse && enabled ? Theme.overlay : "transparent"

  Column {
    anchors {
      left: parent.left; right: parent.right
      leftMargin: 12; rightMargin: 12
      verticalCenter: parent.verticalCenter
    }

    Text {
      width: parent.width
      text: root.text
      color: root.danger ? Theme.danger : Theme.text
      font.pixelSize: 14
      elide: Text.ElideRight
    }
    Text {
      width: parent.width
      visible: root.subtitle !== ""
      text: root.subtitle
      color: Theme.muted
      font.pixelSize: 12
      elide: Text.ElideRight
    }
  }

  MouseArea {
    id: area
    anchors.fill: parent
    enabled: root.enabled
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.triggered()
  }
}
