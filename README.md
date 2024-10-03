# Automated Software Installation Script

This script streamlines the setup of essential tools for software development on macOS, covering popular programming languages, development environments, and system utilities. It's designed to be idempotent, meaning it checks for existing installations before proceeding, avoiding unnecessary reinstallations.

## Tools Installed (if not already present)

- **Xcode Command Line Tools:** Essential development tools for macOS.
- **Homebrew:** Package manager for macOS, simplifying software installation and management.
- **Java (Temurin 17):** Versatile programming language used for various applications.
- **Tomcat:** Java web server for deploying and running web applications.
- **Maven:** Java build automation and dependency management tool.
- **MySQL:** Powerful and widely used relational database management system.
- **Node.js:** JavaScript runtime for executing code outside web browsers.
- **Visual Studio Code:** Feature-rich integrated development environment (IDE) for various programming languages.
- **Salesforce CLI:** Command Line Interface designed to streamline and enhance the Salesforce development process.
- **Additional Apps:** Zoom, Slack, Draw.io, CakeBrew, Google Chrome (for Google Meet), ProtonVPN.

## Additional Configurations

- **SSH Key Setup:** Generate and manage SSH keys for secure, passwordless authentication to remote systems (e.g., GitHub), if not already set up. The script now configures the SSH key to work with the Mac's Keychain Access for added convenience and security. The SSH Agent is properly configured to work with GitHub, eliminating the need for repeated password entry.
- **Global Gitignore:** Set up a global gitignore file to exclude specific files or patterns from version control, if not already configured.
- **Default Git Editor:** Set the default commit editor to nano, if not already set.

## Installation

1. **Open your terminal.**
2. **Copy and paste the following command:**

   ```bash
   bash -c "$(curl -sS https://raw.githubusercontent.com/chininchu/setup-script/main/install.sh)"
   ```

## Script Overview

The installation script performs the following actions:

1. Checks for and installs Xcode Command Line Tools if not already present.
2. Checks for and installs Homebrew if not already present.
3. Sets up SSH keys for GitHub if not already configured, including integration with Mac's Keychain Access and proper SSH Agent configuration.
4. Checks for and installs Java, Maven, Tomcat, MySQL, Visual Studio Code, and Node.js using Homebrew, only if they are not already installed.
5. Installs Salesforce CLI using npm if Node.js was just installed or updated.
6. Installs additional applications: Zoom, Slack, Draw.io, CakeBrew, Google Chrome, and ProtonVPN.
7. Configures a global gitignore file and sets the default Git editor to nano, if these configurations don't already exist.
8. Provides a summary of the installation results, indicating which tools were successfully installed or were already present.

## Post-Installation

After running the script, it's recommended to visit https://www.toptal.com/developers/gitignore to set up a comprehensive global gitignore file tailored to your development needs.

## SSH Agent Configuration

The script now properly configures the SSH Agent to work seamlessly with GitHub. This means:

- Your SSH key is added to the SSH Agent.
- The SSH Agent is configured to use the Mac's Keychain for secure storage of your passphrase.
- You won't need to enter your SSH key passphrase repeatedly when performing Git operations.

This configuration enhances both security and convenience in your development workflow.

## Disclaimer

**Important:** This script is intended for convenience and to automate repetitive tasks. While it's designed to be safe and avoid unnecessary reinstallations, it will make changes to your system. Please review the script's contents at the provided GitHub link to ensure you're comfortable with the tools being installed and the modifications being made before running it.
