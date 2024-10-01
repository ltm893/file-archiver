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
    message="Backing up $1 to $2"
    echo "$message"
    log "$message"
    tar -rvf "$2" "$1" # Add file to tar archive
}

restore_the_file() {
    message="Restoring $1 from $2"
    echo "$message"
    log "$message"
    tar -xvf "$2" "$1" "$3" #  Restore from tar archive
}

 remove_file_from_archive() {
    message="Removing $1 from $2"
    echo "$message"
    log "$message"
    tar --delete -f $2 $1
 }

 get_file_byte_size() {
     file_byte_size=`cat $1 | wc -c`
     echo "file_byte_size $file_byte_size"
 }

 get_file_gzip_byte_size() {
    file_gzip_byte_size=`gzip -c $1 | wc -c`
    echo "file_gzip_byte_size $file_gzip_byte_size"
 }

check_file_older_than_in_archive() {
    file_ts=$(stat -c %Y $1)
    echo "Stat $file_ts"

    tar_day=$(tar --list -v --full-time -f $2 | grep $1 | awk '{print $4}')
     echo "tar_day $tar_day"
    tar_time=$(tar --list -v --full-time -f $2 | grep $1 | awk '{print $5}')
    echo "tar time $tar_time"

    tar_ts=$(date -d "${tar_day} ${tar_time}" +"%s")
    echo "tar ts $tar_ts"
    # count=$((file_ts-tar_ts))
    # echo $count
    if [ "$file_ts" -lt "$tar_ts" ]; then
        # archive
        file_older_than_in_archive="yes"
    else
        file_older_than_in_archive="no"
    fi
    echo "file_older_than_in_archive $file_older_than_in_archive"

}

check_file_in_archive() {
    tar -tf $2 | grep -q $1
    if [ $? == 0 ]; then
        file_in_archive="yes"
   else
        file_in_archive="no"
    fi
    echo "file in archive $file_in_archive"

}

# The name of the archive file to use (create, modify, or query) will be passed to the script on the command line.




# Initialize variables
#backup_file=""
restore_file=""
#archive_name="query.tar"  # Default archive name
compression=false # Track if compression is requested

while getopts ":b:rc" opt; do
  case $opt in
    b)
        opt_type=backup
        backup_file=${files_dir}/"$OPTARG"
        echo "B"
       
      ;;
    r)
         opt_type=restore
         restore_file=${files_dir}/"$OPTARG"
      ;;
    c)
        compression=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# Access positional arguments after getopts processing
shift $((OPTIND-1))
echo "Remaining positional arguments: $@"
archive_file=${@[0]}
archive_name=$archive_dir/$archive_file.tar
echo "$archive_anme"

if [ $opt_type = "backup" ]; then
    if [ $"compression" == "true" ]; then
        get_file_byte_size "$backup_file"
        gzip "$backup_file" # Compress the specified file
        get_file_gzip_byte_size "$backup_file"
        backup_file=$backup_file.gz
       
    else 
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

        if [ -e "$archive_name" ]; then
            echo "files $backup_file $archive_name"
            check_file_in_archive $backup_file $archive_name
            
            echo  "File in archive $file_in_archive"
            if [ "$file_in_archive" = "no" ] ; then
                    backup_the_file $backup_file $archive_name
            else 
                check_file_older_than_in_archive $backup_file $archive_name
                echo "File Older than archive $file_older_than_in_archive"
                if [ "$file_older_than_in_archive" = "no" ]; then
                    remove_file_from_archive $backup_file $archive_name
                    backup_the_file $backup_file $archive_name
                fi
            fi
       
        else
            backup_the_file $backup_file $archive_name
        fi

    fi
fi
        

