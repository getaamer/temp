#!/bin/bash
echo "*** Installing awscli2 ***"
sudo apt update
sudo apt upgrade -y
sudo apt install awscli -y
echo "alias k=kubectl">>/home/ubuntu/.bashrc
echo "alias tf=terraform">>/home/ubuntu/.bashrc
sudo reboot now
echo "*** Completed Installing awscli2 ***"