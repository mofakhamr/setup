#!/bin/bash

# delete test
#  sudo rm /etc/nginx/sites-enabled/test /etc/nginx/sites-available/test /etc/php/7.3/fpm/pool.d/test.conf

# Setup colours.
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PURPLE='\033[1;35m'
DIM='\e[2m'
NC='\033[0m'

# Ensure root available.
if [ "$UID" -ne 0 ]; then
  echo -e "${YELLOW}** Some commands require root privileges **${NC}"
fi
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

# Only run on ubuntu 19.10.
if grep -q "Ubuntu 19.04" /etc/os-release
then
  echo -e "Ubuntu 19.04 ${GREEN}found${NC}, continuing...\n"
else
  echo -e "Sorry ${RED}you are not running Ubuntu 19.04${NC}, I will continue but at your own risk!\n"
#  exit 1;
fi


echo -e "${PURPLE}Configuring NGINX${NC}"
echo ""
echo -e "${YELLOW}Choose a site name, it cannot contain spaces or hyphens${NC}"
read sitename
if [ -f "/etc/nginx/sites-enabled/${sitename}" ]; then
  echo -e "${RED}Sorry, /etc/nginx/sites-available/${sitename} exists already${NC}"
  exit 1;
fi

echo -e "${YELLOW}Select a PHP version for the site${NC}"
PS3="Choose: "
options=(`ls -b /usr/bin/php*|grep -o [0-9]\.[0-9]` "Quit")
select phpver in "${options[@]}"
do
  echo -e ""
  break
done

echo -e "${YELLOW}Enter a folder to locate the files${NC}"
read -p "[/var/www/${sitename}]" destination
destination=${destination:-"/var/www/${sitename}"}
if [ ! -d "${destination}" ]; then
  echo -e "${RED}Folder ${destination} doesn't exist${NC}"
  echo -e "${YELLOW}Shall I create the folder ${destination}? [y N]${NC}"
  read create
  if [ "$create" != "${create#[Yy]}" ]; then
    mkdir -p ${destination}
    echo '<?php phpinfo();' > "${destination}/index.php"
  fi
fi

#
# TODO
#
# A LOT OF CHECKS !!!
#

echo -e "${YELLOW}Would you like to create the following site definition:${NC}"
echo -e "${NC}'${sitename}' using PHP ${phpver} in ${destination} ? ${NC} [y N]"
read confirm
if [ "$confirm" != "${confirm#[Yy]}" ]; then
  # Configure nginx site definition
  echo "Configuring nginx site definition"
  sudo cp ./configs/nginx.txt /etc/nginx/sites-available/${sitename}
  if ! [ -e /etc/nginx/sites-enabled/${sitename} ]; then
    sudo ln -s /etc/nginx/sites-available/${sitename} /etc/nginx/sites-enabled/${sitename}
  fi
  # using forward slashes in variables requires a different escape char!
  sudo sed -i "s@DESTINATION@${destination}@g" /etc/nginx/sites-available/${sitename}
  sudo sed -i "s/SITENAME/${sitename}/g" /etc/nginx/sites-available/${sitename}
  sudo sed -i "s/PHPVER/${phpver}/g" /etc/nginx/sites-available/${sitename}
  sudo service nginx restart

  # Configure FPM pool
  echo "Configuring FPM pool"
  sudo cp /etc/php/${phpver}/fpm/pool.d/www.conf /etc/php/${phpver}/fpm/pool.d/${sitename}.conf
  sudo sed -i "s/^\[www\]/\[${sitename}\]/g" /etc/php/${phpver}/fpm/pool.d/${sitename}.conf
  sudo sed -i "s/php${phpver}-fpm.sock/php${phpver}-fpm-${sitename}.sock/g" /etc/php/${phpver}/fpm/pool.d/${sitename}.conf
  sudo service php${phpver}-fpm restart
fi

