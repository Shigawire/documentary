# documentary
Raspi + document scanner


# Important
The container must mount devices manually. Otherwise, the resin guests do not recognize remounted hardware.
```
mount -t devtmpfs none /dev
```

## Dependencies
```sanebd``` and ```libsane``` must be installed as package.

libopenjp2-7-dev

libopenjp2.so.7

## sanebd and sane configuration
sanebd must be configured properly:

sane/sane.dll must hold net, only.
sanebd

## Setup
Set the following environment variables:
- `SANE_DEVICE_NAME`
- `GDRIVE_FOLDER_ID`

# script to start:
SANE_CONFIG_DIR=/usr/local/etc/scanbd /usr/local/sbin/scanbd -d2 -f -c /usr/local/etc/scanbd/scanbd.conf
