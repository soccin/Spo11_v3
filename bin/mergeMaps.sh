#!/bin/bash

set -e

TMPDIR=/scratch/socci
mkdir -p $TMPDIR

DIR=$1
base=$(echo $DIR | perl -ne 'm|/Sample_([^/]*)|; print "s_$1";')
file1=$(ls $DIR/*UNIQUE.map|head -1)
OUT=$2
echo "OUT="$OUT
head -1 $file1 >$OUT
ls $DIR/*UNIQUE.map | xargs fgrep -hv mixer | sort -T $TMPDIR -k1,1 -k2,2n >>$OUT

