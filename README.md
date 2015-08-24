# Factorio Docker Image

## Usage

1. First you need to get your session cookie from factorio. Login to
[https://www.factorio.com](https://www.factorio.com) using Google Chrome.
2. Open the developer tools `F12`, `Ctrl+Shift_J`
3. Click on `Console`
4. Run the following `document.cookie` and you will see the output

![Cookie Screenshot]()

```bash
docker pull themodem/factorio
docker run -i --rm -p 33:33 \
    -e UPDATE_USERNAME=username \
    -e UPDATE_TOKEN=12345 \
    -v PATH_TO_SAVE_GAME_FOLDER:/opt/factorio/saves \
    themodem/factorio
```

The `-v` param mounts a folder containing saved games (the folder with *.zip).

## Environmental Variables
### Required

 - `UPDATE_USERNAME` your factorio username
 - `UPDATE_TOKEN` your update token from factorio_root/player-data.json

### Optional

 - `LATENCY` default **250**
 - `AUTOSAVE_INTERVAL` default **10**
 - `AUTOSAVE_SLOTS` default **3**

### FAQ
Q: I cant see my player-data.json file!

A: You need to run Factorio on any platform and when the box asking you to login
to check for updates pops up fill out the details. Then exit Factorio and you
should see the file there.
