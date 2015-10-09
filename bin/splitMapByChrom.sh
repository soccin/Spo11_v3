#!/bin/bash

# /bin/egrep -w \"\($ci\|chrom\)\" $MAPFILE \| cut -f1-12,14- \>$OUTMAP;

/bin/egrep -w "("$1"|chrom)" $2 | cut -f1-12,14- 