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

echo "${GREEN}Choose a PHP version${NC}"

# site configs in nginx control version (via fpm sockets)

# switch cli
# sudo update-alternatives --set php /usr/bin/php7.1 > /dev/null


PS3='Please select a PHP version: '
options=(`ls -b /usr/bin/php*|grep php[0-9]\.[0-9]` "Quit")

select opt in "${options[@]}"
do
    case $opt in
        "/usr/bin/php5.6")
            echo "Override specific things: You didn't install ${opt} yet"
	    break
            ;;
        "Quit")
            break
            ;;
        *)
            echo "you chose choice $REPLY which is $opt"
 	    sudo update-alternatives --set php $opt > /dev/null
	    echo "CLI PHP Set to $opt"
	    break;;
    esac
done

