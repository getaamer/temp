#cloud-config
preserve_hostname: true

manage_etc_hosts: false

packages:
  - git
  - unzip
  - awscli
  - docker.io
  - unattended-upgrades

package_update: true

package_upgrade: true

groups:
  - docker

system_info:
  default_user:
    groups: [docker]

package_reboot_if_required: true

write_files:
  - path: /root/install.sh
    content: |
      #!/bin/bash
      apt update -y && apt upgrade -y
      apt install -y ansible
      hostnamectl set-hostname ${hostname}
      echo "${hostname}">>/etc/hostname
      ipv4=$(ec2metadata --local-ipv4)
      echo "$ipv4 ${hostname}">>/etc/hosts
      echo "alias k=kubectl">>/home/ubuntu/.bashrc
      echo "alias tf=terraform">>/home/ubuntu/.bashrc
      curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
      sudo apt-get install apt-transport-https --yes
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
      sudo apt-get update
      sudo apt-get install -y helm
      sudo curl -L --output /usr/local/bin/gitlab-runner "https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64"
      sudo chmod +x /usr/local/bin/gitlab-runner
      sudo useradd --comment 'GitLab Runner' --create-home gitlab-runner --shell /bin/bash
      sudo rm /etc/systemd/system/gitlab-runner.service
      sudo gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner
      docker volume create gitlab-runner-config
      docker run -d --name gitlab-runner --restart always -v /var/run/docker.sock:/var/run/docker.sock -v gitlab-runner-config:/etc/gitlab-runner gitlab/gitlab-runner:latest
      sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-00e74c2b55d52d73d.efs.ap-south-2.amazonaws.com:/ efs

runcmd:
  - sudo apt update
  - sudo apt upgrade -y
  - service sshd restart || service ssh restart
  - bash /root/install.sh
  # - gitlab-runner register --non-interactive --url "https://gitlab.com/" --token "glrt-aoejHu2RyBLiSnPsuY73" --executor "docker" --docker-image alpine:latest --description "docker-runner"

power_state:
  mode: reboot
  timeout: 45
  condition: True
