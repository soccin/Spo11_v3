for dir in `cat DIRS`; do
	sample=$(echo $dir | pyp 's[-1]' | sed 's/Sample_/s_/'); echo $sample;
   	mkdir -p $sample;
   	cd $sample;
   	bsub -N SPO11.MM10 ../Spo11.MM10/pipe.sh ../$dir;
   	cd ..;
done
