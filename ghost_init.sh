#!/bin/bash

# Written by Andy Boutte and David Balderston of howtoinstallghost.com

# To prevent having to create a new AMI every time there is a new release of Ghost we built this process:
## build a new EC2 with CloudFormation
## in the UserData section of CloudFormation this script gets curled from GitHub into /home/ec2-user/ghost_init.sh and a cron entry gets added to the root user to run this script on startup
## after the new EC2 instance is tested it is turned into an AMI and submited to the AWS Marketplac
## when somebody lauches our AMI /home/ec2-user/ghost_init.sh runs, compares the installed version of Ghost to the latest version, and if out of date downloads and installs the latest version.  

## Variables
GHOST_DIR="/var/www/ghost"
INSTALLED_VERSION=$(cat $GHOST_DIR/package.json | grep version | sed 's/\"//g' | sed 's/version//' | sed 's/://' | sed 's/,//' | sed 's/ //g' | tr -d '\r')
CURRENT_VERSION=$(curl -sL -w "%{url_effective}" "https://ghost.org/zip/ghost-latest.zip" -o /dev/null | sed 's/https:\/\/en.ghost.org\/archives\/ghost-//' | sed 's/.zip//')

## Functions
function log {
    echo "[Ghost Init] - $*" >> /var/log/ghost_init.log
}

function cleanup {
	log "Remove the cron from /etc/cron.d/ that ran this script"
	rm /etc/cron.d/ghost_init
	log "Deleting this script"
	rm -- "$0"
}

# Check and see if this instance is running the current version.  If it is exit.
log "The installed version of Ghost is $INSTALLED_VERSION and the current version of Ghost is $CURRENT_VERSION"
if [[ "$INSTALLED_VERSION" == "$CURRENT_VERSION" ]]; then
    log "This instance is already running the latest version of Ghost, $INSTALLED_VERSION"
	cleanup
    exit 0
fi

# Stop Ghost and download and install the new version
pm2 kill
cp $GHOST_DIR/config.js /tmp/
rm -rf $GHOST_DIR/*
cd /var/www/ 
log "Downloading latest version of Ghost"
curl -L -O https://ghost.org/zip/ghost-latest.zip
unzip -d ghost ghost-latest.zip  
rm ghost-latest.zip
cp /tmp/config.js /$GHOST_DIR/
rm /tmp/config.js
cd ghost
log "Running npm install"
/usr/bin/npm install --production
chown -R ghost:ghost /var/www/ghost

log "Starting Ghost using pm2 under the ghost user"
/usr/bin/pm2 start /root/.pm2/ghost.json
/usr/bin/pm2 dump

cleanup