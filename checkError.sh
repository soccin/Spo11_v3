#!/bin/bash
SDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
find . -name 'q*.e*' | xargs egrep -vf $SDIR/noError.grp
