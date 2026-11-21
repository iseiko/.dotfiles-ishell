import QtQuick

// The screenshot panel (content of its popout): a preview and what to do with it
Item {
  id: root

  implicitWidth: 560
  implicitHeight: column.implicitHeight + 36

  // A tiny copy of the picture, only to learn its shape so the preview isn't squashed
  Image {
    id: probe
    visible: false
    asynchronous: true
    cache: false
    source: Screenshot.path !== "" ? "file://" + Screenshot.path : ""
    sourceSize.width: 64
  }

  readonly property real ratio: probe.implicitWidth > 0 ? probe.implicitHeight / probe.implicitWidth : 0.5625
  readonly property real previewHeight: Math.min(300, 520 * ratio)
  readonly property real previewWidth: previewHeight / ratio

  Connections {
    target: Visibilities
    function onScreenshotChanged() {
      if (Visibilities.screenshot) Qt.callLater(() => root.forceActiveFocus())
    }
  }

  Keys.onPressed: event => {
    const ctrl = event.modifiers & Qt.ControlModifier

    if (ctrl && event.key === Qt.Key_S) Screenshot.finish(true, false)
    else if (ctrl && event.key === Qt.Key_C) Screenshot.finish(false, true)
    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) Screenshot.finish(true, true)
    else if (event.key === Qt.Key_Escape) Screenshot.discard()
    else if (event.key === Qt.Key_R) Screenshot.retake()
    else return

    event.accepted = true
  }

  Column {
    id: column
    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
    spacing: 14

    Text {
      text: "Screenshot"
      color: Theme.text
      font.pixelSize: 18
      font.bold: true
    }

    // The preview
    Item {
      width: parent.width
      height: root.previewHeight

      RoundedImage {
        anchors.centerIn: parent
        width: root.previewWidth
        height: root.previewHeight
        radius: 12
        source: Screenshot.path !== "" ? "file://" + Screenshot.path : ""
      }
    }

    // Actions
    Item {
      width: parent.width
      height: 34

      SmallButton {
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        height: 34
        text: "Retake (R)"
        onClicked: Screenshot.retake()
      }

      Row {
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        spacing: 8

        SmallButton {
          height: 34
          text: "Discard (Esc)"
          onClicked: Screenshot.discard()
        }
        SmallButton {
          height: 34
          text: "Save (Ctrl+S)"
          onClicked: Screenshot.finish(true, false)
        }
        SmallButton {
          height: 34
          text: "Copy (Ctrl+C)"
          onClicked: Screenshot.finish(false, true)
        }
        SmallButton {
          height: 34
          accent: true
          text: "Save & copy (Enter)"
          onClicked: Screenshot.finish(true, true)
        }
      }
    }
  }
}
