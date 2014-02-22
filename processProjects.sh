for dir in $*; do
    dir=$(echo $dir | perl -pe 's|/$||');
    sample=$(basename $dir | sed 's/Sample_/s_/');
    echo $sample, $dir;
    mkdir -p Results/$sample;
    cp spo11.sh Results/$sample;
    cd Results/$sample;
    qsub -pe alloc 1 -N q_SPO ~/Work/SGE/qCMD ../../../Spo11_v3.1/pipe.sh $dir;
    cd ../..;
done
