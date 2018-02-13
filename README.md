# documentary
Raspi + document scanner

## Dependencies
```sanebd``` and ```libsane``` must be installed as package.

install tesseract-ocr tesseract-ocr-deu ruby ghostscript ruby-nokogiri

gem install google_drive thread

https://bugs.launchpad.net/ubuntu/+source/scanbd/+bug/1500095

Compile from scratch:
Follow docs at
https://sourceforge.net/p/scanbd/code/HEAD/tree/trunk/doc/

download source from https://sourceforge.net/p/scanbd/code/HEAD/tree/trunk/

*Note: most of the scripts are not well configured. *
```make install``` installs into /usr/local/sbin/scanbd and /usr/local/etc/scanbd,
so make sure this is reflected in scanbd.conf and the systemd scripts.

## Setup systemd:

https://sourceforge.net/p/scanbd/code/HEAD/tree/trunk/integration/systemd/

## sanebd and sane configuration
sanebd must be configured properly:

sane/sane.dll must hold net, only.
sanebd


Permissions:

chown -R pi:scanner /usr/local/share/documentary
