#!/bin/bash

###
## User Paramters
###

GENOME=/home/socci/Work/Keeney/LamI/S.mikatae/CLEAN/sacMik.fa
GTAG=sacMik

#GENOME=/home/socci/Work/Keeney/LamI/S.kudriavzevii/CLEAN/sacKud.fa
#GTAG=sacKud

DOFULL="NO"


DDIR=$(echo $1 | sed 's/\/$//')
PROJ=$(echo $DDIR | pyp s[-2])
SAMPLE=$(echo $DDIR | pyp s[-1])

DATA=$DDIR/*R1_*.gz

OUTFOLDER=_._results05/$GTAG/$PROJ/$SAMPLE
mkdir -p $OUTFOLDER

###

source /home/socci/Work/SGE/sge.sh
SDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BIN=$SDIR/bin

ls $DATA >FASTQ
NUMFASTQ=$(wc -l FASTQ | awk '{print $1}')
echo NUMFASTQ=$NUMFASTQ

TAG=q_SPO11_$$
echo TAG=$TAG

qsub -pe alloc 12 -N ${TAG}_MAP -t 1-$NUMFASTQ ~/Work/SGE/qArrayCMD FASTQ \
    $BIN/spo11_Pipeline01.sh \$task $GTAG $GENOME $OUTFOLDER

qSYNC ${TAG}_MAP

find $OUTFOLDER/* -name '*.sam' | xargs -n 1 -I % bsub -pe alloc 2 -N ${TAG}_SAM2MAP $BIN/sam2MapCheckClip.py % $GENOME
qSYNC ${TAG}_SAM2MAP

$SDIR/getStats.py ${PROJ}___${SAMPLE/Sample_/s_} >${SAMPLE/Sample_/s_}___STATS.txt
$BIN/mergeMaps.sh $OUTFOLDER

head -100 $(find $OUTFOLDER -name '*.sam' | head -1) | egrep "^@SQ" | cut -f2 | sed 's/SN://' >CHROMS

MAPFILE=${SAMPLE/Sample_/s_}___UNIQUE_FILT.map
echo "MAPFILE="$MAPFILE

if [ $DOFULL == "YES" ]; then
    echo "DO FULL MAPS"
    exit
else
    for ci in `cat CHROMS`; do
        echo $ci;
        mkdir -p splitChrom/$ci;
        bsub -N ${TAG}_GREP \
        	/bin/egrep -w \"\($ci\|chrom\)\" $MAPFILE \| cut -f1-12,14- \>splitChrom/$ci/${MAPFILE%%.map}__SPLIT,${ci}.map;
    done
    qSYNC ${TAG}_GREP

    find splitChrom | fgrep .map | xargs -n 1 qsub -N ${TAG}_RSCRIPT ~/Work/SGE/qCMD Rscript --no-save $BIN/cvt2R.R
    qSYNC ${TAG}_RSCRIPT

    find splitChrom | fgrep Rdata | fgrep -v HitMap | fgrep UNIQUE \
    	| xargs -n 1 qsub -N ${TAG}_RSCRIPT ~/Work/SGE/qCMD Rscript --no-save $BIN/mkHitMap.R
fi

qsub -pe alloc 12 -N ${TAG}_MERGEMULTI ~/Work/SGE/qCMD $BIN/mergeMultiMaps.sh $OUTFOLDER
qSYNC ${TAG}_MERGEMULTI

MAPFILE=${SAMPLE/Sample_/s_}___MULTI_FILT.map

for ci in `cat CHROMS`; do
    echo $ci;
    mkdir -p splitChrom/$ci;
    bsub -N ${TAG}_GREP \
    	/bin/egrep -w \"\($ci\|chrom\)\" $MAPFILE \| cut -f1-12,14- \>splitChrom/$ci/${MAPFILE%%.map}__SPLIT,${ci}.map;
done
qSYNC ${TAG}_GREP
find splitChrom | fgrep .map | fgrep MULTI | xargs -n 1 qsub -N ${TAG}_RSCRIPT ~/Work/SGE/qCMD Rscript --no-save $BIN/cvt2R.R
qSYNC ${TAG}_RSCRIPT

find splitChrom | fgrep Rdata | fgrep -v HitMap | fgrep MULTI \
	| xargs -n 1 qsub -N ${TAG}_RSCRIPT ~/Work/SGE/qCMD Rscript --no-save $BIN/mkHitMap.R

