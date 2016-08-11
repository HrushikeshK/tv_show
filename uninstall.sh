Dir=$(sed -n 1p "$HOME/.TVshowLog/.location.log")		# TV_show directory
Log_dir="$HOME/.TVshowLog" 		# Log Directory

sudo rm -r "$Dir"
sudo rm -r "$Log_dir"

## Remove aliases, if made any ##

echo "Removing link (if any)... "
if [ -f /usr/bin/tv ];then
	echo "Enter password to remove link" 
	sudo rm /usr/bin/tv
	echo "Link removed..."
else 
	echo "No link found"
fi

