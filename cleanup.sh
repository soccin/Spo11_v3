#!/bin/bash
SDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
find Results -depth | egrep -f $SDIR/cleanupFiles.grp | xargs -t rm -rf
