#!/bin/bash
set -e

SDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#
# Check the venv has been setup
#
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
deactivate

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
