#!/bin/bash
# Self-play with the sampling engine. Samples land in <out dir>/samples/*.txt.
#
#   generate.sh <stockfish with sampler.patch> <openings.epd> <games> <out dir>
#
# Environment: P (sample probability, default 0.0085), NODES (per move, default
# 200000), CONCURRENCY (default 4), FASTCHESS (default fastchess), SEED.
set -e
SF=$(realpath "$1") BOOK=$(realpath "$2") GAMES=$3 OUT=$4
mkdir -p "$OUT/samples"
export TREE_SAMPLE_DIR=$(realpath "$OUT/samples") TREE_SAMPLE_P=${P:-0.0085}

${FASTCHESS:-fastchess} \
  -engine cmd=$SF name=A -engine cmd=$SF name=B \
  -each proto=uci tc=inf nodes=${NODES:-200000} option.Hash=64 option.Threads=1 \
  -openings file=$BOOK format=epd order=random -srand ${SEED:-1} \
  -rounds $GAMES -games 1 -concurrency ${CONCURRENCY:-4} -recover \
  -draw movenumber=34 movecount=8 score=20 \
  -resign movecount=3 score=600 twosided=true \
  -pgnout file="$OUT/games.pgn" > "$OUT/fastchess.log" 2>&1
cat "$OUT"/samples/*.txt | wc -l
