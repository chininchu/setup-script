#!/bin/bash

# Comprehensive setup script for MacOS development environment
# ============================================================

set -e  # Exit immediately if a command exits with a non-zero status
trap 'echo "An error occurred. Exiting..."; exit 1' ERR

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a setup.log
}

# Progress spinner
show_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Backup function
backup_configs() {
    log "Backing up configurations..."
    [ -f ~/.gitconfig ] && cp ~/.gitconfig ~/.gitconfig.bak
    [ -f ~/.zshrc ] && cp ~/.zshrc ~/.zshrc.bak
    # Add more backup commands as needed
}

# Cleanup function
cleanup() {
    log "Cleaning up..."
    # Add cleanup commands here
}
trap cleanup EXIT

# Load user configurations
[ -f ~/.setup_config ] && source ~/.setup_config

# Default configurations
JAVA_VERSION=${JAVA_VERSION:-17}
TOMCAT_VERSION=${TOMCAT_VERSION:-9}

wait-to-continue() {
    echo
    echo 'Press Enter to continue or Ctrl-C to exit'
    read -r
}

check_system_requirements() {
    log "Checking system requirements..."
    # Check available disk space
    local available_space=$(df -h / | awk 'NR==2 {print $4}')
    if [[ ${available_space%G} -lt 10 ]]; then
        log "Warning: Less than 10GB of free space available. Some installations may fail."
    fi
    # Add more system checks as needed
}

install-xcode() {
    log "Installing Xcode Command Line Tools..."
    xcode-select --install 2>&1 || true
    while sleep 1; do
        xcode-select --print-path >/dev/null 2>&1 && break
    done
    log "Xcode Command Line Tools installed successfully."
}

install-brew() {
    log "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" &
    show_spinner $!
    if [[ "$(uname -m)" == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $HOME/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    log "Homebrew installed successfully."
}

update_brew() {
    log "Updating Homebrew..."
    brew update && brew upgrade
    log "Homebrew updated successfully."
}

setup-ssh-keys() {
    log "Setting up SSH keys..."
    read -p $'Enter your name: ' USERSNAME
    read -p $'Enter your github email: ' GITHUBEMAIL
    while [[ ! ($GITHUBEMAIL =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$) ]]; do
        echo "Invalid email"
        read -p $'Enter your github email: ' GITHUBEMAIL
    done

    git config --global user.name "$USERSNAME"
    git config --global user.email $GITHUBEMAIL

    ssh-keygen -t ed25519 -C "$USERSNAME" -f "$HOME/.ssh/id_ed25519"
    pbcopy < "$HOME/.ssh/id_ed25519.pub"
    
    log "SSH key generated and copied to clipboard."
    open https://github.com/settings/ssh
    wait-to-continue
}

install-java() {
    log "Installing Java ${JAVA_VERSION}..."
    brew install --cask temurin@${JAVA_VERSION}
    log "Java ${JAVA_VERSION} installed successfully."
}

check_java_version() {
    if java -version 2>&1 | grep -q "version \"${JAVA_VERSION}"; then
        log "Java ${JAVA_VERSION} is already installed."
    else
        log "Java ${JAVA_VERSION} is not installed. Installing..."
        install-java
    fi
}

install-tomcat() {
    log "Installing Tomcat ${TOMCAT_VERSION}..."
    brew install tomcat@${TOMCAT_VERSION}
    log "Tomcat ${TOMCAT_VERSION} installed successfully."
}

install-maven() {
    log "Installing Maven..."
    brew install maven
    log "Maven installed successfully."
}

install-mysql() {
    log "Installing and configuring MySQL..."
    brew install mysql
    brew link mysql --force

    mysql.server start

    mysql -u root <<-EOF
SET PASSWORD FOR 'root'@'localhost' = 'codeup';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

    mysql.server stop
    log "MySQL installed and configured successfully."
}

install-visual-studio-code() {
    log "Installing Visual Studio Code..."
    brew install --cask visual-studio-code
    log "Visual Studio Code installed successfully."
}

install-node() {
    log "Installing Node.js..."
    brew install node
    log "Node.js installed successfully."
    
    log "Installing Salesforce CLI..."
    npm install -g @salesforce/cli
    log "Salesforce CLI installed successfully."
}

setup-global-gitignore() {
    log "Setting up comprehensive global .gitignore file..."
    cat << 'EOF' > ~/.gitignore_global
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
    log "Global .gitignore file has been set up with comprehensive rules."
}

script-results() {
    log "Checking installed tools..."

    tools=(
        "brew:Homebrew"
        "node:Node.js"
        "java:Java"
        "mvn:Maven"
        "catalina:Tomcat"
        "mysql:MySQL"
        "code:Visual Studio Code"
        "sf:Salesforce CLI"
    )

    installed=()
    not_installed=()

    for tool in "${tools[@]}"; do
        IFS=":" read -r command name <<< "$tool"
        if command -v $command >/dev/null 2>&1; then
            installed+=("$name")
        else
            not_installed+=("$name")
        fi
    done

    log "✅ Successfully installed:"
    printf "   %s\n" "${installed[@]}" | tee -a setup.log

    if [ ${#not_installed[@]} -eq 0 ]; then
        log "🎉 Great job! All tools are present and accounted for!"
    else
        log "❗ The following tools were not installed or not found:"
        printf "   %s\n" "${not_installed[@]}" | tee -a setup.log
        log "You might want to install these manually or re-run the script."
    fi

    log "💡 Pro Tip: Remember to set up your global .gitignore file!"
    