pragma Singleton

import Quickshell

// Nerd Font icons, written as code points so they can't get mangled when copying files around
Singleton {
  readonly property string apps:      String.fromCodePoint(0xF003B)
  readonly property string power:     String.fromCodePoint(0xF0425)
  readonly property string lock:      String.fromCodePoint(0xF033E)
  readonly property string suspend:   String.fromCodePoint(0xF0904)
  readonly property string hibernate: String.fromCodePoint(0xF02CA)
  readonly property string reboot:    String.fromCodePoint(0xF0709)
  readonly property string play:      String.fromCodePoint(0xF040A)
  readonly property string pause:     String.fromCodePoint(0xF03E4)
  readonly property string prev:      String.fromCodePoint(0xF04AE)
  readonly property string next:      String.fromCodePoint(0xF04AD)
  readonly property string music:     String.fromCodePoint(0xF075A)

  // ---- Icons that change with the level -------------------------------------
  function volume(level, muted) {
    if (muted || level <= 0) return String.fromCodePoint(0xF075F)   // muted
    if (level < 0.34)        return String.fromCodePoint(0xF057F)   // low
    if (level < 0.67)        return String.fromCodePoint(0xF0580)   // medium
    return String.fromCodePoint(0xF057E)                            // high
  }

  function brightness(level) {
    if (level < 0.34) return String.fromCodePoint(0xF00DE)
    if (level < 0.67) return String.fromCodePoint(0xF00DF)
    return String.fromCodePoint(0xF00E0)
  }

  // percent: 0 to 100
  function battery(percent, charging) {
    const normal   = [0xF007A, 0xF007B, 0xF007C, 0xF007D, 0xF007E, 0xF007F, 0xF0080, 0xF0081, 0xF0082, 0xF0079]
    const charge   = [0xF089C, 0xF0086, 0xF0087, 0xF0088, 0xF089D, 0xF0089, 0xF089E, 0xF008A, 0xF008B, 0xF0085]
    const i = Math.max(0, Math.min(9, Math.ceil(percent / 10) - 1))
    return String.fromCodePoint((charging ? charge : normal)[i])
  }
}
