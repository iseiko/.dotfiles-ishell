import QtQuick
import Quickshell

// The app launcher (content of its popout)
Item {
  id: root

  // Filtered, sorted list; re-evaluates whenever search.text changes
  readonly property var results: {
    const q = search.text.toLowerCase()
    return Array.from(DesktopEntries.applications.values)
      .filter(e => !e.noDisplay && e.name.toLowerCase().includes(q))
      .sort((a, b) => a.name.localeCompare(b.name))
  }

  function launch(entry) {
    if (!entry) return
    entry.execute()
    Visibilities.closeAll()
  }

  // Start fresh every time it opens
  Connections {
    target: Visibilities
    function onLauncherChanged() {
      if (!Visibilities.launcher) return
      search.text = ""
      list.currentIndex = 0
      Qt.callLater(() => { if (!search.activeFocus) search.forceActiveFocus() })
    }
  }

  // Search box
  Rectangle {
    id: searchBox
    anchors { top: parent.top; left: parent.left; right: parent.right; margins: 14 }
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

      Keys.onEscapePressed: Visibilities.closeAll()
      Keys.onDownPressed: list.incrementCurrentIndex()
      Keys.onUpPressed: list.decrementCurrentIndex()
      Keys.onReturnPressed: root.launch(root.results[list.currentIndex])
      Keys.onEnterPressed: root.launch(root.results[list.currentIndex])
    }

    Text {
      anchors.fill: search
      verticalAlignment: Text.AlignVCenter
      text: "Search apps..."
      color: Theme.muted
      font.pixelSize: 16
      visible: search.text === ""
    }
  }

  ListView {
    id: list
    anchors {
      top: searchBox.bottom; bottom: parent.bottom
      left: parent.left; right: parent.right
      margins: 14
    }
    clip: true
    spacing: 4
    currentIndex: 0
    boundsBehavior: Flickable.StopAtBounds

    model: ScriptModel { values: root.results }

    delegate: Rectangle {
      required property var modelData
      required property int index

      width: ListView.view.width
      height: 44
      radius: 8
      color: ListView.isCurrentItem ? Theme.overlay
           : mouse.containsMouse    ? Theme.surface : "transparent"

      Row {
        anchors.fill: parent
        anchors.leftMargin: 10
        spacing: 12

        Image {
          anchors.verticalCenter: parent.verticalCenter
          width: 28; height: 28
          source: Quickshell.iconPath(modelData.icon, true)
          sourceSize: Qt.size(56, 56)
          asynchronous: true
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: modelData.name
          color: Theme.text
          font.pixelSize: 15
        }
      }

      MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.launch(modelData)
      }
    }
  }
}
