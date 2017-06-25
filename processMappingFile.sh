#!/bin/bash
SDIR="$( cd "$( dirname "$0" )" && pwd )"
MAPPING=$1

if [ "$#" -ne 1 ]; then
    echo "usage processMappingFile.sh MAPPING_FILE"
    exit
fi

for sample in $(cat $MAPPING | cut -f2 | sort | uniq); do
    echo $sample;
    mkdir -p Results/$sample;
    cp spo11.sh Results/$sample;
    cd Results/$sample
    cat ../../$MAPPING | awk -v S=$sample '$2==S{print $4}' \
        | xargs bsub -o ../../LSF.CONTROL/ -J q_SPO $SDIR/pipe.sh
    cd ../..
done
