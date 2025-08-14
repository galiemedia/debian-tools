#!/bin/bash

# +----------------------------------------------------------------------------+
# |   ds-secure.sh - A script to help harden and secure a Debian environment   |
# |                                                                            |
# | The latest version and more information can be found within our repository |
# |   at github.com/galiemedia/debian-tools or on our site at galiemedia.com   |
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

# Version check, since this is designed for Debian 12 or Debian 13 only
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

# The script uses "sudo" and "gum" - this checks if they are installed.
if ! command -v sudo &> /dev/null; then
    if [[ $EUID -ne 0 ]]; then
        echo "+------------------------------------------------------------------------------+"
        echo "|     Error: This script must be run as root or with superuser privileges.     |"
        echo "+------------------------------------------------------------------------------+"
        exit 1
    fi
    echo " "
    echo " The sudo package is used by dt-update.sh and will now be installed..."
    echo " "
    apt update && apt install -y sudo
fi
if ! command -v gum &> /dev/null; then
    echo " "
    echo " Gum from Charm is used by dt-update.sh and will now be installed..."
    echo " "
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
    sudo apt update && apt install -y gum
fi

# Offer to set the default locale for Debian along with the Environment Timezone (needed for brand new images)
if gum confirm "Do you want to set the locale and timezone for this environment?"; then
    gum style --foreground 57 --padding "1 1" "Running Configuration Utility to set Environment Locale..."
    sudo dpkg-reconfigure locales
    gum style --foreground 57 --padding "1 1" "Running Configuration Utility to set Environment Timezone..."
    sudo dpkg-reconfigure tzdata
    gum style --foreground 212 --padding "1 1" "Environment Locale and Timezone have been set and updated."
fi

# Prompting for actions that help secure Debian environments
gum style --foreground 57 --padding "1 1" "Choose security practices or actions to implement:"
readarray -t ENV_OPTIONS < <(gum choose --no-limit \
    "Configure SSH" \
    "Install and Configure UFW" \
    "Install and Configure Fail2ban" \
    "Setup and Configure Unattended Upgrades" \
    "Update and Upgrade Installed Packages")
for OPTION in "${ENV_OPTIONS[@]}"; do
    case $OPTION in
        "Configure SSH")
            gum style --foreground 57 --padding "1 1" "Configuring SSH..."
            if [ ! -f /etc/ssh/sshd_config.bak ]; then
                sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
            fi
            if gum confirm "Do you want to change the default SSH port? (default is 22)"; then
                SSH_PORT=$(gum input --placeholder "Enter new SSH port")
                if [[ "$SSH_PORT" =~ ^[0-9]+$ ]] && [ "$SSH_PORT" -ge 1 ] && [ "$SSH_PORT" -le 65535 ]; then
                    if grep -qE '^#?Port ' /etc/ssh/sshd_config; then
                        sudo sed -i "s/^#*Port .*/Port $SSH_PORT/" /etc/ssh/sshd_config
                    else
                        echo "Port $SSH_PORT" | sudo tee -a /etc/ssh/sshd_config > /dev/null
                    fi
                else
                    gum style --foreground 196 --padding "1 1" "Invalid port number. Skipping port change."
                fi
            fi
            if gum confirm "Do you want to disable root login via SSH?"; then
                if grep -qE '^#?PermitRootLogin ' /etc/ssh/sshd_config; then
                    sudo sed -i "s/^#*PermitRootLogin .*/PermitRootLogin no/" /etc/ssh/sshd_config
                else
                    echo "PermitRootLogin no" | sudo tee -a /etc/ssh/sshd_config > /dev/null
                fi
            fi
            if gum confirm "Do you want to disable password authentication for SSH?"; then
                if grep -qE '^#?PasswordAuthentication ' /etc/ssh/sshd_config; then
                    sudo sed -i "s/^#*PasswordAuthentication .*/PasswordAuthentication no/" /etc/ssh/sshd_config
                else
                    echo "PasswordAuthentication no" | sudo tee -a /etc/ssh/sshd_config > /dev/null
                fi
            fi
            sudo systemctl restart sshd
            gum style --foreground 212 --padding "1 1" "SSH configuration completed."
            ;;
        "Install and Configure UFW")
            gum style --foreground 57 --padding "1 1" "Installing and configuring UFW..."
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
                sudo ufw allow 80/tcp comment 'HTTP'
                sudo ufw allow 443/tcp comment 'HTTPS'
            fi
            if gum confirm "Do you want to allow FTP traffic through the firewall?"; then
                sudo ufw allow 20/tcp comment 'FTP Transfer'
                sudo ufw allow 21/tcp comment 'FTP Control'
            fi
            if gum confirm "Do you want to allow DNS traffic through the firewall?"; then
                sudo ufw allow 53/tcp comment 'DNS TCP'
                sudo ufw allow 53/udp comment 'DNS UDP'
            fi
            if gum confirm "Do you want to allow mail traffic (POP3, IMAP, and SMTP) through the firewall?"; then
                sudo ufw allow 110/tcp comment 'POP3'
                sudo ufw allow 143/tcp comment 'IMAP'
                sudo ufw allow 465/tcp comment 'SMTP TLS'
                sudo ufw allow 587/tcp comment 'SMTP SSL'
                sudo ufw allow 993/tcp comment 'POP3S'
                sudo ufw allow 995/tcp comment 'IMAPS'
            fi
            if gum confirm "Do you want to allow remote MySQL traffic through the firewall?"; then
                sudo ufw allow 3306/tcp comment 'MySQL'
            fi
            if gum confirm "Do you want to allow Docker (Port 3000) traffic through the firewall?"; then
                sudo ufw allow 3000/tcp comment 'Docker'
            fi
            if gum confirm "Do you want to allow Container Application (Ports 6001, 6002, and 8000) traffic through the firewall?"; then
                sudo ufw allow 6001/tcp comment 'Container RTC'
                sudo ufw allow 6002/tcp comment 'Container SSH'
                sudo ufw allow 8000/tcp comment 'Container Controls'
            fi
            if gum confirm "Do you want to allow Control Panel (Port 8083) traffic through the firewall?"; then
                sudo ufw allow 8083/tcp comment 'Control Panel'
            fi
            if gum confirm "Do you want to allow Application Control (Port 8443) traffic through the firewall?"; then
                sudo ufw allow 8443/tcp comment 'Application Controls'
            fi
            if gum confirm "Do you want to enable the firewall?"; then
                sudo ufw enable
            fi
            gum style --foreground 212 --padding "1 1" "UFW installation and configuration completed."
            ;;
        "Install and Configure Fail2ban")
            gum style --foreground 57 --padding "1 1" "Installing and configuring Fail2Ban..."
            sudo apt install -y fail2ban
            if [ ! -f /etc/fail2ban/jail.local ]; then
                sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
            fi
            if gum confirm "Do you want to configure Fail2Ban for SSH?"; then
                sudo sed -i "s/^#*port\s*=.*/port = ssh/" /etc/fail2ban/jail.local
                sudo sed -i "s/^#*enabled\s*=.*/enabled = true/" /etc/fail2ban/jail.local
            fi
            sudo systemctl restart fail2ban
            gum style --foreground 212 --padding "1 1" "Fail2Ban configuration completed."
            ;;
        "Setup and Configure Unattended Upgrades")
            gum style --foreground 57 --padding "1 1" "Installing and configuring unattended upgrades..."
            sudo apt install -y unattended-upgrades
            sudo dpkg-reconfigure unattended-upgrades
            gum style --foreground 212 --padding "1 1" "Unattended upgrades configuration completed."
            ;;
        "Update and Upgrade Installed Packages")
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
            ;;

        *)
            gum style --foreground 57 --padding "1 1" "No practices or actions selected, skipping..."
            ;;
    esac
done

# Prompt for a reboot before completing the script
if gum confirm "Do you want to reboot this environment?"; then
    gum style --border double --foreground 212 --border-foreground 57 --margin "1" --padding "1 2" "The dt-secure.sh script has completed successfully, rebooting..."
    sleep 1
    sudo systemctl reboot
else
    gum style --border double --foreground 212 --border-foreground 57 --margin "1" --padding "1 2" "The dt-secure.sh script has completed successfully."
fi
exit 0