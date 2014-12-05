# CloudFormation Templates

Currently this repository contains the CloudFormation template that is used to make our Ghost AMI (http://www.howtoinstallghost.com/how-to-setup-an-amazon-ec2-instance-to-host-ghost-for-free/).

# Getting Involved

Want to report a bug, request a feature, or have a question?  Create a GitHub issue and we can work with you.  

# What does this CloudFormation Template Do?

1. This template stands up an EC2 instance (parameratized) based off whatever base AMI you like (default Amazon Linux AMI in us-east-1)
1. Installs the latest version of Node
1. Installs the latest version of Ghost
1. Adds a ghost user and starts Ghost with pm2 under the ghost user
1. Downloads and creates a cron job to run the ghost_init.sh script.  This script allows us to avoid having to publish a new AMI every two weeks when Ghost updates come out by checking to see if a newer version of Ghost has been released on the instances first boot.