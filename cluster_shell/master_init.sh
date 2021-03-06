#!/bin/sh

# installations
yum install -y yum-utils device-mapper-persistent-data \
  lvm2 nfs-utils rpcbind git

yum-config-manager \
    --add-repo \
    https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

yum install -y docker-ce

# !!!export /mnt as nfs folder!!!
# refer to [http://www.linuxidc.com/Linux/2015-05/117378.htm]
echo "/mnt 172.17.*.*(rw,no_root_squash,no_all_squash,sync,anonuid=501,anongid=501)" > /etc/exports
exportfs -r

# apply aliyun docker images hub mirror
mkdir -p /etc/docker
tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://0ndtep40.mirror.aliyuncs.com"]
}
EOF

# ensure that nessesary services are working
systemctl start rpcbind
systemctl start nfs
systemctl start docker

# install nodejs
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install 8
nvm use 8

# download codes
cd ~ && git clone https://github.com/Maslow/nsfw.git

# install the dependencies
cd /root/nsfw/spider && npm install --registry=https://registry.npm.taobao.org

mkdir /mnt/data

# init cluster
docker swarm init > /root/join.sh

# deploy services
cd /root/nsfw/ && docker stack deploy -c docker-stack.yaml nsfw

# import 1st-layer urls
sleep 60s
cd /root/nsfw/spider && node import.js

cat /root/join.sh