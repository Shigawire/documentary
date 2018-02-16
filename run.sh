#!/bin/bash
#
# echo "This is a idle script (infinite loop) to keep container running."
# echo "Please replace this script."
#
# cleanup ()
# {
#   kill -s SIGTERM $!
#   exit 0
# }

echo "mounting usb devices properly!"
mount -t devtmpfs none /dev

# trap cleanup SIGINT SIGTERM
#
# while [ 1 ]
# do
#   sleep 60 &
#   wait $!
# done

dumb-init \
  sidekiq -c 10 -r /usr/src/app/boot.rb && \
  sidekiq -c 4 -q ocr -r /usr/src/app/boot.rb && \
  SANE_CONFIG_DIR=/usr/local/etc/scanbd /usr/local/sbin/scanbd -f -c /usr/local/etc/scanbd/scanbd.conf
