<h1 align='center'>Dotfiles</p>

<h3 align='center'>My Arch Linux setup: <b>Hyprland</b> (Lua config) + <b>Quickshell</b> + <b>zsh</b>, with colors generated from the wallpaper via <b>matugen</b>.</h3>

 <h2 align='center'>Overview</h2>

| Component       | Choice                                                                           |
| --------------- | -------------------------------------------------------------------------------- |
| OS              | [Arch Linux](https://archlinux.org)                                              |
| Compositor      | [Hyprland](https://hypr.land/) (Lua config, 0.55+)                               |
| Shell / widgets | [Quickshell](https://quickshell.org/)                                            |
| Terminal shell  | zsh + [oh-my-posh](https://ohmyposh.dev/)                                        |
| Theming         | [Matugen](https://github.com/InioX/matugen) (Material You colors from wallpaper) |
| Terminal        | [Kitty](https://sw.kovidgoyal.net/kitty/)                                        |
| Font            | Fira Code Nerd Font                                                              |

<h2 align='center'>Structure</h2>

```
.config/
├── hypr/
│   ├── hyprland.lua          # entry point, loads the modules below
│   ├── matugen-colors.lua    # generated colors (matugen output)
│   ├── theme.lua             # theme loader
│   └── modules/
│       ├── binds.lua         # keybinds
│       ├── inputs.lua        # keyboard / mouse / touchpad
│       ├── looknfeel.lua     # gaps, borders, rounding, animations
│       ├── monitors.lua      # monitor layout
│       └── winrules.lua      # window rules
├── quickshell/
│   ├── shell.qml             # entry point
│   ├── Bar.qml               # status bar
│   ├── AppLauncher.qml       # app launcher
│   ├── PowerMenu.qml         # power / session menu
│   ├── Lock.qml              # lock screen (PAM)
│   ├── WallpaperPicker.qml   # wallpaper picker
│   ├── Theme.qml             # theme singleton
│   ├── colors.json           # generated colors (matugen output)
│   └── pam/password.conf     # PAM config used by the lock screen
└── zsh/
    ├── aliases.zsh
    ├── bindings.zsh
    ├── fzf.zsh
    ├── prompt.zsh
    ├── omp.yaml              # oh-my-posh prompt theme
    ├── plugins.zsh           # plugin loader
    └── plugins/              # fast-syntax-highlighting, zsh-autosuggestions,
                              # zsh-history-substring-search, zsh-vi-mode
```

<h2 align='center'>Features</h2>

- **Hyprland** configured in Lua and split into small modules (binds, inputs, look & feel, monitors, window rules).
- **Quickshell** desktop shell: bar, app launcher, power menu, lock screen and wallpaper picker.
- **Dynamic theming**: matugen generates `matugen-colors.lua` and `colors.json`, so Hyprland and Quickshell share one palette.
- **zsh** with syntax highlighting, autosuggestions, history substring search, vi mode, fzf integration and an oh-my-posh prompt.

<h2 align='center'>Dependencies</h2>

Core:

```sh
sudo pacman -S hyprland zsh fzf
paru -S quickshell-git matugen-bin oh-my-posh-bin awww   # or your AUR helper of choice
```

> Hyprland **0.55 or newer** is required, since the config uses the Lua API (`hl.*`) instead of hyprlang.

<h2 align='center'>Installation</h2>

```sh
git clone https://github.com/<user>/<repo>.git ~/dotfiles
cd ~/dotfiles

# back up existing configs first
mv ~/.config/hypr ~/.config/hypr.bak
mv ~/.config/quickshell ~/.config/quickshell.bak
mv ~/.config/zsh ~/.config/zsh.bak

# symlink
ln -s ~/dotfiles/.config/hypr       ~/.config/hypr
ln -s ~/dotfiles/.config/quickshell ~/.config/quickshell
ln -s ~/dotfiles/.config/zsh        ~/.config/zsh
```

Then point zsh at the config directory by adding this to `~/.zshenv`:

```sh
export ZDOTDIR="$HOME/.config/zsh"
```

You can also manage the symlinks with [GNU Stow](https://www.gnu.org/software/stow/) if you prefer.

<h2 align='center'>Usage</h2>

<h3 align='center'>Wallpaper and colors</h3>


```sh
matugen image /path/to/wallpaper.png
```

This regenerates `hypr/matugen-colors.lua` and `quickshell/colors.json`.

<h3 align='center'>Keybinds</h3>

See [`hypr/modules/binds.lua`](https://claude.ai/chat/.config/hypr/modules/binds.lua). `SUPER` is the main modifier.

| Keys                     | Action                   |
| ------------------------ | ------------------------ |
| `SUPER + Return`         | Terminal                 |
| `SUPER + F`              | Toggle fullscreen        |
| `SUPER + Q`              | Kill active              |
| `SUPER + SHIFT + arrows` | Move window              |
| `SUPER + 1-9`            | Switch workspace         |
| `SUPER + SHIFT + 1-9`    | Move window to workspace |

<!-- TODO: fill in from binds.lua -->

<h2 align='center'>Notes</h2>

- `quickshell/temp.qml` is a scratch file; consider removing it.
    
- The zsh plugins are vendored in `zsh/plugins/`. To keep the repo small and always up to date, you can replace them with git submodules:
    
    ```sh
    git submodule add https://github.com/zdharma-continuum/fast-syntax-highlighting .config/zsh/plugins/fast-syntax-highlighting
    git submodule add https://github.com/zsh-users/zsh-autosuggestions .config/zsh/plugins/zsh-autosuggestions
    git submodule add https://github.com/zsh-users/zsh-history-substring-search .config/zsh/plugins/zsh-history-substring-search
    git submodule add https://github.com/jeffreytse/zsh-vi-mode .config/zsh/plugins/zsh-vi-mode
    ```
    
<h2 align='center'>To Do</h2>

[X] Add icons to the main bar

[ ] Fix wallpaper rounding on wallpaper chooser script

[ ] Add calendar

[X] Fix animation of the app launcher

[ ] Add bluetooth and wifi connection center

[ ] Add bluetooth and wifi to the bar 


<h2 align='center'>Credits</h2>

- [Hyprland](https://hypr.land/)
- [Quickshell](https://quickshell.org/)
- [matugen](https://github.com/InioX/matugen)
- [oh-my-posh](https://ohmyposh.dev/)
- zsh plugins: fast-syntax-highlighting, zsh-autosuggestions, zsh-history-substring-search, zsh-vi-mode

<h2 align='center'>License</h2>

                    GNU GENERAL PUBLIC LICENSE
                       Version 3, 29 June 2007

 Copyright (C) 2007 Free Software Foundation, Inc. <https://fsf.org/>
 Everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.

