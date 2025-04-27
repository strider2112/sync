# LFTP seedbox sync script

A simple script to download new content from your seedbox.  It will download content from the server (overwriting any local duplicates) and delete it from the server once the download is complete.

### Requirements:
- LFTP, an awesome command line FTP utility
- A way to run bash scripts (/bin/bash on most Linux Distributions)
- Cron for scheduled automation (default on most Linux Distributions
- A little bit of setup

If you are on windows, that means you'll need something like [cygwin](http://cygwin.com/install.html) or [babun](http://babun.github.io/).

### How to use:
1- Change script values by editing the fields in synctorrent.conf

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

# Local location for downloads
local_downloads="/local/path/for/downloads/"
```

2- Set a cron job to run at desired frequency.