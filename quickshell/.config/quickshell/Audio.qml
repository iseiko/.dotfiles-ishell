pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// The default audio output. The bar and the volume/brightness panel both use it.
Singleton {
  id: root

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property bool available: (sink && sink.audio) ? true : false
  readonly property real volume: (sink && sink.audio) ? sink.audio.volume : 0
  readonly property bool muted: (sink && sink.audio) ? sink.audio.muted : false

  // Audio properties only update while the node is tracked
  PwObjectTracker { objects: [ root.sink ] }

  // Any change (the bar, the panel's slider or your keybinds) makes the panel pop out
  onVolumeChanged: Osd.notify()
  onMutedChanged: Osd.notify()

  function setVolume(v) {
    if (sink && sink.audio) sink.audio.volume = Math.max(0, Math.min(1, v))
  }
  function changeVolume(delta) { setVolume(volume + delta) }
  function toggleMute() {
    if (sink && sink.audio) sink.audio.muted = !sink.audio.muted
  }
}
