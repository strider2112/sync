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
	ssh_args=$(set sftp:connect-program "ssh -a -x -i $ssh_key")
else
	ssh_args=$(set sftp:connect-program "ssh -a -x")
fi

# Remote download finished location, use symlinks on remote server
remote_finished="/remote/path/to/finished/"

# Local location for downloads
local_downloads="/local/path/for/downloads/"

# Touch timestamp file to prevent deleting links that are created while rsync is running
ssh $login@$host touch $remote_finished/.download-timestamp

# If ltfp is not running, start the transfer
if [ -e synctorrent.lock ]
then
	# Kill the ssh-agent
	pkill ssh-agent
	echo "Synctorrent is running already."
	exit 1
else
	# Create file to track if lftp is running
	touch synctorrent.lock
	lftp -p 22 -u $login,$pass sftp://$host << EOF
 	$ssh_args
 	set mirror:use-pget-n 3
	mirror -c -P5 --log=sync.log $remote_finished $local_downloads
	quit
EOF

	# Check if lftp exited without error, if so, remove the symbolic links
	if [ $? != 0 ]; then
    		# Kill the ssh-agent
		if [ "$use_key" = true ]; then
  			pkill ssh-agent
     		fi
       		rm -f synctorrent.lock
      		exit 2
	else
    		printf "\n\nTransfer successful. Deleted following symbolic links:\n\n"
    		ssh $login@$host find $remote_finished \! -newer $remote_finished/.download-timestamp -type l -delete -print
	fi
	
 	# Set permissions for Sonarr / Radarr
	chown -R nobody:users "$local_downloads"
	chmod -R 777 "$local_downloads"
	
	# Kill the ssh-agent
	if [ "$use_key" = true ]; then
 		pkill ssh-agent
	fi

	rm -f synctorrent.lock
	exit 0
fi
