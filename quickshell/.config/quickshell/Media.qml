pragma Singleton

import Quickshell
import Quickshell.Services.Mpris
import QtQuick

// The media player the bar chip and the music popup are showing
Singleton {
  id: root

  // The player that is playing right now, otherwise the first one available
  readonly property var player: {
    const list = Mpris.players.values
    for (const p of list) if (p.isPlaying) return p
    return list.length > 0 ? list[0] : null
  }

  readonly property bool playing: player ? player.isPlaying : false
  readonly property string title:  player && player.trackTitle ? player.trackTitle : "Unknown title"
  readonly property string artist: player && player.trackArtist ? player.trackArtist : ""
  readonly property string artUrl: player && player.trackArtUrl ? player.trackArtUrl : ""

  // Close the music popup when the last player goes away
  onPlayerChanged: if (!player) Visibilities.music = false
}
