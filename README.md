# About this project
This project enhances your hardware document scanner.
Attach it to a Raspberry Pi and get your scans automatically OCR'd and uploaded to Google Drive or sent via E-Mail.

Built on top of Resin.io.

## !Important!
In order to allow device mounts, set a device-specific environment variable `UDEV` to `1`. 
More information: https://www.balena.io/docs/reference/base-images/base-images/#how-the-images-work-at-runtime

## Installation
If you don't already have an account, go to [https://resin.io](https://resin.io) and create one.
Create a new application inside the dashboard and configure a new device (e.g. Raspberry Pi3).

Go to the applications page, note the git remote URL on the top right corner and add the remote to your local repository:
```
git remote add resin ...
```
Then push the code to the resin origin: `git push resin`.

## Scanning workflow
In `scripts/scanbd.conf` particular actions for the scanner's buttons are defined. The sample action (works with the `CANON P-215` device) is:
```
action scan {
        filter = "start"
        desc   = "Canon P-215 button is pressed"
        script = "/usr/src/app/scan.rb"
}
```

`start` is an event emitted by the canon_dr sane backend upon clicking the button on the scanner.
This starts the `scan.rb` file.

## Supported document scanners
The project is specifically tailored to work with the Canon P-215 (**not the P-215 II**) device. While being relatively aged, it delivers good performance at an acceptable price.

In theory, any scanner that is recognized by the Linux-package `sane` should work. However, configuration scripts in the `Dockerfile` and `/scripts` must be changed to fit your device then. This includes the udev-rule, the scanbd configuration and enabling the correct scanner backends in the Dockerfile.

## LCD Display
The included `lcd.rb` controls a HD44780 4x20 LCD, controlled via I2C. [This one](https://www.ebay.de/itm/2004-I2C-Serial-Blau-LCD-Module-5V-20x4-Zeichen-HD44780-f%C3%BCr-Arduino-Raspberry-Pi/281658783936?ssPageName=STRK%3AMEBIDX%3AIT&_trksid=p2057872.m2749.l2649) is tested and found to be well working.

**Note that, in addition, a 3.3V <-> 5V level shifter is required for the Pi!** ([this one](https://www.ebay.de/itm/5x-Pegelwandler-4-Kanal-5V-3-3V-Level-Shifter-bidirektional-I2C-Arduino-Raspb/162352091615?ssPageName=STRK%3AMEBIDX%3AIT&_trksid=p2057872.m2749.l2649)) is working well.

A suitable case to hold display and Pi can be found [here](https://www.ebay.de/itm/20x4-16x2-LCD-case-for-Raspberry-Pi-2-3-model-B-Pi-1-Model-B-Zero-Arduino/122976819365?ssPageName=STRK%3AMEBIDX%3AIT&var=423424123333&_trksid=p2057872.m2749.l2649)

## HTTP post upload
Documents can be uploaded to any `UPLOAD_URL` set via environment variable.
Basic Authentication credentials should be provided as part of the URI (scheme://username:password@hostname:port/path).

## Google Drive upload
If you want upload scanned documents to Google Drive, create a Google Project with OAuth credentials:
https://github.com/gimite/google-drive-ruby/blob/master/doc/authorization.md#command-line

After that, set the following environment variables:

```
GDRIVE_FOLDER_ID
GOOGLE_OAUTH_CLIENT_ID
GOOGLE_OAUTH_CLIENT_SECRET
```

Then go to the Resin.io dashboard, start a local shell into the container and run `./auth.sh`.
This will open an interactive shell guiding you through the OAuth Token exchange process required for GDrive upload.

**This command must only be run once. OAuth credentials are stored in the persistent /data volue**

## Email sending
Set the following environment variables to have the scanned file sent as attachment:
```
EMAIL_ADDRESS
SMTP_HOST
SMTP_USERNAME
SMTP_PASSWORD
```

## Important
The container must mount devices manually. Otherwise, the resin guests do not recognize remounted hardware.
```
mount -t devtmpfs none /dev
```
