#!/bin/bash
#
# Run the radiation counter and update the website with frequent plots
#
# prerequisites:
# sudo apt-get install ncftp gnuplot alsa-utils

UPDATE_PERIOD_SEC=600
LOCATION="Bend, OR"
DETECTOR_TYPE="Scionix 38B57/1.5M PMT + 38x38mm NaI(Tl)"
RAIN_GAUGE_LOG="../../arduino_oregon_sci_rx/rain_gauge.log"

# Kill subprocesses when this script exits.
# Note that the trap is not take effect while bash is running a command in the foreground.
# So later we will run commands in the background and then 'wait' for it to finish. 
# This will allow the trap to execute.
trap "trap - SIGTERM && /bin/kill -- -$$ && exit" SIGINT SIGTERM EXIT

# Make gnuplot command files:

# Daily
cat << EOF > plot_daily.gp
set term png font arial 12 size 1280,640
set output 'daily_radiation.png'

set xdata time
set timefmt '%s'
set format x "%H:%M\n%m-%d"
set grid 
set autoscale xfix

set title "Radiation Level in $LOCATION\n$DETECTOR_TYPE"
set ylabel 'Counts / min'
set xlabel 'UTC Time'
set y2label 'inches / hour'
set y2tics
set y2range [0:]

plot 'daily_rad.log' using 1:3 with lines title 'Detector #1' lw 2, \
     'daily_rain.log' using 1:4 with lines axes x1y2 title 'Rain Rate' lw 3 lc 3, \
     0 axes x1y2 notitle
EOF

# Weekly
cat << EOF > plot_weekly.gp
set term png font arial 12 size 1280,640
set output 'weekly_radiation.png'

set xdata time
set timefmt '%s'
set format x "%H:%M\n%m-%d"
set grid 
set autoscale xfix

set title "Weekly Radiation Level in $LOCATION\n$DETECTOR_TYPE"
set ylabel 'Counts / min'
set xlabel 'UTC Time'
set y2label 'inches / hour'
set y2tics
set y2range [0:]

plot 'weekly_rad.log' using 1:3 with lines title 'Detector #1' lw 2, \
     'weekly_rain.log' using 1:4 with lines axes x1y2 title 'Rain Rate' lw 3 lc 3, \
     0 axes x1y2 notitle
EOF

# Monthly
cat << EOF > plot_monthly.gp
set term png font arial 12 size 1280,640
set output 'monthly_radiation.png'

set xdata time
set timefmt '%s'
set format x "%H:%M\n%m-%d"
set grid 
set autoscale xfix

set title "Monthly Radiation Level in $LOCATION\n$DETECTOR_TYPE"
set ylabel 'Counts / min'
set xlabel 'UTC Time'
set y2label 'inches / hour'
set y2tics
set y2range [0:]

plot 'monthly_rad.log' using 1:3 with lines title 'Detector #1' lw 2, \
     'weekly_rain.log' using 1:4 with lines axes x1y2 title 'Rain Rate' lw 3 lc 3, \
     0 axes x1y2 notitle
EOF

# Continuously capture and log
# If we run as root or SUID-root, we can bump the record thread to higher priority
# Restart arecord if it crashes for some reason.
(while true; do nice --1 arecord -f S16_LE -c 1 -r 48000  -t raw -D hw:1,0 | ./counter >> log.txt; sleep 5; echo 'restarting'; done) &

# Periodically generate plots and upload to website
# Run this command in a subshell and wait (forever) for it to finish. This is needed for the trap above to work.
(while true; do 
	# Extract lines from log
	cat log.txt  |awk 'BEGIN {now=systime(); start=now-30*86400} {if($1 > start) { print $0 }}' > monthly_rad.log
	cat monthly_rad.log  |awk 'BEGIN {now=systime(); start=now-7*86400} {if($1 > start) { print $0 }}' > weekly_rad.log
	cat weekly_rad.log  |awk 'BEGIN {now=systime(); start=now-86400} {if($1 > start) { print $0 }}' > daily_rad.log

	# Extract the associated rain gauge data
	if [ "$RAIN_GAUGE_LOG" != "" ]; then
		cat $RAIN_GAUGE_LOG  |awk 'BEGIN {now=systime(); start=now-30*86400} {if($1 > start) { print $0 }}' > monthly_rain.log
		cat monthly_rain.log  |awk 'BEGIN {now=systime(); start=now-7*86400} {if($1 > start) { print $0 }}' > weekly_rain.log
		cat weekly_rain.log  |awk 'BEGIN {now=systime(); start=now-86400} {if($1 > start) { print $0 }}' > daily_rain.log
	else
		# Generate empty files
		cat monthly_rad.log |awk '{print $1 " 0 0 0"}' > monthly_rain.log
		cat weekly_rad.log |awk '{print $1 " 0 0 0"}' > weekly_rain.log
		cat daily_rad.log |awk '{print $1 " 0 0 0"}' > daily_rain.log
	fi

	# Create plots
	gnuplot plot_daily.gp
	gnuplot plot_weekly.gp
	gnuplot plot_monthly.gp

	# upload plots to FTP server
	DIR=$(grep ^directory login.txt |sed 's?directory ??g')
	ncftpput -f login.txt $DIR daily_radiation.png weekly_radiation.png monthly_radiation.png

	sleep $UPDATE_PERIOD_SEC
done) &

# Wait forever, or until trap executes.
wait	
echo "Exiting!"

