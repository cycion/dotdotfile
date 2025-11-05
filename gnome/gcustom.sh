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
red=$(tput setaf 1)

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

# === Install paru (-p)
if pacman -Qs paru > /dev/null; then
  log info "Checking: paru is installed"
else
  log info "Checking: paru is NOT installed, building paru"
  rustup default stable
  mkdir /tmp/paru
  git clone https://aur.archlinux.org/paru.git /tmp/paru
  sed -i '23 i export RUSTFLAGS="-Ctarget-cpu=native -C opt-level=3 -Ctarget-feature=+avx2,+aes,+sse4.2,+bmi2,+fma,+lzcnt,+popcnt"' "/tmp/paru/PKGBUILD"
  makepkg -D /tmp/paru -si
  log info "paru is now installed"
fi
  
# === Install librewolf === (-l)
if pacman -Qs librewolf > /dev/null; then
  log info "Checking: librewolf is installed"
else
  log info "Checking: librewolf is NOT installed"
  curl -fsSL "https://drive.usercontent.google.com/download?id=1CpQui555KoKgB2ZbvUJx8zQyp-qsWTPv&export=download" -o /tmp/librewolf-1:144.0.2_1-1-x86_64.pkg.tar.zst
  sudo pacman -U /tmp/librewolf-1:144.0.2_1-1-x86_64.pkg.tar.zst --noconfirm
  log info "librewolf is now installed"
  read -n 1 -s -r -p "$(log warn 'You should install some additional GNOME extensions')"
fi
  
# === Modifying /etc/nanorc === (-n)
if grep -Fxq "include /usr/share/nano-syntax-highlighting/*.nanorc " "/etc/nanorc"; then
  log info "Checking: nano is already configured"
else
  log info "Checking: nano is NOT configured"
  
  sudo bash -c 'echo "## nano syntax definitions" >> /etc/nanorc'
  sudo bash -c 'echo "include /usr/share/nano/*.nanorc" >> /etc/nanorc'
  sudo bash -c 'echo "include /usr/share/nano/extra/*.nanorc" >> /etc/nanorc'
  sudo bash -c 'echo "include /usr/share/nano-syntax-highlighting/*.nanorc" >> /etc/nanorc'

fi
  
# === Install cachyos optimised repos === (-c)
echo "${bold}${green}==>${normal}${bold} Installing cachyos repos${normal}"
cd /tmp
curl https://mirror.cachyos.org/cachyos-repo.tar.xz -o /tmp/cachyos-repo.tar.xz
tar xvf cachyos-repo.tar.xz && cd cachyos-repo
sudo ./cachyos-repo.sh
sudo ~/.config/gtk-themes/MacTahoe-gtk-theme/tweaks.sh -g -i apple -b ~/Pictures/Wallpapers/MountainLakeCenterSunset.jpg -nd -nb

# === Install packages === (-u)
log info "Installing GNOME utilities"
sudo pacman -Sy --needed --noconfirm gnome-terminal gtksourceview5 gnome-browser-connector dconf-editor gnome-sound-recorder collision ghex file-roller gnome-firmware

log info "Removing GNOME bloatware"
sudo pacman -Rns --noconfirm malcontent gnome-user-docs yelp gnome-weather gnome-maps gnome-tour gnome-music gnome-contacts simple-scan 2>/dev/null || true

# === Download Wallpapers === (-w)
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

# === Install oh-my-zsh === (-z)
if [ -d "$HOME/.oh-my-zsh" ]; then
  log step "Skipped installing oh-my-zsh: already installed"
else
  log info "Installing oh-my-zsh"
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# oh-my-posh 
if [ -e "$HOME/.local/bin/oh-my-posh" ]; then
  log step "Skipped installing oh-my-posh: already installed"
else
  log info "Installing oh-my-posh"
  curl -s https://ohmyposh.dev/install.sh | bash -s
fi

# config files
log info "Loading configs"
log step "Loading oh-my-posh configs"
curl -fsSL https://raw.githubusercontent.com/cycion/dotdotfile/refs/heads/main/.config/oh-my-posh/dots.toml -o ~/.config/oh-my-posh/dots.toml
log step "Loading .zshrc"
curl -fsSL https://raw.githubusercontent.com/cycion/dotdotfile/refs/heads/main/.zshrc -o ~/.zshrc

# ZSH Plugins 
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

# === GNOME Settings Themes === (-gs)
log info "Enabling fractional scaling + xwayland native scaling"
gsettings set org.gnome.mutter experimental-features '["scale-monitor-framebuffer", "xwayland-native-scaling"]'
echo -e "[org.gnome.desktop.interface]\nscaling-factor=1" | sudo tee /usr/share/glib-2.0/schemas/99_hidpi.gschema.override >/dev/null
sudo glib-compile-schemas /usr/share/glib-2.0/schemas

# === GTK Themes === (-gt)
log info "Downloading gtk themes"
log substep "Downloading MacTahoe-gtk-theme"
[ -d "$HOME/.config/gtk-themes/MacTahoe-gtk-theme" ] || git clone --depth=1 https://github.com/vinceliuice/MacTahoe-gtk-theme.git ~/.config/gtk-themes/MacTahoe-gtk-theme

log step "Installing MacTahoe-gtk-theme"
~/.config/gtk-themes/MacTahoe-gtk-theme/install.sh --libadwaita --shell -i apple -ns --round --darker

if ! gnome-extensions list | grep -q dash-to-dock; then
  log warn "Dash-to-dock not installed. Skipping dock tweaks."
else
  ~/.config/gtk-themes/MacTahoe-gtk-theme/tweaks.sh -d
fi
log step "Installing gdm theme"
sudo ~/.config/gtk-themes/MacTahoe-gtk-theme/tweaks.sh -g -i apple -b ~/Pictures/Wallpapers/MountainLakeCenterSunset.jpg -nd -nb

# === Icon themes (-gi)
log substep "Downloading MacTahoe-icon-theme"
[ -d "$HOME/.config/gtk-themes/MacTahoe-icon-theme" ] || git clone --depth=1 https://github.com/vinceliuice/MacTahoe-icon-theme.git ~/.config/gtk-themes/MacTahoe-icon-theme
log step "Installing MacTahoe-icon-theme"
sudo ~/.config/gtk-themes/MacTahoe-icon-theme/install.sh -b

# === Blur-my-shell themes (-gb)
log info "Installing Blur-my-shell theme"
curl -fsSL https://raw.githubusercontent.com/cycion/dotdotfile/refs/heads/main/.config/blur-my-shell/org.gnome.shell.extensions.blur-my-shell.gschema.xml -o $HOME/.local/share/gnome-shell/extensions/blur-my-shell@aunetx/schemas/org.gnome.shell.extensions.blur-my-shell.gschema.xml

# === Gedit Themes === (-e)
log info "Installing gedit theme"
curl -fsSL https://raw.githubusercontent.com/kevin-nel/tokyo-night-gtksourceview/main/tokyo-night.xml -o ~/.local/share/gtksourceview-5/styles/tokyo-night.xml

# === GNOME Terminal Themes === (-t)
log info "Installing gnome-terminal theme"
curl -fsSL https://raw.githubusercontent.com/cycion/dotdotfile/refs/heads/main/.config/dconf/gnomeProfiles.dconf -o /tmp/gnomeProfs.dconf
dconf load /org/gnome/terminal/legacy/profiles:/ < /tmp/gnomeProfs.dconf

# === Cursor Themes === (-gc)
log info "Installing Bibata cursor theme"
curl -fsSL https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata.tar.xz -o /tmp/Bibata.tar.xz
tar -xvf /tmp/Bibata.tar.xz
mv Bibata-* ~/.local/share/icons/

# === LibreWolf Theme === (-lt
log info "Installing librewolf theme"
LIBREPATH=$(find ~/.librewolf -maxdepth 1 -type d -name "*default-release" | head -n 1)
mkdir -p $LIBREPATH/chrome
cp ~/.config/gtk-themes/MacTahoe-gtk-theme/other/firefox/* $LIBREPATH/chrome -r

mv $LIBREPATH/chrome/userChrome.css $LIBREPATH/chrome/userChrome-lighter.css
mv $LIBREPATH/chrome/userChrome-darker.css $LIBREPATH/chrome/userChrome.css
mv $LIBREPATH/chrome/userContent.css $LIBREPATH/chrome/userContent-lighter.css
mv $LIBREPATH/chrome/userContent-darker.css $LIBREPATH/chrome/userContent.css

echo "Rememeber to enable toolkit.legacyUserProfileCustomizations.stylesheets and svg.context-properties.content.enabled"
log info "Installation completed, please reboot"
