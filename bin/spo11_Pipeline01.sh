#!/bin/bash

echo "###TS" `date`

SDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BIN=$SDIR

####
# Clipping Parameters
#
ADAPTER=AGATCGGAAGAGCACACGTCTGAACTCCAGTCAC
MIN_CLIP_LEN=20

SHRIMP_FOLDER=$SDIR/SHRiMP_2_1_1b
GMAPPER=$SDIR/SHRiMP_2_1_1b/bin/gmapper-ls

####
# Mapping Parameters
#
MULTI_MAP_LIMIT=100001

FASTQ=$1
echo FASTQ=$FASTQ
GENOMETAG=$2
GENOME=$3
GENOME_INDEX=$(dirname $GENOME)/SHRiMP/DNA/$GENOMETAG-ls

OUTFOLDER=$4

FOLDER=${FASTQ%/*}
BASE=${FASTQ##*/}
BASE=${BASE%%.*}
BASE=$OUTFOLDER/$BASE

echo BASE=$BASE

zcat $FASTQ | head -400000 | $SDIR/fastx_clipper -a $ADAPTER -l $MIN_CLIP_LEN -n -v -Q33 -i - \
    | $BIN/splitMixer.py > ${BASE}___CLIPPED.fastq

$GMAPPER -N 24 -U -g -1000 -q -1000 \
    -m 10 -i -20 -h 100 -r 50% \
    -n 1 \
    -L $GENOME_INDEX \
    -o $MULTI_MAP_LIMIT -Q -E --sam-unaligned --strata \
    ${BASE}___CLIPPED.fastq >${BASE}.sam

echo "###TS" `date`
