# Debian Setup & Update Tools

Our [Debian Tools](https://www.github.com/galiemedia/debian-tools.git) are a collection of local scripts to help automate the configuration, updates, and management for local [Debian-based](https://www.debian.org/) environments such as development containers, WSL instances, cloud-based server images, or local machines.

These scripts are designed to be simple to run for anyone using Debian 12 or higher in their application development, web design, or server hosting workflows - and setup the basic needs for various platforms used by our studio team.

This script was written as an easy way to configure these local environments when other playbooks, image management, or initialization tools wouldn't fit the needs of the team or project. The `ds-setup.sh` script will ask questions about which packages should be added, but the goal is to setup a "blank slate" for whatever is going to be deployed in the future.

*  **`dt-setup.sh`**: This script will setup the basic packages that our team commonly uses with interactive prompts to setup a local user with `sudo` privileges as well as install common tools useful for server-side development.

*  **`dt-update.sh`**: This script will update the Debian environment with the latest packages and security updates using the `apt` package manager as well as display information on system health, active services, and storage details.

## How to use this script

- Clone the repository using the command `git clone https://github.com/galiemedia/debian-tools.git`

- Review the `./debian-tools/dt-setup.sh` and `./debian-tools/dt-update.sh` scripts to make sure that you don't need to modify any parts to fit your project

- Make the cloned scripts executable with the command `chmod +x ./debian-tools/dt-setup.sh && chmod +x ./debian-tools/dt-update.sh`

- Run the setup script using the command `./debian-tools/dt-setup.sh`

- Run the update script using the command `./debian-tools/dt-update.sh`

## Note from the Author

These scripts are specifically for a Debian 12 or newer server or headless environment, and does not install or upgrade non-command line applications or service packages.  If you are looking for something that will update a Debian 12 or newer desktop or virtual machine, check out [Bender](https://www.github.com/seangalie/bender.git) on [Sean's personal repository](https://www.github.com/seangalie/).

If you are looking for scripts to configure [Fedora](https://www.fedoraproject.org/) - check out [Galie Media's](https://www.galiemedia.com/) [Fedora Tools](https://www.github.com/galiemedia/fedora-tools.git) and [Bespoke](https://www.github.com/seangalie/bespoke.git) on [Sean's personal repository](https://www.github.com/seangalie/).