#!/bin/bash

SDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

for dir in $*; do
    dir=$(echo $dir | perl -pe 's|/$||');
    dir=$(readlink -e $dir)
    sample=$(basename $dir | sed 's/Sample_/s_/');
    echo $sample, $dir;
    mkdir -p Results/$sample;
    cp spo11.sh Results/$sample;
    cd Results/$sample;
    bsub -o LSF.CONTROL/ -J q_SPO -W 96:00 $SDIR/pipe.sh $dir;
    cd ../..;
done
