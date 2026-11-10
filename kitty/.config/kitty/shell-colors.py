#!/usr/bin/env python3
"""Turns the shell's colors.json into a kitty color config (shell-colors.conf)."""

import colorsys
import json
import os

home = os.path.expanduser("~")
src = os.path.join(home, ".config/quickshell/colors.json")
dst = os.path.join(home, ".config/kitty/shell-colors.conf")

c = json.load(open(src))


def to_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


def to_hex(rgb):
    return "#%02x%02x%02x" % tuple(round(max(0, min(1, v)) * 255) for v in rgb)


def hue(hex_color, degrees, lighten=0.0):
    """Same saturation and lightness as hex_color, but with another hue (for the ANSI colors)."""
    r, g, b = to_rgb(hex_color)
    _, l, s = colorsys.rgb_to_hls(r, g, b)
    l = max(0, min(1, l + lighten))
    return to_hex(colorsys.hls_to_rgb(degrees / 360, l, s))


# The 8 normal ANSI colors. Red and green come straight from your theme, the others are the
# accent color with a different hue, so blue stays blue whatever your wallpaper is.
red, green = c["danger"], c["success"]
blue = hue(c["accent"], 215)
yellow = hue(c["accent"], 45)
magenta = hue(c["accent"], 300)
cyan = hue(c["accent"], 180)

# Bright versions are a little lighter
def bright(x):
    return hue(x, colorsys.rgb_to_hls(*to_rgb(x))[0] * 360, 0.06)

lines = f"""# Generated from colors.json by shell-colors.py, do not edit by hand
foreground              {c['text']}
background              {c['base']}
selection_foreground    {c['base']}
selection_background    {c['accent']}
cursor                  {c['accent']}
cursor_text_color       {c['base']}
url_color               {c['accent']}

active_border_color     {c['accent']}
inactive_border_color   {c['overlay']}
bell_border_color       {c['danger']}

tab_bar_background      {c['base']}
active_tab_foreground   {c['base']}
active_tab_background   {c['accent']}
inactive_tab_foreground {c['subtext']}
inactive_tab_background {c['surface']}

color0  {c['overlay']}
color1  {red}
color2  {green}
color3  {yellow}
color4  {blue}
color5  {magenta}
color6  {cyan}
color7  {c['subtext']}

color8  {c['muted']}
color9  {bright(red)}
color10 {bright(green)}
color11 {bright(yellow)}
color12 {bright(blue)}
color13 {bright(magenta)}
color14 {bright(cyan)}
color15 {c['text']}
"""

with open(dst, "w") as f:
    f.write(lines)
