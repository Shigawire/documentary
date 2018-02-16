#!/bin/bash

echo "Mounting USB devices..."
mount -t devtmpfs none /dev

echo "Starting subprocesses..."
dumb-init \
  redis-server & \
  sidekiq -c 10 -r /usr/src/app/boot.rb & \
  sidekiq -c 4 -q ocr -r /usr/src/app/boot.rb & \
  SANE_CONFIG_DIR=/usr/local/etc/scanbd /usr/local/sbin/scanbd -f -c /usr/local/etc/scanbd/scanbd.conf
