#!/usr/bin/env bash

cd $1

for file in $(find -name "*.[Vv][Oo][Bb]" -size +10M)
do
	bsnm="$2${file#./}"
	bsnm="${bsnm%.VOB}.avi"
	echo "out: $bsnm"
	ffmpeg -i $file ~/tmp/$bsnm
done
