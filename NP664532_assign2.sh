#!/bin/bash

# Set default logfile or use environment variable A2LOG
logfile=${A2LOG:-assign2.log}

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$logfile"
}

# Initialize variables
backup_file=""
restore_file=""
archive_name="query.tar"  # Default archive name
compression=false  # Track if compression is requested

# Check for options
while getopts ":b:r:c" opt; do
    case $opt in
        b)
            # Backup option
            backup_file="$OPTARG"
            if [ ! -r "$backup_file" ]; then
                echo "Archive access failure" >&2
                log "Archive access failure: $backup_file is not readable"
                exit 6  # Exit status code 6 for archive access failure
            fi

            if [ -e "$archive_name" ] && [ ! -w "$archive_name" ]; then
                echo "Archive access failure" >&2
                log "Archive access failure: $archive_name is not writable"
                exit 6  # Exit status code 6 for archive access failure
            fi

            # Logic for backing up the file (e.g., adding to an archive)
            echo "Backing up $backup_file to $archive_name"
            log "Backing up $backup_file to $archive_name"
            tar -rvf "$archive_name" "$backup_file"  # Add file to tar archive
            ;;

        r)
            # Restore option
            restore_file="$OPTARG"
            if [ ! -r "$archive_name" ]; then
                echo "Archive retrieval failure" >&2
                log "Archive retrieval failure: $archive_name is not readable"
                exit 9  # Exit status code 9 for archive retrieval failure
            fi

            # Logic for restoring the file from the archive
            echo "Restoring $restore_file from $archive_name"
            log "Restoring $restore_file from $archive_name"
            tar -xvf "$archive_name" "$restore_file"  # Extract file from tar archive
            ;;

        c)
            # Compression option
            compression=true  # Mark that compression is requested
            if [ -z "$backup_file" ]; then
                exit 127  # Exit status code 127 if -c is used without -b
            fi

            # Logic for compressing the file before backup
            echo "Compressing $backup_file"
            log "Compressing $backup_file"
            gzip "$backup_file"  # Compress the specified file
            ;;

        \?)
            echo "Invalid option: -$OPTARG" >&2
            log "Invalid option: -$OPTARG"
            exit 1  # Exit status code 1 for invalid option
            ;;
    esac
done

# Final check for -c option provided without -b
if $compression && [ -z "$backup_file" ]; then
    exit 127  # Exit status code 127 if -c is provided without a backup file
fi
