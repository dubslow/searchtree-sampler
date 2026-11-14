"""Turn sampler output into plain training entries.

stdin:  sampler lines, already shuffled: fen <tab> quiet move <tab> eval <tab> flag
stdout: plain entries for `stockfish convert`, marked as search-tree samples by ply 9999
stderr: counts

Positions that repeat (same board, side to move, castling rights and en passant
square) are written once.
"""

import sys

seen = set()
kept = malformed = duplicates = 0
write = sys.stdout.write
for line in sys.stdin:
    p = line.rstrip("\n").split("\t")
    if len(p) != 4:
        malformed += 1
        continue
    f = p[0].split(" ")
    try:
        score = int(p[2])
    except ValueError:
        malformed += 1
        continue
    if (
        len(f) != 6
        or not 4 <= len(p[1]) <= 5
        or f[0].count("/") != 7
        or p[3] not in ("0", "1")
    ):
        malformed += 1
        continue
    key = hash((f[0], f[1], f[2], f[3]))
    if key in seen:
        duplicates += 1
        continue
    seen.add(key)
    kept += 1
    score = max(-31000, min(31000, score))
    write(f"fen {p[0]}\nmove {p[1]}\nscore {score}\nply 9999\nresult 0\ne\n")
print(f"kept {kept}, malformed {malformed}, duplicates {duplicates}", file=sys.stderr)
