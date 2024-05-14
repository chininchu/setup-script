# Automated Software Installation Script

This script streamlines the setup of essential tools for software development on macOS, covering popular programming languages, development environments, and system utilities.

## Tools Installed

* **Xcode:** Command line tools for macOS, providing essential developer tools.
* **Brew:** Package manager for macOS, simplifying software installation and management.
* **Java:** Versatile programming language used for various applications.
* **Tomcat:** Java web server for deploying and running web applications.
* **Maven:** Java build automation and dependency management tool.
* **MySQL:** Powerful and widely used relational database management system.
* **Node.js:** JavaScript runtime for executing code outside web browsers.
* **NPM:** Node Package Manager, for managing JavaScript packages and dependencies.
* **IntelliJ:** Feature-rich integrated development environment (IDE) for Java development.


## Additional Configurations

* **SSH Key Setup:** Generate and manage SSH keys for secure, passwordless authentication to remote systems (e.g., GitHub).
* **Global Gitignore:** Customize Git's default behavior to exclude specific files or patterns from version control.
* **Default Commit Editor:** Setup a global gitignore file and set the default commit editor to nano (only if these are not already set).


## Installation

1. **Open your terminal.**
2. **Copy and paste the following command:**

   ```bash
   bash -c "$(curl -sS https://raw.githubusercontent.com/chininchu/setup-script/main/install.sh)"



The following should do the trick if they already have a ssh key pair, but it's
not wired up to Github.

```bash
pbcopy < ~/.ssh/id_rsa.pub
open https://github.com/settings/ssh

```


## Disclaimer
**Important:** This script is intended for convenience and to automate repetitive tasks. However, it's crucial to understand that it will make changes to your system. Please review the script's contents at the provided GitHub link to ensure you're comfortable with the tools being installed and the modifications being made before running it.
