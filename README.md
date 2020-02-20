# "setup"
Scripts to setup fresh operating system 

# What happens when I run this
The script runs bash as sudo (you will be prompted to provide admin password for sudo):

https://github.com/mofakhamr/setup/blob/master/setup-1910.sh#L15

Then it auto installs curl and git:

https://github.com/mofakhamr/setup/blob/master/setup-1910.sh#L27

The rest of the script then offers to install various software:

- Pritunl VPN
- Slack
- Zoom
- MySQL MariaDB
- PHP and minimal common modules
- Nginx (also offers to setup a new site with fpm unix socket with one fpm pool)
- Platform.sh CLI
- Composer
- Drush
- DBeaver
- Git-Crypt

The script then offers "final bits" such as:

- setting perms on the /var/www/* dir so you can actually use it.
- Create a DBeaver friendly SSH keypair
- TODO Install XHProf
- TODO Create SSH aliases
- TODO Checkout git repo of site
- TODO Setup Drupal settings file

# Installation

1. Set the script to executable
`chmod +x setup-1910.sh`

2. Execute script
`./setup-1910.sh`

3. Follow instructions and prompts
