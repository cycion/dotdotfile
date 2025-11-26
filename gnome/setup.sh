#!/bin/bash
set -euo pipefail

# === Colors ===
bold=$(tput bold)
normal=$(tput sgr0)
blue=$(tput setaf 4)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
white=$(tput setaf 7)
red=$(tput setaf 1)

# === Temporary directory creation ===
TEMP=$(mktemp -d)

cleanup() {
    rm -rf "$TEMP"
}

trap cleanup EXIT

# === Logging styles ===
log() {
    local type="$1"
    local msg="$2"

    case $type in 
        info)     echo "${bold}${green}==>${normal}${bold} $msg${normal}" ;;
        inst)     echo "${bold}${blue}    ->${normal}${bold} $msg${normal}" ;;
        dl)  echo "${bold}${blue}    ~>${normal}${bold} $msg${normal}" ;;
        warn)     echo "${bold}${yellow}==> WARNING:${normal}${bold} $msg${normal}" ;;
        error)    echo "${bold}${red}==> ERROR:${normal}${bold} $msg${normal}" ;;
        *)        echo "${bold}${white}$msg${normal}" ;;
    esac
}

# === Download with retries ===
dltry() {
    set +u
    local cmd="$1"
    local alcmd="$2"
    set -u

    while true; do
        set +e
        bash -c "$cmd"
        local status=$?
        set -e

        if [ $status -eq 0 ]; then
            return 0
        fi

        while true; do
            if [[ -z "$alcmd" ]]; then
                read -p "$(log error "Failed to execute '$cmd', retry? (y/n) ")" opt
                case "$opt" in
                    [yY]* ) break ;;
                    [nN]* ) return $status ;;
                    *) ;;
                esac
            else
                read -p "$(log error "Failed to execute '$cmd', retry or execute '$alcmd'? (y/n/e) ")" opt
                case $opt in
                    [yY]* ) break ;;
                    [nN]* ) return $status ;;
                    [eE]* ) if dltry "$alcmd"; then
                                return 0
                            else
                                return $?
                            fi;;
                    *) ;;
                esac
            fi
        done
    done
}

# === Directory creations ===
mkdir -p ~/.config/gtk-themes ~/.config/oh-my-posh ~/Pictures/Wallpapers ~/.local/share/gtksourceview-5/styles ~/.local/share/icons

# === Setup task ===

# modifying the build args
build_mod () {
    if grep -Fxq 'export CFLAGS="-march=native -O3"' "$HOME/.makepkg.conf"; then
        log info "makepkg.conf is already configured"
    else
cat >> "$HOME/.makepkg.conf" <<'EOF'
export CFLAGS="-march=native -O3"
export CXXFLAGS="-march=native -O3"
export RUSTFLAGS="-Ctarget-cpu=native -C opt-level=3 -Ctarget-feature=+avx2,+aes,+sse4.2,+bmi,+bmi2,+fma,+lzcnt,+popcnt"
EOF

        log info "Successfully configured makepkg.conf"
    fi
}

# configuring nano
nano_config() {
    if grep -Fxq "include /usr/share/nano-syntax-highlighting/*.nanorc" "/etc/nanorc"; then
        log info "Checking: nano is already configured"
    else
        sudo tee -a /etc/nanorc >/dev/null <<'EOF'
## == Syntax highlighting ==
include /usr/share/nano/*.nanorc
include /usr/share/nano/extra/*.nanorc
include /usr/share/nano-syntax-highlighting/*.nanorc
EOF
        log info "Successfully configured nano"
    fi
}

# installing paru
paru_install() {
    if pacman -Qs paru > /dev/null; then
        log info "Checking: paru is installed"
    else
        rustup default stable
        dltry "git clone https://aur.archlinux.org/paru.git $TEMP/paru" "git clone --branch paru --single-branch https://github.com/archlinux/aur.git paru $TEMP/paru"
        makepkg -D $TEMP/paru -si --noconfirm
        log info "paru is now installed"
    fi
}

# installing cachyos repo
cachyos_install() {
    echo "${bold}${green}==>${normal}${bold} Installing cachyos repos${normal}"
    dltry "curl https://mirror.cachyos.org/cachyos-repo.tar.xz -o $TEMP/cachyos-repo.tar.xz"
    tar xvf $TEMP/cachyos-repo.tar.xz -C $TEMP
    sudo $TEMP/cachyos-repo.sh
}

# install/uninstall packages
utils_install() {
    log info "Installing GNOME utilities"
    dltry "sudo pacman -Sy --needed --noconfirm gnome-terminal gtksourceview5 gnome-browser-connector dconf-editor gnome-sound-recorder collision ghex file-roller gnome-firmware"

    log info "Removing GNOME bloatware"
    sudo pacman -Rns --noconfirm malcontent gnome-user-docs yelp gnome-weather gnome-maps gnome-tour gnome-music gnome-contacts simple-scan 2>/dev/null || true

    log info "Installing useful programs"
    dltry "paru -Sy --needed code code-marketplace ibus-rime go fwupd apple-fonts yazi --noconfirm"
    dltry "git clone https://github.com/LotusInputEngine/ibus-lotus.git $TEMP/ibus-lotus"
    sudo make -C $TEMP/ibus-lotus install 
    ibus restart
}

# installing librewolf
librewolf_install() {
    if pacman -Qs librewolf > /dev/null; then
        log info "Checking: librewolf is installed"
    else
        dltry "curl -fsSL 'https://drive.usercontent.google.com/download?id=1CpQui555KoKgB2ZbvUJx8zQyp-qsWTPv&export=download' -o $TEMP/librewolf-1:144.0.2_1-1-x86_64.pkg.tar.zst"
        sudo pacman -U $TEMP/librewolf-1:144.0.2_1-1-x86_64.pkg.tar.zst --noconfirm
        log info "Successfully installed Librewolf"
        log warn "You should install some additional GNOME extensions"
        read -n 1 -s -r -p "Press any key to continue..."
    fi
}


# downloading wallpapers
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
        log dl "Downloading $wallpaper"
        dltry "curl -sSL ${base_url}/${wallpaper} -o $HOME/Pictures/Wallpapers/${wallpaper}"
    done
}

# installing zsh
zsh_install() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        log step "Skipped installing oh-my-zsh: already installed"
    else
        log info "Installing oh-my-zsh"
        dltry 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
    fi

    if [ -e "$HOME/.local/bin/oh-my-posh" ]; then
        log step "Skipped installing oh-my-posh: already installed"
    else
        log info "Installing oh-my-posh"
        dltry "curl -s https://ohmyposh.dev/install.sh | bash -s"
    fi

    log info "Loading configs"
    log inst "Loading oh-my-posh configs"
    dltry "curl -fsSL https://raw.githubusercontent.com/cycion/dotdotfile/refs/heads/main/.config/oh-my-posh/dots.toml -o $HOME/.config/oh-my-posh/dots.toml"
    log inst "Loading .zshrc"
    dltry "curl -fsSL https://raw.githubusercontent.com/cycion/dotdotfile/refs/heads/main/.zshrc -o $HOME/.zshrc"

    log info "Installing zsh plugins"
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
        log inst "Installing zsh-syntax-highlighting"
        dltry "git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
    else
        log step "Skipped installing zsh-syntax-highlighting: already installed"
    fi

    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
        log inst "Installing zsh-autosuggestions"
        dltry "git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
    else
        log step "Skipped installing zsh-autosuggestions: already installed"
    fi
}

# Configuring HiDPI
scale_enable() {
    log info "Enabling fractional scaling + xwayland native scaling"
    gsettings set org.gnome.mutter experimental-features '["scale-monitor-framebuffer", "xwayland-native-scaling"]'
    echo -e "[org.gnome.desktop.interface]\nscaling-factor=1" | sudo tee /usr/share/glib-2.0/schemas/99_hidpi.gschema.override >/dev/null
    sudo glib-compile-schemas /usr/share/glib-2.0/schemas
}

# Installing MacTahoe GTK theme
gtk_theme_install() {
    log dl "Downloading MacTahoe-gtk-theme"
    [ -d "$HOME/.config/gtk-themes/MacTahoe-gtk-theme" ] || dltry "git clone --depth=1 https://github.com/vinceliuice/MacTahoe-gtk-theme.git ~/.config/gtk-themes/MacTahoe-gtk-theme"

    log inst "Installing MacTahoe-gtk-theme"
    ~/.config/gtk-themes/MacTahoe-gtk-theme/install.sh --libadwaita --shell -i apple -ns --round --darker

    if ! gnome-extensions list | grep -q dash-to-dock; then
        log warn "Dash-to-dock not installed. Skipping dock fix."
    else
        ~/.config/gtk-themes/MacTahoe-gtk-theme/tweaks.sh -d
    fi

    log step "Installing gdm theme"
    sudo ~/.config/gtk-themes/MacTahoe-gtk-theme/tweaks.sh -g -i apple -b ~/Pictures/Wallpapers/MountainLakeCenterSunset.jpg -nd -nb
}

# Installing MacTahoe icon theme
icons_install() {
    log dl "Downloading MacTahoe-icon-theme"
    [ -d "$HOME/.config/gtk-themes/MacTahoe-icon-theme" ] || dltry "git clone --depth=1 https://github.com/vinceliuice/MacTahoe-icon-theme.git ~/.config/gtk-themes/MacTahoe-icon-theme"
    log inst "Installing MacTahoe-icon-theme"
    sudo ~/.config/gtk-themes/MacTahoe-icon-theme/install.sh -b
}

# Installing gtksourceview theme
gtksrc_theme() {
    log info "Installing gtk-source-view theme"
    dltry "curl -fsSL https://raw.githubusercontent.com/cycion/dotdotfile/refs/heads/main/gnome/tokyonight-dark.xml -o ~/.local/share/gtksourceview-5/styles/tokyonight-dark.xml"
}

# Installing terminal themes
terminal_theme() {
    log info "Installing gnome-terminal theme"
    dltry "curl -fsSL https://raw.githubusercontent.com/cycion/dotdotfile/refs/heads/main/.config/dconf/gnomeProfiles.dconf -o $TEMP/gnomeProfs.dconf"
    dconf load /org/gnome/terminal/legacy/profiles:/ < $TEMP/gnomeProfs.dconf
}

# Installing cursor themes
cursor_install() {
    log info "Installing Bibata cursor theme"
    dltry "curl -fsSL https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Classic.tar.xz -o $TEMP/Bibata-Modern-Classic.tar.xz"
    dltry "curl -fsSL https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Ice.tar.xz -o $TEMP/Bibata-Modern-Ice.tar.xz"

    7z x $TEMP/Bibata-Modern-Classic.tar.xz -o$TEMP
    7z x $TEMP/Bibata-Modern-Ice.tar.xz -o$TEMP

    7z x $TEMP/Bibata-Modern-Classic.tar -o$TEMP
    7z x $TEMP/Bibata-Modern-Ice.tar -o$TEMP

    mv $TEMP/Bibata-Modern-Classic ~/.local/share/icons/
    mv $TEMP/Bibata-Modern-Ice ~/.local/share/icons/
}

# Installing librewolf themes
librewolf_theme() {
    [[ -d "$HOME/.config/gtk-themes/MacTahoe-gtk-theme" ]] && gtk_theme_install
    log info "Installing librewolf theme"
    read -n 1 -s -r -p "Make sure you have created a firefox profile"
    LIBREPATH=$(find ~/.librewolf -maxdepth 1 -type d -name "*default-release" | head -n 1)
    mkdir -p $LIBREPATH/chrome
    cp ~/.config/gtk-themes/MacTahoe-gtk-theme/other/firefox/* $LIBREPATH/chrome -r

    mv $LIBREPATH/chrome/userChrome.css $LIBREPATH/chrome/userChrome-lighter.css
    mv $LIBREPATH/chrome/userChrome-darker.css $LIBREPATH/chrome/userChrome.css
    mv $LIBREPATH/chrome/userContent.css $LIBREPATH/chrome/userContent-lighter.css
    mv $LIBREPATH/chrome/userContent-darker.css $LIBREPATH/chrome/userContent.css

    echo "Remember to enable toolkit.legacyUserProfileCustomizations.stylesheets and svg.context-properties.content.enabled"
}

yazi_theme() {
    if grep -Fxq 'dark = "dracula"' "$HOME/.config/yazi/theme.toml"; then
        log info "Checking: yazi is already configured"
    else
        log info "Installing yazi theme"
        ya pkg add yazi-rs/flavors:dracula
        cat >> "$HOME/.config/yazi/theme.toml" <<'EOF'
[flavor]
dark = "dracula"
EOF
    fi
}

# Applying ntfs mounting fix
ntfs3_fix() {
    if grep -Fxq "blacklist ntfs3" "/etc/modprobe.d/FIX-ntfs_mount.conf" > /dev/null; then
        log info "Checking: ntfs mounting is already fixed"
    else
        log info "Fixing NTFS drive mount issue"
        echo 'blacklist ntfs3' | sudo tee /etc/modprobe.d/FIX-ntfs_mount.conf
    fi
}

# Do not display certain things
desktop_file() {
    apps=(
        avahi-discover
        bssh
        bvnc
        org.gnome.Evince
        qv4l2
        qvidcap
        htop
        vim
        nm-connection-editor
        yazi
    )

    # Ensure local applications directory exists
    mkdir -p "$HOME/.local/share/applications"

    # Loop through each app
    for app in "${apps[@]}"; do
        src="/usr/share/applications/${app}.desktop"
        dest="$HOME/.local/share/applications/${app}.desktop"

        # Copy if it doesn't exist
        if [ ! -e "$dest" ]; then
            cp "$src" "$dest"
        fi

        # Check if NoDisplay=true already exists
        if grep -Fxq "NoDisplay=true" "$dest"; then
            echo "${app}.desktop is already configured"
        else
            sed -i '3 i NoDisplay=true' "$dest"
            echo "    -> Processed ${app}.desktop"
        fi
    done
}

# === Help Menu ===
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
  -e,  --gtksourceview      Install gtksourceview theme
  -t,  --terminal-theme     Install GNOME Terminal theme
  -gc, --cursor             Install Bibata cursor theme
  -lt, --librewolf-theme    Install LibreWolf theme
  -yz, --yazi               Install yazi dracula theme
  -fs, --ntfs               Fixing ntfs3 mounting
  -d,  --desktop            Modifying desktop entries

  -a,  --all                Run all modules
  -h,  --help               Show help

Examples:
  ./$(basename "$0") -n -w
  ./$(basename "$0") --nano --wallpapers --zsh
EOF
}

# === Argument Parser ===
# Flags
RUN_NANO=0
RUN_PARU=0
RUN_CACHYOS=0
RUN_UTILS=0
RUN_LIBREWOLF=0
RUN_WALLPAPERS=0
RUN_ZSH=0
RUN_GNOME_SCALE=0
RUN_GTK_THEME=0
RUN_ICONS=0
RUN_GTKSRC=0
RUN_TERMINAL=0
RUN_CURSOR=0
RUN_LIBREWOLF_THEME=0
RUN_YAZI=0
RUN_NTFS=0
RUN_DESKTOP=0

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
    -e|--gtksourceview) RUN_GTKSRC=1 ;;
    -t|--terminal-theme) RUN_TERMINAL=1 ;;
    -gc|--cursor) RUN_CURSOR=1 ;;
    -lt|--librewolf-theme) RUN_LIBREWOLF_THEME=1 ;;
    -yz|--yazi) RUN_YAZI=1 ;;
    -fs|--ntfs) RUN_NTFS=1 ;;
    -d|--desktop) RUN_DESKTOP=1 ;;
    -a|--all) RUN_PARU=1;RUN_LIBREWOLF=1;RUN_NANO=1;RUN_CACHYOS=1;RUN_UTILS=1;RUN_WALLPAPERS=1;RUN_ZSH=1;RUN_GNOME_SCALE=1;RUN_GTK_THEME=1;RUN_ICONS=1;RUN_GTKSRC=1;RUN_TERMINAL=1;RUN_CURSOR=1;RUN_LIBREWOLF_THEME=1;RUN_YAZI=1;RUN_NTFS=1;RUN_DESKTOP=1 ;;
    -h|--help) show_help; exit 0 ;;
    *) echo "Unknown option: $arg"; exit 1 ;;
  esac
done

# === Execution ===
build_mod
[[ $RUN_NANO == 1 ]] && nano_config
[[ $RUN_PARU == 1 ]] && paru_install
[[ $RUN_CACHYOS == 1 ]] && cachyos_install
[[ $RUN_UTILS == 1 ]] && utils_install
[[ $RUN_LIBREWOLF == 1 ]] && librewolf_install
[[ $RUN_WALLPAPERS == 1 ]] && wallpapers_install
[[ $RUN_ZSH == 1 ]] && zsh_install
[[ $RUN_GNOME_SCALE == 1 ]] && scale_enable
[[ $RUN_GTK_THEME == 1 ]] && gtk_theme_install
[[ $RUN_ICONS == 1 ]] && icons_install
[[ $RUN_GTKSRC == 1 ]] && gtksrc_theme
[[ $RUN_TERMINAL == 1 ]] && terminal_theme
[[ $RUN_CURSOR == 1 ]] && cursor_install
[[ $RUN_LIBREWOLF_THEME == 1 ]] && librewolf_theme
[[ $RUN_YAZI == 1 ]] && yazi_theme
[[ $RUN_NTFS == 1 ]] && ntfs3_fix
[[ $RUN_DESKTOP == 1 ]] && desktop_file
