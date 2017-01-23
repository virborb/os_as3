#!/bin/bash

# Tests the noop, deadline and cfq io shedulers.
# For the benchmark to work this script must 
# be on the disc that you want test.
# The name of the disc should be send as an 
# argument to the script.
# It must be run with root access otherwise it
# can't change the schedulers.

declare -a shed=(noop deadline cfq)

if [ $# -ne 1 ]; then
    echo $0: usage: bench.sh disc
    exit 1
fi

tmp=`cat /sys/block/sda/queue/scheduler | grep -o -P '(?<=\[).*(?=\])'`
disc=$1
nr=10

# Creates test file to read
dd bs=1M count=1k if=/dev/zero of=test_file 2> /dev/null

for i in ${shed[@]}
do
	#Changes the io sheduler
	echo $i > /sys/block/${disc}/queue/scheduler
	cat /sys/block/${disc}/queue/scheduler

	# Runs ten write operations
	for j in `seq 1 $nr`
	do
		dd bs=1M count=1k if=/dev/zero of=file$j conv=fdatasync 2> $j &
		PIDS[${j}]=$!
	done
	
	dd bs=1M if=test_file of=/dev/null 2> read 

	# Prints out result and removes files
	for j in `seq 1 $nr`
	do
	        wait ${PIDS[${j}]}
	        cat $j | grep -o -P '(?<=copied, ).*(?= s,)'
	        rm $j
	        rm file$j
	done
	echo "Writes-Starving-Reads:"
	cat read | grep -o -P '(?<=copied, ).*(?= s,)'
	rm read


done

rm test_file

#resets the io sheduler
echo $tmp > /sys/block/${disc}/queue/scheduler