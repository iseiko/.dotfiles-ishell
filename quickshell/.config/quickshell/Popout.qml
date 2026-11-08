import QtQuick
import QtQuick.Shapes

// A panel that grows out of the bar. Put the content inside it, the content is stuck to the bottom
// and gets revealed as the panel grows.
//
//   Popout { shown: ...; fullWidth: 400; fullHeight: 300; x: ...; attachY: ... ; MyContent { anchors.fill: parent } }
Item {
  id: root

  property bool shown: false
  property real fullWidth: 400
  property real fullHeight: 300
  property real attachY: 0            // y of the bar's top edge, where the popout is attached
  // Set this when the popout's right edge touches the right border (a corner popout). Then the
  // top-right corner becomes a concave curve into the border instead of a rounded corner.
  property bool attachRight: false
  default property alias content: body.data

  // 0 = closed, 1 = fully open
  property real progress: 0

  // Size of the concave curves at the bottom corners, they grow together with the popout
  readonly property real fillet: Math.min(Theme.fillet, height)

  width: fullWidth
  height: fullHeight * progress
  y: attachY - height
  visible: shown || progress > 0

  Behavior on progress {
    NumberAnimation {
      id: anim
      duration: 380
      easing.type: Easing.OutQuart
    }
  }

  onShownChanged: {
    // fast and soft when opening, quicker when closing
    anim.duration = shown ? 380 : 240
    anim.easing.type = shown ? Easing.OutQuart : Easing.InCubic
    progress = shown ? 1 : 0
  }

  // The body. It is taller than the popout so its square bottom corners hide inside the bar.
  Rectangle {
    width: root.width
    height: root.height + Theme.popoutRounding
    topLeftRadius: Theme.popoutRounding
    topRightRadius: root.attachRight ? 0 : Theme.popoutRounding
    color: Theme.base
  }

  // Swallows clicks on the popout's empty areas so they don't close it
  MouseArea { anchors.fill: parent }

  // The two concave curves where the popout's walls meet the top of the bar
  Shape {
    x: -root.fillet
    y: root.height - root.fillet
    width: root.width + root.fillet * 2
    height: root.fillet
    visible: root.fillet > 0.5
    preferredRendererType: Shape.CurveRenderer

    // left side
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

    // right side (not needed when the popout touches the right border)
    ShapePath {
      strokeWidth: -1
      fillColor: root.attachRight ? "transparent" : Theme.base
      startX: root.fillet + root.width
      startY: root.fillet
      PathLine { x: root.width + root.fillet * 2; y: root.fillet }
      PathArc {
        x: root.fillet + root.width; y: 0
        radiusX: root.fillet; radiusY: root.fillet
        direction: PathArc.Clockwise
      }
    }
  }

  // Corner popouts only: the concave curve where the popout's top edge meets the right border
  Shape {
    x: root.width - root.fillet
    y: -root.fillet
    width: root.fillet
    height: root.fillet
    visible: root.attachRight && root.fillet > 0.5
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

  // Content: clipped to the popout and faded in once it is partly open
  Item {
    anchors.fill: parent
    clip: true
    opacity: Math.max(0, (root.progress - 0.25) / 0.75)

    Item {
      id: body
      width: root.fullWidth
      height: root.fullHeight
      anchors.bottom: parent.bottom
    }
  }
}
