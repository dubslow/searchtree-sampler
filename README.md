# searchtree-sampler

Collects positions from inside Stockfish's search during self-play, for use as
NNUE training data. It produced the positions of
[sf-searchtree-bt4](https://huggingface.co/datasets/xushawn/sf-searchtree-bt4).

## What gets sampled

`sampler.patch` hooks the point where search asks the net for a static eval.
A position is written out with probability `TREE_SAMPLE_P` if

- the side to move is not in check,
- it has no capture or queen promotion that wins material (by static exchange), and
- it has a legal quiet move. Binpack entries need a move; this one means nothing.

Each line is `fen <tab> move <tab> static eval <tab> flag`. The flag is 1 if
the previous move was a capture. Evals taken from the hash table are never
sampled, and the search itself is unchanged.

## Usage

Patch and build Stockfish:

```bash
git clone https://github.com/official-stockfish/Stockfish
cd Stockfish && git checkout 43e01e07
git apply ../searchtree-sampler/sampler.patch
make -C src -j build
```

Play games and pack the samples:

```bash
./generate.sh Stockfish/src/stockfish UHO_Lichess_4852_v1.epd 100 out
./build_binpack.sh out/samples out/tree.binpack <stockfish from the tools branch>
```

`generate.sh` needs [fastchess](https://github.com/Disservin/fastchess).
`build_binpack.sh` needs a Stockfish built from the
[tools branch](https://github.com/official-stockfish/Stockfish/tree/tools) for
its `convert` command.

The engine writes one file per search thread into `TREE_SAMPLE_DIR`. Without
that variable it behaves like a normal Stockfish.

## Settings used for the dataset

| | |
|---|---|
| Engine | Stockfish 43e01e07 with its default net |
| Search | 200,000 nodes per move, 1 thread, 64 MB hash |
| Openings | UHO_Lichess_4852_v1, one game per opening |
| Adjudication | fishtest's draw and resign rules |
| Sample probability | 0.0085 |

At a probability of 0.01 a game yields about 47,000 samples. A packed position
takes 34 bytes.

## After sampling

- **Labels.** The eval stored by the sampler is a placeholder. The dataset
  replaces it with the value Leela's
  [BT4-tf13tune](https://huggingface.co/xushawn/BT4-tf13tune) net gives the
  position on its own, without game history. The relabeler is
  [this lc0 branch](https://github.com/xu-shawn/lc0/tree/searchtree-relabel):

  ```bash
  LC0_RELABEL_HISTORY=fen LC0_RELABEL_QF32=out.q.f32 \
    lc0 BT4-tf13tune.pb.gz in.binpack out.binpack 1024
  ```

  `out.q.f32` holds the net's raw value of every entry as a float32.
- **Training.** Entries carry ply 9999 as a marker.
  [This trainer commit](https://github.com/xu-shawn/nnue-pytorch/commit/289991ed8fe7a926533c153dd7bbeef9ac737161)
  adds `--tree-sample-accept`: marked entries skip the position filters, are
  kept with that probability, and are trained on their score alone.

`sampler.patch` modifies Stockfish and is under Stockfish's licence (GPL-3.0).
