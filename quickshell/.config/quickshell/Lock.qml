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
    interval: 580   // a bit more than the closing animation (520 ms)
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
        //
        // Locking uses a "decelerate" curve (it leaves the bar fast and settles slowly), unlocking
        // an "accelerate" one (it gathers speed on its way back into the bar). These are the same
        // curves the popups of the shell use.
        property real p: 0

        NumberAnimation {
          id: lockAnim
          target: content
          property: "p"
          to: 1
          duration: 950
          easing.type: Easing.BezierSpline
          easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
        }
        NumberAnimation {
          id: unlockAnim
          target: content
          property: "p"
          to: 0
          duration: 520
          easing.type: Easing.BezierSpline
          easing.bezierCurve: [0.3, 0.0, 0.8, 0.15, 1.0, 1.0]
        }

        // Everything that is not the clock appears in the second half of the animation
        readonly property real late: Math.max(0, Math.min(1, (p - 0.5) / 0.5))

        // Wait a moment so the surface is on screen before the animation starts
        Timer {
          running: true
          interval: 40
          onTriggered: if (!root.closing) lockAnim.start()
        }
        Connections {
          target: root
          function onClosingChanged() {
            if (root.closing) {
              lockAnim.stop()
              unlockAnim.start()
            }
          }
        }

        function lerp(a, b, t) { return a + (b - a) * t }
        function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

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
        // A dark layer so the text is readable on bright wallpapers: darker at the top and, most of
        // all, at the bottom (where the buttons are)
        Rectangle {
          anchors.fill: parent
          opacity: content.p
          gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.30) }
            GradientStop { position: 0.5; color: Qt.rgba(0, 0, 0, 0.18) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.45) }
          }
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
            if (root.status !== "") root.status = ""   // typing again clears "Wrong password"
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

          // The password box
          Rectangle {
            id: passBox
            anchors.horizontalCenter: parent.horizontalCenter
            width: 320; height: 52; radius: 26
            color: content.alpha(Theme.surface, 0.62)
            border.width: 2
            border.color: root.status !== "" ? Theme.danger : content.alpha(Theme.accent, 0.9)
            Behavior on border.color { ColorAnimation { duration: 160 } }

            opacity: content.late
            scale: content.lerp(0.94, 1, content.late)
            transform: Translate { x: content.shake }

            // Placeholder, or "Checking..." while PAM answers
            Text {
              id: hint
              anchors.centerIn: parent
              visible: root.buffer.length === 0 || root.checking
              text: root.checking ? "Checking..." : "Password"
              color: root.checking ? Theme.text : Theme.muted
              font.pixelSize: 16

              SequentialAnimation on opacity {
                running: root.checking
                loops: Animation.Infinite
                onRunningChanged: if (!running) hint.opacity = 1
                NumberAnimation { from: 1; to: 0.35; duration: 500; easing.type: Easing.InOutSine }
                NumberAnimation { from: 0.35; to: 1; duration: 500; easing.type: Easing.InOutSine }
              }
            }

            // One dot per character typed, each one pops in
            Row {
              anchors.centerIn: parent
              spacing: 8
              visible: root.buffer.length > 0 && !root.checking

              Repeater {
                model: Math.min(root.buffer.length, 20)
                delegate: Rectangle {
                  width: 10; height: 10; radius: 5
                  color: Theme.text
                  scale: 0
                  Component.onCompleted: scale = 1
                  Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
                }
              }
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

        // A short shake of the password box when the password is wrong
        property real shake: 0
        SequentialAnimation {
          id: shakeAnim
          NumberAnimation { target: content; property: "shake"; to: -12; duration: 50 }
          NumberAnimation { target: content; property: "shake"; to: 12; duration: 70 }
          NumberAnimation { target: content; property: "shake"; to: -8; duration: 60 }
          NumberAnimation { target: content; property: "shake"; to: 5; duration: 50 }
          NumberAnimation { target: content; property: "shake"; to: 0; duration: 50 }
        }
        Connections {
          target: root
          function onStatusChanged() { if (root.status !== "") shakeAnim.restart() }
        }

        // ---- The flying clock: starts as the bar's clock, ends as the big one ------------
        // Every piece of text is drawn at its FINAL size and shrunk with `scale`. Changing the
        // font size on every frame makes text jitter (the letters snap to the pixel grid each
        // time), a scale moves smoothly.
        Text {
          text: content.timeStr
          color: Theme.text
          font.bold: true
          font.pixelSize: 96
          transformOrigin: Item.Center
          scale: content.lerp(15 / 96, 1, content.p)
          x: content.lerp(content.startTimeX, content.width / 2, content.p) - width / 2
          y: content.lerp(content.startY, content.endY_time, content.p) - height / 2
        }

        // The date changes format on the way ("Sat, 21 Nov 2026" -> "Saturday, 21 November 2026"),
        // so the short one fades out while the long one fades in
        Text {
          text: barDate.text
          color: Theme.subtext
          font.pixelSize: 20
          transformOrigin: Item.Center
          scale: content.lerp(15 / 20, 1, content.p)
          opacity: 1 - Math.min(1, content.p * 3)
          x: content.lerp(content.startDateX, content.width / 2, content.p) - width / 2
          y: content.lerp(content.startY, content.endY_date, content.p) - height / 2
        }
        Text {
          text: dateTarget.text
          color: Theme.subtext
          font.pixelSize: 20
          transformOrigin: Item.Center
          scale: content.lerp(15 / 20, 1, content.p)
          opacity: Math.max(0, Math.min(1, (content.p - 0.15) * 2))
          x: content.lerp(content.startDateX, content.width / 2, content.p) - width / 2
          y: content.lerp(content.startY, content.endY_date, content.p) - height / 2
        }

        // ---- Music: only while a player exists -------------------------------------------
        Rectangle {
          id: mediaCard
          visible: Media.player !== null
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: stack.bottom
          anchors.topMargin: 36
          width: 440; height: 104; radius: 26
          color: content.alpha(Theme.surface, 0.62)
          border.width: 1
          border.color: Qt.rgba(1, 1, 1, 0.09)

          opacity: content.late
          transform: Translate { y: (1 - content.late) * 18 }

          readonly property var player: Media.player
          readonly property real position: player ? player.position : 0
          readonly property real length: player ? player.length : 0
          readonly property real ratio: length > 0 ? Math.max(0, Math.min(1, position / length)) : 0

          // MPRIS doesn't push the position, so ask for it while it plays
          Timer {
            interval: 500
            repeat: true
            running: mediaCard.visible && Media.playing && mediaCard.player
                     && mediaCard.player.positionSupported && content.late > 0.5
            onTriggered: mediaCard.player.positionChanged()
          }

          // The album art, blurred, as a tint (like the music popup)
          RoundedImage {
            anchors.fill: parent
            radius: mediaCard.radius
            source: Media.artUrl
            blurAmount: 1
            opacity: 0.30
          }

          Row {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
            height: 64
            spacing: 14

            // Album art (falls back to a note icon)
            Item {
              id: art
              width: 64; height: 64
              anchors.verticalCenter: parent.verticalCenter

              Rectangle {
                anchors.fill: parent
                radius: 16
                color: Theme.overlay
              }
              RoundedImage {
                anchors.fill: parent
                radius: 16
                source: Media.artUrl
              }
              Text {
                anchors.centerIn: parent
                visible: Media.artUrl === ""
                text: Icons.music
                color: Theme.muted
                font.pixelSize: 28
              }
            }

            // Title and artist
            Column {
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width - art.width - controls.width - parent.spacing * 2
              spacing: 3

              Text {
                width: parent.width
                text: Media.title
                color: Theme.text
                font.pixelSize: 16
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
              spacing: 6

              Rectangle {
                width: 38; height: 38; radius: 19
                anchors.verticalCenter: parent.verticalCenter
                opacity: Media.player && Media.player.canGoPrevious ? 1 : 0.35
                color: prevMouse.containsMouse ? content.alpha(Theme.overlay, 0.9) : "transparent"
                scale: prevMouse.pressed ? 0.9 : 1
                Behavior on scale { NumberAnimation { duration: 100 } }
                Text { anchors.centerIn: parent; text: Icons.prev; color: Theme.text; font.pixelSize: 21 }
                MouseArea {
                  id: prevMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: if (Media.player && Media.player.canGoPrevious) Media.player.previous()
                }
              }

              Rectangle {
                width: 46; height: 46
                radius: Media.playing ? 15 : 23   // circle <-> rounded square, like the music popup
                Behavior on radius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.accent
                scale: playMouse.pressed ? 0.92 : playMouse.containsMouse ? 1.06 : 1
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
                Text {
                  anchors.centerIn: parent
                  text: Media.playing ? Icons.pause : Icons.play
                  color: Theme.base
                  font.pixelSize: 22
                }
                MouseArea {
                  id: playMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: if (Media.player && Media.player.canTogglePlaying) Media.player.togglePlaying()
                }
              }

              Rectangle {
                width: 38; height: 38; radius: 19
                anchors.verticalCenter: parent.verticalCenter
                opacity: Media.player && Media.player.canGoNext ? 1 : 0.35
                color: nextMouse.containsMouse ? content.alpha(Theme.overlay, 0.9) : "transparent"
                scale: nextMouse.pressed ? 0.9 : 1
                Behavior on scale { NumberAnimation { duration: 100 } }
                Text { anchors.centerIn: parent; text: Icons.next; color: Theme.text; font.pixelSize: 21 }
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

          // How far the song is
          Rectangle {
            anchors {
              left: parent.left; right: parent.right; bottom: parent.bottom
              leftMargin: 20; rightMargin: 20; bottomMargin: 14
            }
            height: 4
            radius: 2
            color: Qt.rgba(1, 1, 1, 0.14)
            visible: mediaCard.length > 0

            Rectangle {
              width: parent.width * mediaCard.ratio
              height: parent.height
              radius: parent.radius
              color: Theme.accent
            }
          }
        }

        // ---- Logout / hibernate / reboot / shutdown (bottom center, two clicks to confirm) ---
        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 44
          spacing: 20

          Repeater {
            model: [
              {
                label: "Logout", icon: Icons.logout, danger: false,
                cmd: ["sh", "-c", "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"]
              },
              { label: "Hibernate", icon: Icons.hibernate, danger: false, cmd: ["systemctl", "hibernate"] },
              { label: "Reboot",    icon: Icons.reboot,    danger: true,  cmd: ["systemctl", "reboot"] },
              { label: "Shutdown",  icon: Icons.power,     danger: true,  cmd: ["systemctl", "poweroff"] }
            ]

            delegate: Item {
              id: btn
              required property var modelData
              required property int index

              property bool armed: false   // first click arms it for 3 seconds, second click runs it
              property real remaining: 0   // 1 -> 0 while it is armed, drawn as a thin line

              // The buttons come in one after the other, a little after the clock arrived
              readonly property real appear: Math.max(0, Math.min(1, (content.late - index * 0.12) / 0.64))

              width: 78
              height: 96
              opacity: appear
              transform: Translate { y: (1 - btn.appear) * 16 }

              function disarm() {
                armed = false
                countdown.stop()
                remaining = 0
              }

              Timer {
                id: disarmTimer
                interval: 3000
                onTriggered: btn.disarm()
              }
              NumberAnimation {
                id: countdown
                target: btn
                property: "remaining"
                from: 1
                to: 0
                duration: 3000
              }

              Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 9

                // The round button
                Rectangle {
                  anchors.horizontalCenter: parent.horizontalCenter
                  width: 62; height: 62; radius: 31

                  color: btn.armed ? Theme.danger
                       : btnMouse.containsMouse ? content.alpha(Theme.overlay, 0.92)
                       : content.alpha(Theme.surface, 0.62)
                  border.width: 1
                  border.color: btn.armed ? Theme.danger : Qt.rgba(1, 1, 1, btnMouse.containsMouse ? 0.18 : 0.09)
                  scale: btnMouse.pressed ? 0.93 : btn.armed ? 1.1 : btnMouse.containsMouse ? 1.06 : 1

                  Behavior on color { ColorAnimation { duration: 150 } }
                  Behavior on border.color { ColorAnimation { duration: 150 } }
                  Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }

                  Text {
                    anchors.centerIn: parent
                    text: btn.modelData.icon
                    color: btn.armed ? Theme.base : btn.modelData.danger ? Theme.danger : Theme.text
                    font.pixelSize: 25
                    Behavior on color { ColorAnimation { duration: 150 } }
                  }

                  MouseArea {
                    id: btnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      if (btn.armed) {
                        btn.disarm()
                        disarmTimer.stop()
                        Quickshell.execDetached(btn.modelData.cmd)
                      } else {
                        btn.armed = true
                        disarmTimer.restart()
                        countdown.restart()
                      }
                    }
                  }
                }

                // The name, or what to do next
                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: btn.armed ? "Click again" : btn.modelData.label
                  color: btn.armed ? Theme.danger : Theme.subtext
                  font.pixelSize: 12
                  font.bold: btn.armed
                }
              }

              // Time left to confirm: a thin line that empties in 3 seconds
              Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                width: 46 * btn.remaining
                height: 2
                radius: 1
                color: Theme.danger
                visible: btn.armed
              }
            }
          }
        }
      }
    }
  }
}
