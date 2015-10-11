#!/usr/bin/env python2.7

import sys

SECTION_MARK="------------------------------------------------------------"

def parseLogFile(fp):
    sections=[]
    output=[]
    for line in fp:
        if line.strip()==SECTION_MARK:
            sections.append(output)
            output=[]
        else:
            output.append(line.strip())
    sections.append(output)
    return sections

if __name__=="__main__":

    for logFile in sys.argv[1:]:
        with open(logFile) as fp:
            output=parseLogFile(fp)
            exitStatus="".join(output[3][:3]).strip()
            print exitStatus,"<<>>",output[1][1]
        