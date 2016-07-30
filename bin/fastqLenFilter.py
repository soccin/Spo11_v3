#!/opt/bin/python2.7

import Bio.SeqIO
import sys

input=0
output=0
MINLEN=int(sys.argv[1])
for rec in Bio.SeqIO.parse(sys.stdin,"fastq"):
    input+=1
    if len(rec)>=MINLEN:
        output+=1
        Bio.SeqIO.write(rec,sys.stdout,"fastq")

print >>sys.stderr, "Input: %d reads." % (input)
print >>sys.stderr, "Output: %d reads." % (output)
