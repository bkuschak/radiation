This is a simple command line app to track counts/min from a scintillation 
probe.  Meant for use on Beaglebone Black or Raspberry PI, as a continuous monitor.
Here is an example of a daily plot when things are quiet. (The slow drift is temperature-related.)

![Daily Radiation Plot](latest_radiation.png?raw=true "Daily Radiation Plot")

Setup:
- I'm using the Theremino PMT adapter with a PMT/scintillator
- Use the USB audio device that comes with Theremino.
- Old Raspberry Pi and externally powered USB hub. 

We use the ALSA utility program arecord to grab raw samples and then process them.

The code at this point uses only 2% CPU on a RasPi.

-----
INSTALLATION

Install ncftp if necessary:

	apt-get update
	apt-get install ncftp

Create a file called login.txt that contains you FTP login credentials, like this:

	host ftpserver.com
	user username
	pass password
	directory /path/for/upload

Run the script run.sh to do everything automatically.  It logs the data periodically into 
a logfile (of unlimited length!) and generates daily plots, uploading those to a website.

To have this program start at boot, add a line to /etc/rc.local:

	(cd /<path_to_this_directory>/git/radiation/counter && ./run.sh) &

-----

For simple testing, you can just run the counter program like this:
arecord -f S16_LE -c 1 -r 48000  -t raw -D hw:1,0 | ./counter

To inspect raw samples, you can do this: 
arecord -f S16_LE -c 1 -r 48000  -t raw -d 1 -D hw:1,0 |hexdump




