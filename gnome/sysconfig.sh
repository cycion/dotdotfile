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
echo "${bold}${green}==>${normal}${bold} Installing code, code marketplace, ibus-rime, ibus-lotus${normal}"
paru -Sy --needed code code-marketplace ibus-rime go --noconfirm
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
echo 'blacklist ntfs3' | sudo tee /etc/modprobe.d/ntfs-3g_mount_fix.conf

# Editing desktop files
echo "${bold}${green}==>${normal}${bold} Configuring desktop files${normal}"
[ ! -e "$HOME/.local/share/applications/avahi-discover.desktop" ] && cp /usr/share/applications/avahi-discover.desktop ~/.local/share/applications/avahi-discover.desktop
[ ! -e "$HOME/.local/share/applications/bssh.desktop" ] && cp /usr/share/applications/bssh.desktop ~/.local/share/applications/bssh.desktop
[ ! -e "$HOME/.local/share/applications/bvnc.desktop" ] && cp /usr/share/applications/bvnc.desktop ~/.local/share/applications/bvnc.desktop
[ ! -e "$HOME/.local/share/applications/org.gnome.Evince.desktop" ] && cp /usr/share/applications/org.gnome.Evince.desktop ~/.local/share/applications/org.gnome.Evince.desktop
[ ! -e "$HOME/.local/share/applications/qv4l2.desktop" ] && cp /usr/share/applications/qv4l2.desktop ~/.local/share/applications/qv4l2.desktop
[ ! -e "$HOME/.local/share/applications/qvidcap.desktop" ] && cp /usr/share/applications/qvidcap.desktop ~/.local/share/applications/qvidcap.desktop
[ ! -e "$HOME/.local/share/applications/htop.desktop" ] && cp /usr/share/applications/htop.desktop ~/.local/share/applications/htop.desktop
[ ! -e "$HOME/.local/share/applications/vim.desktop" ] && cp /usr/share/applications/vim.desktop ~/.local/share/applications/vim.desktop

[ $(grep -Fxq "NoDisplay=true" ~/.local/share/applications/avahi-discover.desktop; echo $?) == "0" ] && echo "avahi-discover.desktop is already configured" || (echo "NoDisplay=true" >> ~/.local/share/applications/avahi-discover.desktop && echo "    -> Processed avahi-discover.desktop")
[ $(grep -Fxq "NoDisplay=true" ~/.local/share/applications/bssh.desktop; echo $?) == "0" ] && echo "bssh.desktop is already configured" || (echo "NoDisplay=true" >> ~/.local/share/applications/bssh.desktop && echo "    -> Processed bssh.desktop")
[ $(grep -Fxq "NoDisplay=true" ~/.local/share/applications/bvnc.desktop; echo $?) == "0" ] && echo "bvnc.desktop is already configured" || (echo "NoDisplay=true" >> ~/.local/share/applications/bvnc.desktop && echo "    -> Processed bvnc.desktop")
[ $(grep -Fxq "NoDisplay=true" ~/.local/share/applications/org.gnome.Evince.desktop; echo $?) == "0" ] && echo "org.gnome.Evince.desktop is already configured" || (sed -i '241 i NoDisplay=true' ~/.local/share/applications/org.gnome.Evince.desktop && echo "    -> Processed org.gnome.Evince.desktop")
[ $(grep -Fxq "NoDisplay=true" ~/.local/share/applications/qv4l2.desktop; echo $?) == "0" ] && echo "qv4l2.desktop is already configured" || (echo "NoDisplay=true" >> ~/.local/share/applications/qv4l2.desktop && echo "    -> Processed qv4l2.desktop")
[ $(grep -Fxq "NoDisplay=true" ~/.local/share/applications/qvidcap.desktop; echo $?) == "0" ] && echo "qvidcap.desktop is already configured" || (echo "NoDisplay=true" >> ~/.local/share/applications/qvidcap.desktop && echo "    -> Processed qvidcap.desktop")
[ $(grep -Fxq "NoDisplay=true" ~/.local/share/applications/htop.desktop; echo $?) == "0" ] && echo "htop.desktop is already configured" || (echo "NoDisplay=true" >> ~/.local/share/applications/htop.desktop && echo "    -> Processed htop.desktop")
[ $(grep -Fxq "NoDisplay=true" ~/.local/share/applications/vim.desktop; echo $?) == "0" ] && echo "vim.desktop is already configured" || (echo "NoDisplay=true" >> ~/.local/share/applications/vim.desktop && echo "    -> Processed vim.desktop")
