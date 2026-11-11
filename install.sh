#!/bin/sh

# Install paru if needed, my choice of aur helper

is_paru_installed () {
  pacman -Qi "paru" &> /dev/null
}

if ! is_paru_installed; then
  echo "Paru is not installed, starting install process"
  echo "You will need to allow some prompts!"
  cd ~
  git clone https://aur.archlinux.org/paru.git
  cd paru
  makepkg -si 
  cd ~ 
  rm -rf paru
  echo "Done!"
  echo "Next..."
else
  echo "Paru is already installed, skipping..."
fi

# Install necessary packages

echo "Now all the packages needed will be installed!"

paru -Syyu --noconfirm --needed zen-browser oh-my-posh-bin neovim kitty hyprland noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-dejavu ttf-jetbrains-mono-nerd ttf-ms-fonts ttf-symbola fira-code-nerd-fonts stow eza zoxide hyprpolkitagent pipewire pipewire-alsa pipewire-jack pipewire-pulse wireplumber bluez blueman bluez-utils python-pillow libnotify awww quickshell zsh matugen-bin fzf hyprsunset hypridle 

# Set zsh as the main shell

sudo touch /dev/zsh/zshenv
sudo echo '
if [[ -z "$XDG_CONFIG_HOME" ]]; then
  export XDG_CONFIG_HOME="$HOME/.config"
fi

if [[ -d "$XDG_CONFIG_HOME/zsh" ]]; then
  export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
fi
' > /dev/zsh/zshenv

sudo chsh -s  $(which zsh)

# Configure needed directories

cd ~/.config

rm -r hypr zsh kitty matugen quickshell

cd ~/.dotfiles-ishell
stow -t ~ hypr 
stow -t ~ kitty
cd ~/.config/kitty 
python3 shell-colors.py
cd ~/.dotfiles-ishell
stow -t ~ matugen 
stow -t ~ quickshell
stow -t ~ zsh

# Reboot system

sudo systemctl soft-reboot
