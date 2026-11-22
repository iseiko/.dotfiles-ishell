import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick
import QtQuick.Effects

Scope {
  id: root
  property string buffer: ""      // What has been typed so far
  property string status: ""
  property bool checking: false
  property bool closing: false    // true while the lockscreen plays its "shrink back into the bar" animation
  property string wallpaperPath: ""

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  Process {
    id: wallProc
    command: ["awww", "query", "-j"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const data = JSON.parse(this.text);
          const outputs = data[""] || [];
          if (outputs.length > 0 && outputs[0].displaying) {
            root.wallpaperPath = "file://" + outputs[0].displaying.image;
          }
        } catch (e) {
          console.warn("Failed to parse awww output:", e);
        }
      }
    }
  }

  IpcHandler {
    target: "lock"
    function lock(): void {
      root.buffer = ""
      root.status = ""
      root.closing = false
      wallProc.running = true
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
      if (result === PamResult.Success) {
        // Play the closing animation first, the session is really unlocked when it ends
        root.closing = true
        unlockTimer.restart()
      } else {
        root.status = "Wrong password"
      }
    }
  }

  Timer {
    id: unlockTimer
    interval: 550   // a bit more than the closing animation (500 ms)
    onTriggered: sessionLock.locked = false
  }

  // Get whats in the buffer and check with the pam module
  function submit() {
    if (checking || closing || buffer === "") return
    checking = true
    status = ""
    pam.start()
  }

  // Built in wayland session locker to manage the lockscreen process
  WlSessionLock {
    id: sessionLock

    // Only WlSessionLockSurface should be inside WlSessionLock
    WlSessionLockSurface {
      Item {
        id: content
        anchors.fill: parent
        focus: true

        // ---- The animation -------------------------------------------------------------
        // p goes 0 -> 1 when the screen locks and 1 -> 0 when it unlocks.
        //   p = 0: the clock is exactly where it is in the bar (small, bottom center)
        //   p = 1: the clock is big in the middle of the lockscreen
        property real p: 0
        Behavior on p {
          NumberAnimation { duration: root.closing ? 500 : 800; easing.type: Easing.OutCubic }
        }
        // Everything that is not the clock appears in the second half of the animation
        readonly property real late: Math.max(0, Math.min(1, (p - 0.55) / 0.45))

        // Wait a moment so the surface is on screen before the animation starts
        Timer {
          running: true
          interval: 40
          onTriggered: content.p = root.closing ? 0 : 1
        }
        Connections {
          target: root
          function onClosingChanged() { if (root.closing) content.p = 0 }
        }

        function lerp(a, b, t) { return a + (b - a) * t }

        // ---- Where the clock starts (the bar, see Bar.qml) -------------------------------
        // Same fonts as the bar: time 15 bold, date 15, 12 px between them, centered in the screen
        readonly property string timeStr: Qt.formatDateTime(clock.date, "HH:mm")

        TextMetrics {
          id: barTime
          text: content.timeStr
          font.pixelSize: 15
          font.bold: true
        }
        TextMetrics {
          id: barDate
          text: Qt.formatDateTime(clock.date, "ddd, dd MMM yyyy")
          font.pixelSize: 15
        }

        readonly property real barRowWidth: barTime.width + 12 + barDate.width
        readonly property real startTimeX: width / 2 - barRowWidth / 2 + barTime.width / 2
        readonly property real startDateX: width / 2 - barRowWidth / 2 + barTime.width + 12 + barDate.width / 2
        readonly property real startY: height - Theme.barHeight / 2

        // ---- Where the clock ends (the invisible copies in the column below) -------------
        readonly property real endY_time: stack.y + timeTarget.y + timeTarget.height / 2
        readonly property real endY_date: stack.y + dateTarget.y + dateTarget.height / 2

        // ---- Background: the frame color first, then the wallpaper fades in --------------
        Rectangle {
          anchors.fill: parent
          color: Theme.base
        }
        // The raw image is hidden, MultiEffect draws it blurred. The blur grows with the animation.
        Image {
          id: wallpaper
          anchors.fill: parent
          source: root.wallpaperPath
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          visible: false
          layer.enabled: true
        }
        MultiEffect {
          anchors.fill: parent
          source: wallpaper
          visible: wallpaper.status === Image.Ready
          autoPaddingEnabled: false   // otherwise the edges of the screen get dark
          blurEnabled: true
          blurMax: 64
          blur: content.p * 0.8       // 0 to 1, raise the 0.8 for more blur
          opacity: Math.min(1, content.p * 1.5)
        }
        // Slight dark layer so the text is readable on bright wallpapers
        Rectangle {
          anchors.fill: parent
          color: "black"
          opacity: 0.25 * content.p
        }

        // ---- Keyboard --------------------------------------------------------------------
        Keys.onPressed: event => {
          if (root.closing) { event.accepted = true; return }

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

        // ---- Final layout: clock, date and password box ----------------------------------
        Column {
          id: stack
          anchors.centerIn: parent
          spacing: 14

          // Invisible: they only reserve the place where the flying clock lands
          Text {
            id: timeTarget
            anchors.horizontalCenter: parent.horizontalCenter
            text: content.timeStr
            font.pixelSize: 96
            font.bold: true
            opacity: 0
          }
          Text {
            id: dateTarget
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "dddd, dd MMMM yyyy")
            font.pixelSize: 20
            opacity: 0
          }

          Item { width: 1; height: 24 }

          Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 300; height: 48; radius: 12
            color: Theme.surface
            border.width: 2
            border.color: root.status !== "" ? Theme.danger : Theme.accent
            opacity: content.late

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
            opacity: content.late
          }
        }

        // ---- The flying clock: starts as the bar's clock, ends as the big one ------------
        Text {
          text: content.timeStr
          color: Theme.text
          font.bold: true
          font.pixelSize: content.lerp(15, 96, content.p)
          x: content.lerp(content.startTimeX, content.width / 2, content.p) - width / 2
          y: content.lerp(content.startY, content.endY_time, content.p) - height / 2
        }

        // The date changes format on the way ("Sat, 21 Nov 2026" -> "Saturday, 21 November 2026"),
        // so the short one fades out while the long one fades in
        Text {
          text: barDate.text
          color: Theme.subtext
          font.pixelSize: content.lerp(15, 20, content.p)
          opacity: 1 - Math.min(1, content.p * 3)
          x: content.lerp(content.startDateX, content.width / 2, content.p) - width / 2
          y: content.lerp(content.startY, content.endY_date, content.p) - height / 2
        }
        Text {
          text: dateTarget.text
          color: Theme.subtext
          font.pixelSize: content.lerp(15, 20, content.p)
          opacity: Math.max(0, Math.min(1, (content.p - 0.15) * 2))
          x: content.lerp(content.startDateX, content.width / 2, content.p) - width / 2
          y: content.lerp(content.startY, content.endY_date, content.p) - height / 2
        }

        // ---- Music: only while a player exists -------------------------------------------
        Rectangle {
          id: mediaCard
          visible: Media.player !== null
          opacity: content.late
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: stack.bottom
          anchors.topMargin: 36
          width: 380; height: 84; radius: 18
          color: Theme.surface

          Row {
            anchors { fill: parent; margins: 12 }
            spacing: 12

            // Album art (falls back to a note icon)
            Item {
              width: 60; height: 60
              anchors.verticalCenter: parent.verticalCenter

              Rectangle {
                anchors.fill: parent
                radius: 12
                color: Theme.overlay
              }
              RoundedImage {
                anchors.fill: parent
                radius: 12
                source: Media.artUrl
              }
              Text {
                anchors.centerIn: parent
                visible: Media.artUrl === ""
                text: Icons.music
                color: Theme.muted
                font.pixelSize: 26
              }
            }

            // Title and artist
            Column {
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width - 60 - 12 - controls.width - 12
              spacing: 2

              Text {
                width: parent.width
                text: Media.title
                color: Theme.text
                font.pixelSize: 15
                font.bold: true
                elide: Text.ElideRight
              }
              Text {
                width: parent.width
                visible: text !== ""
                text: Media.artist
                color: Theme.subtext
                font.pixelSize: 13
                elide: Text.ElideRight
              }
            }

            // Controls
            Row {
              id: controls
              anchors.verticalCenter: parent.verticalCenter
              spacing: 4

              Rectangle {
                width: 36; height: 36; radius: 18
                anchors.verticalCenter: parent.verticalCenter
                opacity: Media.player && Media.player.canGoPrevious ? 1 : 0.35
                color: prevMouse.containsMouse ? Theme.overlay : "transparent"
                Text { anchors.centerIn: parent; text: Icons.prev; color: Theme.text; font.pixelSize: 20 }
                MouseArea {
                  id: prevMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: if (Media.player && Media.player.canGoPrevious) Media.player.previous()
                }
              }

              Rectangle {
                width: 40; height: 40
                radius: Media.playing ? 12 : 20   // circle <-> rounded square, like the music popup
                Behavior on radius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.accent
                Text {
                  anchors.centerIn: parent
                  text: Media.playing ? Icons.pause : Icons.play
                  color: Theme.base
                  font.pixelSize: 20
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: if (Media.player && Media.player.canTogglePlaying) Media.player.togglePlaying()
                }
              }

              Rectangle {
                width: 36; height: 36; radius: 18
                anchors.verticalCenter: parent.verticalCenter
                opacity: Media.player && Media.player.canGoNext ? 1 : 0.35
                color: nextMouse.containsMouse ? Theme.overlay : "transparent"
                Text { anchors.centerIn: parent; text: Icons.next; color: Theme.text; font.pixelSize: 20 }
                MouseArea {
                  id: nextMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: if (Media.player && Media.player.canGoNext) Media.player.next()
                }
              }
            }
          }
        }

        // ---- Reboot / shutdown (bottom center, two clicks to confirm) --------------------
        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 56
          spacing: 12
          opacity: content.late

          Repeater {
            model: [
              { label: "Reboot",   icon: "",           cmd: ["systemctl", "reboot"] },
              { label: "Shutdown", icon: Icons.power,  cmd: ["systemctl", "poweroff"] }
            ]

            delegate: Rectangle {
              id: btn
              required property var modelData
              property bool armed: false   // first click arms it for 3 seconds, second click runs it

              width: 150; height: 44; radius: 12
              color: armed ? Theme.danger : btnMouse.containsMouse ? Theme.overlay : Theme.surface

              Timer {
                id: disarm
                interval: 3000
                onTriggered: btn.armed = false
              }

              Row {
                anchors.centerIn: parent
                spacing: 8

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  visible: btn.modelData.icon !== ""
                  text: btn.modelData.icon
                  color: btn.armed ? Theme.base : Theme.danger
                  font.pixelSize: 16
                }
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: btn.armed ? "Click again" : btn.modelData.label
                  color: btn.armed ? Theme.base : Theme.text
                  font.pixelSize: 14
                }
              }

              MouseArea {
                id: btnMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (btn.armed) {
                    btn.armed = false
                    disarm.stop()
                    Quickshell.execDetached(btn.modelData.cmd)
                  } else {
                    btn.armed = true
                    disarm.restart()
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
