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

wait-to-continue(){
    echo
    echo 'Press Enter to continue or Ctrl-C to exit'
    read -r
}

install-xcode(){
    echo "We need to install some commandline tools for Xcode. When you press 'Enter',"
    echo "a dialog will pop up with several options. Click the 'Install' button and wait."
    echo "Once the process completes, come back here and we will proceed with the next step."

    xcode-select --install 2>&1

    # wait for xcode...
    while sleep 1; do
        xcode-select --print-path >/dev/null 2>&1 && break
    done

    echo
}

install-java(){
    echo 'We are now going to use homebrew to install java. While your mac comes'
    echo 'with a version of java, it may not be the most recent version, and we want'
    echo 'to make sure everyone is on the same version.'
    # Using this install because it is recommended by Salesforce for dev environment 
    brew install --cask temurin@17
}

install-tomcat(){
    echo 'We are now going to install tomcat, the java web server we will use for this course'
    brew install tomcat
}

install-maven(){
    echo 'We will now install maven, a build tool and dependency manager for java'
    brew install maven
}

install-brew(){
    echo 'We are now going to install homebrew, a package manager for OSX.'
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ "$(uname -m)" == "arm64" ]]; then
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $HOME/.zprofile
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
}

install-visual-studio-code(){
  echo 'We are now going to install Visual Studio Code.'
  brew install --cask visual-studio-code
}

setup-ssh-keys(){
    echo "We're now going to generate an SSH public/private key pair. This key is"
    echo "like a fingerprint for you on your laptop. We'll use this key for connecting"
    echo "to GitHub without having to enter a password."

    echo "We will be putting a comment in the SSH key pair as well. Comments can be"
    echo "used to keep track of different keys on different servers. The comment"
    echo "will be formatted as [your name]."

    echo "Please enter your name"
    echo "Example: Casey Edwards"

    read -p $'Enter your name: ' USERSNAME
    read -p $'Enter your github email: ' GITHUBEMAIL
      while [[ ! ($GITHUBEMAIL =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$) ]];
        do
        echo "Invalid email"
        echo "Please check and re-enter your email when prompted"
        read -p $'Enter your github email: ' GITHUBEMAIL
    done

    git config --global user.name "$USERSNAME"
    git config --global user.email $GITHUBEMAIL

    ssh-keygen -t ed25519 -C "$USERSNAME" -f "$HOME/.ssh/id_ed25519"
    pbcopy < "$HOME/.ssh/id_ed25519.pub"
    
    echo "We've copied your ssh key to the clipboard for you. Now, we are going to take you"
    echo "to the GitHub website where you will add it as one of your keys by clicking the"
    echo '"New SSH key" button, giving the key a title (for example: Macbook-Pro), and'
    echo 'pasting the key into the "key" textarea.'
    wait-to-continue
    open https://github.com/settings/ssh

    echo 'Once you have done all of the above, click the big green "Add SSH key" button'
    echo 'then come back here.'
    wait-to-continue
}

install-mysql(){
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
}

install-node() {
    echo 'We are now going to install node, which lets us execute javascript outside'
    echo 'of the browser, and gives us access to the node package manager, npm'
    brew install node
    
    # Install Salesforce CLI globally
    echo 'Installing Salesforce CLI globally...'
    npm install -g @salesforce/cli
}

setup-global-gitignore() {
    echo 'Setting up comprehensive global gitignore file...'
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
    echo 'Global .gitignore file has been set up with comprehensive rules.'
}

script-results(){
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

    echo "✅ Successfully installed:"
    printf "   %s\n" "${installed[@]}"

    if [ ${#not_installed[@]} -eq 0 ]; then
        echo "🎉 Great job! All tools are present and accounted for!"
    else
        echo "❗ The following tools were not installed or not found:"
        printf "   %s\n" "${not_installed[@]}"
        echo "You might want to install these manually or re-run the script."
    fi



   echo "
💡 Pro Tip: Remember to set up your global .gitignore file!
   Visit https://www.toptal.com/developers/gitignore for a great starting point.
    "
}

setup() {
    echo 'We are going to check if xcode and brew are installed, and if you have ssh keys setup.'
    echo 'We will then setup our java development environment, including installing MySQL,'
    echo 'and a mild bit of git configuration.'
    echo ''
    echo 'All together we will be installing: '
    echo '  - xcode tools   - brew'
    echo '  - java 17       - maven'
    echo '  - tomcat 9      - mysql'
    echo '  - node.js (includes npm)  - Visual Studio Code'
    echo '  - Salesforce CLI'

    echo '*Note*: if you have already setup any of the above on your computer, this script will _not_'
    echo '        attempt to reinstall.'
    echo ''
    echo 'During this process you may be asked for your password several times. This is the password'
    echo 'you use to log into your computer. When you type it in, you will not see any output in the'
    echo 'terminal, this is normal.'

    which brew >/dev/null 2>&1 || install-brew
    [ -f "$HOME/.ssh/id_rsa" ] || setup-ssh-keys

    brew list java || install-java
    which mvn >/dev/null || install-maven
    which catalina >/dev/null || install-tomcat
    which mysql >/dev/null || install-mysql

    which code >/dev/null 2>&1 || install-visual-studio-code

    which node >/dev/null || install-node

    setup-global-gitignore

    if git config --global core.editor >/dev/null ; then
        echo 'It looks like you already have a preferred editor setup for git'
        echo 'We will not modify this.'
    else
        echo 'Setting default git editor to nano...'
        git config --global core.editor nano
    fi

    echo "🎊 Setup complete! You're ready to start coding!"
    echo "🌟 Good luck on your development journey!"

    script-results
}

# Run the setup
setup