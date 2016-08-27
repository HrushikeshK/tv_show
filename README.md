# tv_show
#### Watch and manage your TV shows from command line.

### Requirements:
* vlc media player
* Linux OS
* git

### Installation:
* Open your terminal and type `$ git clone https://github.com/hrushikeshk/tv_show.git`
* A folder with name "tv_show" will be created in which necessary files are placed.
* `$ cd tv_show`
* `$ ./install.sh`

### While running program for first time
* You need to specify the path to your TV shows directory.
* The format must be: TV show name(directory) -> Season number(directory) -> episodes(media files)
* There should not be an extra directory between episodes and Season Number. e.g: The following path won't work
  TvShows/Show_name/Show_season/Extra_directory/episode.mp4

#### If your tv shows are on the other device which is connected to your LAN and has ssh server running
* Install sshfs utility. To install sshfs, type
  `$ apt-get install sshfs` on the terminal
* Uncomment a line from the code which says `mountFS`
* Create a mount point (create a directory in your home directory. This will act as a mount point) to mount it virtually. The command sshfs is used to mount virtually.
* For example: If your remote device is a Raspberry Pi with ip "192.168.1.101" and username "pi", then the complete command can look like this(example): 
  `sshfs pi@192.168.1.101:"/media/pi/MY_HD/TV_shows/" "/mount_point/"`
