#!/bin/sh

# You HAVE TO replace the value with your real ip addr.
export REDIS_HOST=172.17.216.196

yum install -y nfs-utils docker rpcbind git
systemctl start docker

# update codes
# cd ~ && git clone https://github.com/Maslow/nsfw.git
cd /root/nsfw && git pull origin master

# mount nfs from $REDIS_HOST
mount -t nfs $REDIS_HOST:/mnt /mnt -o proto=tcp -o nolock

# run several caffe processor
docker run -d -v /root/nsfw/open_nsfw:/workspace -v /mnt:/mnt -e REDIS_HOST=$REDIS_HOST --name nsfw bvlc/caffe:cpu sh run.sh
docker run -d -v /root/nsfw/open_nsfw:/workspace -v /mnt:/mnt -e REDIS_HOST=$REDIS_HOST --name nsfw1 bvlc/caffe:cpu sh run.sh
docker run -d -v /root/nsfw/open_nsfw:/workspace -v /mnt:/mnt -e REDIS_HOST=$REDIS_HOST --name nsfw2 bvlc/caffe:cpu sh run.sh
docker run -d -v /root/nsfw/open_nsfw:/workspace -v /mnt:/mnt -e REDIS_HOST=$REDIS_HOST --name nsfw3 bvlc/caffe:cpu sh run.sh