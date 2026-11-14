#!/bin/bash
# Samples -> shuffled, de-duplicated binpack of standalone positions.
#
#   build_binpack.sh <samples dir> <out.binpack> <stockfish from the tools branch>
#
# Shuffling matters: consecutive samples come from the same search.
set -e -o pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
PLAIN=${2%.binpack}.plain
cat "$1"/*.txt | shuf | python3 "$HERE/to_plain.py" > "$PLAIN"
rm -f "$2"
"$3" convert "$PLAIN" "$2" > "${2%.binpack}.convert.log" 2>&1
rm -f "$PLAIN"
ls -l "$2"
