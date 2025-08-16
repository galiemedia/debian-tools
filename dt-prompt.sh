#!/bin/bash

# +----------------------------------------------------------------------------+
# |   dt-prompt.sh - A simple script to setup the Starship prompt for a user.  |
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

# Check to make sure that Starship is already installed, and then enhance this user's prompts
gum style --foreground 57 --padding "1 1" "Checking that starship is already installed..."
if ! command -v starship &> /dev/null; then
    curl -sS https://starship.rs/install.sh | sh
fi
gum style --foreground 57 --padding "1 1" "Adding starship to the bash shell..."
echo "eval \"\$(starship init bash)\"" >> $HOME/.bashrc
gum style --foreground 57 --padding "1 1" "Installing the plain text prompt presets..."
if [ ! -d "$HOME/.config" ]; then
    mkdir -p "$HOME/.config"
fi
touch $HOME/.config/starship.toml
starship preset plain-text-symbols -o $HOME/.config/starship.toml
echo "if [ -f /usr/bin/fastfetch ]; then fastfetch; fi" >> $HOME/.bashrc
gum style --foreground 212 --padding "1 1" "Starship has been configured and will be available on your next login."
exit 0