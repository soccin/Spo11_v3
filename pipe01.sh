#!/bin/bash

source ~/Work/SGE/sge.sh

BIN=pipe01.bin

DDIR=$(echo $1 | sed 's/\/$//')
PROJ=$(echo $DDIR | pyp s[-2])
SAMPLE=$(echo $DDIR | pyp s[-1])

DATA=Data/$PROJ/$SAMPLE/*R1_*.gz
TAG=Data/$PROJ

GTAG=mm10
GENOME=/ifs/data/bio/Genomes/M.musculus/mm10/mouse_mm10__All.fa

#ls -1 $DATA | head -5 | xargs -n 1 bsub -N PIPE01 $BIN/spo11_Pipeline01.sh

ls $DATA >FASTQ
NUMFASTQ=$(wc -l FASTQ | awk '{print $1}')
echo $NUMFASTQ

#qsub -pe alloc 12 -N PIPE01 -tc 10 -t 1-$NUMFASTQ ~/Work/SGE/qArrayCMD FASTQ $BIN/spo11_Pipeline01.sh \$task
qsub -pe alloc 12 -N PIPE01 -t 1-$NUMFASTQ ~/Work/SGE/qArrayCMD FASTQ $BIN/spo11_Pipeline01.sh \$task
qSYNC PIPE01
#qSYNC SPO11

find _._results04a/$GTAG/* -name '*.sam' | xargs -n 1 -I % bsub -pe alloc 2 -N SAM2MAP $BIN/sam2MapCheckClip.py % $GENOME
qSYNC SAM2MAP

$BIN/mergeMaps.sh _._results04a/$GTAG/$TAG/${SAMPLE}

head -100 $(find _._results04a -name '*.sam' | head -1) | egrep "^@SQ" | cut -f2 | sed 's/SN://' >CHROMS

MAPFILE=${SAMPLE/Sample_/}___03a___UNIQUE_FILT.map
for ci in `cat CHROMS`; do
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

MAPFILE=${SAMPLE/Sample_/}___03a___MULTI_FILT.map
for ci in `cat CHROMS`; do
    echo $ci;
    mkdir $ci;
    bsub -N GREP \
    	/bin/egrep -w \"\($ci\|chrom\)\" $MAPFILE \| cut -f1-12,14- \>$ci/${MAPFILE%%.map}__SPLIT,${ci}.map;
done
qSYNC GREP
find chr* | fgrep .map | fgrep MULTI | xargs -n 1 qsub -N RSCRIPT ~/Work/SGE/qCMD Rscript --no-save $BIN/cvt2R.R
qSYNC RSCRIPT

find chr* | fgrep Rdata | fgrep -v HitMap | fgrep MULTI \
	| xargs -n 1 qsub -N RSCRIPT ~/Work/SGE/qCMD Rscript --no-save $BIN/mkHitMap.R

