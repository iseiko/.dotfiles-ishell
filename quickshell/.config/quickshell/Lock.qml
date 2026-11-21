import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick

Scope {
  id: root
  property string buffer: ""      // What has been typed so far
  property string status: ""
  property bool checking: false

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  IpcHandler {
    target: "lock"
    function lock(): void {
      root.buffer = ""
      root.status = ""
      sessionLock.locked = true
    }
  }

  PamContext {
    id: pam
    configDirectory: "pam"        // Relative to your shell.qml folder
    config: "password.conf"

    // PAM asks for the password, we answer with what was typed
    onPamMessage: {
      if (responseRequired) respond(root.buffer)
    }

    // Check if the password was correct
    onCompleted: result => {
      root.checking = false
      root.buffer = ""
      if (result === PamResult.Success) sessionLock.locked = false
      else root.status = "Wrong password"
    }
  }

  // Get whats in the buffer and check with the pam module
  function submit() {
    if (checking || buffer === "") return
    checking = true
    status = ""
    pam.start()
  }

  // Built in wayland session locker to manage the lockscreen process
  WlSessionLock {
    id: sessionLock

    // This is instantiated once per monitor
    WlSessionLockSurface {
      color: "transparent" 

      Item {
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
          if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.submit()
          } else if (event.key === Qt.Key_Backspace) {
            root.buffer = root.buffer.slice(0, -1)
          } else if (event.key === Qt.Key_Escape) {
            root.buffer = ""
          } else if (event.text.length > 0 && !(event.modifiers & Qt.ControlModifier)) {
            root.buffer += event.text
          }
          event.accepted = true
        }

        Column {
          anchors.centerIn: parent
          spacing: 14

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: Theme.text
            font.pixelSize: 96
            font.bold: true
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "dddd, dd MMMM yyyy")
            color: Theme.subtext
            font.pixelSize: 20
          }

          Item { width: 1; height: 24 }

          Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 300; height: 48; radius: 12
            color: Theme.surface
            border.width: 2
            border.color: root.status !== "" ? Theme.danger : Theme.accent

            Text {
              anchors.centerIn: parent
              // one dot per character typed
              text: root.checking ? "Checking..."
                  : root.buffer.length > 0 ? "●".repeat(root.buffer.length)
                  : "Password"
              color: root.buffer.length > 0 ? Theme.text : Theme.muted
              font.pixelSize: 16
            }
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.status
            color: Theme.danger
            font.pixelSize: 14
          }
        }
      }
    }
  }
}
