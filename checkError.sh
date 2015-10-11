#!/bin/bash
SDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
find . -name "*.out" | fgrep LSF. \
	| xargs $SDIR/parseLSFExitStatus.py \
	| fgrep -v "Successfully completed."