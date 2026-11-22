import QtQuick
import Quickshell
import Quickshell.Io

// The main menu (content of its popout). The entries come from ~/.config/quickshell/menu.json,
// and the same menu is built in below so it works before you create that file.
//
// Each entry has a "label" and an optional "icon", and ONE of these:
//   "open":    a panel to open: launcher, picker, keybinds, wifi, bluetooth, power, music
//   "command": a shell command to run
//   "submenu": a list of more entries
Item {
  id: root

  readonly property var defaultTree: [
    {
      "label": "Apps",
      "icon": "apps",
      "open": "launcher"
    },
    {
      "label": "Clipboard",
      "icon": "clipboard",
      "open": "clipboard"
    },
    {
      "label": "Calendar",
      "icon": "calendar",
      "open": "calendar"
    },
    {
      "label": "Wallpaper",
      "icon": "wallpaper",
      "open": "picker"
    },
    {
      "label": "Keybinds",
      "icon": "keyboard",
      "open": "keybinds"
    },
    {
      "label": "Settings",
      "icon": "settings",
      "submenu": [
        {
          "label": "Wi-Fi",
          "icon": "wifi",
          "open": "wifi"
        },
        {
          "label": "Bluetooth",
          "icon": "bluetooth",
          "open": "bluetooth"
        }
      ]
    },
    {
      "label": "Install",
      "icon": "install",
      "submenu": [
        {
          "label": "Package from the official repos",
          "icon": "install",
          "command": "kitty --class shell-installer --title Install -e bash ~/.config/quickshell/scripts/install-package.sh"
        },
        {
          "label": "Package from the AUR",
          "icon": "install",
          "command": "kitty --class shell-installer --title Install -e bash ~/.config/quickshell/scripts/install-package.sh aur"
        }
      ]
    },
    {
      "label": "Update system",
      "icon": "update",
      "command": "kitty --class shell-installer --title Update -e bash -c 'sudo pacman -Syu; echo; read -rp \"Press Enter to close\"'"
    },
    {
      "label": "System",
      "icon": "power",
      "submenu": [
        {
          "label": "Lock",
          "icon": "lock",
          "command": "qs ipc call lock lock"
        },
        {
          "label": "Suspend",
          "icon": "suspend",
          "command": "systemctl suspend"
        },
        {
          "label": "Hibernate",
          "icon": "hibernate",
          "command": "systemctl hibernate"
        },
        {
          "label": "Reboot",
          "icon": "reboot",
          "command": "systemctl soft-reboot"
        },
        {
          "label": "Shutdown",
          "icon": "power",
          "command": "systemctl poweroff"
        }
      ]
    }
  ]

  property var tree: defaultTree
  property var levels: []   // the submenus we went into: { title, items }
  readonly property var current: levels.length > 0 ? levels[levels.length - 1]
                                                   : ({ title: "", items: tree })
  readonly property var results: {
    const q = search.text.toLowerCase()
    return current.items.filter(e => (e.label || "").toLowerCase().includes(q))
  }

  implicitWidth: 520
  implicitHeight: column.implicitHeight + 28

  function activate(entry) {
    if (!entry) return

    if (entry.submenu) {
      levels = levels.concat([{ title: entry.label, items: entry.submenu }])
      search.text = ""
      list.currentIndex = 0
    } else if (entry.open) {
      if (Visibilities[entry.open] !== undefined) {
        Visibilities.toggle(entry.open)
        Visibilities.fromMenu = true   // Esc in that panel comes back to this menu
      }
    } else if (entry.command) {
      Visibilities.closeAll()
      Quickshell.execDetached(["sh", "-c", entry.command])
    }
  }

  function back() {
    if (levels.length === 0) {
      Visibilities.closeAll()
      return
    }
    levels = levels.slice(0, -1)
    search.text = ""
    list.currentIndex = 0
  }

  // The menu file
  FileView {
    path: Quickshell.env("HOME") + "/.config/quickshell/menu.json"
    watchChanges: true
    onFileChanged: reload()

    onLoaded: {
      try {
        const data = JSON.parse(text())
        root.tree = data.items
        root.levels = []
      } catch (e) {
        console.warn("menu.json has a mistake, using the built-in menu:", e.message)
        root.tree = root.defaultTree
      }
    }
    onLoadFailed: root.tree = root.defaultTree
  }

  // Start from the top every time it opens
  Connections {
    target: Visibilities
    function onMenuChanged() {
      if (!Visibilities.menu) return
      // Coming back from a panel: stay in the submenu we were in. Otherwise start from the top.
      if (Visibilities.returningToMenu) Visibilities.returningToMenu = false
      else root.levels = []
      search.text = ""
      list.currentIndex = 0
      Qt.callLater(() => search.forceActiveFocus())
    }
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
          else root.back()
        }
        Keys.onDownPressed: list.incrementCurrentIndex()
        Keys.onUpPressed: list.decrementCurrentIndex()
        Keys.onReturnPressed: root.activate(root.results[list.currentIndex])
        Keys.onEnterPressed: root.activate(root.results[list.currentIndex])
        // Backspace on an empty search goes back one level
        Keys.onPressed: event => {
          if (event.key === Qt.Key_Backspace && text === "" && root.levels.length > 0) {
            root.back()
            event.accepted = true
          }
        }
      }

      Text {
        anchors.fill: search
        verticalAlignment: Text.AlignVCenter
        visible: search.text === ""
        text: root.levels.length > 0 ? "Search in " + root.current.title + "..." : "Search the menu..."
        color: Theme.muted
        font.pixelSize: 16
      }
    }

    // Where we are, with a back button (only inside a submenu)
    Item {
      width: parent.width
      height: 26
      visible: root.levels.length > 0

      Row {
        anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
        spacing: 8

        Text {
          text: Icons.arrowLeft
          color: Theme.accent
          font.pixelSize: 16
        }
        Text {
          text: root.current.title
          color: Theme.subtext
          font.pixelSize: 14
          font.bold: true
        }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.back()
      }
    }

    Text {
      visible: root.results.length === 0
      text: "No matches"
      color: Theme.muted
      font.pixelSize: 14
    }

    ListView {
      id: list
      width: parent.width
      height: Math.max(0, Math.min(root.results.length, 8) * 48 - 4)
      clip: true
      spacing: 4
      currentIndex: 0
      boundsBehavior: Flickable.StopAtBounds
      onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

      model: ScriptModel { values: root.results }

      delegate: Rectangle {
        id: row
        required property var modelData
        required property int index

        width: ListView.view.width
        height: 44
        radius: 8
        color: ListView.isCurrentItem ? Theme.overlay
             : mouse.containsMouse    ? Theme.surface : "transparent"

        Text {
          id: icon
          anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
          width: 24
          horizontalAlignment: Text.AlignHCenter
          text: Icons.named(row.modelData.icon || "")
          color: Theme.accent
          font.pixelSize: 18
        }

        Text {
          anchors {
            left: icon.right; leftMargin: 12
            right: arrow.left; rightMargin: 8
            verticalCenter: parent.verticalCenter
          }
          text: row.modelData.label
          color: Theme.text
          font.pixelSize: 15
          elide: Text.ElideRight
        }

        Text {
          id: arrow
          anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
          visible: row.modelData.submenu !== undefined
          text: Icons.chevronRight
          color: Theme.muted
          font.pixelSize: 16
        }

        MouseArea {
          id: mouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.activate(row.modelData)
        }
      }
    }
  }
}
