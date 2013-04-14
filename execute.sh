#!/bin/bash
FEEDBACK=false
while getopts ri:o:m:d: option
do
    case "${option}" in
		r) FEEDBACK=true;;
		i) INPUT=${OPTARG};;
		o) OUTPUT=${OPTARG};;
		m) MODEL=${OPTARG};;
		d) NTCIR=${OPTARG};;
	esac
done

if $FEEDBACK
then
	ruby main.rb -r-i $INPUT -o $OUTPUT -m $MODEL -d $NTCIR
else
	ruby main.rb -i $INPUT -o $OUTPUT -m $MODEL -d $NTCIR
fi