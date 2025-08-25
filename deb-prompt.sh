#!/bin/bash

# +----------------------------------------------------------------------------+
# |  deb-prompt.sh - A simple script to setup the Starship prompt for a user.  |
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

# The script uses "gum" - this checks if it is installed.
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

# Verify that "starship" is installed, and then run the prompt installation
gum style --foreground 57 --padding "1 1" "Checking that starship is already installed..."
if ! command -v starship &> /dev/null; then
    curl -sS https://starship.rs/install.sh | sh
fi
gum style --foreground 57 --padding "1 1" "Adding starship to the bash shell..."

# Check for and duplicate entries in .bashrc
if ! grep -q "eval \"\$(starship init bash)\"" "$HOME/.bashrc"; then
    echo "eval \"\$(starship init bash)\"" >> "$HOME/.bashrc"
fi

# Check for the local configuration directory and create it before creating a prompt config file
gum style --foreground 57 --padding "1 1" "Installing the plain text prompt presets..."
if [ ! -d "$HOME/.config" ]; then
    mkdir -p "$HOME/.config"
fi
touch $HOME/.config/starship.toml
starship preset plain-text-symbols -o $HOME/.config/starship.toml

# Add "fastfetch" to the bash login
if ! grep -q "if [ -f /usr/bin/fastfetch ]; then fastfetch; fi" "$HOME/.bashrc"; then
    echo "if [ -f /usr/bin/fastfetch ]; then fastfetch; fi" >> "$HOME/.bashrc"
fi

# Validate "starship" installation
if ! command -v starship &> /dev/null; then
    error_handler 1 $LINENO $BASH_LINENO "Starship installation failed" "main"
fi

gum style --foreground 212 --padding "1 1" "Starship has been configured and will be available on your next login."
exit 0
