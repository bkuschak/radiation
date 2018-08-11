#!/bin/sh
#
# Run the radiation counter and update the website with frequent plots
#
# prerequisites:
# sudo apt-get install ncftp gnuplot alsa-utils

UPDATE_PERIOD_SEC=600
LOCATION="Sunnyvale, CA"
DETECTOR_TYPE="Scionix 38B57/1.5M PMT + 38x38mm NaI(Tl)"

# Make gnuplot command files:

# Daily
cat << EOF > plot.gp
set term png font arial 12 size 1280,640
set output 'latest_radiation.png'

set xdata time
set timefmt '%s'
set format x "%H:%M\n%m-%d"
set grid 
set autoscale xfix

set title "Radiation Level in $LOCATION\n$DETECTOR_TYPE"
set ylabel 'Counts / min'
set xlabel 'UTC Time'

plot 'latest.log' using 1:3 with lines title 'Detector #1' lw 2
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

plot 'weekly.log' using 1:3 with lines title 'Detector #1' lw 2
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

plot 'monthly.log' using 1:3 with lines title 'Detector #1' lw 2
EOF

# Continuously capture and log
# If we run as root or SUID-root, we can bump the record thread to higher priority
nice --1 arecord -f S16_LE -c 1 -r 48000  -t raw -D hw:1,0 | ./counter >> log.txt &

# Periodically generate plots and upload to website
while true; do 
	# Assuming file is logged at constant rate, compute the period
	PERIOD=$(tail -2 log.txt  |awk ' {t[NR] = $1} END {print t[NR]-t[NR-1]}')
	LINES_DAY=$((86400/$PERIOD))
	LINES_WEEK=$((7*86400/$PERIOD))
	LINES_MONTH=$((30*86400/$PERIOD))

	# Get one day worth of lines
	tail -$LINES_DAY log.txt > latest.log
	gnuplot plot.gp

	# Get one week worth of lines
	tail -$LINES_WEEK log.txt > weekly.log
	gnuplot plot_weekly.gp

	# Get one month worth of lines
	tail -$LINES_MONTH log.txt > monthly.log
	gnuplot plot_monthly.gp

	# upload plots to FTP server
	DIR=$(grep ^directory login.txt |sed 's?directory ??g')
	ncftpput -f login.txt $DIR latest_radiation.png weekly_radiation.png monthly_radiation.png

	sleep $UPDATE_PERIOD_SEC

done
echo "Exiting!"

