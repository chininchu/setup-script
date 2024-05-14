#!/bin/bash

# TODO: brew cask install google-chrome

# Setup script for codeup student's laptops
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
# 8. setup a global gitignore file and set the default commit editor to nano

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
	  brew install openjdk@17
	  brew link openjdk@17
}

install-tomcat(){
    echo 'We are now going to install tomcat, the java web server we will use for this course'
    brew install tomcat@9
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

install-visual-studio(){
  echo 'We are now going to install Visual-Studio IDE.'
  # brew install --cask intellij-idea
  brew install --cask visual-studio-code
}

setup-ssh-keys(){
    echo "We're now going to generate an SSH public/private key pair. This key is"
    echo "like a fingerprint for you on your laptop. We'll use this key for connecting"
    echo "to GitHub without having to enter a password."

    echo "We will be putting a comment in the SSH key pair as well. Comments can be"
    echo "used to keep track of different keys on different servers. The comment"
    echo "will be formatted as [your name]@codeup."

    echo "Please enter your name"
    echo "Example: Casey Edwards"

    read -p $'Enter your name: ' USERSNAME
    read -p $'Enter the your github email: ' GITHUBEMAIL
      while [[ ! ($GITHUBEMAIL =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$) ]];
        do
        echo "Invalid email"
        echo "Please check and re-enter your email when prompted"
        read -p $'Enter the your github email: ' GITHUBEMAIL
    done

    git config --global user.name "$USERSNAME"
    git config --global user.email $GITHUBEMAIL

    ssh-keygen -t ed25519 -C "$USERSNAME@codeup" -f "$HOME/.ssh/id_ed25519"
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
    echo 'We are now going to install and configure MySQL, the database managment system we will'
        echo 'use for this course.'
        echo 'We will lock down your local MySQL install so that only you can only access it'
        echo 'from this computer'

        brew install mysql@8.0
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
}

script-results(){

HASERRORS=false
BREWHADERRORS=false
NODEHADERRORS=false
JAVAHADERRORS=false
MAVENHADERRORS=false
TOMCATHADERRORS=false
MYSQLHADERRORS=false

tput setaf 1
command -v brew >/dev/null 2>&1 || { BREWHADERRORS=true; HASERRORS=true; }
command -v node >/dev/null 2>&1 || { NODEHADERRORS=true; HASERRORS=true; }
command -v java >/dev/null 2>&1 || { JAVAHADERRORS=true; HASERRORS=true; }
command -v mvn >/dev/null 2>&1 || { MAVENHADERRORS=true; HASERRORS=true; }
brew list tomcat@9 &> /dev/null || { TOMCATHADERRORS=true; HASERRORS=true; }
command -v mysql >/dev/null 2>&1 || { MYSQLHADERRORS=true; HASERRORS=true; }
tput sgr0

if [ "$HASERRORS" = false ]; then
    tput setaf 2
    echo "All services were installed successfully."
    tput sgr0
else
  tput setaf 3
  echo "Not all services were installed."
  echo "Results are below"
  tput sgr0
  if [ "$BREWHADERRORS" = false ]; then
    tput setaf 2
    echo "BREW was installed successfully."
    tput sgr0
  else
    tput setaf 1
    echo "BREW was not able to be installed. Installation page can be found here https://brew.sh"
    tput sgr0
  fi
  if [ "$NODEHADERRORS" = false ]; then
    tput setaf 2
    echo "NODE was installed successfully."
    tput sgr0
  else
    tput setaf 1
    echo "NODE was not able to be installed. Installation page can be found here https://formulae.brew.sh/formula/node#default"
    tput sgr0
  fi
  if [ "$JAVAHADERRORS" = false ]; then
    tput setaf 2
    echo "JAVA was installed successfully."
    tput sgr0
  else
    tput setaf 1
    echo "JAVA was not able to be installed. Installation page can be found here https://formulae.brew.sh/formula/openjdk@17#default"
    tput sgr0
  fi
  if [ "$MAVENHADERRORS" = false ]; then
    tput setaf 2
    echo "MAVEN was installed successfully."
    tput sgr0
  else
    tput setaf 1
    echo "MAVEN was not able to be installed. Installation page can be found here https://formulae.brew.sh/formula/maven#default"
    tput sgr0
  fi
  if [ "$TOMCATHADERRORS" = false ]; then
    tput setaf 2
    echo "TOMCAT-9 was installed successfully."
    tput sgr0
  else
    tput setaf 1
    echo "TOMCAT-9 was not able to be installed. Installation page can be found here https://formulae.brew.sh/formula/tomcat@9#default"
    tput sgr0
  fi
  if [ "$MYSQLHADERRORS" = false ]; then
    tput setaf 2
    echo "MYSQL-8 was installed successfully."
    tput sgr0
  else
    tput setaf 1
    echo "MYSQL-8 was not able to be installed. Installation page can be found here https://formulae.brew.sh/formula/mysql#default"
    tput sgr0
  fi
fi


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
	echo '  - node          - Visual-Studio'

	echo '*Note*: if you have already setup any of the above on your computer, this script will _not_'
	echo '        attempt to reinstall them, please talk to an instructor to ensure everything'
	echo '        is configured properly'
	echo ''
	echo 'During this process you may be asked for your password several times. This is the password'
	echo 'you use to log into your computer. When you type it in, you will not see any output in the'
	echo 'terminal, this is normal.'

	# check for xcode, brew, and ssh keys and run the relevant installer functions
	# if they do not exist
	xcode-select --print-path >/dev/null 2>&1 || install-xcode
	which brew >/dev/null 2>&1 || install-brew
	[ -f "$HOME/.ssh/id_rsa" ] || setup-ssh-keys

	# check if java was installed with brew cask if not install it
	brew list java || install-java
	# check for tomcat, maven, and mysql
	which mvn >/dev/null || install-maven
	which catalina >/dev/null || install-tomcat
	which mysql >/dev/null || install-mysql
	# which intellij >/dev/null || install-intellij

  which code >/dev/null 2>&1 || install-visual-studio

	# and lastly, node
	which node >/dev/null || install-node

	# setup the global gitignore file
	if git config --global -l | grep core.excludesfile >/dev/null ; then
		echo 'It looks like you already have a global gitignore file setup (core.excludesfile).'
		echo 'We will not modify it, but make sure you have the following values in it:'
		echo
		echo '	.DS_Store'
		echo '	.idea'
		echo '	*.iml'
		echo
	else
		echo 'Setting up global gitignore file...'
		{
			echo '.DS_Store'
			echo '.idea'
			echo '*.iml'
		} >> ~/.gitignore_global
		git config --global core.excludesfile ~/.gitignore_global
	fi
	# set the default git editor to nano
	if git config --global core.editor >/dev/null ; then
		echo 'It looks like you already have a preferred editor setup for git'
		echo 'We will not modify this.'
	else
		echo 'Setting default git editor to nano...'
		git config --global core.editor nano
	fi

	set-git-config

	echo "Ok! We've gotten everything setup and you should be ready to go!"
	echo "Good luck in class!"
	echo "     _____         _____           _                  _ "
	echo "    |  __ \\       /  __ \\         | |                | |"
	echo "    | |  \\/ ___   | /  \\/ ___   __| | ___ _   _ _ __ | |"
	echo "    | | __ / _ \\  | |    / _ \\ / _  |/ _ \\ | | | '_ \\| |"
	echo "    | |_\\ \\ (_) | | \\__/\\ (_) | (_| |  __/ |_| | |_) |_|"
	echo "     \\____/\\___/   \\____/\\___/ \\__,_|\\___|\\__,_| .__/(_)"
	echo "                                               | |      "
	echo "                                               |_|      "

	script-results
}



# delay script execution until the entire file is transferred
setup
