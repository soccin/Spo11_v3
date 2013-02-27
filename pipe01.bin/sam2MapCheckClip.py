#!/usr/bin/env python2.6

import sys
import pysam
BAM_CHARD_CLIP=5
BAM_CSOFT_CLIP=4
BAM_CMATCH=0

cigarDict={BAM_CSOFT_CLIP:"S",BAM_CMATCH:"M",BAM_CHARD_CLIP:"H"}

def formatCigar(cigar):
    cigarStr=""
    for (code,num) in cigar:
        try:
            cigarStr+=str(num)+cigarDict[code]
        except:
            print cigar, code, num
            raise
    return cigarStr

def getGmapperOpts(cmd):
    F=cmd.split()
    parse=[(i,x.replace("-","")) for i,x in enumerate(F) 
           if x[0]=="-" and x[1] not in "-0123456789"]
    ret=dict([(x,F[i+1]) for i,x in parse]) 
    ret['h']=int(ret['h'])
    ret['i']=int(ret['i'])
    ret['m']=int(ret['m'])
    return ret

def fmtSAMalignPos(aa):
    if aa.flag & 16:
        return [aa.aend,aa.pos+1,"-"]
    else:
        return [aa.pos+1,aa.aend,"+"]

samFile=sys.argv[1]
genomeFile=sys.argv[2]

uniqueFP=open(samFile+"_UNIQUE.map","w")
multiFP=open(samFile+"_MULTI.map","w")

COLNAMES="chrom start stop strand cigar leftClip rightClip NH NM AS.orig AS.clip alignLen rID mixerID seqOrig seqAligned leftClipSeq rightClipSeq".replace(" ","\t")

print >>uniqueFP, COLNAMES
print >>multiFP, COLNAMES

sam=pysam.Samfile(samFile)
opts=getGmapperOpts(sam.header['PG'][0]['CL'])
genome=pysam.Fastafile(genomeFile)

for si in sam:
    assert isinstance(si,pysam.AlignedRead)
    if si.is_unmapped:
        continue
    leftClip=0 if si.cigar[0][0]!=BAM_CSOFT_CLIP else si.cigar[0][1]
    leftClipSeq = si.seq[:leftClip]
    leftClipMM = sum([x.upper() not in "CN" for x in leftClipSeq])
    leftClipMM_N = sum([x.upper()=="N" for x in leftClipSeq])
    rightClip=0 if si.cigar[-1][0]!=BAM_CSOFT_CLIP else si.cigar[-1][1]
    rightClipSeq = si.seq[-rightClip:]
    rightClipMM = sum([x.upper() not in "GN" for x in rightClipSeq])
    rightClipMM_N = sum([x.upper()=="N" for x in rightClipSeq])
    oldScore=si.opt("AS")
    
    newScore=opts['i']*(leftClipMM+leftClipMM_N/4+rightClipMM+rightClipMM_N/4)+oldScore
    #print >>sys.stderr, sam.references[si.rname], si.pos-1, si.aend+1, "clip=",(leftClip, rightClip), "CIGAR=",si.cigar, "Score=",(oldScore, newScore), "OPTS=",(opts['i'],opts['h'])
    if 1 or newScore>=opts['h']:
        chrom=sam.references[si.rname]
        pos=fmtSAMalignPos(si)
        out=[chrom]+pos
        #print >>sys.stderr, si
        out.append(formatCigar(si.cigar))
        out.extend([leftClip,rightClip,si.opt("IH"),si.opt("NM")])
        out.extend([si.opt("AS"),newScore])
        out.append(si.alen)
        out.append(si.qname),
        out.append(si.qname.split(":")[-1])
        out.append(si.seq)
        out.append(si.seq[si.qstart:si.qend])
        out.append(leftClipSeq)
        out.append(rightClipSeq)
        #out.append((leftClipMM,rightClipMM))
        # 
        # Get genome flank
        #leftFlank=0 if si.pos-1<0 else si.pos-1 
        #out.append(genome.fetch(chrom,leftFlank,si.pos))
        #out.append(genome.fetch(chrom,si.aend,si.aend+1))
        if si.opt("IH")==1:
            print >>uniqueFP, "\t".join(map(str,out))
        else:
            print >>multiFP, "\t".join(map(str,out))
            
uniqueFP.close()
multiFP.close()

