for dir in `cat DIRS`; do
	sample=$(echo $dir | pyp 's[-1]' | sed 's/Sample_/s_/'); echo $sample;
   	mkdir -p $sample;
	cp spo11.sh $sample
   	cd $sample;
   	bsub -N SPO11 ../../Spo11_v3/pipe.sh $dir;
   	cd ..;
done
