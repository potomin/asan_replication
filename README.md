# AddressSanitizer — Partial Reproduction

Updated 22 November 2026. Member 1 — Wang Yihan (王一涵), 1240012912.

## Project and final scope

This Operating Systems project studies *AddressSanitizer: A Fast Address Sanity Checker* (Serebryany et al., USENIX ATC 2012). We evaluate runtime overhead on three publicly available C benchmarks and explain selected memory-error detection behavior through controlled tests.

The paper uses SPEC CPU2006. Our group lacks access to a licensed copy and therefore selects LLVM test-suite's `ary3.c`, `heapsort.c`, and `matrix.c`. These upstream sources are used with their original notices. This is a partial reproduction using substitute workloads and a modern compiler/runtime.

| Item | Final treatment |
| --- | --- |
| Figure 2 runtime comparison | Main quantitative objective; baseline and ASan whole-process elapsed seconds |
| Max RSS | Supplementary peak resident-memory metric in KiB |
| Table 1 VmPeak | Deferred; no VmPeak values are collected by the formal script |
| Memory-error demonstrations | Functional evidence for selected heap and stack bounds errors |
| Custom `workload_c.cpp` | Environment smoke test, separate from the three-program timing summary |

This document consolidates the project instructions and results into one current specification.

## Paper method and experiment mapping

ASan combines compiler-inserted access checks with shadow memory and a runtime library. The default shadow representation uses one shadow byte per aligned eight-byte application region. Redzones mark inaccessible memory around objects. Freed allocations are poisoned and delayed reuse through quarantine helps expose use-after-free. Diagnostics identify the invalid access and its context.

| Paper component | Group experiment | Evidence and coverage |
| --- | --- | --- |
| Figure 2, runtime overhead | Three LLVM kernels, ordinary and ASan builds | Five valid measured pairs per kernel, with warm-ups excluded |
| Table 1, virtual-memory overhead | VmPeak deferred | Max RSS retained under its own name |
| Sections 3.3–3.4, bounds checking | Stack smoke test and 16-integer heap demonstration | Selected stack and heap errors have recorded reports |
| Use-after-free and global bounds errors | Current tests focus on stack/heap bounds | Coverage remains incomplete |
| Application deployment and tuning | Fixed small-workload configuration | Application-scale testing and parameter sweeps remain outside this evaluation |

Detailed analysis is in [PAPER_REVIEW.md](PAPER_REVIEW.md).

## Workloads, source version and inputs

LLVM test-suite commit `d3f64b96fe6176716771a2e172f799caf1239b5b` is the source revision. Files are under `SingleSource/Benchmarks/Shootout`.

| Program | Operation | Argument | Expected stdout |
| --- | --- | ---: | --- |
| ary3 | Integer-array accumulation | 1500000 | `1000 1500000000` |
| heapsort | Heap sort | 8000000 | `0.999993` |
| matrix | Integer-matrix multiplication | 3000000 | `3355 13320 17865 23575` |

| Source | SHA-256 |
| --- | --- |
| ary3.c | `451e15b91ce45d781d998a2575daa73b381e97c4fcdbc0ecdb924650b58f4192` |
| heapsort.c | `ab2810d9868668a4d652eb380da68cb15d78c4c5b7325c99963e18b336959490` |
| matrix.c | `ff3f6ef68db20d2c8afe516ea4123b5bef0bdbf3b73986941406ef5612b01a31` |

The local LLVM dependency is ignored by Git. Recreate it at the fixed revision using the commands below, retaining `LICENSE.TXT` and component notices. [WORKLOAD_HANDOFF.md](WORKLOAD_HANDOFF.md) also describes the source package supplied to Member 3.

## Environment and installation

The benchmark validation environment recorded in [environment.md](environment.md) is WSL2, Ubuntu 24.04.5 LTS, x86_64, Ubuntu Clang 18.1.3, AMD Ryzen 7 8845H and approximately 15 GiB visible RAM. The heap demonstration has its own Codespaces environment record under `demo_results/environment.md`.

The formal CSV contains local WSL-style paths and configuration labels. A separate contemporaneous formal-run environment/build snapshot is absent from the reviewed files. The listed validation environment provides context; exact formal-run host and executable provenance remain a reporting limitation.

From the group repository root, install prerequisites and obtain the dependency. Clone into a fresh directory. If a checkout already exists, verify its revision and selected-file hashes before reusing it.

```bash
sudo apt-get update
sudo apt-get install -y git clang build-essential time
mkdir -p third_party build/plain build/asan expected

git clone --depth 1 --filter=blob:none --sparse \
  https://github.com/llvm/llvm-test-suite.git third_party/llvm-test-suite
git -C third_party/llvm-test-suite sparse-checkout set SingleSource/Benchmarks/Shootout
git -C third_party/llvm-test-suite fetch --depth 1 origin \
  d3f64b96fe6176716771a2e172f799caf1239b5b
git -C third_party/llvm-test-suite checkout --detach \
  d3f64b96fe6176716771a2e172f799caf1239b5b
git -C third_party/llvm-test-suite rev-parse HEAD
```

## Build both variants

Run in Bash. Use identical common flags for both variants. C benchmarks use `clang`; the C++ smoke test uses `clang++`.

```bash
export LC_ALL=C
export ASAN_OPTIONS=detect_leaks=0
unset LSAN_OPTIONS
src=third_party/llvm-test-suite/SingleSource/Benchmarks/Shootout

(
  set -e
  for name in ary3 heapsort matrix; do
    clang -std=c17 -O2 -g -fno-omit-frame-pointer \
      "$src/$name.c" -o "build/plain/$name" -lm
    clang -std=c17 -O2 -g -fno-omit-frame-pointer -fsanitize=address \
      "$src/$name.c" -o "build/asan/$name" -lm
    sed '/^exit 0$/d' "$src/$name.reference_output" > "expected/$name.stdout.txt"
  done
)
```

Continue after all six compilations succeed. The `exit 0` line removed from the reference files is an LLVM harness marker. The expected text files contain program stdout only.

## Formal measurement and validity

Run the implemented script from the repository root after compilation.

```bash
bash scripts/run_benchmark.sh --runs 5 --output results/formal_run02/formal_runs.csv
```

This example uses a fresh output directory. Choose another new parent directory if it already exists, because log filenames repeat within a parent directory. The root-level `run_benchmark.sh` in the reviewed snapshot contains only whitespace. Use the script under `scripts/`.

The script fixes the three inputs above and `ASAN_OPTIONS=detect_leaks=0`. It runs each program/mode once as a validated warm-up, then collects at least five valid pairs per program in fresh sequential processes. Execution order alternates across pair attempts. Failed attempts and their logs are retained, with a bounded retry limit.

A valid run has exit code 0, stdout identical to its reference, no ASan error report, and finite positive elapsed time. The current script also requires a numeric Max RSS value from GNU time. Both variants must pass for a pair to enter statistics. Warm-ups and invalid pairs are excluded. Slow valid runs are retained.

GNU `/usr/bin/time` supplies whole-process elapsed seconds (`%e`) and peak resident memory in KiB (`%M`). Pilot runs should check its printed precision. Use a consistently documented higher-resolution timer if the workload is too short. The uploaded data use GNU time values printed to hundredths of a second.

For future collections, save actual OS/CPU/RAM details, compiler/runtime version, source and executable hashes, repository/upstream revisions, exact build/run commands, and runtime options with the run records.

## Formal runtime results

Reviewed data are [formal_runs.csv](formal_runs.csv) and [formal_logs.zip](formal_logs.zip), committed in repository snapshot `94f6473023d92bc1be71cdfe07589e7e679d7e9b`.

The CSV contains 72 rows describing 36 executions. Each execution has a time row and a supplementary RSS row. Six executions are warm-ups and 30 are measured runs, forming five valid pairs for each program. Corresponding stdout, stderr, exit, diff and metrics files were cross-checked against the CSV. All recorded outputs match the references, exits are 0, stderr files are empty, and metric values agree.

| Program | Valid pairs | Baseline seconds, mean ± SD | ASan seconds, mean ± SD | Paired ratio, mean ± SD | Overhead |
| --- | ---: | --- | --- | --- | ---: |
| ary3 | 5 | 0.322 ± 0.004 | 2.152 ± 0.013 | 6.684 ± 0.086 | 568.41% |
| heapsort | 5 | 1.444 ± 0.009 | 2.180 ± 0.012 | 1.510 ± 0.011 | 50.97% |
| matrix | 5 | 0.524 ± 0.009 | 1.642 ± 0.011 | 3.134 ± 0.065 | 213.44% |

For each program, let `r_i = ASan_time_i / baseline_time_i`. The displayed ratio is the arithmetic mean of the five paired ratios. Overhead is `100 × (mean(r) − 1)`. All SD values use the sample denominator `n − 1`. Pairing uses program, pair ID and attempt. Times are seconds and ratios are dimensionless.

For an analysis of the script's CSV, select `claim_id=C1`, `measurement_kind=time`, `phase=measured`, `valid=true`, and `pair_valid=true`. CSV absolute paths identify the producer's machine. Locate the corresponding archived log by its basename under `formal_logs/` in the ZIP.

### Supplementary resident memory

| Program | Baseline Max RSS, KiB, mean ± SD | ASan Max RSS, KiB, mean ± SD |
| --- | --- | --- |
| ary3 | 14031.2 ± 30.6 | 18725.6 ± 30.8 |
| heapsort | 64804.8 ± 7.2 | 75796.8 ± 91.9 |
| matrix | 2416.0 ± 43.4 | 5876.0 ± 57.2 |

These values summarize the five measured RSS observations per variant. VmPeak fields are empty. Virtual address-space reservations and resident-memory use describe different quantities. Table 1's VmPeak increase remains unevaluated in this project.

## Detection demonstrations and smoke tests

Member 2's `asan_test.cpp` and `asan_test.log` record a stack-buffer-overflow smoke test. The custom workload at input `100000 1024` produced checksum `13056000000` in both builds, as recorded under `results/smoke/` and in `environment.md`.

To repeat the custom smoke test after creating `build/`, use the same environment settings as above and retain commands, stdout, stderr and exits.

```bash
clang++ -std=c++17 -O2 -g -fno-omit-frame-pointer \
  workload_c.cpp -o build/workload_plain
clang++ -std=c++17 -O2 -g -fno-omit-frame-pointer -fsanitize=address \
  workload_c.cpp -o build/workload_asan
./build/workload_plain 100000 1024
./build/workload_asan 100000 1024
```

The custom internal `elapsed_us` values stay outside the formal kernel summary.

Member 4's heap demonstration was executed in GitHub Codespaces using Clang 18.1.3 and an `-O0` ASan build. Commands, runtime options and source identity are in [demo_results/environment.md](demo_results/environment.md). Expected outcomes and observations are documented separately in [demo_results/expected_vs_actual.md](demo_results/expected_vs_actual.md).

| Index | Repetitions | Recorded exits | Observed ASan outcome |
| --- | ---: | --- | --- |
| 0 | 3 | 0, 0, 0 | No report |
| 15 | 3 | 0, 0, 0 | No report |
| 16 | 3 | 1, 1, 1 | heap-buffer-overflow |
| 17 | 3 | 1, 1, 1 | heap-buffer-overflow |

All 12 recorded cases match their predefined expectations. Raw logs are under `demo_results/logs/`. The Codespaces demonstration supports detection behavior for these cases; its timing is separate from the WSL benchmark profile. The current `member4_run_demo.sh` can reproduce the demonstration, subject to its documented environment and output handling.

## Comparison with the original paper

The paper reports 73% average slowdown on SPEC CPU2006. Our paired ratios show strongly program-dependent overhead on the selected kernels, with ary3 highest and heapsort lowest. These observations establish overhead for the recorded runs. Differences in workload, input, compiler, host, runtime settings and timing method limit numerical comparison with the paper's suite average.

The paper's evaluation used 64-bit Linux on an HP Z600 with two quad-core Xeon E5620 CPUs and 24 GB RAM. Its reported performance configuration included 32-byte redzones, disabled allocation/free stack unwinding and zero quarantine. Our fixed profile disables leak detection and otherwise relies on the installed runtime's defaults.

Shadow checks, access patterns, compiler transformations and runtime behavior may contribute to different overheads. The present measurements do not isolate their individual effects. The project also lacks the paper's application-scale deployment evaluation, use-after-free coverage, global-error demonstrations and runtime-configuration sweep.

## Repository files and responsibilities

| File or directory | Purpose |
| --- | --- |
| `README.md` | Current consolidated scope, commands and measured results |
| `PAPER_REVIEW.md` | Member 1's paper summary, coverage and result comparison |
| `WORKLOAD_HANDOFF.md` | Source handoff and program inputs |
| `environment.md` | Contributed WSL setup and validation records |
| `scripts/run_benchmark.sh` | Formal collection entry point |
| `formal_runs.csv`, `formal_logs.zip` | Uploaded measured data and raw logs |
| `ASan_Benchmark_and_Logging_Templates_Member3_Final.xlsx` | Current named workbook/template; numerical results here are recalculated from CSV |
| `expected/`, `results/check/`, `results/smoke/` | References, validation and smoke records |
| `demo_results/`, `extension_plan.md` | Codespaces functional demonstration records and plan |
| `third_party/llvm-test-suite/`, `build/` | Reconstructible local dependency and generated executables, ignored by Git |

| Member | Responsibility |
| --- | --- |
| 1 — 王一涵 | Paper interpretation, final scope, workload selection, paper-to-experiment comparison and result discussion |
| 2 — 蔡湘敏 | Environment configuration, test-code checks, diagnostic validation and environment/run records |
| 3 — 郭奕帆 | Formal experiment collection, raw logs, data tables and initial analysis |
| 4 — 陈婉仪 | Extension/demonstration experiments and repository integration |

## References

- Serebryany et al. *AddressSanitizer: A Fast Address Sanity Checker*, USENIX ATC 2012, Sections 3–4, Figure 2 and Table 1. [Original paper](https://www.usenix.org/system/files/conference/atc12/atc12-final39.pdf)
- LLVM test-suite. [Pinned Shootout source directory](https://github.com/llvm/llvm-test-suite/tree/d3f64b96fe6176716771a2e172f799caf1239b5b/SingleSource/Benchmarks/Shootout)
- SPEC. [CPU2006 licensing notices](https://www.spec.org/cpu2006/docs/legal.html)
