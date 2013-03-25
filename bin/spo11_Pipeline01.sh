#!/bin/bash

echo "###TS" `date`

SDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BIN=$SDIR

####
# Clipping Parameters
#
ADAPTER=AGATCGGAAGAGCACACGTCTGAACTCCAGTCAC
MIN_CLIP_LEN=15

SHRIMP_FOLDER=/home/socci/Work/SeqAna/Mappers/SHRiMP/2_1_1/SHRiMP_2_1_1b
GMAPPER=/ifs/data/socci/Work/SeqAna/Mappers/SHRiMP/2_1_1/SHRiMP_2_1_1b/bin/gmapper-ls

FASTQ=$1
GENOMETAG=$2
GENOME=$3
GENOME_INDEX=$(dirname $GENOME)/SHRiMP/DNA/$GENOMETAG-ls

OUTFOLDER=$4

FOLDER=${FASTQ%/*}
BASE=${FASTQ##*/}
BASE=${BASE%%.*}
BASE=$OUTFOLDER/$BASE

zcat $FASTQ | /ifs/data/socci/opt/bin/fastx_clipper -a $ADAPTER -l $MIN_CLIP_LEN -n -v -Q33 -i - \
    | $BIN/splitMixer.py > ${BASE}___CLIPPED.fastq

$GMAPPER -N 24 -U -g -1000 -q -1000 \
    -m 10 -i -20 -h 100 -r 50% \
    -n 1 \
    -L $GENOME_INDEX \
    -o 10001 -Q -E --sam-unaligned --strata \
    ${BASE}___CLIPPED.fastq >${BASE}.sam

echo "###TS" `date`
