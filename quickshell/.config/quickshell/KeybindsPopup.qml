import QtQuick
import Quickshell

// The keybinds panel (content of its popout)
Item {
  id: root

  implicitWidth: 620

  readonly property var rows: Keybinds.flatten(search.text)

  Connections {
    target: Visibilities
    function onKeybindsChanged() {
      if (!Visibilities.keybinds) return
      search.text = ""
      list.contentY = 0
      Qt.callLater(() => search.forceActiveFocus())
    }
  }

  function scrollBy(amount) {
    list.contentY = Math.max(0, Math.min(list.contentHeight - list.height, list.contentY + amount))
  }

  Text {
    id: title
    anchors { left: parent.left; top: parent.top; leftMargin: 24; topMargin: 22 }
    text: "Keybinds"
    color: Theme.text
    font.pixelSize: 18
    font.bold: true
  }

  Rectangle {
    id: searchBox
    anchors {
      left: parent.left; right: parent.right; top: title.bottom
      leftMargin: 24; rightMargin: 24; topMargin: 14
    }
    height: 40
    radius: 10
    color: Theme.surface

    TextInput {
      id: search
      anchors.fill: parent
      anchors.leftMargin: 14
      anchors.rightMargin: 14
      verticalAlignment: TextInput.AlignVCenter
      color: Theme.text
      font.pixelSize: 15
      clip: true

      Keys.onEscapePressed: {
        if (text !== "") text = ""
        else Visibilities.back()
      }
      Keys.onDownPressed: root.scrollBy(80)
      Keys.onUpPressed: root.scrollBy(-80)
    }

    Text {
      anchors.fill: search
      verticalAlignment: Text.AlignVCenter
      visible: search.text === ""
      text: "Search keybinds..."
      color: Theme.muted
      font.pixelSize: 15
    }
  }

  // Shown when keybinds.json is missing or broken
  Text {
    anchors {
      left: parent.left; right: parent.right; top: searchBox.bottom
      leftMargin: 24; rightMargin: 24; topMargin: 16
    }
    visible: Keybinds.error !== ""
    text: Keybinds.error
    color: Theme.danger
    font.pixelSize: 13
    wrapMode: Text.Wrap
  }

  Text {
    anchors {
      left: parent.left; right: parent.right; top: searchBox.bottom
      leftMargin: 24; rightMargin: 24; topMargin: 16
    }
    visible: Keybinds.error === "" && root.rows.length === 0
    text: "No keybinds match"
    color: Theme.muted
    font.pixelSize: 14
  }

  ListView {
    id: list
    anchors {
      left: parent.left; right: parent.right; top: searchBox.bottom; bottom: parent.bottom
      leftMargin: 24; rightMargin: 24; topMargin: 10; bottomMargin: 16
    }
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    model: ScriptModel { values: root.rows }

    delegate: Item {
      id: row
      required property var modelData

      width: ListView.view.width
      height: modelData.header ? 40 : 38

      // Category title
      Text {
        visible: row.modelData.header
        anchors { left: parent.left; bottom: parent.bottom; bottomMargin: 6 }
        text: row.modelData.name
        color: Theme.accent
        font.pixelSize: 13
        font.bold: true
      }

      // A keybind: description on the left, keys on the right
      Item {
        visible: !row.modelData.header
        anchors.fill: parent

        Text {
          anchors {
            left: parent.left; right: caps.left; rightMargin: 12
            verticalCenter: parent.verticalCenter
          }
          text: row.modelData.desc
          color: Theme.text
          font.pixelSize: 14
          elide: Text.ElideRight
        }

        Row {
          id: caps
          anchors { right: parent.right; verticalCenter: parent.verticalCenter }
          spacing: 4

          Repeater {
            model: row.modelData.keys || []

            delegate: Rectangle {
              required property string modelData
              height: 24
              width: capText.implicitWidth + 14
              radius: 6
              color: Theme.overlay
              border.width: 1
              border.color: Theme.muted

              Text {
                id: capText
                anchors.centerIn: parent
                text: parent.modelData
                color: Theme.text
                font.pixelSize: 12
                font.bold: true
              }
            }
          }
        }
      }
    }
  }
}
