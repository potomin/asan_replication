# Formal workload handoff

Prepared by Wang Yihan (Member 1), 21 November 2026.

## Supplied source files

The package supplies unmodified LLVM test-suite sources, their upstream reference outputs, the upstream Shootout README, and the root license. Source revision is `d3f64b96fe6176716771a2e172f799caf1239b5b`. Preserve all source headers and license notices. `SOURCE_SHA256SUMS.txt` identifies the supplied bytes.

| Source | Argument | Expected stdout |
| --- | ---: | --- |
| `ary3.c` | 1500000 | `1000 1500000000` |
| `heapsort.c` | 8000000 | `0.999993` |
| `matrix.c` | 3000000 | `3355 13320 17865 23575` |

## Use with the existing repository

1. Extract this package. Copy the `third_party` and `expected` directories into the group repository root. The resulting source path is `third_party/llvm-test-suite/SingleSource/Benchmarks/Shootout/ary3.c`, with the other sources alongside it. This supplied directory is a source snapshot. A Git checkout already at the pinned revision can also provide these same files.
2. Replace the repository README with the supplied `README.md` and add `PAPER_REVIEW.md` and this handoff file. Review and preserve any later team edits before replacing an existing document.
3. On the experiment machine, install the tools and execute the common-environment and compilation block from README. When using the supplied sources, skip its clone/fetch commands. Build all six executables under `build/plain` and `build/asan`. Run `sha256sum -c SOURCE_SHA256SUMS.txt` from the extracted package root to check supplied sources. If recording provenance without an upstream Git checkout, record the pinned revision and hashes from this package.
4. Invoke the existing formal script from the group repository root using the command below. Preserve the full terminal output and its final exit code.

```bash
bash scripts/run_benchmark.sh --runs 5 --output results/formal/formal_runs.csv
```

The root-level `run_benchmark.sh` in the reviewed repository contains only whitespace. The implemented entry point is `scripts/run_benchmark.sh`. It expects compiled executables, performs warm-ups, validates stdout, alternates paired run order, and writes raw records. It has a bounded retry count. Investigate any failure before interpreting a partial CSV.

For a new data set choose a new parent directory, such as `results/formal_run02/formal_runs.csv`. Its `formal_logs` directory must also be unique because log names are reused within a parent directory. GNU time is required. Check pilot timer resolution before final measurement.

## Analysis columns

Select formal timing rows with `claim_id=C1`, `measurement_kind=time`, `phase=measured`, `valid=true`, and `pair_valid=true`. Match each pair by program, pair ID, and attempt. Use at least five valid pairs per program. Report each build's elapsed seconds and the paired time ratios as mean ± sample standard deviation. Exclude warm-ups. Max RSS rows are supplementary and VmPeak is deferred.

The package provides the benchmark sources for Member 3. It preserves the existing repository script. Actual WSL timings are collected by Member 3 on the experiment machine.
