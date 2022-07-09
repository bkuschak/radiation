This is a simple command line app to track counts/min from a scintillation 
probe.  It is meant for use as a continuous monitor, running on a Beaglebone Black or Raspberry PI.

Below is a daily plot on a day with several passing thunderstorms.
The radiation spikes are due to a phenomenon called radon washout. The slow drift is temperature-related.
(The rain gauge was offline, so no data is available for rain rate in inches/hour).

![Daily Radiation Plot](daily_radiation_070322.jpg?raw=true "Daily Radiation Plot")

Setup:
- Theremino PMT adapter
- PMT + scintillator: Scionix 38B57/1.5M + 38x38mm NaI(Tl)
- USB audio device that comes with Theremino
- Beaglebone Black

The ALSA utility program 'arecord' is used to grab raw samples. A simple program then filters them and logs the data.

The code uses only 2% CPU on a RasPi and a bit less on a Beaglebone.

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
