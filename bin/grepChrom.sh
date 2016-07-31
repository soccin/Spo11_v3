#!/bin/bash
CHROM=$1
MAPFILE=$2
OUTFILE=$3

egrep -w "($CHROM|chrom)" $MAPFILE | cut -f1-12,14- >$OUTFILE


