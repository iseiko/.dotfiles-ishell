import QtQuick
import Quickshell

// The options of a background app (content of its popout), opened with a right click on its icon
Item {
  id: root

  implicitWidth: 340
  implicitHeight: column.implicitHeight + 36

  readonly property var item: Tray.current
  readonly property var windows: Tray.clientsFor(item)

  // The app's own menu (Open, Mute, Quit...), if it has one
  QsMenuOpener {
    id: opener
    menu: root.item && root.item.hasMenu ? root.item.menu : null
  }

  readonly property int menuCount: opener.children
    ? opener.children.values.filter(e => !e.isSeparator && !e.hasChildren).length : 0

  Connections {
    target: Visibilities
    function onTraymenuChanged() {
      if (Visibilities.traymenu) Qt.callLater(() => root.forceActiveFocus())
    }
  }

  Keys.onEscapePressed: Visibilities.closeAll()

  Column {
    id: column
    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
    spacing: 4

    // Which app this is
    Item {
      width: parent.width
      height: 48

      Image {
        id: appIcon
        anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
        width: 28; height: 28
        source: root.item ? root.item.icon : ""
        sourceSize: Qt.size(56, 56)
        fillMode: Image.PreserveAspectFit
      }

      Column {
        anchors {
          left: appIcon.right; leftMargin: 12; right: parent.right
          verticalCenter: parent.verticalCenter
        }
        Text {
          width: parent.width
          text: root.item ? (root.item.title !== "" ? root.item.title : root.item.id) : ""
          color: Theme.text
          font.pixelSize: 16
          font.bold: true
          elide: Text.ElideRight
        }
        Text {
          width: parent.width
          text: root.windows.length === 0 ? "No window open"
              : root.windows.length === 1 ? "1 window" : root.windows.length + " windows"
          color: Theme.subtext
          font.pixelSize: 12
        }
      }
    }

    ActionRow {
      width: parent.width
      text: "Open"
      subtitle: root.windows.length > 0 ? "Go to workspace " + root.windows[0].workspace.name
                                        : "Open a window"
      onTriggered: Tray.open(root.item)
    }

    ActionRow {
      width: parent.width
      visible: root.windows.length > 0
      text: root.windows.length > 1 ? "Close windows" : "Close window"
      onTriggered: {
        Tray.closeWindows(root.item)
        Visibilities.closeAll()
      }
    }

    ActionRow {
      width: parent.width
      text: "Kill app"
      subtitle: "Ends the app right away"
      danger: true
      onTriggered: {
        Tray.killApp(root.item)
        Visibilities.closeAll()
      }
    }

    // The app's windows, when there is more than one
    Text {
      topPadding: 8
      leftPadding: 4
      visible: root.windows.length > 1
      text: "Windows"
      color: Theme.muted
      font.pixelSize: 12
      font.bold: true
    }
    ListView {
      width: parent.width
      height: Math.min(contentHeight, 150)
      visible: root.windows.length > 1
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      model: ScriptModel { values: root.windows.length > 1 ? root.windows : [] }

      delegate: ActionRow {
        required property var modelData
        width: ListView.view.width
        text: modelData.title !== "" ? modelData.title : modelData["class"]
        subtitle: "Workspace " + modelData.workspace.name
        onTriggered: {
          Tray.focus(modelData)
          Visibilities.closeAll()
        }
      }
    }

    // The menu the app itself offers
    Text {
      topPadding: 8
      leftPadding: 4
      visible: root.menuCount > 0
      text: root.item ? root.item.title : ""
      color: Theme.muted
      font.pixelSize: 12
      font.bold: true
    }
    ListView {
      width: parent.width
      height: Math.min(contentHeight, 200)
      visible: root.menuCount > 0
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      model: opener.children

      delegate: ActionRow {
        required property var modelData
        width: ListView.view.width
        // Separators and submenus are not shown
        visible: !modelData.isSeparator && !modelData.hasChildren
        height: visible ? 40 : 0
        enabled: modelData.enabled
        text: modelData.text
        onTriggered: {
          modelData.triggered()
          Visibilities.closeAll()
        }
      }
    }
  }
}
