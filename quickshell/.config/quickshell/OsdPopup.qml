import QtQuick

// The volume and brightness panel (content of its popout)
Item {
  id: root

  implicitWidth: 320
  implicitHeight: column.implicitHeight + 40

  // While the mouse is over the panel it stays open
  HoverHandler { id: hover }
  Binding { target: Osd; property: "hovered"; value: hover.hovered }

  Column {
    id: column
    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
    spacing: 12

    OsdSlider {
      width: parent.width
      label: "Volume"
      value: Audio.volume
      dim: Audio.muted
      valueText: Audio.muted ? "Muted" : Math.round(Audio.volume * 100) + "%"
      onMoved: v => Audio.setVolume(v)
      onLabelClicked: Audio.toggleMute()   // click the name to mute
    }

    OsdSlider {
      width: parent.width
      visible: Brightness.available
      label: "Brightness"
      value: Brightness.value
      valueText: Math.round(Brightness.value * 100) + "%"
      onMoved: v => Brightness.setPercent(v * 100)
    }
  }
}
