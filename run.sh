#!/bin/bash

echo "Mounting USB devices..."
mount -t devtmpfs none /dev

#re-trigger udev to recognize new devices and set udev rules properly
udevadm trigger

echo "Starting subprocesses..."
supervisord -n -c /etc/supervisor/supervisord.conf

#sanebd drops priviliges itself, so no need for gosu here (doesn't work anyways...)

# gosu app bash -c ' \
#   SANE_CONFIG_DIR=/usr/local/etc/scanbd /usr/local/sbin/scanbd -f -c /usr/local/etc/scanbd/scanbd.conf & \
#   redis-server --save "" --appendonly no & \
#   sidekiq -c 10 -r /usr/src/app/boot.rb & \
#   sidekiq -c 4 -q ocr -r /usr/src/app/boot.rb'
#
# dumb-init bash -c 'SANE_CONFIG_DIR=/usr/local/etc/scanbd /usr/local/sbin/scanbd -f -c /usr/local/etc/scanbd/scanbd.conf' & \
# gosu app bash -c 'redis-server --save "" --appendonly no & \
#   sidekiq -c 10 -r /usr/src/app/boot.rb & \
#   sidekiq -c 4 -q ocr -r /usr/src/app/boot.rb'

# cleanup ()
# {
#   kill -s SIGTERM $!
#   exit 0
# }
#
# trap cleanup SIGINT SIGTERM
#
# while [ 1 ]
# do
#   sleep 60 &
#   wait $!
# done
