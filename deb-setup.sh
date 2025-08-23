#!/bin/bash

# +----------------------------------------------------------------------------+
# |        deb-setup.sh - A simple script to setup Debian environments.        |
# |                                                                            |
# |  This script will setup basic packages common to web site and application  |
# |  development environments with either interactive prompts or an automatic  |
# |   execution to setup everything needed within a new Debian installation.   |
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
    echo "Error occurred in script at line $line_no"
    echo "Command: $last_command"
    echo "Exit code: $exit_code"
}

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
sleep 1

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
    sleep 1
    apt update && apt install -y sudo
fi
if ! command -v gum &> /dev/null; then
    echo " "
    echo " Gum from Charm is used by dt-setup.sh and will now be installed..."
    echo " "
    sleep 1
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
    sudo apt update && sudo apt install -y gum
fi
gum style --foreground 212 --padding "1 1" "All required packages for this script are installed."

# Setting the default locale for Debian along with the Environment Timezone
gum style --foreground 57 --padding "1 1" "Running Configuration Utility to set Environment Locale..."
sleep 1
sudo dpkg-reconfigure locales
gum style --foreground 57 --padding "1 1" "Running Configuration Utility to set Environment Timezone..."
sleep 1
sudo dpkg-reconfigure tzdata
gum style --foreground 212 --padding "1 1" "Environment Locale and Timezone have been set and updated."

# This is a new environment, let's make sure that apt is up-to-date and our packages are updated.
gum style --foreground 57 --padding "1 1" "Updating package lists..."
sleep 1
sudo apt update
gum style --foreground 212 --padding "1 1" "Local package listings have been updated."
gum style --foreground 57 --padding "1 1" "Updating installed packages..."
sleep 1
sudo apt upgrade -y && sudo apt full-upgrade -y
gum style --foreground 212 --padding "1 1" "Installed packages have been updated."

# Prompt to setup a non-root user or new user account if needed
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
                sudo adduser "$USERNAME" sudo
            else
                gum style --foreground 212 --padding "1 1"  "Creating user $USERNAME."
                sudo adduser --gecos "$REALNAME" "$USERNAME"
            fi
        fi
fi

# Installing the base packages needed by a development server environment
gum style --foreground 57 --padding "1 1" "Installing common packages for development servers..."
sleep 1
sudo apt install -y apt-transport-https btop build-essential bwm-ng ca-certificates curl cmake cmatrix debian-goodies duf git glances gpg htop iotop locate iftop jq make multitail nano needrestart net-tools p7zip p7zip-full tar tldr-py tree unzip vnstat wget
gum style --foreground 212 --padding "1 1" "Common packages for development servers have been installed."
if [ "$DEBIAN_VERSION" -lt 13 ]; then
    gum style --foreground 57 --padding "1 1" "Installing common packages specific to Debian 12..."
    sleep 1
    sudo apt install -y software-properties-common
    wget https://github.com/fastfetch-cli/fastfetch/releases/download/2.49.0/fastfetch-linux-amd64.deb
    sudo dpkg -i ~/fastfetch-linux-amd64.deb
    rm ~/fastfetch-linux-amd64.deb
    echo 'deb [signed-by=/usr/share/keyrings/azlux.gpg] https://packages.azlux.fr/debian/ bookworm main' | sudo tee /etc/apt/sources.list.d/azlux.list
    curl -s https://azlux.fr/repo.gpg.key | gpg --dearmor | sudo tee /usr/share/keyrings/azlux.gpg > /dev/null
    sudo apt update && sudo apt install -y gping
    gum style --foreground 212 --padding "1 1" "Common packages specific to Debian 12 have been installed."
fi
if [ "$DEBIAN_VERSION" -ge 13 ]; then
    gum style --foreground 57 --padding "1 1" "Installing common packages specific to Debian 13..."
    sleep 1
    sudo apt install -y fastfetch gping
    gum style --foreground 212 --padding "1 1" "Common packages specific to Debian 13 have been installed."
fi

# Prompting for optional packages that can be added to the environment
gum style --foreground 57 --padding "1 1" "Choose optional packages to install:"
readarray -t ENV_OPTIONS < <(gum choose --no-limit \
    "Go Programming Language Support" \
    "Node.js Support and Node Package Manager" \
    "Starship Prompt Enhancements" \
    "System Information Utilities" \
    "Tailscale Virtual Networking" \
    "Terminal AI Coding Agents" \
    "Terminal Multiplexer")
for OPTION in "${ENV_OPTIONS[@]}"; do
    case $OPTION in
        "Go Programming Language Support")
            gum style --foreground 57 --padding "1 1" "Installing go language support from Debian package repositories..."
            sleep 1
            sudo apt install -y golang
            gum style --foreground 212 --padding "1 1" "Go language support has been installed."
            ;;
        "Node.js Support and Node Package Manager")
            gum style --foreground 57 --padding "1 1" "Installing node.js support and npm from Debian package repositories..."
            sleep 1
            sudo apt install -y nodejs npm
            gum style --foreground 212 --padding "1 1" "Node.js support and npm have been installed."
            ;;
        "Starship Prompt Enhancements")
            gum style --foreground 57 --padding "1 1" "Installing starship prompt enchancements..."
            sleep 1
            if ! command -v starship &> /dev/null; then
                curl -sS https://starship.rs/install.sh | sh
                echo "eval \"\$(starship init bash)\"" >> $HOME/.bashrc
            fi
            if [ ! -d "$HOME/.config" ]; then
                mkdir -p "$HOME/.config"
            fi
            touch $HOME/.config/starship.toml
            starship preset plain-text-symbols -o $HOME/.config/starship.toml
            echo "if [ -f /usr/bin/fastfetch ]; then fastfetch; fi" >> $HOME/.bashrc
            gum style --foreground 212 --padding "1 1" "Starship prompt enchancements have been installed."
            ;;
        "System Information Utilities")
            gum style --foreground 57 --padding "1 1" "Installing system information utilities..."
            sleep 1
            sudo apt install -y hwinfo sysstat
            gum style --foreground 212 --padding "1 1" "System information utilties have been installed."
            ;;
        "Tailscale Virtual Networking")
            gum style --foreground 57 --padding "1 1" "Installing Tailscale virtual networking..."
            sleep 1
            sudo curl -fsSL https://tailscale.com/install.sh | sh
            gum style --foreground 57 --padding "1 1" "Prompting for Tailscale activation..."
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
        "Terminal AI Coding Agents")
            if ! command -v npm &> /dev/null; then
                gum style --foreground 57 --padding "1 1" "Installing required packages for coding agents..."
                sleep 1
                sudo apt install -y npm
                gum style --foreground 212 --padding "1 1" "The required packages have been installed."
            fi
            gum style --foreground 57 --padding "1 1" "Installing Crush from Charm..."
            sleep 1
            sudo apt install -y crush
            gum style --foreground 212 --padding "1 1" "Charm Crush has been installed."
            gum style --foreground 57 --padding "1 1" "Installing Opencode..."
            sleep 1
            sudo npm install -g opencode-ai@latest
            gum style --foreground 212 --padding "1 1" "Opencode has been installed."
            ;;
        "Terminal Multiplexer")
            gum style --foreground 57 --padding "1 1" "Installing tmux from Debian package repositories..."
            sleep 1
            sudo apt install -y tmux
            gum style --foreground 212 --padding "1 1" "Tmux has been installed."
            ;;
        *)
            gum style --foreground 57 --padding "1 1" "No optional packages selected, skipping..."
            sleep 1
            ;;
    esac
done

# Offer to setup a firewall and configure with rules for common services
if gum confirm "Do you want to install and configure a firewall?"; then
    sudo apt install -y ufw
    if gum confirm "Do you want to allow SSH traffic through the firewall?"; then
        SSH_PORT=$(gum input --placeholder "Enter your SSH port (default is 22)")
        if [ -z "$SSH_PORT" ]; then
            SSH_PORT=22
        fi
        if [[ "$SSH_PORT" =~ ^[0-9]+$ ]] && [ "$SSH_PORT" -ge 1 ] && [ "$SSH_PORT" -le 65535 ]; then
            sudo ufw allow $SSH_PORT/tcp
        else
            gum style --foreground 196 --padding "1 1" "Invalid port number. Skipping SSH port rule."
        fi
    fi
    if gum confirm "Do you want to allow web site traffic through the firewall?"; then
        gum style --foreground 57 --padding "1 1" "Adding rule for Port 80 HTTP traffic..."
        sudo ufw allow 80/tcp comment 'HTTP'
        gum style --foreground 57 --padding "1 1" "Adding rule for Port 443 HTTPS traffic..."
        sudo ufw allow 443/tcp comment 'HTTPS'
    fi
    if gum confirm "Do you want to allow FTP traffic through the firewall?"; then
        gum style --foreground 57 --padding "1 1" "Adding rule for Port 20 FTP transfer traffic..."
        sudo ufw allow 20/tcp comment 'FTP Transfer'
        gum style --foreground 57 --padding "1 1" "Adding rule for Port 21 FTP control traffic..."
        sudo ufw allow 21/tcp comment 'FTP Control'
    fi
    if gum confirm "Do you want to allow DNS traffic through the firewall?"; then
        gum style --foreground 57 --padding "1 1" "Adding rule for Port 53 DNS TCP traffic..."
        sudo ufw allow 53/tcp comment 'DNS TCP'
        gum style --foreground 57 --padding "1 1" "Adding rule for Port 53 DNS UDP traffic..."
        sudo ufw allow 53/udp comment 'DNS UDP'
    fi
    if gum confirm "Do you want to allow mail traffic (POP3, IMAP, and SMTP) through the firewall?"; then
        gum style --foreground 57 --padding "1 1" "Adding rule for Port 110 POP3 traffic..."
        sudo ufw allow 110/tcp comment 'POP3'
        gum style --foreground 57 --padding "1 1" "Adding rule for Port 143 IMAP traffic..."
        sudo ufw allow 143/tcp comment 'IMAP'
        gum style --foreground 57 --padding "1 1" "Adding rule for Port 465 SMTP TLS traffic..."
        sudo ufw allow 465/tcp comment 'SMTP TLS'
        gum style --foreground 57 --padding "1 1" "Adding rule for Port 587 SMTP SSL traffic..."
        sudo ufw allow 587/tcp comment 'SMTP SSL'
        gum style --foreground 57 --padding "1 1" "Adding rule for Port 993 POP3S traffic..."
        sudo ufw allow 993/tcp comment 'POP3S'
        gum style --foreground 57 --padding "1 1" "Adding rule for Port 995 IMAPS traffic..."
        sudo ufw allow 995/tcp comment 'IMAPS'
    fi
    if gum confirm "Do you want to allow remote MySQL traffic through the firewall?"; then
        gum style --foreground 57 --padding "1 1" "Adding rule for Port 3306 MySQL traffic..."
        sudo ufw allow 3306/tcp comment 'MySQL'
    fi
    if gum confirm "Do you want to allow Docker (Port 3000) traffic through the firewall?"; then
        gum style --foreground 57 --padding "1 1" "Adding rule for Port 3000 Docker traffic..."
        sudo ufw allow 3000/tcp comment 'Docker'
    fi
    if gum confirm "Do you want to allow Container Application (Ports 6001, 6002, and 8000) traffic through the firewall?"; then
        gum style --foreground 57 --padding "1 1" "Adding rule for Port 6001 Container RTC traffic..."
        sudo ufw allow 6001/tcp comment 'Container RTC'
        gum style --foreground 57 --padding "1 1" "Adding rule for Port 6002 Container SSH traffic..."
        sudo ufw allow 6002/tcp comment 'Container SSH'
        gum style --foreground 57 --padding "1 1" "Adding rule for Port 8000 Container traffic..."
        sudo ufw allow 8000/tcp comment 'Container Controls'
    fi
    if gum confirm "Do you want to allow Control Panel (Port 8083) traffic through the firewall?"; then
        gum style --foreground 57 --padding "1 1" "Adding rule for Port 8083 Control Panel traffic..."
        sudo ufw allow 8083/tcp comment 'Control Panel'
    fi
    if gum confirm "Do you want to allow Application Control (Port 8443) traffic through the firewall?"; then
        gum style --foreground 57 --padding "1 1" "Adding rule for Port 8443 Application Controls traffic..."
        sudo ufw allow 8443/tcp comment 'Application Controls'
    fi
    if gum confirm "Do you want to deny all incoming traffic by default other than the allowed rules?"; then
        gum style --foreground 57 --padding "1 1" "Adding rule for denying incoming traffic..."
        sudo ufw default deny incoming
    fi
    if gum confirm "Do you want to allow all outgoing traffic by default?"; then
        gum style --foreground 57 --padding "1 1" "Adding rule for allowing outgoing traffic..."
        sudo ufw default allow outgoing
    fi
    if gum confirm "Do you want to enable the firewall?"; then
        gum style --foreground 57 --padding "1 1" "Enabling firewall..."
        sudo ufw enable
    fi
    gum style --foreground 212 --padding "1 1" "Firewall installation and configuration completed."
else
    gum style --foreground 57 --padding "1 1" "Skipping firewall installation and configuration..."
fi

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

# Prompt for an environment reboot before completing the script
if gum confirm "Do you want to reboot this environment?"; then
    gum style --border double --foreground 212 --border-foreground 57 --margin "1" --padding "1 2" "The dt-setup.sh script has completed successfully, rebooting..."
    sleep 1
    sudo systemctl reboot
else
    gum style --border double --foreground 212 --border-foreground 57 --margin "1" --padding "1 2" "The dt-setup.sh script has completed successfully."
fi
exit 0