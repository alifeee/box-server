# Box Server

Listen for [ConnectedLittleBoxes](https://www.connectedlittleboxes.com/) and respond to commands. Also display a nice HTML page to see the state of the system.

## Setup

```bash
# clone
git clone . /usr/alifeee/box-server/

# set up listener
sudo apt install jq mosquitto-clients
mkdir -p registrations connections heartbeats
./run.sh

# set up frontend
# assumes you have fastcgi set up to run scripts in /var/www/cgi/do/
sudo ln -s /usr/alifeee/box-server/cgi.sh /var/www/cgi/do/boxes
```
