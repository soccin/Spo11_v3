#!/bin/bash

SDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

for dir in $*; do
    dir=$(echo $dir | perl -pe 's|/$||');
    sample=$(basename $dir | sed 's/Sample_/s_/');
    echo $sample, $dir;
    mkdir -p Results/$sample;
    cp spo11.sh Results/$sample;
    cd Results/$sample;
    bsub -o LSF.CONTROL/ -J q_SPO $SDIR/pipe.sh $dir;
    cd ../..;
done
