#!/bin/bash
set -eu

#
# Fix unbound variable issue in virtual env
#
PS1=""

SDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -e $SDIR/venv/bin/activate ]; then
    source $SDIR/venv/bin/activate
    python2.7 -c "import pysam"
else
    echo
    echo Need to setup python2.y venv
    echo read INSTALL.md for info
    echo
    exit 1
fi

# For R in case /tmp is full
export TMPDIR=/scratch/socci
mkdir -p $TMPDIR

# Make sure user sets parameters
GENOME="NULL"

###
## Get Run Paramters
###

source spo11.sh

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

if [ "$#" -lt "1" ]; then
    echo
    echo usage Spo11_v3/pipe.sh FASTQ_SAMPLE_DIR [FASTQ_SAMPLE_DIR_2 ...]
    echo
    exit
fi

DDIR1=$(echo $1 | sed 's/\/$//')
PROJ=$(echo $DDIR1 | awk -F'/' '{print $(NF-1)}')
SAMPLE=$(echo $DDIR1 | awk -F'/' '{print $(NF)}')

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
find $* -name "*_R1_*.gz" >$FASTQ
NUMFASTQ=$(wc -l $FASTQ | awk '{print $1}')
echo NUMFASTQ=$NUMFASTQ

TAG=q_SPO11_$$
echo TAG=$TAG

LSF_TIME_LONG="-W 48:00"
LSF_TIME_MED="-W 359"
LSF_TIME_SHORT="-W 59"
LSF_TIME=$LSF_TIME_MED

for file in $(cat $FASTQ); do
	bsub -o LSF.SPO11/ $LSF_TIME_LONG -n 32 -J ${TAG}_MAP \
	$BIN/spo11_Pipeline01.sh $file $GTAG $GENOME $CACHE $MIN_CLIP_LEN
done

echo "Holding on" ${TAG}_MAP
$SDIR/bin/bSync ${TAG}_MAP

find $CACHE -name '*.sam' | xargs -n 1 -I % \
	bsub -o LSF.SPO11/ $LSF_TIME -n 4 -J ${TAG}_SAM2MAP \
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

if [ $DOFULL == "YES" ]; then
    echo "DO FULL MAPS NO LONGER IMPLEMENTED"
    exit
else
    for ci in `cat $CHROMS`; do
        echo $ci;
        mkdir -p splitChrom/$ci;
        OUTMAP=splitChrom/$ci/$(basename $MAPFILE | sed 's/.map//')__SPLIT,${ci}.map
		bsub -o LSF.SPO11/ $LSF_TIME -J ${TAG}_GREP \
			$SDIR/bin/splitMapByChrom.sh $ci $MAPFILE ">" $OUTMAP
    done

	$SDIR/bin/bSync ${TAG}_GREP

    find splitChrom | fgrep .map | xargs -n 1 \
		bsub -o LSF.SPO11/ $LSF_TIME -J ${TAG}_RSCRIPT \
			Rscript --no-save $BIN/cvt2R.R
    $SDIR/bin/bSync ${TAG}_RSCRIPT

    find splitChrom | fgrep Rdata | fgrep -v HitMap | fgrep UNIQUE \
    	| xargs -n 1 bsub -LSF.SPO11/ $LSF_TIME -J ${TAG}_MKHITMAPU Rscript --no-save $BIN/mkHitMap.R
fi

MAPFILE=${SAMPLE/Sample_/s_}___MULTI_FILT.map
bsub -o LSF.SPO11/ $LSF_TIME -n 24 -J ${TAG}_MERGEMULTI $BIN/mergeMultiMaps.sh $CACHE $MAPFILE
$SDIR/bin/bSync ${TAG}_MERGEMULTI

for ci in `cat $CHROMS`; do
    echo $ci;
    OUTMAP=splitChrom/$ci/$(basename $MAPFILE | sed 's/.map//')__SPLIT,${ci}.map

	bsub -o LSF.SPO11/ $LSF_TIME -J ${TAG}_GREP \
		$SDIR/bin/splitMapByChrom.sh $ci $MAPFILE ">" $OUTMAP

done

$SDIR/bin/bSync ${TAG}_GREP
find splitChrom | fgrep .map | fgrep MULTI | xargs -n 1 \
	bsub -o LSF.SPO11/ $LSF_TIME -J ${TAG}_RSCRIPT Rscript --no-save $BIN/cvt2R.R
$SDIR/bin/bSync ${TAG}_RSCRIPT

find splitChrom | fgrep Rdata | fgrep -v HitMap | fgrep MULTI \
	| xargs -n 1 bsub -o LSF.SPO11/ $LSF_TIME -J ${TAG}_MKHITMAPM Rscript --no-save $BIN/mkHitMap.R

deactivate

GTAG=$(git --git-dir=$SDIR/.git --work-tree=$SDIR describe --long --tags --dirty="-UNCOMMITED" --always)
GURL=$(git --git-dir=$SDIR/.git --work-tree=$SDIR config --get remote.origin.url)

cat <<-END_VERSION > cmd.sh.log
SDIR: $SDIR
GURL: $GURL
GTAG: $GTAG
PWD: $PWD

Script: $0 $*
END_VERSION
