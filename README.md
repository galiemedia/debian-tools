
# Debianator

### Debian 12 or 13 Environment Setup & Update Tools

<img style="float: right;" src="debianator.png" />

Our [Debianator](https://www.github.com/galiemedia/debianator.git) (formerly "Debian Tools") scripts are an informal collection of local scripts to help automate the configuration, updates, and management for local [Debian-based](https://www.debian.org/) Linux environments such as development containers, WSL instances, cloud-based server images, or local machines.

These scripts are designed to be simple to run for anyone using Debian 12 or higher in their application development, web design, or server hosting workflows - and setup the basic needs for various platforms used by our studio team outside of our production ecosystem.

This script was written as an easy way to configure these local environments when other playbooks, image management, or initialization tools wouldn't fit the needs of the team or project.

*  **`deb-setup.sh`**: This script will setup the basic packages that our team commonly uses with interactive prompts to setup a local user with `sudo` privileges as well as install common tools useful for server-side development.

*  **`deb-update.sh`**: This script will update the Debian environment with the latest packages and security updates using the `apt` package manager as well as display information on system health, active services, and storage details.

*  **`deb-secure.sh`**: This script will assist with some good security practices for Debian environments that have public-facing connections.

*  **`deb-prompt.sh`**: This script will setup the prompt enhancements in a user profile.

*  **`deb-trixie.sh`**: This script will assist in updating a new or existing Debian 12 "Bookworm" environment to Debian 13 "Trixie".

## How to use this script

- Clone the repository using the command `git clone https://github.com/galiemedia/debianator.git`

- Review the `./debianator/deb-setup.sh` and `./debianator/deb-update.sh` scripts to make sure that you don't need to modify any parts to fit your project

- Make the cloned scripts executable with the command `chmod +x ./debianator/deb-setup.sh && chmod +x ./debianator/deb-update.sh`

- Run the setup script using the command `./debianator/deb-setup.sh`  

- Run the update script using the command `./debianator/deb-update.sh` 

- Run the security configuration tools script using the command `./debianator/deb-secure.sh`

- Add the prompt enhancements to a user profile using the command `./debianator/deb-prompt.sh`

- Run an upgrade from Debian 12 to 13 using the command `./debianator/deb-trixie.sh` from within a Debian 12 "Bookworm" environment

- Modernize existing apt package sources following an upgrade using the command `./debianator/deb-trixie.sh` from within a Debian 13 "Trixie" environment

## Note from the Studio

These scripts are specifically for a Debian 12 or newer server or headless environment, and does not install or upgrade non-command line applications or service packages. If you are looking for something that will update a Debian 12 or newer desktop or virtual machine, check out [Bender](https://www.github.com/seangalie/bender.git) on [Sean's personal repository](https://www.github.com/seangalie/).

If you are looking for scripts to configure [Fedora](https://www.fedoraproject.org/) environments - we're working on [Galie Media's](https://www.galiemedia.com/)  [Bogart](https://www.github.com/galiemedia/bogart.git) for headless environemtns and [Bespoke](https://www.github.com/seangalie/bespoke.git) on [Sean's personal repository](https://www.github.com/seangalie/) for desktop installations.

## Find any issues?

If you find these scripts useful, and have any ideas for updates or fixes for issues - let us know or [open an issue](https://github.com/galiemedia/debianator/issues/new). 