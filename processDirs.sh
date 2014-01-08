for dir in `cat DIRS`; do
	sample=$(echo $dir | pyp 's[-1]' | sed 's/Sample_/s_/'); echo $sample;
   	mkdir -p $sample;
	cp spo11.sh $sample
   	cd $sample;
   	qsub -N SPO11 ~/Work/SGE/qCMD ../../Spo11_v3/pipe.sh $dir;
   	cd ..;
done
