#!/bin/bash

# +----------------------------------------------------------------------------+
# |         dt-setup.sh - A simple script to setup Debian environments         |
# |                                                                            |
# |  This script will setup basic packages common to web site and application  |
# |  development environments with either interactive prompts or an automatic  |
# |   execution to setup everything needed within a new Debian installation.   |
# |                                                                            |
# | The latest version and more information can be found within our repository |
# |   at github.com/galiemedia/debian-tools or on our site at galiemedia.com   |
# +----------------------------------------------------------------------------+

set -e

echo " "
echo "+------------------------------------------------------------------------------+"
echo "|      This script will configure this instance for web site development.      |"
echo "|                                                                              |"
echo "|     It will guide you through a series of prompts to setup useful server     |"
echo "|    packages such as common development tools, npm, gum, and other userful    |"
echo "|    server tools. It will also prompt you to configure a regular user with.   |"
echo "|               optional superuser capabilities for regular use.               |"
echo "+------------------------------------------------------------------------------+"
echo " "
echo "If you don't want to continue, press Control-C now to exit the script."
echo " "
read -p "If you are ready to proceed, press [Enter] to start the script..."
echo " "

# Version check, since this will not work on anything other than Debian Bookworm
# or Debian Trixie at the moment.
if [ ! -f /etc/debian_version ]; then
    echo "+------------------------------------------------------------------------------+"
    echo "| Error: This script is designed to run within Debian-based environments. Your |"
    echo "|   environment appears to be missing information needed to validate that this |"
    echo "|   installation is compatible with the ds-update.sh script.                   |"
    echo "|                                                                              |"
    echo "| This error is based on information read from the /etc/debian_version file.   |"
    echo "+------------------------------------------------------------------------------+"
    exit 1
fi
DEBIAN_VERSION=$(cat /etc/debian_version | cut -d'.' -f1)
if [ "$DEBIAN_VERSION" -lt 12 ]; then
    echo "+------------------------------------------------------------------------------+"
    echo "| Error: This script requires an environment running Debian version 12 or      |"
    echo "|   higher. You appear to be running a version older than 12 (Bookworm).       |"
    echo "|                                                                              |"
    echo "| This error is based on information read from the /etc/debian_version file.   |"
    echo "+------------------------------------------------------------------------------+"
    exit 1
fi
echo " "
echo " You are running a supported version of Debian in this environment..."

# The script uses "sudo" and "gum" - this checks if they are installed.
if ! command -v sudo &> /dev/null; then
    if [[ $EUID -ne 0 ]]; then
        echo "+------------------------------------------------------------------------------+"
        echo "|     Error: This script must be run as root or with superuser privileges.     |"
        echo "+------------------------------------------------------------------------------+"
        exit 1
    fi
    echo " "
    echo " The sudo package is used by dt-setup.sh and will now be installed..."
    echo " "
    apt update && apt install -y sudo
fi
if ! command -v gum &> /dev/null; then
    echo " "
    echo " Gum from Charm is used by dt-setup.sh and will now be installed..."
    echo " "
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
    sudo apt update && sudo apt install -y gum
fi
gum style --foreground 212 --padding "1 1" "All required packages for this script are installed."

# Setting the default locale for Debian along with the Environment Timezone
gum style --foreground 57 --padding "1 1" "Running Configuration Utility to set Environment Locale..."
sudo dpkg-reconfigure locales
gum style --foreground 57 --padding "1 1" "Running Configuration Utility to set Environment Timezone..."
sudo dpkg-reconfigure tzdata
gum style --foreground 212 --padding "1 1" "Environment Locale and Timezone have been set and updated."

# This is a new environment, let's make sure that apt is up-to-date and our packages are updated.
gum style --foreground 57 --padding "1 1" "Updating package lists..."
sudo apt update
gum style --foreground 212 --padding "1 1" "Local package listings have been updated."
gum style --foreground 57 --padding "1 1" "Updating installed packages..."
sudo apt upgrade -y && sudo apt full-upgrade -y
gum style --foreground 212 --padding "1 1" "Installed packages have been updated."

# Prompt to setup a non-root user or new user account along with the server timezone
if gum confirm "Do you want to create a new user?"; then
    USERNAME=$(gum input --placeholder "Enter the new username:")
    REALNAME=$(gum input --placeholder "Enter the real name:")
    GIVESUDO=$(gum confirm "Should this user have sudo privileges?")
        if id "$USERNAME" &>/dev/null; then
            gum style --foreground 57 --padding "1 1" "User $USERNAME already exists. Skipping creation..."
        else
            if [ "$GIVESUDO" = true ]; then
                gum style --foreground 212 --padding "1 1" "Creating user $USERNAME with sudo privileges."
                sudo adduser --gecos "$REALNAME" "$USERNAME"
                sudo usermod -aG sudo "$USERNAME"
            else
                gum style --foreground 212 --padding "1 1"  "Creating user $USERNAME."
                sudo adduser --gecos "$REALNAME" "$USERNAME"
            fi
        fi
fi

# Installing the base packages needed by a development server environment
gum style --foreground 57 --padding "1 1" "Installing common packages for development servers..."
sudo apt install -y apt-transport-https btop build-essential bwm-ng ca-certificates curl debian-goodies git glances gpg htop iotop locate iftop nano needrestart net-tools p7zip p7zip-full unzip vnstat wget
gum style --foreground 212 --padding "1 1" "Common packages for development servers have been installed."
if [ "$DEBIAN_VERSION" -lt 13 ]; then
    gum style --foreground 57 --padding "1 1" "Installing common packages specific to Debian 12..."
    sudo apt install -y software-properties-common
    gum style --foreground 212 --padding "1 1" "Common packages specific to Debian 12 have been installed."
fi

# Prompting for optional packages that can be added to the environment
gum style --foreground 57 --padding "1 1" "Choose optional packages to install:"
readarray -t ENV_OPTIONS < <(gum choose --no-limit \
    "Disk Usage Viewer" \
    "Go Programming Language Support" \
    "Node.js Support and Node Package Manager" \
    "Starship Prompt Enhancements" \
    "System Information Utilities" \
    "Tailscale Virtual Networking" \
    "Terminal Multiplexer")
for OPTION in "${ENV_OPTIONS[@]}"; do
    case $OPTION in
        "Disk Usage Viewer")
            gum style --foreground 57 --padding "1 1" "Installing duf from Debian package repositories..."
            sudo apt install -y duf
            gum style --foreground 212 --padding "1 1" "Duf has been installed."
            ;;
        "Go Programming Language Support")
            gum style --foreground 57 --padding "1 1" "Installing go language support from Debian package repositories..."
            sudo apt install -y golang
            gum style --foreground 212 --padding "1 1" "Go language support has been installed."
            ;;
        "Node.js Support and Node Package Manager")
            gum style --foreground 57 --padding "1 1" "Installing node.js support and npm from Debian package repositories..."
            sudo apt install -y nodejs npm
            gum style --foreground 212 --padding "1 1" "Node.js support and npm have been installed."
            ;;
        "Starship Prompt Enhancements")
            gum style --foreground 57 --padding "1 1" "Installing starship prompt enchancements..."
            if ! command -v starship &> /dev/null; then
                curl -sS https://starship.rs/install.sh | sh
                echo "eval \"\$(starship init bash)\"" >> $HOME/.bashrc
            fi
            if [ ! -d "$HOME/.config" ]; then
                mkdir -p "$HOME/.config"
            fi
            touch $HOME/.config/starship.toml
            starship preset plain-text-symbols -o $HOME/.config/starship.toml
            gum style --foreground 212 --padding "1 1" "Starship prompt enchancements have been installed."
            ;;
        "System Information Utilities")
            if [ "$DEBIAN_VERSION" -lt 13 ]; then
                gum style --foreground 57 --padding "1 1" "Installing neofetch from Debian 12 package repositories..."
                sudo apt install -y neofetch
                gum style --foreground 212 --padding "1 1" "Neofetch has been installed."
            fi
            if [ "$DEBIAN_VERSION" -ge 13 ]; then
                gum style --foreground 57 --padding "1 1" "Installing fastfetch from Debian 13 package repositories..."
                sudo apt install -y fastfetch
                gum style --foreground 212 --padding "1 1" "Fastfetch has been installed."
            fi
            sudo apt install -y hwinfo sysstat
            ;;
        "Tailscale Virtual Networking")
            gum style --foreground 57 --padding "1 1" "Installing Tailscale virtual networking..."
            sudo curl -fsSL https://tailscale.com/install.sh | sh
            sudo tailscale up
            if gum confirm "Do you want this environment to be an exit node?"; then
                sudo tailscale set --advertise-exit-node=true
                echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
                echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
                sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
            else
                sudo tailscale set --advertise-exit-node=false
            fi
            sudo tailscale set --accept-routes=false
            sudo tailscale set --accept-dns=false
            gum style --foreground 212 --padding "1 1" "Tailscale virtual networking has been installed."
            ;;
        "Terminal Multiplexer")
            gum style --foreground 57 --padding "1 1" "Installing tmux from Debian package repositories..."
            sudo apt install -y tmux
            gum style --foreground 212 --padding "1 1" "Tmux has been installed."
            ;;
        *)
            gum style --foreground 57 --padding "1 1" "No optional packages selected, skipping..."
            ;;
    esac
done

# Offer to complete a full update process with package cleanup
if gum confirm "Do you want to run a full apt update and package cleanup?"; then
    sudo apt update
    sudo apt install --fix-missing
    sudo apt upgrade --allow-downgrades
    sudo apt full-upgrade --allow-downgrades
    sudo apt install -f
    sudo apt autoremove
    sudo apt autoclean
    sudo apt clean
    gum style --foreground 212 --padding "1 1" "Full apt update and package cleanup completed."
else
    gum style --foreground 57 --padding "1 1" "Skipping apt update and package cleanup..."
fi

# Prompt for a reboot before completing the script
if gum confirm "Do you want to reboot this environment?"; then
    gum style --border double --foreground 212 --border-foreground 57 --margin "1" --padding "1 2" "The dt-setup.sh script has completed successfully, rebooting..."
    sleep 1
    sudo systemctl reboot
else
    gum style --border double --foreground 212 --border-foreground 57 --margin "1" --padding "1 2" "The dt-setup.sh script has completed successfully."
fi
exit 0