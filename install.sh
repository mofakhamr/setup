#!/bin/bash

# Setup colours.
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PURPLE='\033[1;35m'
DIM='\e[2m'
NC='\033[0m'

# Ensure root available.
if [ "$UID" -ne 0 ]; then
  echo -e "${PURPLE}** Some commands require root privileges **${NC}"
fi
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

# Only run on ubuntu 19.10.
if grep -q "Ubuntu 19.10" /etc/os-release
then
  echo -e "Ubuntu 19.10 ${GREEN}found${NC}, continuing...\n"
else
  echo -e "Sorry ${RED}you are not running Ubuntu 19.10${NC}, quitting.\n"
  exit 1;
fi

# Install prereqs
sudo apt-get install curl git -y

# Check for $executable, then ask the user to install $name before call $function.
askInstall(){
  is_installed=$(command -v ${1})
  action_verb="install"
  if [ -x "$is_installed" ]; then
    echo -e "${GREEN}${2} already installed${NC}"
    action_verb="reinstall"
  fi
  echo -e "Do you wish to ${PURPLE}${action_verb}${NC} ${YELLOW}${2}?${NC} [y N]"
  read answer
  if [ "$answer" != "${answer#[Yy]}" ]; then
    # Call $function
    echo -e "Installing ${2}..."
    eval $3
  else
   echo -e "${DIM}Skipping $2 installation${NC}\n\n"
  fi
}
# PriTunl VPN
installPriTunl() {
  sudo echo deb http://repo.pritunl.com/stable/apt disco main > /etc/apt/sources.list.d/pritunl.list
  sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com --recv 7568D9BB55FF9E5287D586017AE645C0CF8E292A
  sudo apt-get update
  sudo apt-get install pritunl-client-electron
}
# executable, friendly name, install function
askInstall pritunl-client-electron PriTunl installPriTunl

# Slack
installSlack() {
  sudo snap install slack --classic
}
# executable, friendly name, install function
askInstall slack Slack installSlack

# Zoom
installZoom() {
  wget https://zoom.us/client/latest/zoom_amd64.deb
  sudo apt install ./zoom_amd64.deb
  rm ./zoom_amd64.deb
}
# executable, friendly name, install function
askInstall zoom Zoom installZoom

# mariaDB
installMariaDB() {
  sudo apt-get install mariadb-server mariadb-client
  echo -e "\n\n${PURPLE}Securing mysql_secure_installation, follow prompts${NC}\n"
  sudo mysql_secure_installation
  echo -e "\n\n${DIM}Setting the mysql root account to use your system root account${NC}\n"
  echo "use mysql; update user set plugin='mysql_native_password' where user='root'; flush privileges;"|sudo mysql -u root -p
  echo -e "${GREEN}More information can be found here: https://github.com/THE-Engineering/cms-the-platform/wiki/Native-LNMP-stack-(Linux-Nginx-Mysql-Php)#mysql${NC}"
  sudo usermod -a -G www-data $USER
}
# executable, friendly name, install function
askInstall mysql MariaDB installMariaDB

# PHP
installPhp71() {
  if ! [ -e /etc/apt/sources.list.d/ondrej-ubuntu-php-eoan.list ]; then
    sudo apt-add-repository ppa:ondrej/php
  fi
  sudo apt update
  sudo apt-get install php7.1-xml php7.1-curl php7.1-fpm php7.1-mysql php7.1-mbstring php7.1-redis
  sudo sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/7.1/fpm/php.ini
  sudo systemctl restart php7.1-fpm
}
# executable, friendly name, install function
askInstall71 php7.1 "PHP-7.1" installPhp

# PHP 7.3
installPhp73 () {
  if ! [ -e /etc/apt/sources.list.d/ondrej-ubuntu-php-eoan.list ]; then
    sudo apt-add-repository ppa:ondrej/php
  fi
  sudo apt update
  sudo apt-get install php7.3-xml php7.3-curl php7.3-fpm php7.3-mysql php7.3-mbstring php7.3-redis php7.3-gd
  sudo sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/7.3/fpm/php.ini
  sudo systemctl restart php7.3-fpm
}
askInstall php7.3 "PHP-7.3" installPhp


# Nginx
installNginx() {
  sudo apt-get install nginx
  # start chrome in localhost
  #if [ -x "google-chrome" ]; then
  #  google-chrome http://localhost
  #fi
}
# executable, friendly name, install function
askInstall nginx Nginx installNginx

# Install Platform.sh cli tool
installPsh() {
  curl -sS https://platform.sh/cli/installer | php;
  source ~/.bashrc
}
# executable, friendly name, install function
askInstall platform PlatformSH-cli installPsh

# Install Composer
installComposer() {
  curl -sS https://getcomposer.org/installer | php
  sudo mv composer.phar /usr/local/bin/composer
  sudo chmod +x /usr/local/bin/composer
  echo 'done'
}
# executable, friendly name, install function
askInstall composer Composer installComposer

# Install Drush
installDrush() {
  # actually installs latest drush 10 - that ok??
  composer global require drush/drush
  export PATH="$HOME/.config/composer/vendor/bin:$PATH"
}
# executable, friendly name, install function
askInstall drush Drush installDrush

# dbeaver
installDbeaver() {
  wget https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb
  sudo apt install ./dbeaver-ce_latest_amd64.deb
  rm dbeaver-ce_latest_amd64.deb
}
# executable, friendly name, install function
askInstall dbeaver DBeaver installDbeaver

# Git Crypt
installGitCrypt() {
  sudo apt-get install git-crypt -y
}
# executable, friendly name, install function
askInstall git-crypt GitCrypt installGitCrypt

# Node
installNode() {
  # node 13
  curl -sL https://deb.nodesource.com/setup_13.x | sudo -E bash -
  sudo apt-get install -y nodejs
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.2/install.sh | bash
}
# executable, friendly name, install function
askInstall node Node-and-npm installNode

# Docker
installDocker() {
  sudo apt-get remove docker docker-engine docker.io containerd runc
  sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  # would be nice to verify the key dynamically
  #VERIFY=sudo apt-key fingerprint 0EBFCD88|grep 9DC8 5822 9FC7 DD38 854A E2D8 8D81 803C 0EBF CD88
  # install bionic not eoan
  sudo add-apt-repository  "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
  sudo apt-get update
  sudo apt-get install docker-ce docker-ce-cli containerd.io
  # post install
  sudo groupadd docker
  sudo usermod -aG docker $USER
  newgrp docker
  echo -e "You can now test Docker by running: ${GREEN}docker run hello-world${NC}"
  # install Docker compose
  sudo apt install docker-compose
}
# executable, friendly name, install function
askInstall docker Docker installDocker

# Some final bits
finalBits(){

  echo -e "${YELLOW}Final tweaks consist of${NC}"
  echo " * Set permissions on /var/www to \$USER:www-data"
  echo " * Create a DBeaver friendly SSH keypair"
  echo " * TODO Install XHProf"
  echo " * TODO Create SSH aliases"
  echo " * TODO Checkout git repo of site"
  echo " * TODO Setup Drupal settings file"

  echo -e "Do you wish to ${PURPLE}perform final tweaks?${NC} [y N]"

  read answer
  if [ "$answer" != "${answer#[Yy]}" ]; then

    sudo chown -R $USER:www-data /var/www

    # compatible with dbeaver ssh tunnel
    ssh-keygen -t rsa -b 2048 -m PEM

    # PHP 7 can be rather difficult to install XHProf,
    # for Ubuntu you can follow this:
    # https://github.com/rustjason/xhprof

    # SSH aliases
    # @TODO need git crypt

    # Checkout git repo of site
    cd /var/www
    git clone git@github.com:THE-Engineering/cms-the-platform.git the
    cd /var/www/the
    platform  build

    # Drupal settings file
    # @TODO need git crypt


  else
   echo -e "${DIM}Skipping $2 installation${NC}\n\n"
  fi
}
finalBits


echo -e "${YELLOW}Everything finished${NC}"

