#!/bin/sh

# Login details for remote server
login="your_user"
pass="your_password"
host="your_server_address"

# Use ssh_key for passwordless access
# Set use_key to "true"
use_key=false
ssh_key="/home/user/.ssh/key"

if [ "$use_key" = true ]; then
	eval "$(ssh-agent -s)"
	ssh-add "$ssh_key"
fi

# Set args if key is used
if [ "$use_key" = true ]; then
	ssh_args="-p 22 -u $login, sftp://$host ssh -a -x -i $ssh_key"
else
	ssh_args="-p 22 -u $login,$pass sftp://$host"
fi

# Remote download finished location, use symlinks on remote server
remote_finished="/remote/path/to/finished/"

# Local location for downloads
local_downloads="/local/path/for/downloads/"

# If ltfp is not running, start the transfer
if [ -e synctorrent.lock ]
then
	echo "Synctorrent is running already."
	exit 1
else
	# Create file to track if lftp is running
	touch synctorrent.lock
	lftp "$ssh_args" << EOF
	set mirror:use-pget-n 3
	mirror -c -P5 --log-sync.log --Remove-source-files $remote_finished $local_downloads
	quit
EOF
	# Set permissions for Sonarr / Radarr
	chown -R nobody:users "$local_downloads"
	chmod -R 777 "$local_downloads"
	
	# Kill the ssh-agent
	pkill ssh-agent
 
	rm -f synctorrent.lock
	exit 0
fi
