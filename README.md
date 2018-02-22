# documentary
Raspi + document scanner, built on top of Resin.io.

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
