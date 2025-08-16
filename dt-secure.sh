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
    error_handler 1 $LINENO $BASH_LINENO "Missing /etc/debian_version file" "main"
fi

DEBIAN_VERSION=$(cat /etc/debian_version | cut -d'.' -f1)
if [ "$DEBIAN_VERSION" -lt 12 ]; then
    error_handler 1 $LINENO $BASH_LINENO "Debian version less than 12" "main"
fi

# The script uses "sudo" and "gum" - this checks if they are installed.
if ! command -v sudo &> /dev/null; then
    if [[ $EUID -ne 0 ]]; then
        error_handler 1 $LINENO $BASH_LINENO "Script not run as root" "main"
    fi
    echo " "
    echo " The sudo package is used by dt-update.sh and will now be installed..."
    echo " "
    sleep 1
    apt update && apt install -y sudo
fi
if ! command -v gum &> /dev/null; then
    echo " "
    echo " Gum from Charm is used by dt-update.sh and will now be installed..."
    echo " "
    sleep 1
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
    sudo apt update && apt install -y gum
fi
if [ "$DEBIAN_VERSION" -lt 13 ]; then
    if command -v neofetch >&2; then
        gum style --foreground 57 --padding "1 1" "Replacing neofetch with fastfetch..."
        sleep 1
        sudo apt purge -y neofetch
        wget https://github.com/fastfetch-cli/fastfetch/releases/download/2.49.0/fastfetch-linux-amd64.deb
        sudo dpkg -i ~/fastfetch-linux-amd64.deb
        rm ~/fastfetch-linux-amd64.deb
        gum style --foreground 212 --padding "1 1" "Fastfetch has been installed to update the outdated neofetch package."
    fi
    if ! command -v fastfetch &> /dev/null; then
        echo " Error: fastfetch is used to display system information at a glance for instances running Debian."
        echo "   This package was not found.  Installing Fastfetch from their GitHub repository..."
        echo " "
        sleep 1
        wget https://github.com/fastfetch-cli/fastfetch/releases/download/2.49.0/fastfetch-linux-amd64.deb
        sudo dpkg -i ~/fastfetch-linux-amd64.deb
        rm ~/fastfetch-linux-amd64.deb
        echo " "
    fi
else
    if command -v neofetch >&2; then
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

# Offer to set the default locale for Debian along with the Environment Timezone (needed for brand new images)
if gum confirm "Do you want to set the locale and timezone for this environment?"; then
    gum style --foreground 57 --padding "1 1" "Running Configuration Utility to set Environment Locale..."
    sleep 1
    sudo dpkg-reconfigure locales
    gum style --foreground 57 --padding "1 1" "Running Configuration Utility to set Environment Timezone..."
    sleep 1
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
            sleep 1
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
                gum style --foreground 57 --padding "1 1" "Enabling UFW firewall..."
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
            sleep 1
            sudo apt install -y unattended-upgrades
            sudo dpkg-reconfigure unattended-upgrades
            gum style --foreground 212 --padding "1 1" "Unattended upgrades configuration completed."
            ;;
        "Update and Upgrade Installed Packages")
            gum style --foreground 57 --padding "1 1" "Running a full apt upgrade and package cleanup..."
            sleep 1
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
            sleep 1
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