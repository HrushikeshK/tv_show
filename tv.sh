#!/bin/sh

script_name=`basename "$0"`		# To get the name of script, basename command deletes the prefexing directory's names

if [ $# -ge 1 ]; then 		# If number of comments is one
	if [ $# -eq 2 ]; then
		watch=$1
		name=$2		# The name which we have to search for 
	elif [ $# -eq 3 ]; then
		watch=$1
		arg2=$2
		name=$3
	else
		watch=$1
	fi
fi

if [ ! -d $HOME/.TVshowLog ]; then			# If the Log directory does not exist, then create one.
	mkdir "$HOME/.TVshowLog"					# Needed for first time only, mostly
fi

if [ ! -f $HOME/.TVshowLog/.help.txt ]; then
	cp "tvshow_help.txt" "$HOME/.TVshowLog/.help.txt"		# Copy the help file in Log folder
fi

if [ $watch = '-h' 2> /dev/null ]; then			# Help Page
	clear
	cat "$HOME/.TVshowLog/.help.txt"
	exit
fi

# GENERALISATION
if [ ! -f "$HOME/.TVshowLog/.location.log" ]; then

	pwd > "$HOME/.TVshowLog/.location.log"					# Location of the script file
	
	echo "Enter path for your TV shows directory"
	read tvShow_location 						# Path where your TV shows are located
	echo "$tvShow_location" >> "$HOME/.TVshowLog/.location.log"
	echo "$(date +%s)" >> "$HOME/.TVshowLog/.location.log"		# Enter time used to check last update
else
	if [ $(cat "$HOME/.TVshowLog/.location.log" | wc -l) -ne 3 ]; then
			pwd > "$HOME/.TVshowLog/.location.log"					# Location of the script file
	
		echo "Enter path for your TV shows directory"
		read tvShow_location 						# Path where your TV shows are located
		echo "$tvShow_location" >> "$HOME/.TVshowLog/.location.log"
		echo "$(date +%s)" >> "$HOME/.TVshowLog/.location.log"		# Enter time used to check last update
	else
		tvShow_location=$(cat "$HOME/.TVshowLog/.location.log" | sed -n '2p') 
	fi
fi

	last_epoch=$(sed -n '3p' "$HOME/.TVshowLog/.location.log")		# Get the time when it last checked for update

	if [ $(echo "$(date +%s)") -gt $(($last_epoch+604800)) ]; then		# To check for updates after every 7 days
		if [ `echo "$(locate git)" | wc -l` -ne 0 ]; then   	# Check whether git is installed
			echo "Do you want to check for updates?[y/n]"
			read option 
			if [ $option = 'y' ]; then
				git pull origin master
				sleep 0.5
			fi
		else 
			echo "Download git to check for updates"
			sleep 1
		fi
		new_epoch="$(echo "$(date +%s)")"		# Get the time when update was made
		sed -i s/"$last_epoch"/"$new_epoch" "$HOME/.TVshowLog/.location.log"	# Update last update time with new update time
	fi

	position=$(sed -n '1p' "$HOME/.TVshowLog/.location.log")			# Location of the script

# ASCII CODES for foreground colours and text attributes
NONE='\033[00m'
RED='\033[01;31m'
PINK='\033[0;31m'				# Might look like Red
GREEN='\033[01;32m'				# Might Look like yellow
YELLOW='\033[01;33m'			# Might look like Green
PURPLE='\033[01;35m'
CYAN='\033[01;36m'
LIGHT_CYAN='\033[0;36m'
WHITE='\033[01;37m'
BOLD='\033[1m'
UNDERLINE='\033[4m'


clear

# If your tv shows are on the other device which is connected to your LAN and has ssh server running then uncomment these lines
# Also change the IP address for the ping command in the next line, if needed

# if ping -c 1 192.168.1.100 | grep -q " 0% packet loss"; then		# Check if the connection is working between the devices
#	if [ $(ls $tvShow_location | wc -l) -eq 0 ]; then			# Mount only if it is not already mounted
#		echo "${GREEN} Mounting remote filesystem... ${NONE}"
#		sshfs username@ipAddress:"path_to_your_tv_shows_location_on_your_remote_device" "$tvShow_location"		# Mount TV Shows' directory from your local device to your remote device
#	fi
# else
#		echo "${RED} ${BOLD}Problem in connection...${NONE}"
#		sleep 1
#		exit
# fi

 if [ $(ls "$tvShow_location" | wc -l) -eq 0 ]; then
 	echo "Problem Loading TV shows"
 	echo "Check whether the specified location contains TV shows and is mounted"
 	rm "$HOME/.TVshowLog/.location.log"
 	exit
 fi 

showName() {

cd "$tvShow_location"

# CHECK DATABASE
for tv in */; do
	if [ ! -d "$HOME/.TVshowLog/$tv" ]; then		# If the directory doesnt exist
		mkdir "$HOME/.TVshowLog/$tv"
		echo "Database updated with new show named ${BOLD}$(echo $tv | tr -d "/")${NONE}"		# Update with new TV show
		sleep 0.5
	fi
	cd "$tv"
	for season in */; do 
		show=$(echo "$season" | tr -d "/")
		if [ ! -f "$HOME/.TVshowLog/$tv$show" ]; then		# If the log file does not exist in the database
			touch "$HOME/.TVshowLog/$tv$show"
		fi
	done
	cd ..
done

	clear		# Command to clear screen

# If -n or --nmae parameter is passed to the program
	if [ $# -eq 1 ]; then		# If only one argument is passed to this function
		if [ "$(ls | grep -i "$name" | wc -l )" -eq 1 ]; then 	# If only one show with name expression exists then enter that show's directory
			DIR="$(ls | grep -i $name)"
			cd "$(ls | grep -i $name)"
			showSeason "$DIR"
			return
		else 			# If more than one shows with that expression exist
			for i in `seq 1 $(ls | grep -i $name | wc -l)`; do
				echo "$i. $(ls | grep -i $name | head -n $i | tail -n 1)"
			done
				echo "${LIGHT_CYAN}>> ${NONE}" | tr -d "\n" 
				read num
				if [ $num -ne 0 -o $num -eq 0 2> /dev/null ]; then
					DIR="$(ls | grep -i $name | head -n $num | tail -n 1)"
					cd "$DIR"
					showSeason "$DIR"
					return
				else
					echo "Invalid Number..."
					sleep 0.5
				fi
		fi
	fi

# If -u -n parameters are passed to the program
	if [ $# -eq 2 ]; then		# If user wants to check only unwatched seasons of specified keyword
		if [ "$(ls | grep -i "$name" | wc -l )" -eq 1 ]; then 	# If only one show with name expression exists then enter that show's directory
			DIR="$(ls | grep -i $name)"
			cd "$DIR"
			iswatchedS "$DIR/" 	# Function call to check whether selected tv show is watched
			if [ $? -ne 1 ]; then  	# If this tv show is completely watched
				echo "Woah! You have watched $DIR completely..."
				echo "Press Enter key to continue"
				read enter
				clear
			else 
				cd "$DIR"
				showSeason "$DIR/"
				return
			fi
		else 			# If more than one shows with that expression exist
			for i in `seq 1 $(ls | grep -i $name | wc -l)`; do
				echo "$i. $(ls | grep -i $name | head -n $i | tail -n 1)"
			done
				echo "${LIGHT_CYAN}>> ${NONE}" | tr -d "\n" 
				read num
				if [ $num -ne 0 -o $num -eq 0 2> /dev/null ]; then		# To check that num is a actually a number
					DIR="$(ls | grep -i $name | head -n $num | tail -n 1)"
					cd "$DIR"
					iswatchedS "$DIR/"		# Function call to check whether selected tv show is watched
					if [ $? -ne 1 ]; then		# If the selected TV show is completely watched
						echo "Woah! You have watched $DIR completely..."
						echo "Press Enter key to continue" 
						read enter
						clear
					else
						cd "$DIR"
						showSeason "$DIR/"
						return
					fi
				else
					echo "Invalid Number..."
					sleep 0.5
				fi
		fi
	fi


	echo "${RED} ${BOLD} TV Shows: ${NONE}"		# Red colour
	int=0
	if [ $watch = '-u' 2> /dev/null ]; then
		for tvShow in */; do
			int=$((int+1))
			cd "$tvShow"
			iswatchedS "$tvShow"			# Function call to check whether whole show is watched
			if [ $? -eq 1 ]; then				
				if [ $int -lt 10 ]; then
					echo  " $int." $tvShow | tr -d "/"		# To trim "/" character
				else 
					echo  "$int." $tvShow | tr -d "/"
				fi
			else 
				continue
			fi
		done
	else
		for tvShow in */ 					# Display tv shows
		do
			int=$((int+1))
			if [ $int -lt 10 ]; then
				echo  " $int." $tvShow | tr -d "/"		# To trim "/" character
			else 
				echo  "$int." $tvShow | tr -d "/"
			fi
		done
	fi
	
	echo "${GREEN}# Enter the number of the Show ${NONE}"
	echo "${LIGHT_CYAN}>> ${NONE}" | tr -d "\n"			# deletes \n from echo so that next command is executed on same line i.e read command
	read showNumber
	
	if [ -z $showNumber ]; then 		# If user hasn't entered anything, i.e length of entered string is zero
		echo "Enter valid number..."
		sleep 1
		showName
		return
	elif [ $showNumber = 'h' ]; then
		clear
		cat "$HOME/.TVshowLog/.help.txt"
		echo "${bold}${RED}Press any key to exit ${NONE}"
		read enter
		cd "$position"				# This is required
		sh "$position/$script_name"
		exit
		
	elif [ $showNumber = 'quit' ] || [ $showNumber = 'q' ]; then			# Quit
		for i in T h a n k "-" Y o u; do echo -n $i; sleep 0.10; done; echo; sleep 0.2
		clear
		exit
	elif [ $showNumber = 's' ]; then
		setwatchedT		# Function to set a TV show as watched
		showName
		return
	elif [ $showNumber = 'search' ]; then
		echo "${GREEN}Enter a keyword to search ${NONE}"
		read tname

		if [ "$(ls | grep -i "$tname" | wc -l )" -eq 1 ]; then 	# If only one show with name expression exists then enter that show's directory
			DIR="$(ls | grep -i $tname)"
			cd "$DIR"
			
			if [ $watch = '-u' 2> /dev/null ]; then
				iswatchedS "$DIR/" 	# Function call to check whether selected tv show is watched
				
				if [ $? -ne 1 ]; then  	# If this tv show is completely watched
					echo "Woah! You have watched $DIR completely..."
					echo "Press Enter key to continue"
					read enter
					showName
				else 
					cd "$DIR"
					showSeason "$DIR/"
					return
				fi
		    else
		    	
		    	showSeason "$DIR/"
		    	return
		    fi
		else 			# If more than one shows with that expression exist
			for i in `seq 1 $(ls | grep -i $tname | wc -l)`; do
				echo "$i. $(ls | grep -i $tname | head -n $i | tail -n 1)"
			done
				echo "${LIGHT_CYAN}>> ${NONE}" | tr -d "\n" 
				read num
				if [ $num -ne 0 -o $num -eq 0 2> /dev/null ]; then
					DIR="$(ls | grep -i $tname | head -n $num | tail -n 1)"
					cd "$DIR"
					if [ $watch = '-u' 2> /dev/null ]; then
						iswatchedS "$DIR/" 	# Function call to check whether selected tv show is watched
						if [ $? -ne 1 ]; then		# If the selected TV show is completely watched
							echo "Woah! You have watched $DIR completely..."
							echo "Press Enter key to continue"
							read enter
							showName
						else 		# Else if the tv show is not watched yet, then show seasons
							cd "$DIR"
							showSeason "$DIR/"
							return
						fi
					else
						showSeason "$DIR/"
						return
					fi
				else
					echo "Invalid Number..."
					sleep 0.5
					showName
				fi
		fi


	elif [ $showNumber = 'a' ] && [ $watch = '-u' 2> /dev/null ]; then			# To Shift from "show unwatched" to "show all"
		cd "$position"				# This is required
		sh "$position/$script_name"
		exit
	elif [ $showNumber = 'u' ]; then			# To watch unwatched TV shows
		cd "$position"				# This is required
		sh "$position/$script_name" -u 									# Call tv with "u" as argument for that
		exit
	elif [ $showNumber -gt $int 2> /dev/null ]; then			# If the entered number is greater than availabale options
		echo "Enter valid number..."
		sleep 1
		showName
		return
	elif [ $showNumber -ne 0 -o $showNumber -eq 0 2> /dev/null ]; then 			# Check whether entered value is an integer
		DIR=`for i in */; do echo $i; done | head -n $showNumber | tail -n 1`
		cd "$DIR"		#Enter particular tv show
	else
		echo "Enter valid number..."
		sleep 1
		showName
		return
	fi
	
	showSeason "$DIR"	#Function Call with argument
}


# Function to generate random Episodes
generateRandom() {
	count=$1
	echo $(shuf -i 1-$count -n 1)
}

showSeason() {
DIR=$1		# Argument passed to this Function

clear		# Command to clear screen
echo "${PINK}${BOLD} $DIR: ${NONE}" | tr -d "/"
count=0

# TESTING 
if [ $watch = '-u' 2> /dev/null ]; then			# IF argument is passed
	for int in */; do 
	count=$((count+1))
		cd "$int"
		iswatched "$DIR" "$int"
		if [ $? -eq 1 ]; then		
			if [ $count -lt 10 ]; then
				echo " $count."$int | tr -d "/"
			else
				echo "$count."$int | tr -d "/"
			fi
		else
			continue
		fi
	done
else 									# If argument is not passed
	for season in */				# Display season
do
	count=$((count+1))
	if [ $count -lt 10 ]; then
		echo " $count."$season | tr -d "/"
	else
		echo "$count."$season | tr -d "/"
	fi
done

fi

echo "${GREEN}# Enter Season number ${NONE}"
echo "${LIGHT_CYAN}>> ${NONE}" | tr -d "\n"
read seasonNumber


if [ -z $seasonNumber ]; then 		# If user hasn't entered anything, i.e length of entered string is zero
	echo "Enter vaid number..."
	sleep 1
	showSeason "$DIR"
	return
elif [ $seasonNumber = 'b' ] || [ $seasonNumber = 'B' ] || [ $seasonNumber = 'back' ] 	#Go back
	then 
	cd ..
	showName
	return
	
elif [ $seasonNumber = 'quit' ] || [ $seasonNumber = 'q' ]; then		# Quit
	for i in T h a n k "-" Y o u; do echo -n $i; sleep 0.1; done; echo; sleep 0.2
	clear
	exit

	# To Generate Random Number
elif [ $seasonNumber = 'r' ] || [ $seasonNumber = 'R' ]; then		
	random=$( generateRandom $count )
	Season=`for i in */; do echo $i; done | head -n $random | tail -n 1`
	cd "$Season"
elif [ $seasonNumber = 's' ]; then
	setwatchedS	"$DIR"					# To set complete SEASON as WATCHED
	showSeason "$DIR"
	return
elif [ $seasonNumber -gt $count 2> /dev/null ]; then		# If entered number is greater than available numbers
	echo "Enter valid number..."
	sleep 1 
	showSeason "$DIR"
	return
elif [ $seasonNumber -ne 0 -o $seasonNumber -eq 0 2> /dev/null ]; then			# Check whether entered value is an integer

	Season=`for i in */; do echo $i; done | head -n $seasonNumber | tail -n 1`
	cd "$Season"		#Enter the season 
else
	echo "Enter valid number..."
	sleep 1
	showSeason "$DIR"
	return
fi

showEpisode "$DIR" "$Season"		# Function call with argument

}


showEpisode() {
Dir=$1
			
Season=$2
show=$(echo "$Season" | tr -d "/")					# To remove / from the directory name so that I can use this to browse log entries
count=$(ls | grep -E '*.mp4|*.mkv|*.avi' | wc -l)

clear		# Command to clear screen

echo "${PINK}${BOLD} $Dir ${NONE}${YELLOW}$Season: ${NONE}" | tr -d "/"

for i in `seq 1 $(ls | grep -E '*.mp4|*.mkv|*.avi' | wc -l)`; do 			# seq command used to get range of number of episodes
value=`ls | grep -E '*.mp4|*.mkv|*.avi' | head -n $i | tail -n 1`

# FOR WATCHED EPISODES

	if [ $watch = '-u' 2> /dev/null ]; then 	# If total number of arguments is one and it is set to u
		if grep -q "$value" "$HOME/.TVshowLog/$Dir$show"; then		# Ignore episodes that are in the log
			continue
		else
			if [ $i -lt 10 ]; then
				echo " $i. $value"			#Print Episode's number before 10
			else
				echo "$i. $value"
			fi
		fi
	else
		if [ $i -lt 10 ]; then
				echo " $i. $value"			#Print Episode's number before 10
			else
				echo "$i. $value"
			fi
	fi
done

echo "${GREEN}# Choose Episode number ${NONE}"
echo "${LIGHT_CYAN}>> ${NONE}" | tr -d "\n"
read epNumber


if [ -z $epNumber ]; then 		# If user hasn't entered anything, i.e length of entered string is zero
	echo "Enter valid number..."
	sleep 1							# Sleep for 1 second
	showEpisode "$Dir" "$Season"		# Function call with parameters
	return
elif [ $epNumber = 'b' ] || [ $epNumber = 'B' ] || [ $epNumber = 'back' ] 	# Go back
	then 
	cd .. 
	showSeason "$Dir"		# Call function with $Dir as argument
	return
elif [ $epNumber = 's' ]; then
	setwatchedE "$Dir" "$Season"			# Function call to set EPISODE as WATCHED
	showEpisode "$Dir" "$Season"
	return
elif [ $epNumber = 'u' ]; then
	setunwatchedE "$Dir" "$Season"
	showEpisode "$Dir" "$Season"
	return
elif [ $epNumber = 'quit' ] || [ $epNumber = 'q' ]; then		# Quit
	for i in T h a n k "-" Y o u; do echo -n $i; sleep 0.1; done; echo; sleep 0.2
	clear
	exit

# To generate Random Episodes
elif [ $epNumber = 'r' ]; then				# Generate Random Number
	random=$( generateRandom $count )
	Episode=`ls | grep -E '*.mp4|*.mkv|*.avi' | head -n $random | tail -n 1`
	echo "Playing $Episode..."
	vlc -f "$Episode" 2> /dev/null			#Play Random episode using vlc
	
	# Ask whether current episode is watched
	echo "${GREEN}# Did you watch this episode? (y/n) ${NONE}"
	echo "${LIGHT_CYAN}>> ${NONE}" | tr -d "\n"
	read answer
	if [ $answer = 'y' ]; then 
		if grep -q "$Episode" "$HOME/.TVshowLog/$Dir$show"; then		# Does not repeat the entries in log file
			continue
		else
			echo "$Episode" >> "$HOME/.TVshowLog/$Dir$show"			# Add the entry of the episode to watched list
			sort "$HOME/.TVshowLog/$Dir$show" -o "$HOME/.TVshowLog/$Dir$show"
			echo "Successfully set $Episode as watched"
			sleep 1
		fi
	else
		continue
	fi

elif [ $epNumber -gt $count 2> /dev/null ]; then 		# If entered number is greater than availabe options
	echo "Enter valid number..."	
	sleep 1	
	showEpisode "$Dir" "$Season"
	return
elif [ $epNumber -ne 0 -o $epNumber -eq 0 2> /dev/null ]; then		# Check whether entered value is an integer
	Episode=`ls | grep -E '*.mp4|*.mkv|*.avi' | head -n $epNumber | tail -n 1`
	echo "Playing $Episode..."
	vlc -f "$Episode" 2> /dev/null				#Play episode using vlc in full screen
	
	# Ask whetehr current episode is watched
	echo "${GREEN}# Did you watch this episode? (y/n) ${NONE}"
	echo "${LIGHT_CYAN}>> ${NONE}" | tr -d "\n"
	read answer
	if [ $answer = 'y' ]; then 
		if grep -q "$Episode" "$HOME/.TVshowLog/$Dir$show"; then	# Does not repeat the entries in log file
			continue
		else
			echo "$Episode" >> "$HOME/.TVshowLog/$Dir$show"			# Add the entry of the episode to watched list
			sort "$HOME/.TVshowLog/$Dir$show" -o "$HOME/.TVshowLog/$Dir$show" 	# Sort log file
			echo "Successfully set $Episode as watched"
			sleep 1
		fi
	else
		continue
	fi
else
	echo "Enter valid number..."	
	sleep 1	
	showEpisode "$Dir" "$Season"
	return
fi

clear  		 # Command to clear screen

	showEpisode "$Dir" "$Season"		# Go to episodes section again after watching the video
	return
}

setwatchedE() {
	Dir=$1
	
	Season=$2
	show=$(echo "$Season" | tr -d "/")

	for i in `seq 1 $(ls | grep -E '*.mp4|*.mkv|*.avi' | wc -l)`; do 			# seq command used to get range of number of episodes
value=`ls | grep -E '*.mp4|*.mkv|*.avi' | head -n $i | tail -n 1`
		if grep -q "$value" "$HOME/.TVshowLog/$Dir$show"; then		# Display unwatched episodes only
			continue
		else
			if [ $i -lt 10 ]; then
				echo " $i. $value"			#Print Episodes before 10
			else
				echo "$i. $value"
			fi
		fi
done
echo "${GREEN}# Choose Episode number to set WATCHED ${NONE}"
echo "${LIGHT_CYAN}>> ${NONE}" | tr -d "\n"
read epNumber

if [ $epNumber = 'r' ]; then			# RANGE
	echo "Enter First number"
	read firstNumber
	echo "Enter second number"
	read secondNumber
	i=$firstNumber

	# RANGE
	while [ $i -le $secondNumber ]; do
		Episode=`ls | grep -E '*.mp4|*.mkv|*.avi' | head -n $i | tail -n 1`
		if grep -q "$Episode" "$HOME/.TVshowLog/$Dir$show"; then		# If the episode is already in the log then ignore
			continue
		else
			echo "$Episode" >> "$HOME/.TVshowLog/$Dir$show"
			sort "$HOME/.TVshowLog/$Dir$show" -o "$HOME/.TVshowLog/$Dir$show"
		fi
		echo "Successfully set $Episode as watched"
		sleep 0.5
		i=$((i+1))
	done
	# INDIVIDUAL
elif [ $epNumber -ne 0 -o $epNumber -eq 0 2> /dev/null ]; then		# Check whether entered value is an integer
	if [ $epNumber -gt $count 2> /dev/null ]; then 		# If entered number is greater than availabe options
		echo "Enter valid number..."	
		sleep 1	
		return
	else
		Episode=`ls | grep -E '*.mp4|*.mkv|*.avi' | head -n $epNumber | tail -n 1`
		if grep -q "$Episode" "$HOME/.TVshowLog/$Dir$show"; then		 # If the episode is already in the log then ignore
			continue
		else
			echo "$Episode" >> "$HOME/.TVshowLog/$Dir$show"
			sort "$HOME/.TVshowLog/$Dir$show" -o "$HOME/.TVshowLog/$Dir$show"
		fi
		echo "Successfully set $Episode as watched"
		sleep 0.5
	fi
else
	return 
fi

}

setwatchedS() {

	Dir=$1				# TV show name
	
	echo "${GREEN}# Enter the number of the Season to set watched ${NONE}"
	count=0
for season in */				#Display season
do	 
	count=$((count+1))
		cd "$season"
		iswatched "$DIR" "$season"
		if [ $? -eq 1 ]; then		
			if [ $count -lt 10 ]; then
				echo " $count."$season | tr -d "/"
			else
				echo "$count."$season | tr -d "/"
			fi
		fi
done

echo "${LIGHT_CYAN}>> ${NONE}" | tr -d "\n"
read seasonNumber

# Some Basic conditions
if [ $seasonNumber = 'r' ]; then			# set as watched in RANGE
	echo "Enter First number"
	read firstNumber
	if [ $firstNumber -lt 1 ]; then
		echo "Invalid Number"
		sleep 1
		return
	fi
	echo "Enter second number"
	read secondNumber
	if [ $secondNumber -gt $(echo $(ls | wc -l)) ] || [ $firstNumber -gt $secondNumber ]; then
		echo "Invalid Number"
		sleep 1
		return
	fi
	
	# RANGE
	num=$firstNumber
	while [ $num -le $secondNumber ]; do 				# while the last number in the range is reached
	Season=`for i in */; do echo $i; done | head -n $num | tail -n 1`
	show=$(echo "$Season" | tr -d "/")
	num=$((num+1))
		cd "$Season"		#Enter the season

		for i in `seq 1 $(ls | grep -E '*.mp4|*.mkv|*.avi' | wc -l)`; do 			# seq command used to get range of number of episodes
			value=`ls | grep -E '*.mp4|*.mkv|*.avi' | head -n $i | tail -n 1`
			if grep -q "$value" "$HOME/.TVshowLog/$Dir$show"; then		# If the episode is already in the log then ignore
				continue
			else
				echo "$value" >> "$HOME/.TVshowLog/$Dir$show"			# Else add in the log list
			fi
		done

		sort "$HOME/.TVshowLog/$Dir$show" -o "$HOME/.TVshowLog/$Dir$show" 	# Sort log file
		echo "Successfully set $Season as watched"
		sleep 0.5
		cd ..
	done
	
# INDIVIDUALLY
elif [ $seasonNumber -ne 0 -o $seasonNumber -eq 0 2> /dev/null ]; then			# Check whether entered value is an integer
	if [ $seasonNumber -gt $count 2> /dev/null ]; then		# If entered number is greater than available numbers
		echo "Enter valid number..."
		sleep 1 
		return
	else
		Season=`for i in */; do echo $i; done | head -n $seasonNumber | tail -n 1`
		show=$(echo "$Season" | tr -d "/")
		cd "$Season"		#Enter the season

		for i in `seq 1 $(ls | grep -E '*.mp4|*.mkv|*.avi' | wc -l)`; do 			# seq command used to get range of number of episodes
			value=`ls | grep -E '*.mp4|*.mkv|*.avi' | head -n $i | tail -n 1`
			if grep -q "$value" "$HOME/.TVshowLog/$Dir$show"; then		# If the episode is already in the log then ignore
				continue
			else
				echo "$value" >> "$HOME/.TVshowLog/$Dir$show"			# Else add in the log list
			fi
		done
		sort "$HOME/.TVshowLog/$Dir$show" -o "$HOME/.TVshowLog/$Dir$show" 	# Sort log file
		echo "Successfully set $Season as watched"
		cd ..
		sleep 0.5	
	fi
else
	return
fi

}

setwatchedT() {

	int=0
	for tvShow in */ 					# Display tv shows
	do
		int=$((int+1))
			cd "$tvShow"
			iswatchedS "$tvShow"			# Function call to check whether whole show is watched
			if [ $? -eq 1 ]; then				
				if [ $int -lt 10 ]; then
					echo  " $int." $tvShow | tr -d "/"		# To trim "/" character
				else 
					echo  "$int." $tvShow | tr -d "/"
				fi
			fi
	done
	
	echo "${GREEN}# Enter the number of the Show to set WATCHED ${NONE}"
	echo "${LIGHT_CYAN}>> ${NONE}" | tr -d "\n"			# deletes \n from echo so that next command is executed on same line i.e read command
	read showNumber

	if [ $showNumber -ne 0 -o $showNumber -eq 0 2> /dev/null ]; then 			# Check whether entered value is an integer
		if [ $showNumber -gt $int 2> /dev/null ]; then			# If the entered number is greater than availabale options
			echo "Enter valid number..."
			sleep 1
			return
		else
			DIR=`for i in */; do echo $i; done | head -n $showNumber | tail -n 1`
			cd "$DIR"		#Enter particular tv show
			
			for j in */; do
				cd "$j" 	# Enter every Season
				show=$(echo "$j" | tr -d "/")				# TO remove / from Season name
				for i in `seq 1 $(ls | grep -E '*.mp4|*.mkv|*.avi' | wc -l)`; do 			# seq command used to get range of number of episodes
					value=`ls | grep -E '*.mp4|*.mkv|*.avi' | head -n $i | tail -n 1`
					if grep -q "$value" "$HOME/.TVshowLog/$DIR$show"; then		# If the episode is already in the log then ignore
						continue
					else
						echo "$value" >> "$HOME/.TVshowLog/$DIR$show"			# Else add in the log list
					fi
				done
				sort "$HOME/.TVshowLog/$DIR$show" -o "$HOME/.TVshowLog/$DIR$show" 	# Sort the log file
				echo "Successfully set $DIR$j as watched"
				sleep 0.5
				cd ..
			done
			cd ..
		fi
	else
		return 
	fi
}

# A function which will return boolean value after checking whether all episodes of this season is watched
iswatched() {

	Dir=$1								# TV show name
	
	Season=$2
	show=$(echo "$Season" | tr -d "/")

	value=$(ls | grep -E '*.mp4|*.mkv|*.avi' | wc -l)
	if [ $(cat "$HOME/.TVshowLog/$Dir$show" | wc -l) -eq $value ]; then	# If all episodes are in the entry
		cd ..
		return 0
	else
		cd ..
		return 1
	fi

}

iswatchedS() {

	Dir=$1

	for season in */; do
		 				
	show=$(echo "$season" | tr -d "/")
	lines=$(ls "$season" | grep -E '*.mp4|*.mkv|*.avi' | wc -l)				# Seasons in actual TV show directory
		if [ ! $(cat "$HOME/.TVshowLog/$Dir$show" | wc -l) -eq $lines ]; then		# compared with number of episodes in the log list
			cd ..
			return 1		
		fi
	done

	cd .. 
	return 0
		
}

# SET a specific episode as UNWATCHED

setunwatchedE() {

	Dir=$1					# TV show name
	
	Season=$2
	show=$(echo "$Season" | tr -d "/")

	for i in `seq 1 $(ls | grep -E '*.mp4|*.mkv|*.avi' | wc -l)`; do 			# seq command used to get range of number of episodes
value=`ls | grep -E '*.mp4|*.mkv|*.avi' | head -n $i | tail -n 1`
		if grep -q "$value" "$HOME/.TVshowLog/$Dir$show"; then		# Display unwatched episodes only
			if [ $i -lt 10 ]; then
				echo " $i. $value"			#Print Episodes before 10
			else
				echo "$i. $value"
			fi			
		else
			continue
		fi
done
echo "${GREEN}# Choose Episode number to set UNWATCHED ${NONE}"
echo "${LIGHT_CYAN}>> ${NONE}" | tr -d "\n"
read epNumber

# RANGE
if [ $epNumber = 'r' ]; then
	echo "Enter First Number"
	read firstNumber									# First number of the range
	if [ $firstNumber -eq 0 ] || [ $firstNumber -gt $(ls | wc -l) ]; then
		return
	fi
	echo "Enter second number"
	read secondNumber								# Second number of the range
	if [ $firstNumber -gt $secondNumber ] || [ $secondNumber -gt $(ls | wc -l) ]; then
		return
	fi
	while [ $firstNumber -le $secondNumber ]; do
		Episode=`ls | grep -E '*.mp4|*.mkv|*.avi' | head -n $firstNumber | tail -n 1`
		firstNumber=$((firstNumber+1))										# increment number
		sed -i /"$Episode"/d "$HOME/.TVshowLog/$Dir$show"				# Delete the entry from log
		sort "$HOME/.TVshowLog/$Dir$show" -o "$HOME/.TVshowLog/$Dir$show" 	# Sort log file
		echo "Successfully set $Episode as UNWATCHED"
		sleep 1
	done
fi

# INDIVIDUALLY
if [ $epNumber -ne 0 -o $epNumber -eq 0 2> /dev/null ]; then		# Check whether entered value is an integer
	if [ $epNumber -gt $count 2> /dev/null ]; then 		# If entered number is greater than availabe options
		echo "Enter valid number..."	
		sleep 1	
		return
	else
		Episode=`ls | grep -E '*.mp4|*.mkv|*.avi' | head -n $epNumber | tail -n 1`
		sed -i /"$Episode"/d "$HOME/.TVshowLog/$Dir$show"				# Delete the entry from log
		sort "$HOME/.TVshowLog/$Dir$show" -o "$HOME/.TVshowLog/$Dir$show" 	# Sort log file
		echo "Successfully set $Episode as UNWATCHED"
		sleep 1
	fi
else
	return 
fi

}

# Main starts here

if [ $# -ne 0 ]; then		# If number of parameters is not zero
	if [ $watch = '--name' 2> /dev/null ] || [ $watch = '-n' 2> /dev/null ]; then
		showName $watch 		#function call
	elif [ $arg2 = '-n' 2> /dev/null ]; then
			showName $watch $name 	# If 2 parameters 
	else
		showName
	fi
else 
	showName
fi

tput sgr0		# Resets all color changes made in terminal
exit
#END
