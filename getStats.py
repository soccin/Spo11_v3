#!/usr/bin/env python2.7

import sys
import os
import os.path

class Stats():
    pass

stats=dict(
    total=0,
    clipped=0,
    mapped=0,
    Total_Filtered_Maps=0,
    Unique_Filtered_Maps=0,
    Multi_Filtered_Maps=0)

def parseMapLog(fname,stats):
    with open(fname) as fp:
        for line in fp:
            if line.startswith("Input:"):
                stats["total"]+=int(line.split()[1])
            elif line.startswith("Output:"):
                stats["clipped"]+=int(line.split()[1])
            elif line.find("Reads Matched:")>-1:
                stats["mapped"]+=int(line.split()[2].replace(",",""))

def parseStatsLog(fname,stats):
    with open(fname) as fp:
        for line in fp:
            (key,value)=line.strip().split("= ")
            stats[key.replace(".","_")]+=int(value)

HEADER="SAMPLE TOTAL.READS CLIPPED PCT.CLIPPED" \
+ " MAPPED PCT.MAPPED FILTERED PCT.FILTERED UNIQUE PCT.UNIQUE" \
+ " MULTI PCT.MULTI"
projectSample=sys.argv[1]

if projectSample=="HEADER":
    print HEADER.replace(" ","\t")
    sys.exit()

for fname in os.listdir("LSF.SPO11"):
    if fname.find(".out")>-1:
        parseMapLog(os.path.join("LSF.SPO11",fname),stats)


resultsDir=[x for x in os.listdir(".") if x.startswith("_._res")][0]
for rec in os.walk(resultsDir):
    for fname in rec[2]:
        if fname.endswith("_STATS.txt"):
            fullName=os.path.join(rec[0],fname)
            parseStatsLog(fullName,stats)


fTotal=float(stats["total"])
if fTotal>0:
    print "\t".join(map(str,
        [projectSample,stats["total"],
        stats["clipped"],stats["clipped"]/fTotal,
        stats["mapped"],stats["mapped"]/fTotal,
        stats["Total_Filtered_Maps"],stats["Total_Filtered_Maps"]/fTotal,
        stats["Unique_Filtered_Maps"],stats["Unique_Filtered_Maps"]/fTotal,
        stats["Multi_Filtered_Maps"],stats["Multi_Filtered_Maps"]/fTotal
        ]))
else:
    print "\t".join(map(str,
        [projectSample,stats["total"]]))
    