import QtQuick
import QtQuick.Effects

// The frame around the screen: a solid sheet covering the whole screen with a rounded hole cut out.
// The sides are Theme.border thick, the bottom is Theme.barHeight thick (that is where the bar lives).
Item {
  id: root

  Rectangle {
    anchors.fill: parent
    color: Theme.base

    layer.enabled: true
    layer.effect: MultiEffect {
      maskSource: mask
      maskEnabled: true
      maskInverted: true        // cut the hole instead of keeping it
      maskThresholdMin: 0.5
      maskSpreadAtMin: 1
    }
  }

  // The shape of the hole
  Item {
    id: mask
    anchors.fill: parent
    layer.enabled: true
    visible: false

    Rectangle {
      x: Theme.border
      y: Theme.border
      width: parent.width - Theme.border * 2
      height: parent.height - Theme.border - Theme.barHeight
      radius: Theme.rounding
    }
  }
}
