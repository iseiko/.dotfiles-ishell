import QtQuick
import QtQuick.Shapes

// A panel that hangs from the top border in the top-right corner (touching the top and the right
// border). It grows downward out of the border, with concave curves where it meets the walls.
Item {
  id: root

  property bool shown: false
  property real fullWidth: 400
  property real fullHeight: 300
  property real attachY: 0            // y of the top border's lower edge, where the popout hangs from
  default property alias content: body.data

  // 0 = closed, 1 = fully open
  property real progress: 0

  readonly property real fillet: Math.min(Theme.fillet, height)

  width: fullWidth
  height: fullHeight * progress
  y: attachY
  visible: shown || progress > 0

  // Smooth growth when notifications come and go
  Behavior on fullHeight {
    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
  }

  Behavior on progress {
    NumberAnimation {
      id: anim
      duration: 380
      easing.type: Easing.OutQuart
    }
  }

  onShownChanged: {
    anim.duration = shown ? 380 : 240
    anim.easing.type = shown ? Easing.OutQuart : Easing.InCubic
    progress = shown ? 1 : 0
  }

  // The body. It starts above the popout so its square top corners hide inside the top border.
  Rectangle {
    y: -Theme.popoutRounding
    width: root.width
    height: root.height + Theme.popoutRounding
    bottomLeftRadius: Theme.popoutRounding
    color: Theme.base
  }

  // Swallows clicks on the popout's empty areas
  MouseArea { anchors.fill: parent }

  // Curve where the popout's left wall meets the top border
  Shape {
    x: -root.fillet
    y: 0
    width: root.fillet
    height: root.fillet
    visible: root.fillet > 0.5
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      strokeWidth: -1
      fillColor: Theme.base
      startX: root.fillet
      startY: 0
      PathLine { x: 0; y: 0 }
      PathArc {
        x: root.fillet; y: root.fillet
        radiusX: root.fillet; radiusY: root.fillet
        direction: PathArc.Clockwise
      }
    }
  }

  // Curve where the popout's bottom edge meets the right border
  Shape {
    x: root.width - root.fillet
    y: root.height
    width: root.fillet
    height: root.fillet
    visible: root.fillet > 0.5
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      strokeWidth: -1
      fillColor: Theme.base
      startX: root.fillet
      startY: 0
      PathLine { x: 0; y: 0 }
      PathArc {
        x: root.fillet; y: root.fillet
        radiusX: root.fillet; radiusY: root.fillet
        direction: PathArc.Clockwise
      }
    }
  }

  // Content: clipped to the popout and faded in once it is partly open
  Item {
    anchors.fill: parent
    clip: true
    opacity: Math.max(0, (root.progress - 0.25) / 0.75)

    Item {
      id: body
      width: root.fullWidth
      height: root.fullHeight
      anchors.top: parent.top
    }
  }
}
