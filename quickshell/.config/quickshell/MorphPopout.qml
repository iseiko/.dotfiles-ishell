import QtQuick
import QtQuick.Shapes

// The one panel that every popup (except notifications) is a page of (see MorphPage.qml).
//
// Opening another popup does not close this panel and open another: the panel MOVES and CHANGES
// SHAPE into the new one, wherever it is: above an icon in the bar, in the middle, or in the
// bottom-right corner against the frame. The old page fades into the new one while it happens.
Item {
  id: root

  property string current: ""      // name of the open page, "" = closed
  property real maxHeight: 600     // the tallest the panel may be

  property real attachY: 0         // y of the top of the bar, where the panel stands
  property real attachX: 0         // x of the right border, for the pages that touch it
  property real sceneWidth: 0
  property real inset: 0           // the closest a page in the bar may get to the screen's sides

  default property alias content: body.data

  readonly property bool shown: current !== ""

  // 0 = closed, 1 = fully open
  property real progress: 0

  // The open page, found by its name
  function findPage(name) {
    for (let i = 0; i < body.children.length; i++) {
      if (body.children[i].name === name) return body.children[i]
    }
    return null
  }
  readonly property Item activePage: shown ? findPage(current) : null

  // What the panel is becoming. They keep their last value while closing, so the panel doesn't
  // change shape on its way out. They animate while the panel is open: that is the morph.
  property real pageWidth: 400
  property real pageHeight: 300
  property real centerX: 0             // where the middle of a page in the bar is
  property bool isCorner: false        // the page touches the right border
  property real rightness: isCorner ? 1 : 0   // 0 = a page in the bar, 1 = a corner page
  property bool snapCenter: false

  readonly property bool morphing: progress > 0.25

  Behavior on pageWidth {
    enabled: root.morphing
    NumberAnimation { duration: 340; easing.type: Easing.OutCubic }
  }
  Behavior on pageHeight {
    enabled: root.morphing
    NumberAnimation { duration: 340; easing.type: Easing.OutCubic }
  }
  Behavior on centerX {
    enabled: root.morphing && !root.snapCenter
    NumberAnimation { duration: 340; easing.type: Easing.OutCubic }
  }
  Behavior on rightness {
    enabled: root.morphing
    NumberAnimation { duration: 340; easing.type: Easing.OutCubic }
  }

  // Read the open page: its size, where it goes and which kind it is
  function sync() {
    if (!activePage) return

    pageWidth = activePage.width
    pageHeight = activePage.height

    // Leaving a corner page, the old middle is not visible yet, so don't slide it across the screen
    snapCenter = isCorner
    centerX = activePage.anchorX >= 0 ? activePage.anchorX : sceneWidth / 2
    snapCenter = false

    isCorner = activePage.corner
  }

  onActivePageChanged: sync()

  // Pages can change size (a list getting longer) or move (the music popup following its icon)
  Connections {
    target: root.activePage
    ignoreUnknownSignals: true
    function onWidthChanged() { root.pageWidth = root.activePage.width }
    function onHeightChanged() { root.pageHeight = root.activePage.height }
    function onAnchorXChanged() { root.sync() }
  }

  // The panel's place: in the bar (around centerX) or in the corner, and everything in between
  readonly property real barX: Math.max(inset, Math.min(centerX - width / 2, sceneWidth - width - inset))
  readonly property real cornerX: attachX - width

  width: pageWidth
  height: pageHeight * progress
  y: attachY - height
  x: barX + (cornerX - barX) * rightness
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

  // The body. It is taller than the panel so its square bottom corners hide inside the bar.
  Rectangle {
    width: root.width
    height: root.height + Theme.popoutRounding
    topLeftRadius: Theme.popoutRounding
    topRightRadius: Theme.popoutRounding * (1 - root.rightness)   // square in a corner: it meets the border
    color: Theme.base
  }

  // Swallows clicks on the panel's empty areas
  MouseArea { anchors.fill: parent }

  // Curve on the left, where the panel's wall meets the top of the bar
  Shape {
    id: leftCurve
    readonly property real f: Math.min(Theme.fillet, root.height)
    x: -f
    y: root.height - f
    width: f
    height: f
    visible: f > 0.5
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      strokeWidth: -1
      fillColor: Theme.base
      startX: leftCurve.f
      startY: leftCurve.f
      PathLine { x: 0; y: leftCurve.f }
      PathArc {
        x: leftCurve.f; y: 0
        radiusX: leftCurve.f; radiusY: leftCurve.f
        direction: PathArc.Counterclockwise
      }
    }
  }

  // Curve on the right, where the panel's wall meets the top of the bar (it fades away as the
  // panel moves into the corner, where the border takes its place)
  Shape {
    id: rightCurve
    readonly property real f: Math.min(Theme.fillet, root.height) * (1 - root.rightness)
    x: root.width
    y: root.height - f
    width: f
    height: f
    visible: f > 0.5
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      strokeWidth: -1
      fillColor: Theme.base
      startX: 0
      startY: rightCurve.f
      PathLine { x: rightCurve.f; y: rightCurve.f }
      PathArc {
        x: 0; y: 0
        radiusX: rightCurve.f; radiusY: rightCurve.f
        direction: PathArc.Clockwise
      }
    }
  }

  // Corner pages: the curve where the panel's top edge meets the right border
  Shape {
    id: cornerCurve
    readonly property real f: Math.min(Theme.fillet, root.height) * root.rightness
    x: root.width - f
    y: -f
    width: f
    height: f
    visible: f > 0.5
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      strokeWidth: -1
      fillColor: Theme.base
      startX: cornerCurve.f
      startY: cornerCurve.f
      PathLine { x: 0; y: cornerCurve.f }
      PathArc {
        x: cornerCurve.f; y: 0
        radiusX: cornerCurve.f; radiusY: cornerCurve.f
        direction: PathArc.Counterclockwise
      }
    }
  }

  // The pages: clipped to the panel and faded in once it is partly open
  Item {
    anchors.fill: parent
    clip: true
    opacity: Math.max(0, (root.progress - 0.25) / 0.75)

    Item {
      id: body
      anchors.fill: parent
    }
  }
}
