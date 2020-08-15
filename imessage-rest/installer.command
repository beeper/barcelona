#!/bin/sh

#  Script.sh
#  imessage-rest
#
#  Created by Eric Rabil on 8/14/20.
#  Copyright © 2020 Eric Rabil. All rights reserved.

echo "Uninstalling previous installation if present"

# Uninstall previous
launchctl unload ~/Library/LaunchAgents/com.ericrabil.imessage-rest.plist
rm -rf ~/Library/LaunchAgents/com.ericrabil.imessage-rest.plist ~/Library/ApplicationSupport/iMessageREST

echo "Installing new files"

# Install new
mkdir ~/Library/ApplicationSupport/iMessageREST
cp -r ./imessage-rest.xpc ~/Library/ApplicationSupport/iMessageREST/imessage-rest.xpc
cp ./com.ericrabil.imessage-rest.plist ~/Library/LaunchAgents/com.ericrabil.imessage-rest.xpc.plist
sed -i '' "s/{{CURRENT_USER}}/$(whoami)/g" ~/Library/LaunchAgents/com.ericrabil.imessage-rest.plist

echo "Starting service"

# Load new
launchctl load ~/Library/LaunchAgents/com.ericrabil.imessage-rest.plist

echo "Installed and running!"
