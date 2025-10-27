#!/bin/bash
set -eo pipefail
## GNOME customisation script
## Install librewolf (1.143.0-3) through https://bit.ly/librewolf

# Some font thingy
bold=$(tput bold)
normal=$(tput sgr0)
blue=$(tput setaf 4)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
white=$(tput setaf 7)

mkdir ~/.config/gtk-themes -p
mkdir ~/.config/oh-my-posh -p
mkdir ~/Pictures/Wallpapers -p
mkdir ~/.local/share/gtksourceview-5 -p
mkdir ~/.local/share/gtksourceview-5/styles -p

# Install and remove several package
cd ~
echo "${bold}${green}==>${normal}${bold} Installing gnome utilities${normal}"
sudo pacman -Sy --needed --noconfirm gnome-terminal gtksourceview5 gnome-browser-connector dconf-editor gnome-sound-recorder
echo "${bold}${green}==>${normal}${bold} Removing gnome bloatwares${normal}"
sudo pacman -Rns --noconfirm malcontent gnome-user-docs yelp gnome-weather gnome-maps gnome-tour gnome-music gnome-contacts simple-scan 2>/dev/null || true

# Download wallpapers
echo "${bold}${green}==>${normal}${bold} Downloading wallpapers${normal}"
echo "${bold}${blue}    ~> Downloading${normal}${bold} MountainLakeCenterSunset.jpg${normal}"
curl https://raw.githubusercontent.com/cycion/dotdotfile/refs/heads/main/.config/wallpapers/MountainLakeCenterSunset.jpg  -o ~/Pictures/Wallpapers/MountainLakeCenterSunset.jpg
echo "${bold}${blue}    ~> Downloading${normal}${bold} SunsetMountainRight.jpg${normal}"
curl https://raw.githubusercontent.com/cycion/dotdotfile/refs/heads/main/.config/wallpapers/SunsetMountainRight.jpg  -o ~/Pictures/Wallpapers/SunsetMountainRight.jpg
echo "${bold}${blue}    ~> Downloading${normal}${bold} SnowMountain.jpg${normal}"
curl https://raw.githubusercontent.com/cycion/dotdotfile/refs/heads/main/.config/wallpapers/SnowMountain.jpg  -o ~/Pictures/Wallpapers/SnowMountain.jpg
# Install oh-my-zsh
[ -d "$HOME/.oh-my-zsh" ] && echo "Skipped installing oh-my-zsh: already installed" || (echo "${bold}${green}==>${normal}${bold} Installing oh-my-zsh${normal}" && sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended)
# Install oh-my-posh
[ -e "$HOME/.local/bin/oh-my-posh" ] && echo "Skipped installing oh-my-posh: already installed" || (echo "${bold}${green}==>${normal}${bold} Installing oh-my-posh${normal}" && curl -s https://ohmyposh.dev/install.sh | bash -s)
# Install configs
echo "${bold}${green}==>${normal}${bold} Loading configs${normal}"
echo "${bold}${blue}    -> Loading${normal}${bold} oh-my-posh configs${normal}"
curl https://raw.githubusercontent.com/cycion/dotdotfile/refs/heads/main/.config/oh-my-posh/dots.toml -o ~/.config/oh-my-posh/dots.toml
echo "${bold}${blue}    -> Loading${normal}${bold} .zshrc${normal}"
curl https://raw.githubusercontent.com/cycion/dotdotfile/refs/heads/main/.zshrc -o ~/.zshrc
# Install zsh plugins
echo "${bold}${green}==>${normal}${bold} Installing zsh plugins${normal}"
[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ] && echo "Skipped installing zsh-syntax-highlighting: already installed" || (echo "${bold}${blue}    -> Installing${normal}${bold} zsh-syntax-highlighting${normal}" && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting)

[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ] && echo "Skipped installing zsh-autosuggestions: already installed" || (echo "${bold}${blue}    -> Installing${normal}${bold} zsh-autosuggestions${normal}" && git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions)
# Install gtk themes
echo "${bold}${green}==>${normal}${bold} Enabling fractional scaling + xwayland native scaling${normal}"
gsettings set org.gnome.mutter experimental-features '["scale-monitor-framebuffer", "xwayland-native-scaling"]'

echo "${bold}${green}==>${normal}${bold} Downloading gtk themes${normal}"
echo "${bold}${blue}    ~> Downloading${normal}${bold} MacTahoe-gtk-theme${normal}"
[ -d "$HOME/.config/gtk-themes/MacTahoe-gtk-theme" ] && echo "Skipped downloading MacTahoe-gtk-theme: already downloaded" || git clone --depth=1 https://github.com/vinceliuice/MacTahoe-gtk-theme.git ~/.config/gtk-themes/MacTahoe-gtk-theme
echo "${bold}${blue}    ~> Downloading${normal}${bold} MacTahoe-icon-theme${normal}"
[ -d "$HOME/.config/gtk-themes/MacTahoe-icon-theme" ] && echo "Skipped downloading MacTahoe-icon-theme: already downloaded" || git clone --depth=1 https://github.com/vinceliuice/MacTahoe-icon-theme.git ~/.config/gtk-themes/MacTahoe-icon-theme

echo "${bold}${green}==>${normal}${bold} Installing gtk themes${normal}"
echo "${bold}${blue}    -> Installing${normal}${bold} MacTahoe-gtk-theme${normal}"
~/.config/gtk-themes/MacTahoe-gtk-theme/install.sh --libadwaita --shell -i apple -ns --round --darker
read -n 1 -s -r -p "${bold}${yellow}==> WARNING:${normal}${bold} About to install Dash-to-dock fix. Please make sure you have installed Dash-to-dock before pressing enter to continue.${normal}"
~/.config/gtk-themes/MacTahoe-gtk-theme/tweaks.sh -d
echo "${bold}${blue}    -> Installing${normal}${bold} gdm theme${normal}"
sudo ~/.config/gtk-themes/MacTahoe-gtk-theme/tweaks.sh -g -i apple -b ~/Pictures/Wallpapers/MountainLakeCenterSunset.jpg -nd -nb
echo "${bold}${blue}    -> Installing${normal}${bold} MacTahoe-icon-theme${normal}"
sudo ~/.config/gtk-themes/MacTahoe-icon-theme/install.sh -b

# Install gedit themes
echo "${bold}${green}==>${normal}${bold} Installing gedit theme${normal}"
curl https://raw.githubusercontent.com/kevin-nel/tokyo-night-gtksourceview/main/tokyo-night.xml  -o ~/.local/share/gtksourceview-5/styles/tokyo-night.xml

# Install gnome-terminal themes
echo "${bold}${green}==>${normal}${bold} Installing gnome-terminal theme${normal}"
curl https://raw.githubusercontent.com/cycion/dotdotfile/refs/heads/main/.config/dconf/gnomeProfiles.dconf -o /tmp/gnomeProfs.dconf
dconf load /org/gnome/terminal/legacy/profiles:/ < /tmp/gnomeProfs.dconf

echo "${bold}${blue}Installation completed, please reboot${normal}${bold}"
