#!/bin/bash
echo "Uninstalling..."
cmd() { sudo security 2>&1 >/dev/null delete-generic-password -D "Encrypted Volume Password" -s "UnlockLogicalVolumeHelper" "/Library/Keychains/System.keychain"; }
err=`cmd`
while [[ $err == "password has been deleted." ]]; do
	err=`cmd`
done
sudo rm /Library/LaunchDaemons/name.ridgewell.ulvh.plist
sudo rm -rf /Library/UnlockLogicalVolumeHelper

echo "--------------------------"
echo ""
echo "Uninstalled."
