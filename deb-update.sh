#!/bin/bash

# +----------------------------------------------------------------------------+
# |      deb-update.sh - A script to update Debian 12 or 13 environments.      |
# |                                                                            |
# |    This script will update a Debian environment with the latest updates    |
# |     using installed package managers as well as display information on     |
# |      system health, active services, and file system storage details.      |
# |                                                                            |
# | The latest version and more information can be found within our repository |
# |    at github.com/galiemedia/debianator or on our site at galiemedia.com    |
# +----------------------------------------------------------------------------+

set -e
trap 'error_handler $? $LINENO $BASH_LINENO "$BASH_COMMAND" $(printf "::%s" ${FUNCNAME[@]:-})' ERR

error_handler() {
    local exit_code=$1
    local line_no=$2
    local bash_lineno=$3
    local last_command=$4
    local func_trace=$5
    echo "Error occurred in script ${BASH_SOURCE[0]} at line $line_no"
    echo "Command: $last_command"
    echo "Exit code: $exit_code"
    exit $exit_code
}

# Version check, since this will not work on anything other than Debian 12 Bookworm or Debian 13 Trixie.
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
DEBIAN_VERSION="$(cut -d'.' -f1 < /etc/debian_version)"
if [ "$DEBIAN_VERSION" -lt 12 ]; then
    echo "+------------------------------------------------------------------------------+"
    echo "| Error: This script requires an environment running Debian version 12 or      |"
    echo "|   higher. You appear to be running a version older than 12 (Bookworm).       |"
    echo "|                                                                              |"
    echo "| This error is based on information read from the /etc/debian_version file.   |"
    echo "+------------------------------------------------------------------------------+"
    exit 1
fi

# The script uses "sudo", "curl", "jq", and "gum" - this checks if they are installed.
if ! command -v sudo &> /dev/null; then
    if [[ $EUID -ne 0 ]]; then
        echo "+------------------------------------------------------------------------------+"
        echo "|     Error: This script must be run as root or with superuser privileges.     |"
        echo "+------------------------------------------------------------------------------+"
        exit 1
    fi
    echo " "
    echo " The sudo package is used by deb-setup.sh and will now be installed..."
    echo " "
    sleep 1
    apt update && apt install -y sudo
fi
if ! command -v curl &> /dev/null; then
    echo " "
    echo " The curl package is used by deb-setup.sh and will now be installed..."
    echo " "
    sleep 1
    sudo apt update && sudo apt install -y curl
fi
if ! command -v jq &> /dev/null; then
    echo " "
    echo " The jq package is used by deb-setup.sh and will now be installed..."
    echo " "
    sleep 1
    sudo apt update && sudo apt install -y jq
fi
if ! command -v gum &> /dev/null; then
    echo " "
    echo " Gum from Charm is used by deb-setup.sh and will now be installed..."
    echo " "
    sleep 1
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
    sudo apt update && sudo apt install -y gum
    if ! command -v gum &> /dev/null; then
        echo "+------------------------------------------------------------------------------+"
        echo "|       Error: This script uses gum from Charm, which failed to install.       |"
        echo "+------------------------------------------------------------------------------+"
        exit 1
    fi
fi

# Open the update script with a quick glance at the system status before beginning the update scripts
sudo echo " "
uptime
echo " "
if [ "$DEBIAN_VERSION" -lt 13 ]; then
    if command -v neofetch &> /dev/null; then
        gum style --foreground 57 --padding "1 1" "Replacing neofetch with fastfetch..."
        sleep 1
        sudo apt purge -y neofetch
        ARCH=$(dpkg --print-architecture)
        FASTFETCH_URL=$(curl -s "https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest" | jq -r ".assets[] | select(.name | endswith(\"_$ARCH.deb\")) | .browser_download_url")
        wget -O "$HOME/fastfetch-linux-$ARCH.deb" "$FASTFETCH_URL"
        sudo dpkg -i "$HOME/fastfetch-linux-$ARCH.deb"
        rm "$HOME/fastfetch-linux-$ARCH.deb"
        gum style --foreground 212 --padding "1 1" "Fastfetch has been installed to update the outdated neofetch package."
    fi
    if ! command -v fastfetch &> /dev/null; then
        echo " Error: fastfetch is used to display system information at a glance for instances running Debian."
        echo "   This package was not found.  Installing Fastfetch from their GitHub repository..."
        echo " "
        sleep 1
        ARCH=$(dpkg --print-architecture)
        FASTFETCH_URL=$(curl -s "https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest" | jq -r ".assets[] | select(.name | endswith(\"_$ARCH.deb\")) | .browser_download_url")
        wget -O "$HOME/fastfetch-linux-$ARCH.deb" "$FASTFETCH_URL"
        sudo dpkg -i "$HOME/fastfetch-linux-$ARCH.deb"
        rm "$HOME/fastfetch-linux-$ARCH.deb"
        echo " "
    fi
else
    if command -v neofetch &> /dev/null; then
        gum style --foreground 57 --padding "1 1" "Replacing neofetch with fastfetch..."
        sleep 1
        sudo apt purge -y neofetch
        sudo apt install -y fastfetch
        gum style --foreground 212 --padding "1 1" "Fastfetch has been installed to update the outdated neofetch package."
    fi
    if ! command -v fastfetch &> /dev/null; then
        echo " Error: fastfetch is used to display system information at a glance for instances running Debian 13 or higher."
        echo "   This package was not found.  Installing Fastfetch from the Debian 13 repositories..."
        echo " "
        sleep 1
        sudo apt install -y fastfetch
        echo " "
    fi
fi
fastfetch
echo " "
read -p " If you are ready to proceed, press [Enter] to start the script..."
echo " "

# Offer to display the status of currently running services as well the list of package upgrades
if gum confirm "Do you want to view the status of currently running services?"; then
    gum style --foreground 212 --padding "1 1" "Displaying all currently configured services..."
    sudo service --status-all
    echo " "
    read -p " Press [Enter] to continue..."
fi
gum style --foreground 57 --padding "1 1" "Updating local package lists..."
sudo apt update
gum style --foreground 212 --padding "1 1" "Local package lists have been updated."
if gum confirm "Do you want to review the list of packages need updates?"; then
    gum style --foreground 212 --padding "1 1" "Displaying packages with pending updates..."
    sudo apt list --upgradable
    echo " "
    read -p " Press [Enter] to continue..."
fi

# Begin the core update process using the built-in package managers
gum style --foreground 57 --padding "1 1" "Updating installed packages..."
sleep 1
sudo apt upgrade -y
gum style --foreground 212 --padding "1 1" "Installed packages have been updated."
if command -v npm &> /dev/null; then
    gum style --foreground 57 --padding "1 1" "Updating global npm packages..."
    sleep 1
    sudo npm update -g
    gum style --foreground 212 --padding "1 1" "Global npm packages have been updated."
fi

# Offer to complete a full update process with package cleanup
if gum confirm "Do you want to run a full apt upgrade along with a set package cleanup tools?"; then
    gum style --foreground 57 --padding "1 1" "Running a full apt upgrade and package cleanup..."
    sudo apt update
    sudo apt install --fix-missing
    sudo apt upgrade --allow-downgrades
    sudo apt full-upgrade --allow-downgrades -V
    sudo apt install -f
    sudo apt autoremove --purge
    sudo apt autoclean
    sudo apt clean
    gum style --foreground 212 --padding "1 1" "Packages have been updated and cleanup tools have completed."
fi

# Show storage device statuses and prompt if an environment restart is need before wrapping up
if command -v duf &> /dev/null; then
    gum style --foreground 57 --padding "1 1" "Querying current status of storage devices..."
else
    gum style --foreground 57 --padding "1 1" "Duf utility not found, installing from apt repositories..."
    sleep 1
    sudo apt install -y duf
    gum style --foreground 57 --padding "1 1" "Querying current status of storage devices..."
fi
sleep 1
duf -hide special
if command -v needrestart &> /dev/null; then
    gum style --foreground 57 --padding "1 1" "Checking if a restart or reboot is recommended..."
    sleep 1
else
    gum style --foreground 57 --padding "1 1" "Needrestart utility not found, installing from apt repositories..."
    sleep 1
    sudo apt install -y needrestart
    gum style --foreground 57 --padding "1 1" "Checking if a restart or reboot is recommended..."
    sleep 1
fi
sudo /sbin/needrestart
gum style --foreground 212 --padding "1 1" "Packages have been updated and cleanup tools have completed."

# Prompt for an environment reboot before completing the script
if gum confirm "Do you want to reboot this environment?"; then
    gum style --border double --foreground 212 --border-foreground 57 --margin "1" --padding "1 2" "The deb-update.sh script has completed successfully, rebooting..."
    sleep 1
    sudo systemctl reboot
else
    gum style --border double --foreground 212 --border-foreground 57 --margin "1" --padding "1 2" "The deb-update.sh script has completed successfully."
fi
exit 0
