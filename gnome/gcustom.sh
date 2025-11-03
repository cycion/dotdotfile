#!/bin/bash
set -eo pipefail
## GNOME customisation script
## Install librewolf (1.143.0-3) through https://bit.ly/librewolf

# Colors
bold=$(tput bold)
normal=$(tput sgr0)
blue=$(tput setaf 4)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
white=$(tput setaf 7)

# === Logging Helper Function ===
log() {
  local type="$1"; shift
  local msg="$*"

  case "$type" in
    info)     echo "${bold}${green}==>${normal}${bold} $msg${normal}" ;;
    step)     echo "${bold}${blue}    ->${normal}${bold} $msg${normal}" ;;
    substep)  echo "${bold}${blue}    ~>${normal}${bold} $msg${normal}" ;;
    warn)     echo "${bold}${yellow}==> WARNING:${normal}${bold} $msg${normal}" ;;
    error)    echo "${bold}${red}==> ERROR:${normal}${bold} $msg${normal}" ;;
    *)        echo "${bold}${white}$msg${normal}" ;;
  esac
}

# === Setup Directories ===
mkdir -p ~/.config/gtk-themes ~/.config/oh-my-posh ~/Pictures/Wallpapers ~/.local/share/gtksourceview-5/styles

# === Install Packages ===
log info "Installing GNOME utilities"
sudo pacman -Sy --needed --noconfirm gnome-terminal gtksourceview5 gnome-browser-connector dconf-editor gnome-sound-recorder collision ghex

log info "Removing GNOME bloatware"
sudo pacman -Rns --noconfirm malcontent gnome-user-docs yelp gnome-weather gnome-maps gnome-tour gnome-music gnome-contacts simple-scan 2>/dev/null || true

# === Download Wallpapers ===
log info "Downloading wallpapers"

wallpapers=(
  MountainLakeCenterSunset.jpg
  SunsetMountainRight.jpg
  SnowMountain.jpg
  CloudySnowMountain.jpg
)
base_url="https://raw.githubusercontent.com/cycion/dotdotfile/refs/heads/main/.config/wallpapers"

for wallpaper in "${wallpapers[@]}"; do
  log substep "Downloading $wallpaper"
  curl -sSL "${base_url}/${wallpaper}" -o "$HOME/Pictures/Wallpapers/${wallpaper}"
done

# === Install oh-my-zsh ===
if [ -d "$HOME/.oh-my-zsh" ]; then
  log step "Skipped installing oh-my-zsh: already installed"
else
  log info "Installing oh-my-zsh"
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# === Install oh-my-posh ===
if [ -e "$HOME/.local/bin/oh-my-posh" ]; then
  log step "Skipped installing oh-my-posh: already installed"
else
  log info "Installing oh-my-posh"
  curl -s https://ohmyposh.dev/install.sh | bash -s
fi

# === Config Files ===
log info "Loading configs"
log step "Loading oh-my-posh configs"
curl -fsSL https://raw.githubusercontent.com/cycion/dotdotfile/refs/heads/main/.config/oh-my-posh/dots.toml -o ~/.config/oh-my-posh/dots.toml
log step "Loading .zshrc"
curl -fsSL https://raw.githubusercontent.com/cycion/dotdotfile/refs/heads/main/.zshrc -o ~/.zshrc

# === ZSH Plugins ===
log info "Installing zsh plugins"
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
  log step "Installing zsh-syntax-highlighting"
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
else
  log step "Skipped installing zsh-syntax-highlighting: already installed"
fi

if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
  log step "Installing zsh-autosuggestions"
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
else
  log step "Skipped installing zsh-autosuggestions: already installed"
fi

# === GTK Themes ===
log info "Enabling fractional scaling + xwayland native scaling"
gsettings set org.gnome.mutter experimental-features '["scale-monitor-framebuffer", "xwayland-native-scaling"]'
echo -e "[org.gnome.desktop.interface]\nscaling-factor=1" | sudo tee /usr/share/glib-2.0/schemas/99_hidpi.gschema.override >/dev/null
sudo glib-compile-schemas /usr/share/glib-2.0/schemas

log info "Downloading gtk themes"
log substep "Downloading MacTahoe-gtk-theme"
[ -d "$HOME/.config/gtk-themes/MacTahoe-gtk-theme" ] || git clone --depth=1 https://github.com/vinceliuice/MacTahoe-gtk-theme.git ~/.config/gtk-themes/MacTahoe-gtk-theme

log substep "Downloading MacTahoe-icon-theme"
[ -d "$HOME/.config/gtk-themes/MacTahoe-icon-theme" ] || git clone --depth=1 https://github.com/vinceliuice/MacTahoe-icon-theme.git ~/.config/gtk-themes/MacTahoe-icon-theme

log info "Installing gtk themes"
log step "Installing MacTahoe-gtk-theme"
~/.config/gtk-themes/MacTahoe-gtk-theme/install.sh --libadwaita --shell -i apple -ns --round --darker
read -n 1 -s -r -p "$(log warn 'About to install Dash-to-dock fix. Please make sure you have installed Dash-to-dock before pressing enter to continue.')"
~/.config/gtk-themes/MacTahoe-gtk-theme/tweaks.sh -d
log step "Installing gdm theme"
sudo ~/.config/gtk-themes/MacTahoe-gtk-theme/tweaks.sh -g -i apple -b ~/Pictures/Wallpapers/MountainLakeCenterSunset.jpg -nd -nb
log step "Installing MacTahoe-icon-theme"
sudo ~/.config/gtk-themes/MacTahoe-icon-theme/install.sh -b

# === Gedit Themes ===
log info "Installing gedit theme"
curl -fsSL https://raw.githubusercontent.com/kevin-nel/tokyo-night-gtksourceview/main/tokyo-night.xml -o ~/.local/share/gtksourceview-5/styles/tokyo-night.xml

# === GNOME Terminal Themes ===
log info "Installing gnome-terminal theme"
curl -fsSL https://raw.githubusercontent.com/cycion/dotdotfile/refs/heads/main/.config/dconf/gnomeProfiles.dconf -o /tmp/gnomeProfs.dconf
dconf load /org/gnome/terminal/legacy/profiles:/ < /tmp/gnomeProfs.dconf

# === LibreWolf Theme ===
log info "Installing librewolf theme"
mkdir -p ~/.librewolf/*.default-release/chrome
cp ~/.config/gtk-themes/MacTahoe-gtk-theme/other/firefox/* ~/.librewolf/*.default-release/chrome

mv ~/.librewolf/*.default-release/chrome/userChrome.css ~/.librewolf/*.default-release/chrome/userChrome-lighter.css
mv ~/.librewolf/*.default-release/chrome/userChrome-darker.css ~/.librewolf/*.default-release/chrome/userChrome.css
mv ~/.librewolf/*.default-release/chrome/userContent.css ~/.librewolf/*.default-release/chrome/userContent-lighter.css
mv ~/.librewolf/*.default-release/chrome/userContent-darker.css ~/.librewolf/*.default-release/chrome/userContent.css

log info "Installation completed, please reboot"
