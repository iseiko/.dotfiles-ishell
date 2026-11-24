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
│   ├── hyprland.lua            # entry point, loads the modules below
│   ├── matugen-colors.lua      # generated colors (matugen output)
│   ├── theme.lua               # theme loader
│   └── modules/
│       ├── binds.lua           # keybinds
│       ├── inputs.lua          # keyboard / mouse / touchpad
│       ├── looknfeel.lua       # gaps, borders, rounding, animations
│       ├── monitors.lua        # monitor layout
│       └── winrules.lua        # window rules
├── quickshell/
│   ├── Audio.qml               # audio osd notification
│   ├── Bar.qml                 # status bar
│   ├── BarModule.qml           # holds the modules located on the main bar
│   ├── BluetoothPopup.qml      # manages the bluetooth module on the shell
│   ├── BluetoothRow.qml        # 
│   ├── Brightness.qml          #
│   ├── colors.json             # generated colors (matugen output)
│   ├── Drawers.qml             #
│   ├── Icons.qml               #
│   ├── LauncherPopup.qml       #
│   ├── Lock.qml                # lock screen (PAM)
│   ├── Media.qml               #
│   ├── MusicPopup.qml          #
│   ├── NotificationsPopup.qml  #
│   ├── Osd.qml                 #
│   ├── OsdPopup.qml            #
│   ├── OsdSlider.qml           #
│   ├── pam/password.conf       # PAM config used by the lock screen
│   ├── Popout.qml              # 
│   ├── PowerPopout.qml         # 
│   ├── RoundedImage.qml        #
│   ├── ScreenFrame.qml         #
│   ├── shell.qml               # entry point
│   ├── SmallButton.qml         #
│   ├── SwitchButton.qml        #
│   ├── Theme.qml               # theme singleton
│   ├── TopPopout.qml           #
│   ├── Visibilities.qml        #
│   ├── WallpaperPopout.qml     #
│   ├── Wifi.qml                #
│   └── WifiPopout.qml          # 
└── zsh/
    ├── aliases.zsh
    ├── bindings.zsh
    ├── fzf.zsh
    ├── prompt.zsh
    ├── omp.yaml                # oh-my-posh prompt theme
    ├── plugins.zsh             # plugin loader
    └── plugins/                # fast-syntax-highlighting, zsh-autosuggestions,
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

git clone https://github.com/iseiko/.dotfiles-ishell.git

cd ~/dotfiles-ishell

sh ./install.sh

```

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

[X] Fix wallpaper rounding on wallpaper chooser script

[X] Add calendar on the mains clock 

[ ] Add power-profiles configuration tlpctl

[ ] Add keyboard layout switch icon and configuration

[ ] Reestructure readme

[X] Add icon tray for background apps

[X] Fix animations

[ ] Configure lockscreen

[X] Add logout option


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

