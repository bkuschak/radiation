#!/bin/sh
#
# Run the radiation counter and update the website with frequent plots
#
# prerequisites:
# sudo apt-get install ncftp gnuplot alsa-utils

UPDATE_PERIOD_SEC=300
LOCATION="Sunnyvale, CA"
DETECTOR_TYPE="Scionix 38B57/1.5M PMT + 38x38mm NaI(Tl)"

# Make a gnuplot command file
cat << EOF > plot.gp
set term png font arial 12 size 1280,640
set output 'latest_radiation.png'

set xdata time
set timefmt '%s'
set format x "%H:%M\n%m-%d"
set grid 

set title "Radiation Level in $LOCATION\n$DETECTOR_TYPE"
set ylabel 'Counts / min'
set xlabel 'UTC Time'

plot 'latest.log' using 1:3 with lines title 'Detector #1' lw 2
EOF

# Continuously capture and log
# If we run as root or SUID-root, we can bump the record thread to higher priority
nice --1 arecord -f S16_LE -c 1 -r 48000  -t raw -D hw:1,0 | ./counter >> log.txt &

# Periodically generate plots and upload to website
while true; do 
	# Assuming file is logged at constant rate, compute the period
	PERIOD=$(tail -2 log.txt  |awk ' {t[NR] = $1} END {print t[NR]-t[NR-1]}')
	LINES=$((86400/$PERIOD))

	# Get one days' worth of lines
	tail -$LINES log.txt > latest.log
	gnuplot plot.gp

	# upload plot to FTP server
	DIR=$(grep ^directory login.txt |sed 's?directory ??g')
	ncftpput -f login.txt $DIR latest_radiation.png

	sleep $UPDATE_PERIOD_SEC

done
echo "Exiting!"

