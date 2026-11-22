import QtQuick

// The calendar (content of its popout)
Item {
  id: root

  implicitWidth: 380
  implicitHeight: column.implicitHeight + 40

  readonly property var locale: Qt.locale()

  property date today: new Date()
  property date selected: new Date()
  property int viewYear: new Date().getFullYear()
  property int viewMonth: new Date().getMonth()

  // The 42 days shown (6 weeks), starting on the first day of the week of your language
  readonly property var cells: {
    const first = new Date(viewYear, viewMonth, 1)
    const offset = (first.getDay() - locale.firstDayOfWeek + 7) % 7
    const list = []
    for (let i = 0; i < 42; i++) {
      const d = new Date(viewYear, viewMonth, 1 - offset + i)
      list.push({
        day: d.getDate(),
        month: d.getMonth(),
        year: d.getFullYear(),
        inMonth: d.getMonth() === viewMonth
      })
    }
    return list
  }

  readonly property string title: {
    const name = locale.monthName(viewMonth, Locale.LongFormat)
    return name.charAt(0).toUpperCase() + name.slice(1) + " " + viewYear
  }

  function sameDay(cell, date) {
    return cell.year === date.getFullYear() && cell.month === date.getMonth() && cell.day === date.getDate()
  }

  function shiftMonth(delta) {
    const d = new Date(viewYear, viewMonth + delta, 1)
    viewYear = d.getFullYear()
    viewMonth = d.getMonth()
  }

  function goToday() {
    today = new Date()
    selected = new Date()
    viewYear = today.getFullYear()
    viewMonth = today.getMonth()
  }

  // Every time it opens, start on today
  Connections {
    target: Visibilities
    function onCalendarChanged() {
      if (!Visibilities.calendar) return
      root.goToday()
      Qt.callLater(() => root.forceActiveFocus())
    }
  }

  Keys.onPressed: event => {
    if (event.key === Qt.Key_Left || event.key === Qt.Key_PageUp) shiftMonth(-1)
    else if (event.key === Qt.Key_Right || event.key === Qt.Key_PageDown) shiftMonth(1)
    else if (event.key === Qt.Key_Home || event.key === Qt.Key_T) goToday()
    else if (event.key === Qt.Key_Escape) Visibilities.back()
    else return

    event.accepted = true
  }

  // Scrolling the mouse wheel changes the month
  WheelHandler {
    onWheel: event => root.shiftMonth(event.angleDelta.y > 0 ? -1 : 1)
  }

  Column {
    id: column
    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
    spacing: 12

    // Month and year, and the buttons to move between months
    Item {
      width: parent.width
      height: 32

      Text {
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        text: root.title
        color: Theme.text
        font.pixelSize: 18
        font.bold: true

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.goToday()
        }
      }

      Row {
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        spacing: 4

        Rectangle {
          width: 32; height: 32; radius: 8
          color: prevMouse.containsMouse ? Theme.overlay : Theme.surface
          Text {
            anchors.centerIn: parent
            text: Icons.chevronLeft
            color: Theme.text
            font.pixelSize: 18
          }
          MouseArea {
            id: prevMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.shiftMonth(-1)
          }
        }

        Rectangle {
          width: 32; height: 32; radius: 8
          color: nextMouse.containsMouse ? Theme.overlay : Theme.surface
          Text {
            anchors.centerIn: parent
            text: Icons.chevronRight
            color: Theme.text
            font.pixelSize: 18
          }
          MouseArea {
            id: nextMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.shiftMonth(1)
          }
        }
      }
    }

    // Names of the days of the week
    Row {
      Repeater {
        model: 7
        delegate: Text {
          required property int index
          width: 46
          horizontalAlignment: Text.AlignHCenter
          text: root.locale.dayName((root.locale.firstDayOfWeek + index) % 7, Locale.ShortFormat).slice(0, 3)
          color: Theme.muted
          font.pixelSize: 12
          font.bold: true
        }
      }
    }

    // The days
    Grid {
      columns: 7

      Repeater {
        model: root.cells

        delegate: Rectangle {
          id: cell
          required property var modelData

          readonly property bool isToday: root.sameDay(modelData, root.today)
          readonly property bool isSelected: root.sameDay(modelData, root.selected)

          width: 46
          height: 40
          radius: 10
          color: isToday ? Theme.accent
               : isSelected ? Theme.overlay
               : mouse.containsMouse ? Theme.surface : "transparent"

          Text {
            anchors.centerIn: parent
            text: cell.modelData.day
            color: cell.isToday ? Theme.base
                 : cell.modelData.inMonth ? Theme.text : Theme.muted
            font.pixelSize: 14
            font.bold: cell.isToday
          }

          MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              root.selected = new Date(cell.modelData.year, cell.modelData.month, cell.modelData.day)
              if (!cell.modelData.inMonth) {
                root.viewYear = cell.modelData.year
                root.viewMonth = cell.modelData.month
              }
            }
          }
        }
      }
    }

    // The selected day, and a way back to today
    Item {
      width: parent.width
      height: 30

      Text {
        anchors { left: parent.left; right: todayButton.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
        text: root.locale.toString(root.selected, "dddd, d MMMM yyyy")
        color: Theme.subtext
        font.pixelSize: 13
        elide: Text.ElideRight
      }

      SmallButton {
        id: todayButton
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        text: "Today"
        onClicked: root.goToday()
      }
    }
  }
}
