#!/bin/bash

source /home/socci/Work/SGE/sge.sh
SDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Make sure user sets parameters
GENOME="NULL"

###
## Get Run Paramters
###

. spo11.sh

if [ "$GENOME" == "NULL" ]; then
    echo ""
    echo "**********************************************"
    echo "Must setup spo11.sh parameter file with"
    echo "  GENOME"
    echo "  GTAG"
    echo "  MIN_CLIP_LEN"
    echo ""
    exit
fi

echo GENOME=$GENOME
echo GTAG=$GTAG
echo MIN_CLIP_LEN=$MIN_CLIP_LEN

DOFULL="NO"


DDIR=$(echo $1 | sed 's/\/$//')
PROJ=$(echo $DDIR | awk -F'/' '{print $(NF-1)}')
SAMPLE=$(echo $DDIR | awk -F'/' '{print $(NF)}')

DATA=$DDIR/*R1_*.gz

## Subsample for testing on MOUSE RUNS
#DATA=$(ls $DDIR/*_R1_*.gz | awk 'BEGIN{srand(31415)}rand()<0.05{print $1}')

OUTFOLDER=`pwd`/_._resultsV3/$GTAG/$PROJ/$SAMPLE
echo $OUTFOLDER

CACHE=$OUTFOLDER/_cache
mkdir -p $OUTFOLDER
mkdir -p $CACHE

###

BIN=$SDIR/bin

FASTQ=$CACHE/FASTQ
ls $DATA >$FASTQ
NUMFASTQ=$(wc -l $FASTQ | awk '{print $1}')
echo NUMFASTQ=$NUMFASTQ

TAG=q_SPO11_$$
echo TAG=$TAG

for file in $(cat $FASTQ); do
	bsub -o LSF.SPO11/ -We 59 -n 24 -J ${TAG}_MAP \
	$BIN/spo11_Pipeline01.sh $file $GTAG $GENOME $CACHE $MIN_CLIP_LEN
done

echo "Holding on" ${TAG}_MAP
$SDIR/bin/bSync ${TAG}_MAP

find $CACHE -name '*.sam' | xargs -n 1 -I % \
	bsub -o LSF.SPO11/ -We 59 -n 4 -J ${TAG}_SAM2MAP \
	$BIN/sam2MapCheckClip.py % $GENOME

echo "Holding on" ${TAG}_SAM2MAP
$SDIR/bin/bSync ${TAG}_SAM2MAP

echo "Calling getStats ..."
$SDIR/getStats.py ${PROJ}___${SAMPLE/Sample_/s_} >${SAMPLE/Sample_/s_}___STATS.txt
echo "done"

MAPFILE=${SAMPLE/Sample_/s_}___UNIQUE_FILT.map
$BIN/mergeMaps.sh $CACHE $MAPFILE

CHROMS=$CACHE/CHROMS
head -1000 $(find $CACHE -name '*.sam' | head -1) | egrep "^@SQ" | cut -f2 | sed 's/SN://' >$CHROMS

echo "MAPFILE="$MAPFILE

exit

if [ $DOFULL == "YES" ]; then
    echo "DO FULL MAPS NO LONGER IMPLEMENTED"
    exit
else
    for ci in `cat $CHROMS`; do
        echo $ci;
        mkdir -p splitChrom/$ci;
        OUTMAP=splitChrom/$ci/$(basename $MAPFILE | sed 's/.map//')__SPLIT,${ci}.map
		bsub -o LSF.SPO11/ -We 59 -J ${TAG}_GREP \
			$SDIR/bin/splitMapByChrom $ci $MAPFILE ">" $OUTMAP
    done
    
	$SDIR/bin/bSync ${TAG}_GREP
	exit
	
    find splitChrom | fgrep .map | xargs -n 1 qsub -q $QUEUES -N ${TAG}_RSCRIPT ~/Work/SGE/qCMD Rscript --no-save $BIN/cvt2R.R
    qSYNC ${TAG}_RSCRIPT

    find splitChrom | fgrep Rdata | fgrep -v HitMap | fgrep UNIQUE \
    	| xargs -n 1 qsub -q $QUEUES -N ${TAG}_MKHITMAPU ~/Work/SGE/qCMD Rscript --no-save $BIN/mkHitMap.R
fi

MAPFILE=${SAMPLE/Sample_/s_}___MULTI_FILT.map
qsub -q $QUEUES -pe alloc 24 -N ${TAG}_MERGEMULTI ~/Work/SGE/qCMD $BIN/mergeMultiMaps.sh $CACHE $MAPFILE
qSYNC ${TAG}_MERGEMULTI

for ci in `cat $CHROMS`; do
    echo $ci;
    OUTMAP=splitChrom/$ci/$(basename $MAPFILE | sed 's/.map//')__SPLIT,${ci}.map

    qsub -N ${TAG}_GREP ~/Work/SGE/qCMD \
    	/bin/egrep -w \"\($ci\|chrom\)\" $MAPFILE \| cut -f1-12,14- \>$OUTMAP;
done
qSYNC ${TAG}_GREP
find splitChrom | fgrep .map | fgrep MULTI | xargs -n 1 qsub -N ${TAG}_RSCRIPT ~/Work/SGE/qCMD Rscript --no-save $BIN/cvt2R.R
qSYNC ${TAG}_RSCRIPT

find splitChrom | fgrep Rdata | fgrep -v HitMap | fgrep MULTI \
	| xargs -n 1 qsub -N ${TAG}_MKHITMAPM ~/Work/SGE/qCMD Rscript --no-save $BIN/mkHitMap.R

