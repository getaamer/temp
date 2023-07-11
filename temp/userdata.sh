#!/bin/bash
echo "*** Installing awscli2 ***"
sudo apt update
sudo apt upgrade -y
sudo apt install awscli -y
echo "alias k=kubectl">>/home/ubuntu/.bashrc
echo "alias tf=terraform">>/home/ubuntu/.bashrc
sudo perl -pi -e 's/^#?Port 22$/Port 7777/' /etc/ssh/sshd_config
sudo service sshd restart || service ssh restart
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-00e74c2b55d52d73d.efs.ap-south-2.amazonaws.com:/ efs
echo "*** Completed Installing awscli2 ***"