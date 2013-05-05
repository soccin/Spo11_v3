#!/usr/bin/env python2.6

import sys

import Bio.SeqIO
from Bio.Seq import Seq
from Bio.SeqRecord import SeqRecord

for seq in Bio.SeqIO.parse(sys.stdin,"fastq"):
    newSeq=seq[5:]
    newSeq.id=seq.id+":"+str(seq.seq[:5])
    newSeq.name=""
    newSeq.description=""
    Bio.SeqIO.write(newSeq,sys.stdout,"fastq")
