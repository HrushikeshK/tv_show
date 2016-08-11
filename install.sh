#!/bin/bash

readonly script_name="tv.sh"		# Get name of the script
readonly relative_location=`dirname "$0"`		# To get relative path of the script, dirname command deletes last entry of the path
readonly script_location="`( cd "$relative_location" && pwd)`"	# To get absolute path of the script

echo "This will create a link in /usr/bin for the script (Default name: tv)"
read -p "Do you want to continue? [Y/n]" response
name="tv"

if [ -z $response ] || [ $response = 'y' ] || [ $response = 'Y' ]; then
	while true; do
		if [ ! -f "/usr/bin/$name" ]; then
			sudo ln -s "$script_location/$script_name" "/usr/bin/$name"
			echo "Link created... Close the terminal and start again and type $name to run the script"
			break
		else
			echo "There is already a program with name $name"
			echo "Enter another name you would like to use for this script or press <q> to quit"
			read name
			if [ $name = 'q' ]; then 
				echo "Another way is to create an alias"
				break
			fi
		fi
	done
else
	echo "Another way is to create an alias"
fi