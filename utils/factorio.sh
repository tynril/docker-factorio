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
GDRIVE_FACTORIO_FOLDER_FILE_ID=`$GDRIVE_UTIL list --no-header --query "name contains '$GDRIVE_FACTORIO_FOLDER_NAME' and trashed = false" -m 1 | cut -d " " -f1`
touch "$FACTORIO_DIR/saves/downloaded_saves"
for save in `$GDRIVE_UTIL list --no-header --query "name contains '.zip' and '$GDRIVE_FACTORIO_FOLDER_FILE_ID' in parents and trashed = false" | cut -d " " -f1`; do
	filename=`$GDRIVE_UTIL download --no-progress --force --path "$FACTORIO_DIR/saves" $save | head -n 1 | cut -d " " -f2`
	checksum=`$GDRIVE_UTIL info $save | grep Md5sum | cut -d " " -f2`
	echo $save $filename $checksum >> "$FACTORIO_DIR/saves/downloaded_saves"
done

# Check if no save exists, in which case, create one.
if [ ! -f "$FACTORIO_DIR/saves/$FACTORIO_SAVE_NAME.zip" ]; then
	"$FACTORIO_DIR/bin/x64/factorio" --create $FACTORIO_SAVE_NAME
fi

# Run the server
"$FACTORIO_DIR/bin/x64/factorio" --start-server $FACTORIO_SAVE_NAME $FACTORIO_SERVER_ARGS

# Upload the saves
for filename in "$FACTORIO_DIR/saves/*.zip"; do
	# Check if we knew about this file already.
	found=0
	while read line; do
		if [ `echo $line | cut -d " " -f2` == `basename $filename` ]; then
			found=1
			fileid=`echo $line | cut -d " " -f1`
			checksum=`echo $line | cut -d " " -f3`
			break
		fi
	done < "$FACTORIO_DIR/saves/downloaded_saves"

	# If we did, update it.
	if [ $found == 1 ]; then
		# Verify if the checksum has changed.
		if [ `md5sum $filename | cut -d " " -f1` == "$checksum" ]; then
			echo $filename has not changed, skipping.
		else
			$GDRIVE_UTIL update --no-progress $fileid $filename
		fi
	else
		$GDRIVE_UTIL upload --no-progress --parent $GDRIVE_FACTORIO_FOLDER_FILE_ID $filename
	fi
done
