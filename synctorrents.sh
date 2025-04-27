#!/bin/sh

# Get variables from synctorrents.conf
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$DIR"/synctorrents.conf


# Set args if key is used
if [ "$use_key" = true ]; then	
	ssh_args=$(set sftp:connect-program "ssh -a -x -i $ssh_key")
else
	ssh_args=$(set sftp:connect-program "ssh -a -x")
fi

# If ltfp is not running, start the transfer
if [ -e synctorrent.lock ]
then
	echo "Synctorrent is running already."
	exit 1
else
	# Start ssh-agent
 	if [ "$use_key" = true ]; then
		eval "$(ssh-agent -s)"
		ssh-add "$ssh_key"
	fi

 	# Touch timestamp file to prevent deleting links that are created while rsync is running
	ssh $login@$host touch $remote_finished/.download-timestamp

 	# Create file to track if lftp is running
	touch synctorrent.lock

	# Run lftp
 	lftp -p 22 -u $login,$pass sftp://$host << EOF
 	$ssh_args
 	set mirror:use-pget-n 3
	mirror -L -c -P5 --log=sync.log $remote_finished $local_downloads
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
