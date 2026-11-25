import QtQuick

// The brightness panel, with the night light (content of its popout)
Item {
  id: root

  implicitWidth: 320
  implicitHeight: column.implicitHeight + 40

  property bool expanded: false   // the night light options are open

  // The quick choices of the night light
  readonly property var presets: [
    { name: "Soft",    kelvin: 5000 },
    { name: "Warm",    kelvin: 4000 },
    { name: "Evening", kelvin: 3200 },
    { name: "Candle",  kelvin: 2500 }
  ]

  // While the mouse is over the panel it stays open
  HoverHandler { id: hover }
  Binding { target: Osd; property: "hoveredBrightness"; value: hover.hovered }

  Column {
    id: column
    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
    spacing: 14

    OsdSlider {
      width: parent.width
      visible: Brightness.available
      label: "Brightness"
      value: Brightness.value
      valueText: Math.round(Brightness.value * 100) + "%"
      onMoved: v => Brightness.setPercent(v * 100)
    }

    // The night light: a switch, and an arrow that opens the options below it
    Item {
      width: parent.width
      height: 44
      visible: Night.available

      Column {
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        spacing: 2

        Text {
          text: "Night light"
          color: Theme.text
          font.pixelSize: 14
        }
        Text {
          text: Night.active ? Night.temperature + "K" : "Off"
          color: Night.active ? Theme.accent : Theme.muted
          font.pixelSize: 12
        }
      }

      Row {
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        spacing: 10

        // The arrow
        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: 32; height: 32; radius: 8
          color: arrowMouse.containsMouse || root.expanded ? Theme.overlay : Theme.surface

          Text {
            anchors.centerIn: parent
            text: Icons.chevronRight
            color: Theme.text
            font.pixelSize: 18
            rotation: root.expanded ? 90 : 0
            Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
          }
          MouseArea {
            id: arrowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
          }
        }

        SwitchButton {
          anchors.verticalCenter: parent.verticalCenter
          checked: Night.active
          onToggled: Night.toggle()
        }
      }
    }

    // The options: it opens and closes by growing
    Item {
      width: parent.width
      visible: Night.available
      height: root.expanded ? options.implicitHeight : 0
      opacity: root.expanded ? 1 : 0
      clip: true
      Behavior on height { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
      Behavior on opacity { NumberAnimation { duration: 180 } }

      Column {
        id: options
        width: parent.width
        spacing: 12

        // Quick choices
        Row {
          spacing: 6

          Repeater {
            model: root.presets

            delegate: Rectangle {
              id: chip
              required property var modelData

              readonly property bool current: Night.active && Math.abs(Night.temperature - modelData.kelvin) < 100

              width: (options.width - 18) / 4
              height: 46
              radius: 10
              color: current ? Theme.accent : chipMouse.containsMouse ? Theme.overlay : Theme.surface
              Behavior on color { ColorAnimation { duration: 120 } }

              Column {
                anchors.centerIn: parent
                spacing: 1

                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: chip.modelData.name
                  color: chip.current ? Theme.base : Theme.text
                  font.pixelSize: 12
                  font.bold: true
                }
                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: chip.modelData.kelvin + "K"
                  color: chip.current ? Theme.base : Theme.muted
                  font.pixelSize: 10
                }
              }

              MouseArea {
                id: chipMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Night.setTemperature(chip.modelData.kelvin)
              }
            }
          }
        }

        // Any temperature in between
        OsdSlider {
          width: parent.width
          label: "Custom"
          value: Night.warmth
          dim: !Night.active
          valueText: Night.temperature + "K"
          onMoved: v => Night.setWarmth(v)
        }
      }
    }

    // Nothing to control (a desktop whose monitor doesn't answer to ddcutil, and no hyprsunset)
    Text {
      width: parent.width
      visible: !Brightness.available && !Night.available
      text: "No brightness control found"
      color: Theme.muted
      font.pixelSize: 14
    }
  }
}
