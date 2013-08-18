#!/bin/bash
DIR=$1
base=$(echo $DIR | perl -ne 'm|/Sample_([^/]*)|; print "s_$1";')
file1=$(ls $DIR/*MULTI.map|head -1)
OUT=$2
echo "OUT="$OUT
head -1 $file1 >$OUT
ls $DIR/*MULTI.map | xargs fgrep -hv mixer | sort -S 80g -T /scratch/socci -k1,1 -k2,2n >>$OUT

