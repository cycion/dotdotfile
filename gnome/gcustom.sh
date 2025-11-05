#!/bin/bash
set -eo pipefail

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

# -------------------------------------------------------------------
# HELP MENU
# -------------------------------------------------------------------
show_help() {
cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Arch GNOME customization script

OPTIONS:
  -p,  --paru               Install paru
  -l,  --librewolf          Install LibreWolf
  -n,  --nano               Configure nano
  -c,  --cachyos            Enable CachyOS repos
  -u,  --utils              Install GNOME utilities & remove bloat
  -w,  --wallpapers         Download wallpapers
  -z,  --zsh                Install zsh + oh-my-zsh + oh-my-posh
  -gs, --gnome-scale        Enable fractional scaling tweaks
  -gt, --gtk-theme          Install GTK theme
  -gi, --icons              Install icon theme
  -gb, --blur-shell         Install Blur-my-shell gschema
  -e,  --gedit-theme        Install gedit syntax theme
  -t,  --terminal-theme     Install GNOME Terminal theme
  -gc, --cursor             Install Bibata cursor theme
  -lt, --librewolf-theme    Install LibreWolf theme

  -a,  --all                Run all modules
  -h,  --help               Show help

Examples:
  $(basename "$0") -nw
  $(basename "$0") --nano --wallpapers --zsh
EOF
}

# Flags
RUN_PARU=0
RUN_LIBREWOLF=0
RUN_NANO=0
RUN_CACHYOS=0
RUN_UTILS=0
RUN_WALLPAPERS=0
RUN_ZSH=0
RUN_GNOME_SCALE=0
RUN_GTK_THEME=0
RUN_ICONS=0
RUN_BLUR=0
RUN_GEDIT=0
RUN_TERMINAL=0
RUN_CURSOR=0
RUN_LIBREWOLF_THEME=0

if [[ $# -eq 0 ]]; then
  show_help
  exit 0
fi

# Parse args
for arg in "$@"; do
  case "$arg" in
    -p|--paru) RUN_PARU=1 ;;
    -l|--librewolf) RUN_LIBREWOLF=1 ;;
    -n|--nano) RUN_NANO=1 ;;
    -c|--cachyos) RUN_CACHYOS=1 ;;
    -u|--utils) RUN_UTILS=1 ;;
    -w|--wallpapers) RUN_WALLPAPERS=1 ;;
    -z|--zsh) RUN_ZSH=1 ;;
    -gs|--gnome-scale) RUN_GNOME_SCALE=1 ;;
    -gt|--gtk-theme) RUN_GTK_THEME=1 ;;
    -gi|--icons) RUN_ICONS=1 ;;
    -gb|--blur-shell) RUN_BLUR=1 ;;
    -e|--gedit-theme) RUN_GEDIT=1 ;;
    -t|--terminal-theme) RUN_TERMINAL=1 ;;
    -gc|--cursor) RUN_CURSOR=1 ;;
    -lt|--librewolf-theme) RUN_LIBREWOLF_THEME=1 ;;
    -a|--all) RUN_PARU=1;RUN_LIBREWOLF=1;RUN_NANO=1;RUN_CACHYOS=1;RUN_UTILS=1;RUN_WALLPAPERS=1;RUN_ZSH=1;RUN_GNOME_SCALE=1;RUN_GTK_THEME=1;RUN_ICONS=1;RUN_BLUR=1;RUN_GEDIT=1;RUN_TERMINAL=1;RUN_CURSOR=1;RUN_LIBREWOLF_THEME=1 ;;
    -h|--help) show_help; exit 0 ;;
    *) echo "Unknown option: $arg"; exit 1 ;;
  esac
done

# Ensure base dirs (before functions)
mkdir -p ~/.config/gtk-themes ~/.config/oh-my-posh ~/Pictures/Wallpapers ~/.local/share/gtksourceview-5/styles

# -------------------------------------------------------------------
# MODULE FUNCTIONS
# -------------------------------------------------------------------

paru_install() {
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
}

librewolf_install() {
if pacman -Qs librewolf > /dev/null; then
  log info "Checking: librewolf is installed"
else
  log info "Checking: librewolf is NOT installed"
  curl -fsSL "https://drive.usercontent.google.com/download?id=1CpQui555KoKgB2ZbvUJx8zQyp-qsWTPv&export=download" -o /tmp/librewolf-1:144.0.2_1-1-x86_64.pkg.tar.zst
  sudo pacman -U /tmp/librewolf-1:144.0.2_1-1-x86_64.pkg.tar.zst --noconfirm
  log info "librewolf is now installed"
  read -n 1 -s -r -p "$(log warn 'You should install some additional GNOME extensions')"
fi
}

nano_config() {
if grep -Fxq "include /usr/share/nano-syntax-highlighting/*.nanorc " "/etc/nanorc"; then
  log info "Checking: nano is already configured"
else
  log info "Checking: nano is NOT configured"
  sudo bash -c 'echo "## nano syntax definitions" >> /etc/nanorc'
  sudo bash -c 'echo "include /usr/share/nano/*.nanorc" >> /etc/nanorc'
  sudo bash -c 'echo "include /usr/share/nano/extra/*.nanorc" >> /etc/nanorc'
  sudo bash -c 'echo "include /usr/share/nano-syntax-highlighting/*.nanorc" >> /etc/nanorc'
fi
}

cachyos_install() {
echo "${bold}${green}==>${normal}${bold} Installing cachyos repos${normal}"
cd /tmp
curl https://mirror.cachyos.org/cachyos-repo.tar.xz -o /tmp/cachyos-repo.tar.xz
tar xvf cachyos-repo.tar.xz && cd cachyos-repo
sudo ./cachyos-repo.sh
}

utils_install() {
log info "Installing GNOME utilities"
sudo pacman -Sy --needed --noconfirm gnome-terminal gtksourceview5 gnome-browser-connector dconf-editor gnome-sound-recorder collision ghex file-roller gnome-firmware

log info "Removing GNOME bloatware"
sudo pacman -Rns --noconfirm malcontent gnome-user-docs yelp gnome-weather gnome-maps gnome-tour gnome-music gnome-contacts simple-scan 2>/dev/null || true
}

wallpapers_install() {
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
}

zsh_install() {
if [ -d "$HOME/.oh-my-zsh" ]; then
  log step "Skipped installing oh-my-zsh: already installed"
else
  log info "Installing oh-my-zsh"
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

if [ -e "$HOME/.local/bin/oh-my-posh" ]; then
  log step "Skipped installing oh-my-posh: already installed"
else
  log info "Installing oh-my-posh"
  curl -s https://ohmyposh.dev/install.sh | bash -s
fi

log info "Loading configs"
log step "Loading oh-my-posh configs"
curl -fsSL https://raw.githubusercontent.com/cycion/dotdotfile/refs/heads/main/.config/oh-my-posh/dots.toml -o ~/.config/oh-my-posh/dots.toml
log step "Loading .zshrc"
curl -fsSL https://raw.githubusercontent.com/cycion/dotdotfile/refs/heads/main/.zshrc -o ~/.zshrc

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
}

scale_enable() {
log info "Enabling fractional scaling + xwayland native scaling"
gsettings set org.gnome.mutter experimental-features '["scale-monitor-framebuffer", "xwayland-native-scaling"]'
echo -e "[org.gnome.desktop.interface]\nscaling-factor=1" | sudo tee /usr/share/glib-2.0/schemas/99_hidpi.gschema.override >/dev/null
sudo glib-compile-schemas /usr/share/glib-2.0/schemas
}

gtk_theme_install() {
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
}

icons_install() {
log substep "Downloading MacTahoe-icon-theme"
[ -d "$HOME/.config/gtk-themes/MacTahoe-icon-theme" ] || git clone --depth=1 https://github.com/vinceliuice/MacTahoe-icon-theme.git ~/.config/gtk-themes/MacTahoe-icon-theme
log step "Installing MacTahoe-icon-theme"
sudo ~/.config/gtk-themes/MacTahoe-icon-theme/install.sh -b
}

blur_install() {
log info "Installing Blur-my-shell theme"
curl -fsSL https://raw.githubusercontent.com/cycion/dotdotfile/refs/heads/main/.config/blur-my-shell/org.gnome.shell.extensions.blur-my-shell.gschema.xml -o $HOME/.local/share/gnome-shell/extensions/blur-my-shell@aunetx/schemas/org.gnome.shell.extensions.blur-my-shell.gschema.xml
}

gedit_theme() {
log info "Installing gedit theme"
curl -fsSL https://raw.githubusercontent.com/kevin-nel/tokyo-night-gtksourceview/main/tokyo-night.xml -o ~/.local/share/gtksourceview-5/styles/tokyo-night.xml
}

terminal_theme() {
log info "Installing gnome-terminal theme"
curl -fsSL https://raw.githubusercontent.com/cycion/dotdotfile/refs/heads/main/.config/dconf/gnomeProfiles.dconf -o /tmp/gnomeProfs.dconf
dconf load /org/gnome/terminal/legacy/profiles:/ < /tmp/gnomeProfs.dconf
}

cursor_install() {
log info "Installing Bibata cursor theme"
curl -fsSL https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata.tar.xz -o /tmp/Bibata.tar.xz
cd /tmp
tar -xvf /tmp/Bibata.tar.xz
mv Bibata-* ~/.local/share/icons/
}

librewolf_theme() {
log info "Installing librewolf theme"
LIBREPATH=$(find ~/.librewolf -maxdepth 1 -type d -name "*default-release" | head -n 1)
mkdir -p $LIBREPATH/chrome
cp ~/.config/gtk-themes/MacTahoe-gtk-theme/other/firefox/* $LIBREPATH/chrome -r

mv $LIBREPATH/chrome/userChrome.css $LIBREPATH/chrome/userChrome-lighter.css
mv $LIBREPATH/chrome/userChrome-darker.css $LIBREPATH/chrome/userChrome.css
mv $LIBREPATH/chrome/userContent.css $LIBREPATH/chrome/userContent-lighter.css
mv $LIBREPATH/chrome/userContent-darker.css $LIBREPATH/chrome/userContent.css

echo "Remember to enable toolkit.legacyUserProfileCustomizations.stylesheets and svg.context-properties.content.enabled"
log info "Installation completed, please reboot"
}

# -------------------------------------------------------------------
# EXECUTION BASED ON FLAGS
# -------------------------------------------------------------------

[[ $RUN_PARU == 1 ]] && paru_install
[[ $RUN_LIBREWOLF == 1 ]] && librewolf_install
[[ $RUN_NANO == 1 ]] && nano_config
[[ $RUN_CACHYOS == 1 ]] && cachyos_install
[[ $RUN_UTILS == 1 ]] && utils_install
[[ $RUN_WALLPAPERS == 1 ]] && wallpapers_install
[[ $RUN_ZSH == 1 ]] && zsh_install
[[ $RUN_GNOME_SCALE == 1 ]] && scale_enable
[[ $RUN_GTK_THEME == 1 ]] && gtk_theme_install
[[ $RUN_ICONS == 1 ]] && icons_install
[[ $RUN_BLUR == 1 ]] && blur_install
[[ $RUN_GEDIT == 1 ]] && gedit_theme
[[ $RUN_TERMINAL == 1 ]] && terminal_theme
[[ $RUN_CURSOR == 1 ]] && cursor_install
[[ $RUN_LIBREWOLF_THEME == 1 ]] && librewolf_theme

echo -e "\n${bold}${green}Done.${normal}"
