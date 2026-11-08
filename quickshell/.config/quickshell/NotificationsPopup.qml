import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Notifications (content of the top-right popout). This is also the notification daemon, so
// only one of mako, dunst or swaync can run at the same time as the shell.
Item {
  id: root

  readonly property int count: server.trackedNotifications.values.length

  implicitWidth: 380
  implicitHeight: column.implicitHeight + 28

  NotificationServer {
    id: server
    actionsSupported: true
    bodySupported: true
    bodyMarkupSupported: true
    imageSupported: true

    // Keep each notification until it expires or gets dismissed
    onNotification: notification => { notification.tracked = true }
  }

  Column {
    id: column
    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
    spacing: 8

    Repeater {
      model: server.trackedNotifications

      delegate: Rectangle {
        id: card
        required property var modelData   // the notification

        readonly property bool critical: modelData.urgency === NotificationUrgency.Critical
        readonly property string iconSource: {
          if (modelData.image !== "") return modelData.image
          if (modelData.appIcon === "") return ""
          if (modelData.appIcon.startsWith("/")) return "file://" + modelData.appIcon
          return Quickshell.iconPath(modelData.appIcon, true)
        }

        width: column.width
        height: content.implicitHeight + 24
        radius: 14
        color: Theme.surface
        border.width: critical ? 2 : 0
        border.color: Theme.danger

        HoverHandler { id: hover }

        // Closes by itself after a few seconds (urgent ones stay until you dismiss them).
        // The timer is paused while the mouse is over the notification.
        Timer {
          running: !hover.hovered && !card.critical && card.modelData.expireTimeout !== 0
          interval: Math.min(15, card.modelData.expireTimeout > 0 ? card.modelData.expireTimeout : 6) * 1000
          onTriggered: card.modelData.expire()
        }

        // Click anywhere on the notification to dismiss it
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: card.modelData.dismiss()
        }

        Column {
          id: content
          anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
          spacing: 10

          Row {
            width: parent.width
            spacing: 12

            RoundedImage {
              width: 40; height: 40
              radius: 10
              visible: card.iconSource !== ""
              source: card.iconSource
            }

            Column {
              width: parent.width - (card.iconSource !== "" ? 52 : 0)
              spacing: 2

              Text {
                width: parent.width
                text: card.modelData.appName
                color: Theme.muted
                font.pixelSize: 12
                elide: Text.ElideRight
              }
              Text {
                width: parent.width
                text: card.modelData.summary
                color: Theme.text
                font.pixelSize: 15
                font.bold: true
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
              }
              Text {
                width: parent.width
                visible: text !== ""
                text: card.modelData.body
                color: Theme.subtext
                font.pixelSize: 13
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
              }
            }
          }

          // Action buttons, if the app sent any
          Row {
            spacing: 8
            visible: card.modelData.actions.length > 0

            Repeater {
              model: card.modelData.actions

              delegate: Rectangle {
                required property var modelData
                height: 28
                width: actionText.implicitWidth + 24
                radius: 8
                color: actionMouse.containsMouse ? Theme.accent : Theme.overlay

                Text {
                  id: actionText
                  anchors.centerIn: parent
                  text: parent.modelData.text
                  color: actionMouse.containsMouse ? Theme.base : Theme.text
                  font.pixelSize: 13
                }
                MouseArea {
                  id: actionMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: parent.modelData.invoke()
                }
              }
            }
          }
        }
      }
    }
  }
}
