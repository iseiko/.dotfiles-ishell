import QtQuick

// One page of the MorphPopout. Put the content inside it (the content needs an implicitWidth and
// implicitHeight, which tell the panel how big to become).
Item {
  id: page

  required property var panel          // the MorphPopout this page belongs to
  required property string name        // what MorphPopout.current has to be to show this page

  property bool corner: false          // true: sits in the bottom-right corner, against the frame
  property real anchorX: -1            // for a page in the bar: where its middle is (-1 = the screen's middle)

  default property alias content: holder.data

  readonly property Item child: holder.children.length > 0 ? holder.children[0] : null

  implicitWidth: child ? child.implicitWidth : 0
  implicitHeight: child ? child.implicitHeight : 0
  width: implicitWidth
  height: Math.min(implicitHeight, panel.maxHeight)

  // Stuck to the bottom, and to the right in a corner page, otherwise in the middle
  anchors.bottom: parent.bottom
  anchors.right: corner ? parent.right : undefined
  anchors.horizontalCenter: corner ? undefined : parent.horizontalCenter

  // The old page fades out while the new one fades in
  opacity: panel.current === name ? 1 : 0
  visible: opacity > 0 || panel.current === name
  Behavior on opacity { NumberAnimation { duration: 200 } }

  Item {
    id: holder
    anchors.fill: parent
  }
}
