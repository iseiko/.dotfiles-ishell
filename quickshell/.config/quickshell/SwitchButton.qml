import QtQuick

// An on/off switch
Rectangle {
  id: root

  property bool checked: false
  signal toggled()

  width: 44
  height: 24
  radius: 12
  color: checked ? Theme.accent : Theme.overlay
  Behavior on color { ColorAnimation { duration: 120 } }

  Rectangle {
    width: 18; height: 18; radius: 9
    y: 3
    x: root.checked ? root.width - width - 3 : 3
    color: root.checked ? Theme.base : Theme.muted
    Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.toggled()
  }
}
