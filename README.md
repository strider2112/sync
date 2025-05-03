# LFTP seedbox sync script

A simple script to download new content from your seedbox.  It will download content from the server (overwriting any local duplicates) and delete it from the server once the download is complete.

### Requirements:
- LFTP, an awesome command line FTP utility
- A way to run bash scripts (/bin/bash on most Linux Distributions)
- Cron for scheduled automation (default on most Linux Distributions
- A little bit of setup

If you are on windows, that means you'll need something like [cygwin](http://cygwin.com/install.html) or [babun](http://babun.github.io/).

### How to use:
1: Download the zip/repo and unpack it.

2: Set the main script to run, $```chmod +x ./synctorrents.sh```

3: Change script values by editing the fields in synctorrent.conf

If using SSH-KEY then leave pass="your_password" exactly as-is
```sh
login="your_user"
pass="your_password"
host="your_server_address"
```

If using SSH-KEY for passwordless authentication, set use_key to true and direct path to key.
```sh
use_key=false
ssh_key="/home/user/.ssh/key"
```

Setup remote and local paths
```sh
# Remote download finished location, use symlinks on remote server
remote_finished="/remote/path/to/finished/"

# Local location for downloads, temp is required to make sure no other scripts interfere with download
local_temp="/local/path/to/temp/"
local_downloads="/local/path/for/downloads/"
```

(Optional) Configure the script to change permissions of local downloads folder, this may be required if you have another program or script that needs to access the files with another user/group. to use it, set use_perm to true and adjust the own and mod perm (chown and chmod syntax).
```sh
use_perm=false
own_perm="nobody:users"
mod_perm="644"
```

(Optional) Configure whether to delete remote files or not
```sh
src_del=false
```

(Optional) Log folder location to store run logs
```sh
logfolder="/path/to/ftplogs/"
```

4: Set a cron job to run at desired frequency.
$```crontab -e```

### Exit Codes
Exit 0 = Program completed successfully

Exit 1 = Script already running when it was called again

Exit 2 = Error in Dialog (progress bar), script will print Dialog exit code into stdout

Exit 3 = Error with remote deletion script, script will print ssh exit code into stdout

