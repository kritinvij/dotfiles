# Software to install on a new Mac

Command-line tools and some apps live in `dev_setup/Brewfile`. Run `brew bundle --file=dev_setup/Brewfile` to install them. The lists below cover everything else.

## Before anything else

| Step | Command or note |
|------|-----------------|
| Xcode command line tools | `xcode-select --install` |
| Homebrew | Install from https://brew.sh, then run the Brewfile |

## Mac utilities

| App | Use |
|-----|-----|
| iTerm | Terminal |
| Raycast | Launcher |
| Flux | Screen color temperature |
| Clipy (https://clipy-app.com) | Clipboard history |
| AppCleaner | Uninstalls apps with their leftover files |
| Caffeine, Amphetamine or NoSleep | Keeps the Mac awake |
| ScreenBrush | Draws on the screen |
| MeetingBar | Shows calendar meetings in the menu bar |
| Hidden Bar | Hides menu bar icons |
| eqMac (https://eqmac.app) | System-wide audio equalizer |
| Sony Headphones Client (https://github.com/Plutoberth/SonyHeadphonesClient/releases) | Controls Sony headphones |

## Productivity and media

| App | Use |
|-----|-----|
| Sublime Text | Editor |
| BusyCal or Amie | Calendar |
| Keep Notes | Notes |
| WhatsApp | Messaging |
| Spotify | Music |
| VLC | Video player |
| Steam | Games |
| Giphy Capture | Records screen GIFs |

## Command-line extras (not in the Brewfile)

| Tool | Note |
|------|------|
| pip | Comes with Python. `setup_laptop_prereqs.sh` installs Python through pyenv |
| autoexpect | Scripts commands that prompt for a password. See https://stackoverflow.com/questions/4857702/how-to-provide-password-to-a-command-that-prompts-for-one-in-bash |

## Cloud desktop

To open HTML links on a cloud desktop, install `lynx` with `sudo yum -y install lynx`. Or serve the files from your own machine with `python -m http.server`.

## Windows only

Pause Windows updates with https://github.com/Aetherinox/pause-windows-updates.
