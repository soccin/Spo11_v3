#!/bin/bash
DIR=$1
base=$(echo $DIR | perl -ne 'm|Sample_([^/]*)|; print "s_$1";')
file1=$(ls $DIR/*UNIQUE.map|head -1)
OUT=${base}___UNIQUE_FILT.map

echo "OUT="$OUT

head -1 $file1 >$OUT
ls $DIR/*UNIQUE.map | xargs fgrep -hv mixer | sort -T /scratch/socci -k1,1 -k2,2n >>$OUT

