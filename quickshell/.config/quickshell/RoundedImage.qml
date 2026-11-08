import QtQuick
import QtQuick.Effects

// An image with rounded corners (and optional blur), used for album art
Item {
  id: root
  property alias source: img.source
  property alias status: img.status
  property real radius: 8
  property real blurAmount: 0       // 0 = sharp, 1 = fully blurred
  property bool squareBottom: false // only round the top corners (for things attached to the bar)

  // The raw image and the mask are hidden, MultiEffect draws the result
  Image {
    id: img
    anchors.fill: parent
    visible: false
    layer.enabled: true
    asynchronous: true
    fillMode: Image.PreserveAspectCrop
    sourceSize: Qt.size(Math.max(1, root.width) * 2, Math.max(1, root.height) * 2)
  }

  Rectangle {
    id: mask
    anchors.fill: parent
    topLeftRadius: root.radius
    topRightRadius: root.radius
    bottomLeftRadius: root.squareBottom ? 0 : root.radius
    bottomRightRadius: root.squareBottom ? 0 : root.radius
    visible: false
    layer.enabled: true
  }

  MultiEffect {
    anchors.fill: parent
    source: img
    visible: img.status === Image.Ready
    maskEnabled: true
    maskSource: mask
    blurEnabled: root.blurAmount > 0
    blur: root.blurAmount
    blurMax: 64
    autoPaddingEnabled: false   // otherwise the blur grows past the item and escapes the mask
  }
}
