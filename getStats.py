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

for fname in os.listdir("."):
    if fname.find("_MAP.e")>-1:
        parseMapLog(fname,stats)

HEADER="SAMPLE TOTAL.READS CLIPPED PCT.CLIPPED" \
+ "MAPPED PCT.MAPPED FILTERED PCT.FILTERED UNIQUE PCT.UNIQUE" \
+ "MULTI PCT.MULTI"
projectSample=sys.argv[1]
if projectSample=="HEADER":
    print HEADER.replace(" ","\t")
    sys.exit()

resultsDir=[x for x in os.listdir(".") if x.startswith("_._res")][0]
for rec in os.walk(resultsDir):
    for fname in rec[2]:
        if fname.endswith("_STATS.txt"):
            fullName=os.path.join(rec[0],fname)
            parseStatsLog(fullName,stats)

    
fTotal=float(stats["total"])
print "\t".join(map(str,
    [projectSample,stats["total"],
    stats["clipped"],stats["clipped"]/fTotal,
    stats["mapped"],stats["mapped"]/fTotal,
    stats["Total_Filtered_Maps"],stats["Total_Filtered_Maps"]/fTotal,
    stats["Unique_Filtered_Maps"],stats["Unique_Filtered_Maps"]/fTotal,
    stats["Multi_Filtered_Maps"],stats["Multi_Filtered_Maps"]/fTotal
    ]))
