#!/bin/sh
# Login details for remote server
login="your_user"
pass="your_password"
host="your_server_address"

# Remote download finished location, use symlinks on remote server
remote_finished="/remote/path/to/finished"

# Local location for downloads
local_downloads="/local/path/for/downloads"

# If ltfp is not running, start the transfer
if [ -e synctorrent.lock ]
then
	echo "Synctorrent is running already."
	exit 1
else
	# Create file to track if lftp is running
	touch synctorrent.lock
	lftp -p 22 -u $login,$pass sftp://$host << EOF
	set mirror:use-pget-n 3
	mirror -c -P5 --log=movies-sync.log --Remove-source-files $remote_finished $local_downloads
	quit
EOF
	rm -f synctorrent.lock
	exit 0
fi
