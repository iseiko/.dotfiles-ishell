import QtQuick
import Quickshell
import Quickshell.Io

// The clipboard history (content of its popout)
Item {
  id: root

  implicitWidth: 560
  implicitHeight: column.implicitHeight + 28

  readonly property var results: {
    const q = search.text.toLowerCase()
    return ClipHistory.entries.filter(e => e.preview.toLowerCase().includes(q))
  }

  property bool confirmWipe: false

  function choose(entry) {
    if (!entry) return
    ClipHistory.copy(entry)
    Visibilities.closeAll()
  }

  // Every time it opens: read the history again and start with a clean search
  Connections {
    target: Visibilities
    function onClipboardChanged() {
      if (!Visibilities.clipboard) return
      search.text = ""
      list.currentIndex = 0
      root.confirmWipe = false
      ClipHistory.refresh()
      Qt.callLater(() => search.forceActiveFocus())
    }
  }

  // "Clear all" asks twice, and forgets about it after a few seconds
  Timer {
    id: confirmTimer
    interval: 3000
    onTriggered: root.confirmWipe = false
  }

  Column {
    id: column
    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
    spacing: 8

    // Search box
    Rectangle {
      width: parent.width
      height: 44
      radius: 10
      color: Theme.surface

      TextInput {
        id: search
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.text
        font.pixelSize: 16
        clip: true

        onTextChanged: list.currentIndex = 0

        Keys.onEscapePressed: {
          if (text !== "") text = ""
          else Visibilities.closeAll()
        }
        Keys.onDownPressed: list.incrementCurrentIndex()
        Keys.onUpPressed: list.decrementCurrentIndex()
        Keys.onReturnPressed: root.choose(root.results[list.currentIndex])
        Keys.onEnterPressed: root.choose(root.results[list.currentIndex])
        // Ctrl+D removes the selected entry from the history
        Keys.onPressed: event => {
          if (event.key === Qt.Key_D && (event.modifiers & Qt.ControlModifier)) {
            ClipHistory.remove(root.results[list.currentIndex])
            event.accepted = true
          }
        }
      }

      Text {
        anchors.fill: search
        verticalAlignment: Text.AlignVCenter
        visible: search.text === ""
        text: "Search the clipboard history..."
        color: Theme.muted
        font.pixelSize: 16
      }
    }

    // The history. The height is fixed so the panel doesn't jump around while you search.
    Item {
      width: parent.width
      height: 380

      Text {
        anchors.centerIn: parent
        width: parent.width - 40
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        visible: root.results.length === 0
        color: Theme.muted
        font.pixelSize: 14
        text: ClipHistory.entries.length === 0
              ? "Nothing here yet.\nIs cliphist running? It needs:\nwl-paste --watch cliphist store"
              : "No matches"
      }

      ListView {
        id: list
        anchors.fill: parent
        clip: true
        spacing: 4
        currentIndex: 0
        boundsBehavior: Flickable.StopAtBounds
        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

        model: ScriptModel {
          values: root.results
          objectProp: "id"
        }

        delegate: Rectangle {
          id: row
          required property var modelData
          required property int index

          property bool thumbReady: false

          width: ListView.view.width
          height: modelData.image ? 84 : 44
          radius: 8
          color: ListView.isCurrentItem ? Theme.overlay
               : mouse.containsMouse    ? Theme.surface : "transparent"

          // For an image: save a copy in the cache folder (once) so it can be shown
          Process {
            id: thumbProc
            command: [
              "sh", "-c",
              'mkdir -p "${1%/*}"; [ -f "$1" ] || cliphist decode "$0" > "$1"',
              row.modelData.id, ClipHistory.thumbPath(row.modelData.id)
            ]
            onExited: row.thumbReady = true
          }
          Component.onCompleted: if (modelData.image) thumbProc.running = true

          MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.choose(row.modelData)
          }

          // Image entry: a small preview and some details
          RoundedImage {
            id: thumb
            visible: row.modelData.image
            anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
            width: 96
            height: 68
            radius: 8
            source: row.thumbReady ? "file://" + ClipHistory.thumbPath(row.modelData.id) : ""
          }

          Column {
            visible: row.modelData.image
            anchors {
              left: thumb.right; leftMargin: 12
              right: remove.left; rightMargin: 8
              verticalCenter: parent.verticalCenter
            }
            spacing: 2

            Text {
              text: "Image"
              color: Theme.text
              font.pixelSize: 15
              font.bold: true
            }
            Text {
              width: parent.width
              text: row.modelData.info
              color: Theme.subtext
              font.pixelSize: 12
              elide: Text.ElideRight
            }
          }

          // Text entry: one line of the text
          Text {
            visible: !row.modelData.image
            anchors {
              left: parent.left; leftMargin: 14
              right: remove.left; rightMargin: 8
              verticalCenter: parent.verticalCenter
            }
            text: row.modelData.preview
            color: Theme.text
            font.pixelSize: 14
            elide: Text.ElideRight
          }

          SmallButton {
            id: remove
            anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
            visible: mouse.containsMouse || row.ListView.isCurrentItem
            text: "Delete"
            onClicked: ClipHistory.remove(row.modelData)
          }
        }
      }
    }

    // Footer: a reminder of the keys, and clearing everything
    Item {
      width: parent.width
      height: 28

      Text {
        anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
        text: "Enter: copy    Ctrl+D: delete    " + root.results.length + " items"
        color: Theme.muted
        font.pixelSize: 12
      }

      SmallButton {
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        visible: ClipHistory.entries.length > 0
        accent: root.confirmWipe
        text: root.confirmWipe ? "Really clear all?" : "Clear all"
        onClicked: {
          if (root.confirmWipe) {
            ClipHistory.wipe()
            root.confirmWipe = false
          } else {
            root.confirmWipe = true
            confirmTimer.restart()
          }
        }
      }
    }
  }
}
