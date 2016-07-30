#!/bin/bash

###
## User Paramters
###

GENOME=/ifs/work/socci/Depot/Genomes/M.musculus/ucsc/mm10/mouse_mm10.fa
GTAG=mouse_mm10
DOFULL="NO"


DDIR=$(echo $1 | sed 's/\/$//')
PROJ=$(echo $DDIR | awk -F"/" '{print $(NF-1)}')
SAMPLE=$(echo $DDIR | awk -F"/" '{print $NF}')

DATA=$DDIR/*R1_*.gz
## Subsample for testing
#DATA=$(ls $DDIR/*_R1_*.gz | awk 'BEGIN{srand(31415)}rand()<0.05{print $1}')

OUTFOLDER=_._results05/$GTAG/$PROJ/$SAMPLE
mkdir -p $OUTFOLDER


###

SDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BIN=$SDIR/bin

ls $DATA >FASTQ
NUMFASTQ=$(wc -l FASTQ | awk '{print $1}')
echo NUMFASTQ=$NUMFASTQ

TAG=q_SPO11_$(uuidgen -t)
echo TAG=$TAG


for fi in $(cat FASTQ); do

    bsub -n 18 -o LSF/ -J ${TAG}_MAP -R "rusage[mem=80]" -M 81 \
        $BIN/spo11_Pipeline01.sh $fi $GTAG $GENOME $OUTFOLDER

done

bSync ${TAG}_MAP

find $OUTFOLDER/* -name '*.sam' | xargs -n 1 -I % \
    bsub -n 2 -o LSF/ -J ${TAG}_SAM2MAP $BIN/sam2MapCheckClip.py % $GENOME

bSync ${TAG}_SAM2MAP

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
        bsub -o LSF/ -J ${TAG}_GREP \
        	/bin/egrep -w \"\($ci\|chrom\)\" $MAPFILE \| cut -f1-12,14- \>splitChrom/$ci/${MAPFILE%%.map}__SPLIT,${ci}.map;
    done
    bSync ${TAG}_GREP

    find splitChrom | fgrep .map | xargs -n 1 \
        bsub -o LSF/ -J ${TAG}_RSCRIPT \
        Rscript --no-save $BIN/cvt2R.R

    bSync ${TAG}_RSCRIPT

    find splitChrom | fgrep Rdata | fgrep -v HitMap | fgrep UNIQUE \
    	| xargs -n 1 \
            bsub -o LSF/ -J ${TAG}_RSCRIPT \
            Rscript --no-save $BIN/mkHitMap.R
fi

bsub -o LSF/ -R "rusage[mem=70]" -M 70 -n 12 -J ${TAG}_MERGEMULTI \
    $BIN/mergeMultiMaps.sh $OUTFOLDER
bSync ${TAG}_MERGEMULTI

MAPFILE=${SAMPLE/Sample_/s_}___MULTI_FILT.map

for ci in `cat CHROMS`; do
    echo $ci;
    mkdir -p splitChrom/$ci;
    bsub -o LSF/ -J ${TAG}_GREP \
    	/bin/egrep -w \"\($ci\|chrom\)\" $MAPFILE \| cut -f1-12,14- \>splitChrom/$ci/${MAPFILE%%.map}__SPLIT,${ci}.map;
done
bSync ${TAG}_GREP

find splitChrom | fgrep .map | fgrep MULTI | xargs -n 1 \
    bsub -o LSF/ -J ${TAG}_RSCRIPT \
    Rscript --no-save $BIN/cvt2R.R

bSync ${TAG}_RSCRIPT

find splitChrom | fgrep Rdata | fgrep -v HitMap | fgrep MULTI \
	| xargs -n 1 qsub -N ${TAG}_RSCRIPT ~/Work/SGE/qCMD Rscript --no-save $BIN/mkHitMap.R

