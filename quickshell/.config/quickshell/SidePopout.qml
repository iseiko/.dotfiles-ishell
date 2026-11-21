import QtQuick
import QtQuick.Shapes

// A panel that grows sideways out of the right border (the right-hand version of Popout).
// It is as tall as `fullHeight` and as wide as `fullWidth` once open. Set `y` to place it.
Item {
  id: root

  property bool shown: false
  property real fullWidth: 420
  property real fullHeight: 600
  property real attachX: 0            // x of the right border's inner edge, where it is attached
  default property alias content: body.data

  // 0 = closed, 1 = fully open
  property real progress: 0

  // Size of the concave curves where the panel meets the border, they grow with the panel
  readonly property real fillet: Math.min(Theme.fillet, width)

  width: fullWidth * progress
  height: fullHeight
  x: attachX - width
  visible: shown || progress > 0

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

  // The body. It reaches into the border so its square right corners are hidden there.
  Rectangle {
    width: root.width + Theme.popoutRounding
    height: root.height
    topLeftRadius: Theme.popoutRounding
    bottomLeftRadius: Theme.popoutRounding
    color: Theme.base
  }

  // Swallows clicks on the panel's empty areas
  MouseArea { anchors.fill: parent }

  // Curve where the panel's top edge meets the border
  Shape {
    x: root.width - root.fillet
    y: -root.fillet
    width: root.fillet
    height: root.fillet
    visible: root.fillet > 0.5
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      strokeWidth: -1
      fillColor: Theme.base
      startX: root.fillet
      startY: root.fillet
      PathLine { x: 0; y: root.fillet }
      PathArc {
        x: root.fillet; y: 0
        radiusX: root.fillet; radiusY: root.fillet
        direction: PathArc.Counterclockwise
      }
    }
  }

  // Curve where the panel's bottom edge meets the border
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

  // Content: clipped to the panel, stuck to its right side and revealed as the panel grows
  Item {
    anchors.fill: parent
    clip: true
    opacity: Math.max(0, (root.progress - 0.25) / 0.75)

    Item {
      id: body
      width: root.fullWidth
      height: root.fullHeight
      anchors.right: parent.right
    }
  }
}
