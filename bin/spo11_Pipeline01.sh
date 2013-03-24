#!/bin/bash

echo "###TS" `date`

BIN=pipe01.bin
QSUB=/common/sge/bin/lx24-amd64/qsub
QSYNC=/ifs/data/socci/Work/SGE/qSYNC

ADAPTER=AGATCGGAAGAGCACACGTCTGAACTCCAGTCAC
#GENOME=/ifs/data/bio/Genomes/S.cerevisiae/sacCer2/SGD/20080628/SGD_sacCer2.fasta
#GENOMETAG=SGD_sacCer2
GENOME=/ifs/data/bio/Genomes/M.musculus/mm10/mouse_mm10__All.fa
GENOMETAG=mm10

#GMAPPER=/home/socci/bin/gmapper-ls --local --qv-offset 33
SHRIMP_FOLDER=/home/socci/Work/SeqAna/Mappers/SHRiMP/2_1_1/SHRiMP_2_1_1b
GMAPPER=/ifs/data/socci/Work/SeqAna/Mappers/SHRiMP/2_1_1/SHRiMP_2_1_1b/bin/gmapper-ls

FASTQ=$1
FOLDER=${FASTQ%/*}
BASE=${FASTQ##*/}
BASE=${BASE%%.*}
##OUTFOLDER=_._results100k/$GENOMETAG/$FOLDER
OUTFOLDER=_._results04a/$GENOMETAG/$FOLDER
BASE=$OUTFOLDER/$BASE
mkdir -p $OUTFOLDER

TAG=SPO11

zcat $FASTQ | /ifs/data/socci/opt/bin/fastx_clipper -a $ADAPTER -l 20 -n -v -Q33 -i - \
    | $BIN/splitMixer.py > ${BASE}___CLIPPED.fastq

GENOME_INDEX=/ifs/data/bio/Genomes/M.musculus/mm10/SHRIMP/DNA/mouse_mm10__All-ls

#$QSUB -pe alloc 12 -N $TAG /ifs/data/socci/Work/SGE/qCMD \
#    $GMAPPER -N 20 -U -g -1000 -q -1000 \
#      -m 10 -i -20 -h 100 -r 50% \
#      -n 1 \
#      -L $GENOME_INDEX \
#      -o 100001 -Q -E --sam-unaligned --strata \
#      ${BASE}___CLIPPED.fastq \>${BASE}.sam 

$GMAPPER -N 24 -U -g -1000 -q -1000 \
      -m 10 -i -20 -h 100 -r 50% \
      -n 1 \
      -L $GENOME_INDEX \
      -o 100001 -Q -E --sam-unaligned --strata \
      ${BASE}___CLIPPED.fastq >${BASE}.sam 

#$QSYNC $TAG

echo "###TS" `date`
