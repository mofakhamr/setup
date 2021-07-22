#!/bin/bash

# Setup colours.
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PURPLE='\033[1;35m'
DIM='\e[2m'
NC='\033[0m'

INSTALL_THE_SITE=1

# Ensure root available.
if [ "$UID" -ne 0 ]; then
  echo -e "${PURPLE}** Some commands require root privileges **${NC}"
fi
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

# Only run on ubuntu 20.04.
BUNTUVER="Ubuntu 20.04"
if grep -q "$BUNTUVER" /etc/os-release
then
  echo -e "$BUNTUVER ${GREEN}found${NC}, continuing...\n"
else
  echo -e "Sorry ${RED}you are not running $BUNTUVER${NC}, quitting.\n"
  exit 1;
fi

isInstalled(){
  app_is_installed=$(command -v "${1}")
  if [ -x "$app_is_installed" ]; then
    echo 1
  else
    echo 0
  fi
}

# Software list, maintains order
declare -a APPS_RUNTIME;
declare -a APPS_NAME;
declare -a APPS_DIALOG_LIST;
APPS_RUNTIME+=("pritunl-client-electron"); APPS_NAME+=("PriTunl");
APPS_RUNTIME+=("zoom"); APPS_NAME+=("Zoom");
APPS_RUNTIME+=("node"); APPS_NAME+=("Node");
APPS_RUNTIME+=("docker"); APPS_NAME+=("Docker");
APPS_RUNTIME+=("aws"); APPS_NAME+=("AwsCli");
APPS_RUNTIME+=("aws-vault"); APPS_NAME+=("AwsVault");
APPS_RUNTIME+=("kubectl"); APPS_NAME+=("KubeCtl");
APPS_RUNTIME+=("gitcrypt"); APPS_NAME+=("GitCrypt");
APPS_RUNTIME+=("pho"); APPS_NAME+=("Php");
APPS_RUNTIME+=("composer"); APPS_NAME+=("Composer");
APPS_RUNTIME+=("drush"); APPS_NAME+=("Drush");
APPS_RUNTIME+=("platform-cli"); APPS_NAME+=("platformSH");
APPS_RUNTIME+=("nginx"); APPS_NAME+=("Nginx");
APPS_RUNTIME+=("mysql"); APPS_NAME+=("MariaDB");
APPS_RUNTIME+=("dbeaver"); APPS_NAME+=("Dbeaver");
# Work out what's already installed and set in APPS_DIALOG_LIST
for id in ${!APPS_RUNTIME[*]}
do
  if [ $(isInstalled "${APPS_RUNTIME[$id]}") = 1 ]; then APPS_DIALOG_LIST+=("${id} ${APPS_NAME[$id]} on"); else APPS_DIALOG_LIST+=("${id} ${APPS_NAME[$id]} off");  fi
done
#printf '%s\n' "${APPS_DIALOG_LIST[@]}"

# Install prereqs
installPreReqs(){
  sudo apt update
  PREREQS_INSTALL=()
  PREREQS_AVAIL=(dialog curl git)
  for i in "${PREREQS_AVAIL[@]}"
  do
    app_is_installed=$(isInstalled "${i}")
    echo "$i app_is_installed:  ${app_is_installed} "
    if [ "$app_is_installed" = 0 ]
    then
      PREREQS_INSTALL+=("${i}")
    fi
  done
  if [ "${PREREQS_INSTALL[*]}" ]
  then
    eval "sudo apt-get install ${PREREQS_INSTALL[*]}"
  fi
}

installAll(){
  APPS_TO_INSTALL=$(dialog --stdout \
  --separate-output \
  --ok-label "Install" \
  --checklist "Select options:" 20 80 10 \
  $(printf '%s\n' "${APPS_DIALOG_LIST[@]}") \
  2>&1)
  #printf '%s\n' "${APPS_TO_INSTALL[@]}"

  # shellcheck disable=SC2068
  for sid in ${APPS_TO_INSTALL[@]}; do
    cmd="install${APPS_NAME[$sid]}"
    echo -e "${GREEN}${cmd}${NC}"
    #eval "${cmd}"
  done
  rm -f /tmp/ERRORS$$
}


# PriTunl VPN
installPriTunl() {
  sudo echo deb https://repo.pritunl.com/stable/apt focal main > /etc/apt/sources.list.d/pritunl.list
  sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com --recv 7568D9BB55FF9E5287D586017AE645C0CF8E292A
  sudo apt-get update
  sudo apt-get install pritunl-client-electron
}

# Slack
installSlack() {
  sudo snap install slack --classic
}

# Zoom
installZoom() {
  wget https://zoom.us/client/latest/zoom_amd64.deb
  sudo apt install ./zoom_amd64.deb
  rm ./zoom_amd64.deb
}

# mariaDB
installMariaDB() {
  sudo apt-get install -y mariadb-server mariadb-client
  echo -e "\n\n${PURPLE}Securing mysql_secure_installation, follow prompts${NC}\n"
  sudo mysql_secure_installation
  echo -e "\n\n${DIM}Setting the mysql root account to use your system root account${NC}\n"
  echo "use mysql; update user set plugin='mysql_native_password' where user='root'; flush privileges;"|sudo mysql -u root -p
  echo -e "${GREEN}More information can be found here: https://github.com/THE-Engineering/cms-the-platform/wiki/Native-LNMP-stack-(Linux-Nginx-Mysql-Php)#mysql${NC}"
}

# PHP
installPhp() {
  sudo apt-get install -y php-xml php-curl php-fpm php-mysql php-mbstring php-redis
  sudo sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/7.4/fpm/php.ini
  sudo systemctl restart php7.4-fpm
}

# Nginx
installNginx() {
  if [ $(isInstalled "php") = 0 ]; then installPhp;  fi
  PHPVER=$(php -r 'echo PHP_VERSION;'|rev|cut -d"." -f2-|rev)

  sudo apt-get install -y nginx
  if [ "${INSTALL_THE_SITE}" -eq "1" ]; then
    echo -e "${PURPLE}Configuring nginx for timeshighereducation.com${NC}"
    # Configure nginx site definition
    sudo cp ./configs/nginx.txt /etc/nginx/sites-available/the
    if ! [ -e /etc/nginx/sites-enabled/the ]; then
      sudo ln -s /etc/nginx/sites-available/the /etc/nginx/sites-enabled/the
    fi
    echo "Configuring web definition"
    sudo service nginx restart
    # Configure FPM pool
    sudo cp /etc/php/7.4/fpm/pool.d/www.conf /etc/php/7.4/fpm/pool.d/the.conf
    sudo sed -i 's/^\[www\]/\[the\]/g' /etc/php/7.4/fpm/pool.d/the.conf
    sudo sed -i 's/php7.1-fpm.sock/php7.4-fpm-the.sock/g' /etc/php/7.4/fpm/pool.d/the.conf
  fi
  # start chrome in localhost
  #if [ -x "google-chrome" ]; then
  #  google-chrome http://localhost
  #fi
}

# Install Platform.sh cli tool
installPsh() {
  if [ $(isInstalled "php") = 0 ]; then installPhp;  fi

  curl -sS https://platform.sh/cli/installer | php;
  source ~/.bashrc
}

# Install Composer
installComposer() {
  if [ $(isInstalled "php") = 0 ]; then installPhp;  fi

  curl -sS https://getcomposer.org/installer | php
  sudo mv composer.phar /usr/local/bin/composer
  sudo chmod +x /usr/local/bin/composer
  echo 'done'
}

# Install Drush
installDrush() {
  # actually installs latest drush 10 - that ok??
  composer global require drush/drush
  export PATH="$HOME/.config/composer/vendor/bin:$PATH"
}

# dbeaver
installDbeaver() {
  wget https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb
  sudo apt install ./dbeaver-ce_latest_amd64.deb
  rm dbeaver-ce_latest_amd64.deb
}

# Git Crypt
installGitCrypt() {
  sudo apt-get install git-crypt -y
}

# Node
installNode() {
  # node 13
  curl -sL https://deb.nodesource.com/setup_13.x | sudo -E bash -
  sudo apt-get install -y nodejs
  sudo apt-get install gcc g++ make
  curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/yarnkey.gpg >/dev/null
  echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
  sudo apt-get update && sudo apt-get install yarn
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.2/install.sh | bash
}

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
}

installKubeCtl(){
  echo -e "${RED}NOT YET READY${NC}";
}
installAwsCli(){
  echo -e "${RED}NOT YET READY${NC}";
}
installAwsVault(){
  echo -e "${RED}NOT YET READY${NC}";
}

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

installPreReqs
installAll

# finalBits


echo -e "${YELLOW}Everything finished${NC}"
echo -e "${YELLOW}Everything finished${NC}"

