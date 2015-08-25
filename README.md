# Factorio Docker Image

## Usage

There are a few environmental variables that are needed to start Factorio.
1. The session coolie is needed from the Factorio website in order to download
the latest Factorio version.
2. Your username is needed along with your update token in order to keep the
Factorio version up to date.

### Factorio session
1. First you need to get your session cookie from factorio. Login to
[https://www.factorio.com](https://www.factorio.com) using Google Chrome.
2. Open the developer tools `F12`, `Ctrl+Shift_J`
3. Click on `Console`
4. Run the following `document.cookie` and you will see the output
5. ![Cookie Screenshot](https://raw.githubusercontent.com/Themodem/docker-factorio/master/images/cookie.png)
6. Copy the value of `ring-session` to the docker command.

### Username and update token
1. Run Factorio and enter your username and password into the
`check for updates` box that appears when you first run the game.
2. Quit out of the game.
3. Open the Factorio directory e.g. `C:\games\Factorio`
4. Open the `player-data.json` file in a text editor
5. Copy the `updater-token` value
6. ![Update Screenshot](https://raw.githubusercontent.com/Themodem/docker-factorio/master/images/update.png)

Now we can run the docker container
```bash
docker pull themodem/factorio
docker run -i --rm -p 34197:34197/udp \
    -e SESSION=a7f3675d-72b7-4734-8a6a-5dff835ad7fg \
    -e UPDATE_USERNAME=HughJass \
    -e UPDATE_TOKEN=5f3135bf92bd2eac56dfaf89sb2a31 \
    -v PATH_TO_SAVE_GAME_FOLDER:/opt/factorio/saves \
    themodem/factorio
```

The `-v` param mounts a folder containing saved games (the folder with *.zip).

## Environmental Variables
### Required

 - `SESSION` your factorio session cookie
 - `UPDATE_USERNAME` your factorio username
 - `UPDATE_TOKEN` your update token from factorio_root/player-data.json

### Optional

 - `LATENCY` default **250**
 - `AUTOSAVE_INTERVAL` default **10**
 - `AUTOSAVE_SLOTS` default **3**
