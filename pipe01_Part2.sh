#!/bin/bash

source ~/Work/SGE/sge.sh

SDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BIN=$SDIR/pipe01.bin
echo $SDIR $BIN

GTAG=mm10
GENOME=/ifs/data/bio/Genomes/M.musculus/mm10/mouse_mm10__All.fa

MAPFILE=$1
BASE=$(basename $MAPFILE)

echo $MAPFILE

for ci in `cat $SDIR/${GTAG}_CHROMS`; do
    echo $ci;
    mkdir $ci;
    bsub -N GREP \
	    /bin/zcat $MAPFILE \| $BIN/filterNoise.sh \| \
		/bin/egrep -w \"\($ci\|chrom\)\" \| cut -f1-12,14- \>$ci/${BASE%%.map}__SPLIT,${ci}.map;
done

MMAPFILE=${MAPFILE/UNIQUE/MULTI}
MBASE=$(basename $MMAPFILE)

for ci in `cat $SDIR/${GTAG}_CHROMS`; do
    echo $ci;
    mkdir -p $ci;
    bsub -N GREP \
	    /bin/zcat $MMAPFILE \| $BIN/filterNoise.sh \| \
        /bin/egrep -w \"\($ci\|chrom\)\" \| cut -f1-12,14- \>$ci/${MBASE%%.map}__SPLIT,${ci}.map;
done
qSYNC GREP

find chr* | fgrep .map | xargs -n 1 qsub -N RSCRIPT ~/Work/SGE/qCMD Rscript --no-save $BIN/cvt2R.R
find chr* | fgrep .map | fgrep MULTI | xargs -n 1 \
    qsub -N RSCRIPT ~/Work/SGE/qCMD Rscript --no-save $BIN/cvt2R.R
qSYNC RSCRIPT

find chr* | fgrep Rdata | fgrep -v HitMap | fgrep UNIQUE \
	| xargs -n 1 qsub -N RSCRIPT_2 ~/Work/SGE/qCMD Rscript --no-save $BIN/mkHitMap.R

find chr* | fgrep Rdata | fgrep -v HitMap | fgrep MULTI \
	| xargs -n 1 qsub -N RSCRIPT_2 ~/Work/SGE/qCMD Rscript --no-save $BIN/mkHitMap.R

