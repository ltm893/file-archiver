#!/bin/bash

#added directory stucture
files_dir="files"
archive_dir="archives"
logs_dir="logs"

# Set default logfile or use environment variable A2LOG
logfile=${logs_dir}/${A2LOG:-assign2.log}

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >>"$logfile"
}

backup_the_file() {
    echo "Backing up $1 to $2"
    log "Backing up $1 to $2"
    tar -rvf "$2" "$1" # Add file to tar archive
}

check_file_older_than_in_archive() {
    file_ts=$(stat -c %Y $1)
    # echo "$file_ts"

    tar_day=$(tar --list -v --full-time -f $2 | grep $1 | awk '{print $4}')
    # echo "$tar_day"
    tar_time=$(tar --list -v --full-time -f $2 | grep $1 | awk '{print $5}')
    # echo "$tar_time"

    tar_ts=$(date -d "${tar_day} ${tar_time}" +"%s")
    # echo "$tar_ts"
    # count=$((file_ts-tar_ts))
    # echo $count
    if [ "$file_ts" -gt "$tar_ts" ]; then
        # archive
        file_older_than_in_archive="yes"
    else
        file_older_than_in_archive="no"
    fi

}

check_file_in_tar() {
    tar -tf $2 | grep -q $1
    if [ $? == 0 ]; then
        file_in_tar="yes"
    else
        file_in_tar="no"
    fi
   

}

# The name of the archive file to use (create, modify, or query) will be passed to the script on the command line.

archive_array=("create" "modify" "query")
archive_file=$3

if [[ ! " ${archive_array[@]} " =~ " $archive_file " ]]; then
    log_message="$archive_file archive file is not support"log
    echo "$log_message"
    log "$log_message"
    exit
else
    archive_name=$archive_dir/$archive_file.tar
    log_message="${archive_name} is archive file"
    # echo "$log_message"
    # log "$log_message"
fi

# Initialize variables
#backup_file=""
restore_file=""
#archive_name="query.tar"  # Default archive name
compression=false # Track if compression is requested

# Check for options
while getopts ":b:r:c" opt; do
    case $opt in
    b)
        # Backup option
        backup_file=${files_dir}/"$OPTARG"
        if [ ! -f "$backup_file" ]; then
            echo "Backup File Does not exist" >&2
            log "Backup File Does not exist"
            exit 7 # Exit status code 7 for "Backup File Does not exist"
        fi

        if [ ! -r "$backup_file" ]; then
            echo "Archive access failure" >&2
            log "Archive access failure: $backup_file is not readable"
            exit 6 # Exit status code 6 for archive access failure
        fi

        if [ -e "$archive_name" ] && [ ! -w "$archive_name" ]; then
            echo "Archive access failure" >&2
            log "Archive access failure: $archive_name is not writable"
            exit 6 # Exit status code 6 for archive access failure
        fi

        # if the archive file readable compare unixtimestamps of file and whats in tar file

        if [ -r "$archive_name" ]; then
            check_file_older_than_in_archive $backup_file $archive_name
            if [ "$file_older_than_in_archive" = "yes" ]; then
                backup_the_file $backup_file $archive_name
            fi
        else
            echo 'else'
            backup_the_file $backup_file $archive_name
        fi
        # Logic for backing up the file (e.g., adding to an archive)

        ;;

    r)
        # Restore option
        restore_file=${files_dir}/"$OPTARG"
        if [ ! -r "$archive_name" ]; then
            echo "Archive retrieval failure" >&2
            log "Archive retrieval failure: $archive_name is not readable"
            exit 9 # Exit status code 9 for archive retrieval failure
        fi

        check_file_in_tar $restore_file $archive_name

        if [ "$file_in_tar" = "no" ] ; then
            echo "$restore_file does not exist in the  $archive_name"
            log "$restore_file does not exist in the $archive_name"
            exit 14 # does not exist in the archive
        fi

        if [ -e "$restore_file" ]; then
            check_file_older_than_in_archive $restore_file $archive_name
            if [ ${file_older_than_in_archive} = "yes" ]; then
                #  then extract the file from the archive to the current directory as filename.newe
                echo 'abc'
            fi
        fi

        # Logic for restoring the file from the archive
        echo "Restoring $restore_file from $archive_name"
        log "Restoring $restore_file from $archive_name"
        tar -xvf "$archive_name" "$restore_file" # Extract file from tar archive
        ;;

    c)
        # Compression option
        compression=true # Mark that compression is requested
        if [ -z "$backup_file" ]; then
            exit 127 # Exit status code 127 if -c is used without -b
        fi

        # Logic for compressing the file before backup
        echo "Compressing $backup_file"
        log "Compressing $backup_file"
        gzip "$backup_file" # Compress the specified file
        ;;

    \?)
        echo "Invalid option: -$OPTARG" >&2
        log "Invalid option: -$OPTARG"
        exit 1 # Exit status code 1 for invalid option
        ;;
    esac
done

# Final check for -c option provided without -b
if $compression && [ -z "$backup_file" ]; then
    exit 127 # Exit status code 127 if -c is provided without a backup file
fi
