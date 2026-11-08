import QtQuick

// One row of the volume/brightness panel: name, slider and value
Item {
  id: root

  property string label: ""
  property real value: 0          // 0 to 1
  property string valueText: ""
  property bool dim: false        // draws the bar grey (used when muted)

  signal moved(real value)        // you dragged or clicked the slider
  signal labelClicked()

  implicitWidth: 280
  implicitHeight: 36

  Text {
    id: name
    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
    width: 84
    text: root.label
    color: Theme.text
    font.pixelSize: 14

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: root.labelClicked()
    }
  }

  Text {
    id: amount
    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
    width: 48
    horizontalAlignment: Text.AlignRight
    text: root.valueText
    color: Theme.subtext
    font.pixelSize: 13
  }

  Item {
    id: slider
    anchors {
      left: name.right; right: amount.left; verticalCenter: parent.verticalCenter
      leftMargin: 8; rightMargin: 8
    }
    height: 22

    property bool dragging: false
    property real dragValue: 0
    readonly property real shown: Math.max(0, Math.min(1, dragging ? dragValue : root.value))

    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width
      height: area.containsMouse || slider.dragging ? 10 : 8
      radius: height / 2
      color: Theme.overlay
      Behavior on height { NumberAnimation { duration: 100 } }

      Rectangle {
        width: parent.width * slider.shown
        height: parent.height
        radius: parent.radius
        color: root.dim ? Theme.muted : Theme.accent
      }
    }

    MouseArea {
      id: area
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor

      function at(x) { return Math.max(0, Math.min(1, x / width)) }

      onPressed: mouse => {
        slider.dragging = true
        slider.dragValue = at(mouse.x)
        root.moved(slider.dragValue)
      }
      onPositionChanged: mouse => {
        if (!slider.dragging) return
        slider.dragValue = at(mouse.x)
        root.moved(slider.dragValue)
      }
      onReleased: slider.dragging = false
      onCanceled: slider.dragging = false
    }
  }
}
