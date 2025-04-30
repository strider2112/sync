#!/bin/bash

# Get variables from synctorrents.conf
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$DIR"/synctorrents.conf

# temporary log setup
templog=$(mktemp -t templog.XXXX)
templogfind=$(mktemp -t templogfind.XXXX)
dateStamp=$(date +"%Y-%m(%b)")
logfile="$logfolder""logfile_""$dateStamp"".log"
tempmail=".tempmail"
numberOfLogFiles=$(($(find "$logfolder" -maxdepth 1 ! -iname ".*" | wc -l) - 1))

# clean out the log folder if there are more than 30 logs
if [ "$numberOfLogFiles" -eq 1 ]; then
        echo "There is $numberOfLogFiles log file"
else
        echo "There are $numberOfLogFiles log files"
fi

if [ "$numberOfLogFiles" -gt 12 ]; then
        echo "Deleting log files as there are more than 12 (months of the year)"
        rm $logfolder*
fi

# If a log file exists for today, use it, if not create one and set permissions
if [ -e "$logfile" ]; then
        echo "Logfile for today exists at: $logfile"
else
        echo "Created new log file at: $logfile"
        touch "$logfile"
fi
chmod 666 "$logfile"
chown nobody:users "$logfile"

# Create the start of the file here, it will be saved to a temporary file
printf "\t\t~~ START OF LOG ~~\n\nDATE: %s, TIME: %s" "$(date +%b-%d-%Y)" "$(date +%r)" >> $tempmail

# Set args if key is used
if [ "$use_key" = true ]; then
        printf "\nusing ssh-key: %s\n" "$ssh_key" | tee -a $tempmail
        ssh_args=$(set sftp:connect-program "ssh -a -x -i $ssh_key")
else
        printf "\nusing sftp password\n" | tee -a $tempmail
        ssh_args=$(set sftp:connect-program "ssh -a -x")
fi

# If ltfp is not running, start the transfer
if pgrep -f "lftp" > /dev/null
then
        printf "\nSynctorrent is running already. on process %d\n" $(pgrep -f "lftp") | tee -a $tempmail
        exit 1
else
        # Start ssh-agent
        if [ "$use_key" = true ]; then
                eval "$(ssh-agent -s)"
                ssh-add "$ssh_key"
        fi

        # Touch timestamp file to prevent deleting links that are created while rsync is running
        ssh $login@$host touch $remote_finished/.download-timestamp

        # Run lftp
        let remaining=$(ssh $login@$host find -L $remote_finished -exec du -c --block-size=1MiB {} + | grep total$ | awk '{print $1}')
        let total=$(find $local_temp -exec du -c --block-size=1MiB {} + | grep total$ | awk '{print $1}')
        let rfiles=$(ssh $login@$host find -L $remote_finished | wc -l)-2
        let lfiles=$(find $local_temp | wc -l)-2

        unbuffer lftp -p 22 -u $login,$pass sftp://$host -e "$ssh_args;
                set mirror:use-pget-n 5;
                mirror -v -L -c -e $remote_finished $local_temp;
                quit" |

	while read word word2 progress
	do
                let lfiles=$(find $local_temp | wc -l)-3
                total=$(find $local_temp -exec du -c --block-size=1MiB {} + | grep total$ | awk '{print $1}')
                let percent=total*100/remaining
                echo -e "XXX\n$percent\nDownloading $lfiles/$rfiles\n\n$word\n\n$progress\n\n$total MiB / $remaining MiB\nXXX"
        done |

        dialog --title "FTP Transfer" --gauge progress 30 100 0

        # Check if Dialog exited without error, if so, remove the symbolic links
        if [ $? != 0 ]; then
                # Kill the ssh-agent
                if [ "$use_key" = true ]; then
                        pkill ssh-agent
                fi
                printf "\nDialog command failed (line 48). Exited with code %d \n" $? | tee -a $tempmail
                exit 2
        else
		clear
		if [ "$src_del" = true ]; then
                	printf "\n\nTransfer successful. Deleted following symbolic links:\n\n" >> $templogfind
                	ssh $login@$host find $remote_finished \! -newer $remote_finished/.download-timestamp -type l -delete -print >> $templogfind
                	if [ $? != 0 ]; then
                        	printf "\nFailed to run remote file delete command (line 63), exited with code %d \n" $? | tee -a $tempmail
                        	exit 3
                	fi
		fi
        fi

        # Move contents of local_temp into local_downloads and delete all files in local_temp
        printf "\n\n" >> $tempmail
	cp -vRf $local_temp* $local_downloads >> $tempmail
        rm -vRf $local_temp >> $tempmail
	mkdir $local_temp

        if [ "$use_perm" = true ]; then
                # Set permissions for folders
                chown -R "$own_perm" "$local_downloads"
                chmod -R "$mod_perm" "$local_downloads"
        fi

        # Kill the ssh-agent
        if [ "$use_key" = true ]; then
                pkill ssh-agent
        fi

        # Add the symlink deletion results
        cat "$templogfind" >> $tempmail

        # add end of log to the end of the log file before it is saved
        printf "\n\t\t~~ END OF LOG ~~ \n\n" >> $tempmail

        # Log the compiled report
        cat $tempmail >> "$logfile"
        rm "$templog"
        rm "$templogfind"
        rm $tempmail

        exit 0
fi
