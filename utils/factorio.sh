#!/bin/bash

echo Factorio management script version 1.0.6

# Safety checks
error=0
if [ -z "$GDRIVE_REFRESH_TOKEN" ]; then
	echo Missing environment variable GDRIVE_REFRESH_TOKEN
	error=1
fi
if [ -z "$GDRIVE_FACTORIO_FOLDER_NAME" ]; then
	echo Missing environment variable GDRIVE_FACTORIO_FOLDER_NAME
	error=1
fi
if [ -z "$FACTORIO_SAVE_NAME" ]; then
	echo Missing environment variable FACTORIO_SAVE_NAME
	error=1
fi
if [ -z "$FACTORIO_SERVER_ARGS" ]; then
	echo Missing environment variable FACTORIO_SERVER_ARGS
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

# Backup any old save file, and make a new, empty save folder.
if [ -d "$FACTORIO_DIR/saves_bak" ]; then
	rm -rf "$FACTORIO_DIR/saves_bak"
fi
if [ -d "$FACTORIO_DIR/saves" ]; then
	mv "$FACTORIO_DIR/saves" "$FACTORIO_DIR/saves_bak"
fi
mkdir "$FACTORIO_DIR/saves"

# Look for the root saves folder on Drive
echo Looking for a Google Drive folder named $GDRIVE_FACTORIO_FOLDER_NAME...
GDRIVE_FACTORIO_FOLDER_FILE_ID=`$GDRIVE_UTIL list --no-header --query "name = '$GDRIVE_FACTORIO_FOLDER_NAME' and mimeType = 'application/vnd.google-apps.folder' and trashed = false" -m 1 | cut -d " " -f1`
if [ "$GDRIVE_FACTORIO_FOLDER_FILE_ID" == "" ];then
    echo FATAL: Unable to find a folder named $GDRIVE_FACTORIO_FOLDER_NAME on Google Drive.
    exit 1
fi

# Get the latest version of the saves from Google drive
echo $GDRIVE_FACTORIO_FOLDER_FILE_ID > "$FACTORIO_DIR/saves/downloaded_saves"
touch -d '-10 years' "$FACTORIO_DIR/saves/newest_save"
for save in `$GDRIVE_UTIL list --no-header --query "'$GDRIVE_FACTORIO_FOLDER_FILE_ID' in parents and trashed = false" | cut -d " " -f1`; do
	filename=`$GDRIVE_UTIL download --no-progress --force --path "$FACTORIO_DIR/saves" $save | head -n 1 | cut -d " " -f2`
    checksum=`$GDRIVE_UTIL info $save | grep Md5sum | cut -d " " -f2`
    modifieddate=`$GDRIVE_UTIL info $save | grep Modified | cut -d " " -f2-3`
    modified=`date --date="$modifieddate" +"%s"`
    touch -d @$modified "$FACTORIO_DIR/saves/$filename"
    
    if [ "$FACTORIO_DIR/saves/$filename" -nt "$FACTORIO_DIR/saves/newest_save" ]; then
        echo $filename > "$FACTORIO_DIR/saves/newest_save"
        touch -d @$modified "$FACTORIO_DIR/saves/newest_save"
    fi
    
    echo Found save file on Google Drive $filename, id $save, checksum $checksum
	echo $save $filename $checksum >> "$FACTORIO_DIR/saves/downloaded_saves"
done

# Restore the most recent save.
if [ -s "$FACTORIO_DIR/saves/newest_save" ]; then
    newestsave=`cat "$FACTORIO_DIR/saves/newest_save"`
    if [ "$newestsave" != "$FACTORIO_SAVE_NAME.zip" ]; then
        echo Restoring newest save $newestsave
        cp -rf "$FACTORIO_DIR/saves/$newestsave" "$FACTORIO_DIR/saves/$FACTORIO_SAVE_NAME.zip"
    else
        echo $FACTORIO_SAVE_NAME is the newest save, no auto-save restoration
    fi
fi
rm -f "$FACTORIO_DIR/saves/newest_save"

# Check if no save exists, in which case, create one.
if [ ! -f "$FACTORIO_DIR/saves/$FACTORIO_SAVE_NAME.zip" ]; then
	"$FACTORIO_DIR/bin/x64/factorio" --create $FACTORIO_SAVE_NAME
fi

# Trap the interruption
handle_int() {
    echo Interrupted!
    [[ $sleeppid ]] && kill $sleeppid
    kill -s INT $factoriopid
    wait $factoriopid
    echo Executing final save upload...
    "$FACTORIO_DIR/factorio_upload_save.sh"
    exit 0
}
trap handle_int SIGINT SIGTERM SIGKILL

# Run the server
"$FACTORIO_DIR/bin/x64/factorio" --start-server $FACTORIO_SAVE_NAME $FACTORIO_SERVER_ARGS &
factoriopid=$!

# Run saves at an interval
echo Server started with PID $factoriopid
while :; do
    sleep $GDRIVE_UPLOAD_SAVES_FREQUENCY_SEC &
    sleeppid=$!
    wait $sleeppid
    echo Executing regular save upload...
    "$FACTORIO_DIR/factorio_upload_save.sh"
done
