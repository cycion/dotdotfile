#!/bin/bash
set -eo pipefail
## Sysconfig script

# Some font thingy
bold=$(tput bold)
normal=$(tput sgr0)
blue=$(tput setaf 4)
green=$(tput setaf 2)
white=$(tput setaf 7)
red=$(tput setaf 1)

# Check if paru is installed
command -v paru &> /dev/null
[ $? -eq 0 ] && echo "${bold}${green}==>${normal}${bold} Checking: paru is installed${normal}" || (echo "${bold}${red}==> ERROR:${normal}${bold} paru is NOT installed${normal}" && exit 127)

# Install code, code-marketplace
echo "${bold}${green}==>${normal}${bold} Installing code, code marketplace, ibus-rime, ibus-lotus, fwupd, apple-fonts${normal}"
paru -Sy --needed code code-marketplace ibus-rime go fwupd apple-fonts --noconfirm
cd /tmp
git clone https://github.com/LotusInputEngine/ibus-lotus.git && cd ibus-lotus
sudo make install
ibus restart

# Install cachyos optimised repos
echo "${bold}${green}==>${normal}${bold} Installing cachyos repos${normal}"
cd /tmp
curl https://mirror.cachyos.org/cachyos-repo.tar.xz -o /tmp/cachyos-repo.tar.xz
tar xvf cachyos-repo.tar.xz && cd cachyos-repo
sudo ./cachyos-repo.sh

# Fix for mounting NTFS drives
echo "${bold}${green}==>${normal}${bold} Fixing NTFS drives mounting issue${normal}"
echo 'blacklist ntfs3' | sudo tee /etc/modprobe.d/FIX-ntfs-3g_mount.conf

# Editing desktop files
echo "${bold}${green}==>${normal}${bold} Configuring desktop files${normal}"
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
