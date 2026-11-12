import QtQuick

// The music controls (content of its popout)
Item {
  id: root

  readonly property var p: Media.player
  readonly property real pos: p ? p.position : 0
  readonly property real len: p ? p.length : 0

  implicitWidth: 340
  implicitHeight: content.implicitHeight + 40

  function fmt(seconds) {
    if (!isFinite(seconds) || seconds < 0) return "0:00"
    const s = Math.floor(seconds)
    return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
  }

  // MPRIS doesn't push position updates, so we ask for them while the popup is open
  Timer {
    interval: 500
    repeat: true
    running: Visibilities.music && Media.playing && root.p && root.p.positionSupported
    onTriggered: root.p.positionChanged()
  }

  // Blurred album art as the background, tinted by the theme (like iOS / One UI)
  RoundedImage {
    anchors.fill: parent
    radius: Theme.popoutRounding
    squareBottom: false
    source: Media.artUrl
    blurAmount: 2.1
    opacity: 0.1
  }

  Column {
    id: content
    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
    spacing: 16

    // Album art
    Rectangle {
      width: parent.width
      height: width
      radius: 20
      color: Theme.surface

      RoundedImage {
        anchors.fill: parent
        radius: 20
        source: Media.artUrl
      }

      Text {
        anchors.centerIn: parent
        visible: Media.artUrl === ""
        text: Icons.music
        color: Theme.muted
        font.pixelSize: 72
      }
    }

    // Title and artist
    Column {
      width: parent.width
      spacing: 2

      Text {
        width: parent.width
        text: Media.title
        color: Theme.text
        font.pixelSize: 20
        font.bold: true
        elide: Text.ElideRight
      }
      Text {
        width: parent.width
        visible: text !== ""
        text: Media.artist
        color: Theme.subtext
        font.pixelSize: 15
        elide: Text.ElideRight
      }
    }

    // Seek bar + timestamps
    Column {
      width: parent.width
      spacing: 4
      visible: root.p && root.p.lengthSupported && root.len > 0

      Item {
        id: seek
        width: parent.width
        height: 18

        property bool dragging: false
        property real dragRatio: 0
        readonly property real ratio: root.len > 0 ? Math.max(0, Math.min(1, root.pos / root.len)) : 0
        readonly property real shown: dragging ? dragRatio : ratio

        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width
          height: seekMouse.containsMouse || seek.dragging ? 8 : 6
          radius: height / 2
          color: Theme.overlay
          Behavior on height { NumberAnimation { duration: 100 } }

          Rectangle {
            width: parent.width * seek.shown
            height: parent.height
            radius: parent.radius
            color: Theme.accent
          }
        }

        MouseArea {
          id: seekMouse
          anchors.fill: parent
          hoverEnabled: true
          enabled: root.p && root.p.canSeek && root.p.positionSupported
          cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

          function ratioAt(x) { return Math.max(0, Math.min(1, x / width)) }

          onPressed: mouse => { seek.dragging = true; seek.dragRatio = ratioAt(mouse.x) }
          onPositionChanged: mouse => { if (seek.dragging) seek.dragRatio = ratioAt(mouse.x) }
          onReleased: {
            if (root.p) root.p.position = seek.dragRatio * root.len
            seek.dragging = false
          }
          onCanceled: seek.dragging = false
        }
      }

      Item {
        width: parent.width
        height: timeLeft.implicitHeight

        Text {
          id: timeLeft
          anchors.left: parent.left
          text: root.fmt(seek.dragging ? seek.dragRatio * root.len : root.pos)
          color: Theme.muted
          font.pixelSize: 12
        }
        Text {
          anchors.right: parent.right
          text: root.fmt(root.len)
          color: Theme.muted
          font.pixelSize: 12
        }
      }
    }

    // Controls
    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 20

      // Previous
      Rectangle {
        width: 48; height: 48; radius: 24
        anchors.verticalCenter: parent.verticalCenter
        opacity: root.p && root.p.canGoPrevious ? 1 : 0.35
        color: prevMouse.containsMouse ? Theme.overlay : "transparent"
        Text {
          anchors.centerIn: parent
          text: Icons.prev
          color: Theme.text
          font.pixelSize: 28
        }
        MouseArea {
          id: prevMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: if (root.p && root.p.canGoPrevious) root.p.previous()
        }
      }

      // Play / pause
      Rectangle {
        width: 64; height: 64
        radius: Media.playing ? 20 : 32   // morphs between a circle and a rounded square
        Behavior on radius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        color: Theme.accent
        scale: playMouse.pressed ? 0.94 : playMouse.containsMouse ? 1.04 : 1
        Behavior on scale { NumberAnimation { duration: 100 } }
        Text {
          anchors.centerIn: parent
          text: Media.playing ? Icons.pause : Icons.play
          color: Theme.base
          font.pixelSize: 32
        }
        MouseArea {
          id: playMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: if (root.p && root.p.canTogglePlaying) root.p.togglePlaying()
        }
      }

      // Next
      Rectangle {
        width: 48; height: 48; radius: 24
        anchors.verticalCenter: parent.verticalCenter
        opacity: root.p && root.p.canGoNext ? 1 : 0.35
        color: nextMouse.containsMouse ? Theme.overlay : "transparent"
        Text {
          anchors.centerIn: parent
          text: Icons.next
          color: Theme.text
          font.pixelSize: 28
        }
        MouseArea {
          id: nextMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: if (root.p && root.p.canGoNext) root.p.next()
        }
      }
    }
  }
}
