#!/bin/bash

# TODO: brew cask install google-chrome

# Setup script for laptops
# =========================================
#
# This script will
#
# 1. check for xcode, if it does not exist go ahead and install it
# 2. do the same for brew
# 3. if $HOME/.ssh/id_rsa does not exist, generate ssh keys and open github so
#    they can be configured there
# 4. install java with brew cask
# 5. check for maven and tomcat, install them with brew if not present
# 6. check for mysql, install it and configure if not present
# 7. install node with brew
# 8. setup a comprehensive global gitignore file and set the default commit editor to nano

wait-to-continue() {
    echo
    echo 'Press Enter to continue or Ctrl-C to exit'
    read -r
}

install-xcode() {
    if xcode-select -p &>/dev/null; then
        echo "Xcode Command Line Tools are already installed."
    else
        echo "We need to install some commandline tools for Xcode. When you press 'Enter',"
        echo "a dialog will pop up with several options. Click the 'Install' button and wait."
        echo "Once the process completes, come back here and we will proceed with the next step."

        xcode-select --install 2>&1

        # wait for xcode...
        while sleep 1; do
            xcode-select --print-path >/dev/null 2>&1 && break
        done
    fi
    echo
}

install-java() {
    if java -version 2>&1 | grep -q "version \"17"; then
        echo "Java 17 is already installed."
    else
        echo 'We are now going to use homebrew to install java. While your mac comes'
        echo 'with a version of java, it may not be the most recent version, and we want'
        echo 'to make sure everyone is on the same version.'
        # Using this install because it is recommended by Salesforce for dev environment
        brew install --cask temurin@17
    fi
}

install-tomcat() {
    if brew list tomcat &>/dev/null; then
        echo "Tomcat is already installed."
    else
        echo 'We are now going to install tomcat, the java web server we will use for this course'
        brew install tomcat
    fi
}

install-maven() {
    if command -v mvn &>/dev/null; then
        echo "Maven is already installed."
    else
        echo 'We will now install maven, a build tool and dependency manager for java'
        brew install maven
    fi
}

install-brew() {
    if command -v brew &>/dev/null; then
        echo "Homebrew is already installed."
    else
        echo 'We are now going to install homebrew, a package manager for OSX.'
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if [[ "$(uname -m)" == "arm64" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>$HOME/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    fi
}

install-visual-studio-code() {
    if command -v code &>/dev/null; then
        echo "Visual Studio Code is already installed."
    else
        echo 'We are now going to install Visual Studio Code.'
        brew install --cask visual-studio-code
    fi
}

setup-ssh-keys() {
    if [ -f "$HOME/.ssh/id_ed25519" ]; then
        echo "SSH key already exists. Ensuring it's properly configured..."
    else
        echo "We're now going to generate an SSH public/private key pair. This key is"
        echo "like a fingerprint for you on your laptop. We'll use this key for connecting"
        echo "to GitHub without having to enter a password."

        echo "We will be putting a comment in the SSH key pair as well. Comments can be"
        echo "used to keep track of different keys on different servers. The comment"
        echo "will be formatted as [your email]."

        read -p $'Enter your github email: ' GITHUBEMAIL
        while [[ ! ($GITHUBEMAIL =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$) ]]; do
            echo "Invalid email"
            echo "Please check and re-enter your email when prompted"
            read -p $'Enter your github email: ' GITHUBEMAIL
        done

        ssh-keygen -t ed25519 -C "$GITHUBEMAIL" -f "$HOME/.ssh/id_ed25519"
    fi

    # Ensure SSH agent is running
    eval "$(ssh-agent -s)"

    # Create or modify the ~/.ssh/config file
    if [ ! -f "$HOME/.ssh/config" ]; then
        touch "$HOME/.ssh/config"
    fi

    cat <<EOF >>$HOME/.ssh/config

Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
EOF

    # Add the SSH key to the ssh-agent and store passphrase in the keychain
    if [[ $(sw_vers -productVersion) > "12.0.0" ]]; then
        ssh-add --apple-use-keychain ~/.ssh/id_ed25519
    else
        ssh-add -K ~/.ssh/id_ed25519
    fi

    # Set up automatic SSH agent startup in shell configuration
    SHELL_CONFIG_FILE="$HOME/.zshrc"
    if [ -f "$HOME/.bash_profile" ]; then
        SHELL_CONFIG_FILE="$HOME/.bash_profile"
    fi

    if ! grep -q "Start SSH agent automatically" "$SHELL_CONFIG_FILE"; then
        cat <<EOF >>"$SHELL_CONFIG_FILE"

# Start SSH agent automatically
if [ -z "\$SSH_AUTH_SOCK" ] ; then
    eval "\$(ssh-agent -s)"
    ssh-add --apple-use-keychain ~/.ssh/id_ed25519 2>/dev/null
fi
EOF
        echo "Added SSH agent autostart configuration to $SHELL_CONFIG_FILE"
    else
        echo "SSH agent autostart configuration already exists in $SHELL_CONFIG_FILE"
    fi

    # Reload shell configuration
    source "$SHELL_CONFIG_FILE"

    echo "SSH key setup complete. Testing connection to GitHub..."
    ssh -T git@github.com

    if [ $? -eq 1 ]; then
        echo "SSH connection to GitHub successful!"
        pbcopy <"$HOME/.ssh/id_ed25519.pub"
        echo "Your public SSH key has been copied to the clipboard."
        echo "Please add it to your GitHub account if you haven't already:"
        echo "1. Go to GitHub.com and log in to your account."
        echo "2. Click your profile photo, then click Settings."
        echo "3. In the user settings sidebar, click SSH and GPG keys."
        echo "4. Click New SSH key or Add SSH key."
        echo "5. In the 'Title' field, add a descriptive label for the new key."
        echo "6. Paste your key into the 'Key' field."
        echo "7. Click Add SSH key."
        echo "Once you've added the key to your GitHub account, you should be able to push without entering your passphrase."
    else
        echo "There was an issue connecting to GitHub. Please check your SSH key configuration."
    fi
}
install-mysql() {
    if command -v mysql &>/dev/null; then
        echo "MySQL is already installed."
    else
        echo 'We are now going to install and configure MySQL, the database management system we will'
        echo 'use for this course.'
        echo 'We will lock down your local MySQL install so that only you can access it'
        echo 'from this computer'

        brew install mysql
        brew link mysql --force

        # start the mysql server
        mysql.server start

        # set a password for the root user, make sure no other users exist, and drop
        # the test db. Set the root password to 'codeup'
        mysql -u root <<-EOF
SET PASSWORD FOR 'root'@'localhost' = 'codeup';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

        mysql.server stop
    fi
}

install-node() {
    if command -v node &>/dev/null; then
        echo "Node.js is already installed."
    else
        echo 'We are now going to install node, which lets us execute javascript outside'
        echo 'of the browser, and gives us access to the node package manager, npm'
        brew install node
    fi

    # Check for Salesforce CLI
    if command -v sf &>/dev/null; then
        echo "Salesforce CLI is already installed."
    else
        # Install Salesforce CLI globally
        echo 'Installing Salesforce CLI globally...'
        npm install -g @salesforce/cli
    fi
}

install-additional-apps() {
    echo 'Installing additional applications...'

    apps=(
        "zoom"
        "slack"
        "drawio"
        "cakebrew"
        "google-chrome" # For Google Meet access
        "protonvpn"
    )

    for app in "${apps[@]}"; do
        if brew list --cask "$app" &>/dev/null; then
            echo "$app is already installed."
        else
            echo "Installing $app..."
            brew install --cask "$app"
        fi
    done

    echo "Google Meet can be accessed through Google Chrome."
}

setup-global-gitignore() {
    if [ -f ~/.gitignore_global ]; then
        echo "Global .gitignore file already exists."
    else
        echo 'Setting up comprehensive global gitignore file...'
        cat <<'EOF' >~/.gitignore_global
# Created by https://www.toptal.com/developers/gitignore/api/macos,visualstudiocode,node,xcode,java,homebrew,maven,salesforce,salesforcedx,ssh,git
# Edit at https://www.toptal.com/developers/gitignore?templates=macos,visualstudiocode,node,xcode,java,homebrew,maven,salesforce,salesforcedx,ssh,git

### Git ###
# Created by git for backups. To disable backups in Git:
# $ git config --global mergetool.keepBackup false
*.orig

# Created by git when using merge tools for conflicts
*.BACKUP.*
*.BASE.*
*.LOCAL.*
*.REMOTE.*
*_BACKUP_*.txt
*_BASE_*.txt
*_LOCAL_*.txt
*_REMOTE_*.txt

### Homebrew ###
Brewfile.lock.json

### Java ###
# Compiled class file
*.class

# Log file
*.log

# BlueJ files
*.ctxt

# Mobile Tools for Java (J2ME)
.mtj.tmp/

# Package Files #
*.jar
*.war
*.nar
*.ear
*.zip
*.tar.gz
*.rar

# virtual machine crash logs, see http://www.java.com/en/download/help/error_hotspot.xml
hs_err_pid*
replay_pid*

### macOS ###
# General
.DS_Store
.AppleDouble
.LSOverride

# Icon must end with two \r
Icon


# Thumbnails
._*

# Files that might appear in the root of a volume
.DocumentRevisions-V100
.fseventsd
.Spotlight-V100
.TemporaryItems
.Trashes
.VolumeIcon.icns
.com.apple.timemachine.donotpresent

# Directories potentially created on remote AFP share
.AppleDB
.AppleDesktop
Network Trash Folder
Temporary Items
.apdisk

### macOS Patch ###
# iCloud generated files
*.icloud

### Maven ###
target/
pom.xml.tag
pom.xml.releaseBackup
pom.xml.versionsBackup
pom.xml.next
release.properties
dependency-reduced-pom.xml
buildNumber.properties
.mvn/timing.properties
# https://github.com/takari/maven-wrapper#usage-without-binary-jar
.mvn/wrapper/maven-wrapper.jar

# Eclipse m2e generated files
# Eclipse Core
.project
# JDT-specific (Eclipse Java Development Tools)
.classpath

### Node ###
# Logs
logs
npm-debug.log*
yarn-debug.log*
yarn-error.log*
lerna-debug.log*
.pnpm-debug.log*

# Diagnostic reports (https://nodejs.org/api/report.html)
report.[0-9]*.[0-9]*.[0-9]*.[0-9]*.json

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Directory for instrumented libs generated by jscoverage/JSCover
lib-cov

# Coverage directory used by tools like istanbul
coverage
*.lcov

# nyc test coverage
.nyc_output

# Grunt intermediate storage (https://gruntjs.com/creating-plugins#storing-task-files)
.grunt

# Bower dependency directory (https://bower.io/)
bower_components

# node-waf configuration
.lock-wscript

# Compiled binary addons (https://nodejs.org/api/addons.html)
build/Release

# Dependency directories
node_modules/
jspm_packages/

# Snowpack dependency directory (https://snowpack.dev/)
web_modules/

# TypeScript cache
*.tsbuildinfo

# Optional npm cache directory
.npm

# Optional eslint cache
.eslintcache

# Optional stylelint cache
.stylelintcache

# Microbundle cache
.rpt2_cache/
.rts2_cache_cjs/
.rts2_cache_es/
.rts2_cache_umd/

# Optional REPL history
.node_repl_history

# Output of 'npm pack'
*.tgz

# Yarn Integrity file
.yarn-integrity

# dotenv environment variable files
.env
.env.development.local
.env.test.local
.env.production.local
.env.local

# parcel-bundler cache (https://parceljs.org/)
.cache
.parcel-cache

# Next.js build output
.next
out

# Nuxt.js build / generate output
.nuxt
dist

# Gatsby files
.cache/
# Comment in the public line in if your project uses Gatsby and not Next.js
# https://nextjs.org/blog/next-9-1#public-directory-support
# public

# vuepress build output
.vuepress/dist

# vuepress v2.x temp and cache directory
.temp

# Docusaurus cache and generated files
.docusaurus

# Serverless directories
.serverless/

# FuseBox cache
.fusebox/

# DynamoDB Local files
.dynamodb/

# TernJS port file
.tern-port

# Stores VSCode versions used for testing VSCode extensions
.vscode-test

# yarn v2
.yarn/cache
.yarn/unplugged
.yarn/build-state.yml
.yarn/install-state.gz
.pnp.*

### Node Patch ###
# Serverless Webpack directories
.webpack/

# Optional stylelint cache

# SvelteKit build / generate output
.svelte-kit

### Salesforce ###
# GitIgnore for Salesforce Projects
# Project Settings and MetaData
.settings/
.metadata
build.properties
config

# Apex Log as optional
apex-scripts/log

# Eclipse specific
salesforce.schema
Referenced Packages
bin/
tmp/
config/
*.tmp
*.bak
local.properties
.settings
.loadpath
*.cache

# Illuminated Cloud (IntelliJ IDEA)
IlluminatedCloud
.idea
*.iml

# Mavensmate
*.sublime-project
*.sublime-settings
*.sublime-workspace
mm.log

# Haoide SublimeText
.config
.deploy
.history

# OSX-specific exclusions
.[dD][sS]_[sS]tore

# The Welkin Suite specific
**/.localHistory

*.sfuo

TestCache.xml

TestsResultsCache.xml

### SalesforceDX ###
# GitIgnore for Salesforce Projects
# Project Settings and MetaData

# Apex Log as optional

# Eclipse specific

# Illuminated Cloud (IntelliJ IDEA)

# Mavensmate

# Haoide SublimeText

# OSX-specific exclusions

# The Welkin Suite specific

### SalesforceDX Patch ###
.sfdx

### SSH ###
**/.ssh/id_*
**/.ssh/*_id_*
**/.ssh/known_hosts

### VisualStudioCode ###
.vscode/*
!.vscode/settings.json
!.vscode/tasks.json
!.vscode/launch.json
!.vscode/extensions.json
!.vscode/*.code-snippets

# Local History for Visual Studio Code
.history/

# Built Visual Studio Code Extensions
*.vsix

### VisualStudioCode Patch ###
# Ignore all local history of files
.ionide

### Xcode ###
## User settings
xcuserdata/

## Xcode 8 and earlier
*.xcscmblueprint
*.xccheckout

### Xcode Patch ###
*.xcodeproj/*
!*.xcodeproj/project.pbxproj
!*.xcodeproj/xcshareddata/
!*.xcodeproj/project.xcworkspace/
!*.xcworkspace/contents.xcworkspacedata
/*.gcno
**/xcshareddata/WorkspaceSettings.xcsettings

# End of https://www.toptal.com/developers/gitignore/api/macos,visualstudiocode,node,xcode,java,homebrew,maven,salesforce,salesforcedx,ssh,git
EOF

        git config --global core.excludesfile ~/.gitignore_global
        echo 'Global .gitignore file has been set up with comprehensive rules.'
    fi
}

script-results() {
    echo "🔍 Checking installed tools..."

    tools=(
        "brew:Homebrew"
        "node:Node.js"
        "java:Java"
        "mvn:Maven"
        "catalina:Tomcat"
        "mysql:MySQL"
        "code:Visual Studio Code"
        "sf:Salesforce CLI"
        "zoom:Zoom"
        "slack:Slack"
        "drawio:Draw.io"
        "cakebrew:CakeBrew"
        "google-chrome:Google Chrome"
        "protonvpn:ProtonVPN"
    )

    installed=()
    not_installed=()

    for tool in "${tools[@]}"; do
        IFS=":" read -r command name <<<"$tool"
        if command -v $command >/dev/null 2>&1 || brew list --cask $command >/dev/null 2>&1; then
            installed+=("$name")
        else
            not_installed+=("$name")
        fi
    done

    echo "✅ Successfully installed or already present:"
    printf "   %s\n" "${installed[@]}"

    if [ ${#not_installed[@]} -eq 0 ]; then
        echo "🎉 Great job! All tools are present and accounted for!"
    else
        echo "❗ The following tools were not found:"
        printf "   %s\n" "${not_installed[@]}"
        echo "You might want to install these manually or check your system PATH."
    fi

    echo "
💡 Pro Tip: Remember to keep your global .gitignore file updated!
   Visit https://www.toptal.com/developers/gitignore for the latest recommendations.
    "
}

setup() {
    echo '🚀 Welcome to the Development Environment Setup Script!'
    echo 'We will check for and install (if necessary) the following tools:'
    echo '  - Xcode Command Line Tools   - Homebrew'
    echo '  - Java 17                    - Maven'
    echo '  - Tomcat                     - MySQL'
    echo '  - Node.js (includes npm)     - Visual Studio Code'
    echo '  - Salesforce CLI'
    echo '  - SSH Keys (for GitHub)'
    echo '  - Additional apps: Zoom, Slack, Draw.io, CakeBrew, Google Chrome (for Google Meet), ProtonVPN'
    echo
    echo 'We will also set up a comprehensive global .gitignore file.'
    echo
    echo '*Note*: If any of these tools are already installed, we will not reinstall them.'
    echo
    echo 'During this process, you may be asked for your password several times.'
    echo 'This is the password you use to log into your computer.'
    echo 'When you type it in, you will not see any output in the terminal. This is normal.'
    echo
    wait-to-continue

    install-xcode
    install-brew
    setup-ssh-keys
    install-java
    install-maven
    install-tomcat
    install-mysql
    install-visual-studio-code
    install-node
    install-additional-apps # Add this line to call the new function
    setup-global-gitignore

    if git config --global core.editor >/dev/null; then
        echo 'It looks like you already have a preferred editor setup for git.'
        echo 'We will not modify this.'
    else
        echo 'Setting default git editor to nano...'
        git config --global core.editor nano
    fi

    echo "🎊 Setup complete! Your development environment is ready to go!"
    echo "🌟 Happy coding! Remember to keep your tools updated regularly."

    script-results

}

# Run the setup
setup
