#!/bin/bash

Dir=$(sed -n 1p "$HOME/.TVshowLog/.location.log")		# TV_show directory
Log_dir="$HOME/.TVshowLog" 		# Log Directory

## Remove link, if any ##

echo "Removing link (if any)... "
if [ -f "$Log_dir/.install" ]; then
	link_name=`sed -n 2p "$Log_dir/.install"`		# Path where link is created	
	sudo rm "/usr/bin/$link_name"
	echo "link removed..."
fi 

echo "Removing logs..."
sudo rm -r "$Log_dir"
sudo rm -r "$Dir"