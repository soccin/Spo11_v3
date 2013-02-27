#!/bin/bash
DIR=$1
base=$(echo $DIR | perl -ne 'm|Sample_([^/]*)|; print "$1";')
echo $base
file1=$(ls $DIR/*UNIQUE.map|head -1)
OUT=${base}___03a___UNIQUE_FILT.map
head -1 $file1 >$OUT
ls $DIR/*UNIQUE.map | xargs fgrep -hv mixer | awk '$11>0{print $0}' | sort -T /scratch/socci -k1,1 -k2,2n >>$OUT
#ls $DIR/*UNIQUE.map | xargs fgrep -hv mixer | sort -T /scratch/socci -k1,1 -k2,2n >>$OUT

