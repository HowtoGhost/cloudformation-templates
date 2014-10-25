#!/bin/bash

### This script will help us not have to update our AMI all the time.  During the CloudFormation deployment this script will be dropped into /home/ec2-user and a cron job will be laoded into the root users crontab to run this script on startup.  When this script runs it will check what version was installed during the deployment and compare it to the current version 

## Variables

MY_PATH="/home/ec2-user/ghost-init.sh"
GHOST_DIR="/var/www/ghost"
INSTALLED_VERSION=$(cat $GHOST_DIR/package.json | grep version | sed 's/\"//g' | sed 's/version//' | sed 's/://' | sed 's/,//' | sed 's/ //g' | tr -d '\r')
CURRENT_VERSION=$(curl -sL -w "%{url_effective}" "https://ghost.org/zip/ghost-latest.zip" -o /dev/null | sed 's/https:\/\/en.ghost.org\/archives\/ghost-//' | sed 's/.zip//')

## Functions

function log {
    echo "[Ghost Init] - $*" | logger
}

# Check and see if this instance is running the current version.  If it is exit.
log "The installed version of Ghost is $INSTALLED_VERSION and the current version of Ghost is $CURRENT_VERSION"
if [[ "$INSTALLED_VERSION" == "$CURRENT_VERSION" ]]; then
    log "This instance is already running the latest version of Ghost, $INSTALLED_VERSION"
    exit 0
fi

# Stop Ghost and download and install the new version

pm2 kill
cp $GHOST_DIR/config.js /tmp/
rm -rf $GHOST_DIR/*
cd /var/www/ 
curl -L -O https://ghost.org/zip/ghost-latest.zip
unzip -d ghost ghost-latest.zip  
rm ghost-latest.zip
cp /tmp/config.js /$GHOST_DIR/
rm /tmp/config.js
cd ghost
cp $GHOST_DIR/config.example.js $GHOST_DIR/config.js
sudo npm install --production
chown -R ghost:ghost /var/www/ghost

sudo /usr/local/bin/pm2 --run-as-user ghost start index.js --name ghost
sudo -u ghost /usr/local/bin/pm2 dump

# Clean up the cronjob that ran this script
crontab -r -u ec2-user

# Delete myself
rm -f $MY_PATH
