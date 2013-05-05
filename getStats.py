#!/usr/bin/env python2.7

import os

class Stats():
    pass

stats=Stats()
stats.total=0
stats.clipped=0
stats.mapped=0

def parseMapLog(fname,stats):
    with open(fname) as fp:
        for line in fp:
            if line.startswith("Input:"):
                stats.total+=int(line.split()[1])
            elif line.startswith("Output:"):
                stats.clipped+=int(line.split()[1])
            elif line.find("Reads Matched:")>-1:
                stats.mapped+=int(line.split()[2].replace(",",""))

for fname in os.listdir("."):
    if fname.find("_MAP.e")>-1:
        parseMapLog(fname,stats)


print "\t".join(map(str,
    [stats.total,
    stats.clipped,float(stats.clipped)/float(stats.total),
    stats.mapped,float(stats.mapped)/float(stats.total)]))
