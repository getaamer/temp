#!/bin/bash
echo "*** Installing awscli2 ***"
sudo apt update
sudo apt upgrade -y
sudo apt install awscli -y
echo "alias k=kubectl">>/home/ubuntu/.bashrc
echo "alias tf=terraform">>/home/ubuntu/.bashrc
perl -pi -e 's/^#?Port 22$/Port 7777/' /etc/ssh/sshd_config
service sshd restart || service ssh restart
echo "*** Completed Installing awscli2 ***"