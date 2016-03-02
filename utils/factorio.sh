#!/bin/bash

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

# Get the latest version of the saves from Google drive
echo Looking for a Google Drive folder named $GDRIVE_FACTORIO_FOLDER_NAME...
GDRIVE_FACTORIO_FOLDER_FILE_ID=`$GDRIVE_UTIL list --no-header --query "name contains '$GDRIVE_FACTORIO_FOLDER_NAME' and trashed = false" -m 1 | cut -d " " -f1`
echo Folder found with identifier $GDRIVE_FACTORIO_FOLDER_FILE_ID
echo $GDRIVE_FACTORIO_FOLDER_FILE_ID > "$FACTORIO_DIR/saves/downloaded_saves"
for save in `$GDRIVE_UTIL list --no-header --query "'$GDRIVE_FACTORIO_FOLDER_FILE_ID' in parents and trashed = false" | cut -d " " -f1`; do
	filename=`$GDRIVE_UTIL download --no-progress --force --path "$FACTORIO_DIR/saves" $save | head -n 1 | cut -d " " -f2`
	checksum=`$GDRIVE_UTIL info $save | grep Md5sum | cut -d " " -f2`
	echo Found save file on Google Drive $filename, id $save, checksum $checksum
	echo $save $filename $checksum >> "$FACTORIO_DIR/saves/downloaded_saves"
done

# Check if no save exists, in which case, create one.
if [ ! -f "$FACTORIO_DIR/saves/$FACTORIO_SAVE_NAME.zip" ]; then
	"$FACTORIO_DIR/bin/x64/factorio" --create $FACTORIO_SAVE_NAME
fi

# Start the background save uploader.
"$FACTORIO_DIR/factorio_upload_save.sh" --background &

# Run the server
"$FACTORIO_DIR/bin/x64/factorio" --start-server $FACTORIO_SAVE_NAME $FACTORIO_SERVER_ARGS

# Kill the background save
kill $!

# Upload the saves after the server ended
"$FACTORIO_DIR/factorio_upload_save.sh"
