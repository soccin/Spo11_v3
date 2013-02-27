#!/bin/bash

source ~/Work/SGE/sge.sh
BIN=pipe01.bin

GTAG=mm10
GENOME=/ifs/data/bio/Genomes/M.musculus/mm10/mouse_mm10__All.fa

MAPFILE=$1

echo $MAPFILE

for ci in `cat ${GTAG}_CHROMS`; do
    echo $ci;
    mkdir $ci;
    bsub -N GREP \
    	/bin/egrep -w \"\($ci\|chrom\)\" $MAPFILE \| cut -f1-12,14- \>$ci/${MAPFILE%%.map}__SPLIT,${ci}.map;
done
qSYNC GREP

find chr* | fgrep .map | xargs -n 1 qsub -N RSCRIPT ~/Work/SGE/qCMD Rscript --no-save $BIN/cvt2R.R
qSYNC RSCRIPT

find chr* | fgrep Rdata | fgrep -v HitMap | fgrep UNIQUE \
	| xargs -n 1 qsub -N RSCRIPT ~/Work/SGE/qCMD Rscript --no-save $BIN/mkHitMap.R

qsub -pe alloc 12 -N MERGEMULTI ~/Work/SGE/qCMD $BIN/mergeMultiMaps.sh _._results04a/$GTAG/$TAG/${SAMPLE}
qSYNC MERGEMULTI

MMAPFILE=${MAPFILE/UNIQUE/MULTI}
for ci in `cat ${GTAG}_CHROMS`; do
    echo $ci;
    mkdir $ci;
    bsub -N GREP \
    	/bin/egrep -w \"\($ci\|chrom\)\" $MMAPFILE \| cut -f1-12,14- \>$ci/${MMAPFILE%%.map}__SPLIT,${ci}.map;
done
qSYNC GREP
find chr* | fgrep .map | fgrep MULTI | xargs -n 1 qsub -N RSCRIPT ~/Work/SGE/qCMD Rscript --no-save $BIN/cvt2R.R
qSYNC RSCRIPT

find chr* | fgrep Rdata | fgrep -v HitMap | fgrep MULTI \
	| xargs -n 1 qsub -N RSCRIPT ~/Work/SGE/qCMD Rscript --no-save $BIN/mkHitMap.R

