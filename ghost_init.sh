#!/bin/bash

### This script will help us not have to update our AMI all the time.  During the CloudFormation deployment this script will be dropped into /home/ec2-user and a cron job will be laoded into the root users crontab to run this script on startup.  When this script runs it will check what version was installed during the deployment and compare it to the current version 

## Variables

MY_PATH="/home/ec2-user/ghost-init.sh"
GHOST_DIR="/var/www/ghost"
INSTALLED_VERSION=$(cat $GHOST_DIR/package.json | grep version | sed 's/\"//g' | sed 's/version//' | sed 's/://' | sed 's/,//' | sed 's/ //g')
CURRENT_VERSION=$(curl -sL -w "%{url_effective}" "https://ghost.org/zip/ghost-latest.zip" -o /dev/null | sed 's/https:\/\/en.ghost.org\/archives\/ghost-//' | sed 's/.zip//')

## Functions

function log {
    echo "[Ghost Init] - $*" | logger
}

# Check and see if this instance is running the current version.  If it is exit.
log "The installed version of Ghost is $INSTALLED_VERSION and the current version of Ghost is $CURRENT_VERSION"
if [[ "$INSTALLED_VERSION" == "$CURRENT_VERSION" ]]; then
    log "This instance is already running the latest version of Ghost, $INSTALLED_VERSION"
    sendPage "PROBLEM" "Elastic Cache instance $MEMCACHE_INSTANCE is not reachable!"
    exit 0
fi

# Stop Ghost and download and install the new version

pm2 kill
rm -rf $GHOST_DIR/*
cd /var/www/ 
curl -L -O https://ghost.org/zip/ghost-latest.zip
unzip -d ghost ghost-latest.zip  
cd ghost
cp $GHOST_DIR/config.example.js $GHOST_DIR/config.js
sed -i -e 's/mail: {},/mail: {\\\n\t    transport: \\x27SMTP\\x27,\\\n\t    options: {\\\n\t        service: \\x27sendmail\\x27,\\\n\t    }\\\n\t},/' /var/www/ghost/config.js
sudo npm install --production

sudo -u ghost NODE_ENV=production /usr/local/bin/pm2 start index.js --name ghost
sudo -u ghost /usr/local/bin/pm2 dump

# Clean up the cronjob that ran this script
crontab -e -

# Delete myself
rm -f $MY_PATH
