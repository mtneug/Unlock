#!/bin/bash
if [[ `whoami` != "root" ]]; then
# Run as root to avoid Console logging sudo commands.
	echo "Attempting to re-run as root..."
	curl https://raw.github.com/jridgewell/Unlock/master/install.sh -o install.sh
	chmod +x install.sh

	sudo bash ./install.sh
	rm install.sh
	exit
fi

mkdir tmp_install_unlock
cd tmp_install_unlock

echo "--------------------------"
echo ""
echo "Downloading..."
# Download the needed files.
curl "https://raw.github.com/jridgewell/Unlock/master/files/name.ridgewell.ulvh.plist" -o name.ridgewell.ulvh.plist
curl "https://github.com/downloads/jridgewell/Unlock/ulvh" --location -o ulvh



echo "--------------------------"
echo ""
echo "Installing..."
# Move to the LaunchDaemons dir, and set permissions
mv name.ridgewell.ulvh.plist /Library/LaunchDaemons/
chown root:wheel /Library/LaunchDaemons/name.ridgewell.ulvh.plist
chmod 644 /Library/LaunchDaemons/name.ridgewell.ulvh.plist

mkdir -p /Library/UnlockLogicalVolumeHelper
mv ulvh /Library/UnlockLogicalVolumeHelper/
chown root:wheel /Library/UnlockLogicalVolumeHelper
chown root:wheel /Library/UnlockLogicalVolumeHelper/ulvh
chmod 755 /Library/UnlockLogicalVolumeHelper
chmod 755 /Library/UnlockLogicalVolumeHelper/ulvh

vname() { echo `diskutil cs info $1 | grep "Volume Name" | cut -d : -f 2 | sed -e 's/^\ *//'`; }
unlock() {
	echo "What is the passphrase used to encrypt ${2}?"
	read -s password < /dev/tty
	# Add the password to the System keychain
	security add -a "${1}" -D "Encrypted Volume Password" -l "Unlock: ${2}" -s "UnlockLogicalVolumeHelper" \
		-w "${password}" -T "" -T "/Library/UnlockLogicalVolumeHelper/ulvh" -U "/Library/Keychains/System.keychain"
}
ask() {
	# Get the name of the volume with UUID
	name=`vname $1`
	echo "Do you want to unlock ${name} at boot? (y/N)"
	read yn < /dev/tty
	# Make user input lowercase
	answer=`echo ${yn}| awk '{print tolower($0)}'`
	if [[ $answer = "y" || $answer = "yes" ]]; then
		unlock $1 $name
	fi
}

if [ -d tmp_install_unlock ]; then
# In case command was exited before
	rm -r tmp_install_unlock
fi
boolUUID=false
bootUUID=`diskutil cs info \`mount | grep " / " | cut -d " " -f 1\` 2>/dev/null | grep UUID | grep -v LV | cut -d : -f 2 | sed -e 's/^\ *//'`

# http://stackoverflow.com/questions/893585/how-to-parse-xml-in-bash#answer-2608159
rdom() { local IFS=\> ; read -d \< E C ;}
CSVs=`diskutil cs list -plist`
echo $CSVs | while rdom; do
	if [[ $E = "string" ]]; then
	# All the important stuff is inside the "string" elements
		echo "$C"
	fi
done | \
while read LINE; do
# Loop through all found LVGs, LVFs, LVs
	if $boolUUID; then
	# If this is a LV's UUID, ask if they want to unlock it
		if [[ $bootUUID != $LINE ]]; then
		# Don't ask about the boot volume, File Vault will take care of that one
			ask $LINE
		fi
	fi
	if [[ $LINE = "LV" ]]; then
	# If true, the next line will be a LV's UUID
		boolUUID=true
	else
		boolUUID=false
	fi
done

# Cleanup
cd ..
rm -r tmp_install_unlock

echo "--------------------------"
echo ""
echo "Installed!"
