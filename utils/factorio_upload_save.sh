#!/bin/bash

# Safety checks
error=0
if [ -z "$GDRIVE_REFRESH_TOKEN" ]; then
	echo Missing environment variable GDRIVE_REFRESH_TOKEN
	error=1
fi
if [ -z "$GDRIVE_UPLOAD_SAVES_FREQUENCY_SEC" ]; then
	echo Missing environment variable GDRIVE_UPLOAD_SAVES_FREQUENCY_SEC
	error=1
fi

# Exit if something bad happened
if [ $error == 1 ]; then
	echo Errors were detected, aborting.
	exit 1
fi

# Constants
FACTORIO_DIR=/opt/factorio
GDRIVE_UTIL="/opt/gdrive --refresh-token $GDRIVE_REFRESH_TOKEN"

# Execute the save
GDRIVE_FACTORIO_FOLDER_FILE_ID=`cat $FACTORIO_DIR/saves/downloaded_saves | head -n 1`
echo $GDRIVE_FACTORIO_FOLDER_FILE_ID > "$FACTORIO_DIR/saves/downloaded_saves_new"
for filename in $FACTORIO_DIR/saves/*.zip; do
    savename=`basename "$filename"`
    
    # Check if we knew about this file already.
    found=0
    {
        read;	# Skip the first line
        while read line; do
            storedsavename=`echo $line | cut -d " " -f2`
            if [ "$storedsavename" == "$savename" ]; then
                found=1
                fileid=`echo $line | cut -d " " -f1`
                checksum=`echo $line | cut -d " " -f3`
                break
            fi
        done
    } < "$FACTORIO_DIR/saves/downloaded_saves"

    # If we did, update it.
    storedchecksum=`md5sum "$filename" | cut -d " " -f1`
    if [ $found == 1 ]; then
        # Verify if the checksum has changed.
        if [ "$storedchecksum" == "$checksum" ]; then
            echo $filename has not changed, skipping.
        else
            echo $filename has changed, updating.
            $GDRIVE_UTIL update --no-progress $fileid $filename
        fi
        
        # Write to the new status file
        echo $fileid $savename $checksum >> "$FACTORIO_DIR/saves/downloaded_saves_new"
    else
        echo $filename is a new save, uploading.
        fileid=`$GDRIVE_UTIL upload --no-progress --parent $GDRIVE_FACTORIO_FOLDER_FILE_ID $filename | sed -n '2p' | cut -d ' ' -f2`
        
        # Add to the status file
        echo $fileid $savename $storedchecksum >> "$FACTORIO_DIR/saves/downloaded_saves_new"
    fi
done

# Replace the status file
rm -f "$FACTORIO_DIR/saves/downloaded_saves"
mv "$FACTORIO_DIR/saves/downloaded_saves_new" "$FACTORIO_DIR/saves/downloaded_saves"
