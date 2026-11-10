import QtQuick

// A small text button for the popups
Rectangle {
  id: root

  property string text: ""
  property bool accent: false   // the main action: drawn in the accent color
  signal clicked()

  height: 26
  width: label.implicitWidth + 20
  radius: 8
  opacity: enabled ? 1 : 0.5
  color: area.containsMouse && enabled
         ? (accent ? Qt.lighter(Theme.accent, 1.15) : Theme.overlay)
         : (accent ? Theme.accent : Theme.surface)

  Text {
    id: label
    anchors.centerIn: parent
    text: root.text
    color: root.accent ? Theme.base : Theme.text
    font.pixelSize: 12
  }

  MouseArea {
    id: area
    anchors.fill: parent
    enabled: root.enabled
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
