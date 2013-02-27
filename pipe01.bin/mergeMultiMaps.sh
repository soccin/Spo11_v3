#!/bin/bash
DIR=$1
base=$(echo $DIR | perl -ne 'm|Sample_([^/]*)|; print "$1";')
echo $base
file1=$(ls $DIR/*MULTI.map|head -1)
OUT=${base}___03a___MULTI_FILT.map
head -1 $file1 >$OUT
ls $DIR/*MULTI.map | xargs fgrep -hv mixer | awk '$11>0{print $0}' | sort -S 80g -T /scratch/socci -k1,1 -k2,2n >>$OUT
#ls $DIR/*MULTI.map | xargs fgrep -hv mixer | sort -T /scratch/socci -k1,1 -k2,2n >>$OUT

