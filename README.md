# Pi Voice Control
This is a fork of https://github.com/StevenHickson/PiAUISuite that has been modified for use in my project https://github.com/fearthis4/jarvis-pi

Includes voicecommand, speech2text, run-command, mqtt scripts

This requires:

* boost
* curl
* xterm
* espeak
* some other things

To install the dependencies, run:
```bash
sudo apt-get install -y libboost-dev libboost-regex-dev youtube-dl axel curl xterm libcurl4-gnutls-dev mpg123 flac sox
```

To install pivc:
```bash
git clone https://github.com/fearthis4/pivc.git
cd pivc/Install
./Installpivc.sh
```

It will:
* ask if you want to install the dependencies
* to install each script

## Different Parts

Name | Purpose | Blogpost
-----|---------|---------


Copyright

[GPLv3](https://tldrlegal.com/license/gnu-general-public-license-v3-(gpl-3))

Christopher Jones
