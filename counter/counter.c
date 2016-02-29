// Simple program to record radiation count rate from the Theremino 
// Use the USB-Audio stick as the input source, and call this program 
// like this:
//
// (Note: might need to adjust hw:1,0 to match your USB audio source)
// arecord -f S16_LE -c 1 -r 48000  -t raw -D hw:1,0 |./main 

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>

// This must match the incoming rate
#define SAMPLE_RATE		48000

// Time in seconds for each count average to be output
#define OUTPUT_RATE		60	

// Comparator threshold for triggering
#define THRESHOLD		3500

#ifndef elemof
#define elemof(a) 	((sizeof(a) / sizeof((a)[0])))
#endif

// Sample buffer: S16_LE
short buf[16*1024];


int main(int argc, char **argv) 
{
	int ret, i;
	short s, min, max;
	int comp_state = 0;
	unsigned long comp_counter = 0;
	unsigned long last_comp_counter = 0;
	int comp_threshold = THRESHOLD;
	unsigned long sample_counter = 0;
	unsigned long last_sample_counter = 0;
	float rate;

	// read from stdin
	while((ret = read(0, buf, elemof(buf))) != EOF && ret != 0) {
		sample_counter += ret / sizeof(buf[0]);
		min = 0;
		max = 0;
		for(i=0; i<ret; i++) {
			s = buf[i];

			// compute some stats
			if(s > max)
				max = s;
			if(s < min)
				min = s;

			// comparator
			if(s > comp_threshold && comp_state == 0) {
				comp_state = 1;
				comp_counter++;
			}
			else if(s < comp_threshold && comp_state == 1) {
				comp_state = 0;
			}
		}

		// counts/sec
		// fixme - we should make this available via socket
		if((sample_counter-last_sample_counter) >= OUTPUT_RATE * SAMPLE_RATE) {
			rate =  (float)(comp_counter - last_comp_counter) / 
				(sample_counter - last_sample_counter) * SAMPLE_RATE;
			last_comp_counter = comp_counter;
			last_sample_counter = sample_counter;

			fprintf(stdout, "%lu %.2f %.1f %lu %d\n", time(NULL), rate, rate*60, comp_counter, comp_threshold);
			fflush(stdout);
		}
		//fprintf(stdout, "%d %.2f %d %d %d\n", comp_counter, rate, min, max, ret);
		//fflush(stdout);
	}
	fprintf(stderr, "Exit!\n");
	return 0;
}

