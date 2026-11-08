import QtQuick
import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel

// The wallpaper picker (content of its popout)
Item {
  id: root

  // Path to the wallpapers directorie
  readonly property string wallDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"

  // Used by both the mouse and the Enter key
  function select(path) {
    if (!path) return
    setWall.path = path
    setWall.running = true
    Visibilities.closeAll()
  }

  Connections {
    target: Visibilities
    function onPickerChanged() {
      if (!Visibilities.picker) return
      list.currentIndex = 0
      Qt.callLater(() => list.forceActiveFocus())
    }
  }

  // The command that will run when you select the wallpaper.
  // Theme.qml watches colors.json, so the colors update on their own once matugen is done.
  Process {
    id: setWall
    property string path: ""
    command: [
      "sh", "-c",
      'echo "$0" > ~/.cache/current_wall; matugen image "$0" -m dark --source-color-index 0; hyprctl reload; awww img "$0" --transition-type grow',
      path
    ]

    stderr: StdioCollector {
      onStreamFinished: if (text) console.log("setWall stderr:", text)
    }

    onExited: (exitCode, exitStatus) => console.log("setWall exited with code", exitCode)
  }

  ListView {
    id: list
    anchors.fill: parent
    anchors.margins: 14
    orientation: ListView.Horizontal
    spacing: 12
    clip: true
    currentIndex: 0

    // Keep the selected wallpaper on screen while moving with the keys
    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

    Keys.onLeftPressed: decrementCurrentIndex()
    Keys.onRightPressed: incrementCurrentIndex()
    Keys.onReturnPressed: root.select(currentItem ? currentItem.filePath : "")
    Keys.onEnterPressed: root.select(currentItem ? currentItem.filePath : "")
    Keys.onEscapePressed: Visibilities.closeAll()

    model: FolderListModel {
      folder: "file://" + root.wallDir
      nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
      showDirs: false
    }

    delegate: Rectangle {
      required property string filePath
      readonly property bool selected: ListView.isCurrentItem

      width: 240
      height: ListView.view.height
      radius: 10
      clip: true
      color: Theme.surface

      Image {
        anchors.fill: parent
        source: "file://" + parent.filePath
        sourceSize.width: 480
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
      }

      // Selection highlight, drawn ABOVE the image
      Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border.width: 4
        border.color: Theme.accent
        visible: parent.selected || mouse.containsMouse
      }

      MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.select(parent.filePath)
      }
    }
  }
}
