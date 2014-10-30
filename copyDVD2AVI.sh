#!/usr/bin/env bash

############################################################################
##
##  这是一个将 DVD 中的视频转换为 AVI 的脚步。
##  ./copyDVD2AVI.sh /path/ ["AVI文件名前缀"]
##
############################################################################

cd $1

for file in $(find -name "*.[Vv][Oo][Bb]" -size +10M)
do
	bsnm="$2${file#./}"
	bsnm="${bsnm%.VOB}.avi"
	echo "out: $bsnm"
	ffmpeg -i $file ~/tmp/$bsnm
done
