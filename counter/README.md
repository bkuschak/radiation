This is a simple command line app to track counts/min from a scintillation 
probe. Eventually meant for use on Beaglebone Black, as a continuous monitor.

Setup:
- I'm using the Theremino PMT adapter with a PMT/scintillator
- Use the USB audio device that comes with Theremino.
- Use the ALSA utility program arecord to grab raw samples

Run the program like this:
arecord -f S16_LE -c 1 -r 48000  -t raw -D hw:1,0 | ./counter

To inspect raw samples, you can do this: 
arecord -f S16_LE -c 1 -r 48000  -t raw -d 1 -D hw:1,0 |hexdump

Hopefully the BBB has enough horsepower to run this. Can likely reduce
sample rate lower if we run out of steam...

TODO - add logging to file or output to TCP socket.
