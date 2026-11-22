# Paper core content and experiment comparison

**Member 1** — Wang Yihan (王一涵), 1240012912  
**Review date** — 22 November 2026  
**Reviewed repository commit** — `94f6473023d92bc1be71cdfe07589e7e679d7e9b`

## Paper and research objective

Konstantin Serebryany, Derek Bruening, Alexander Potapenko, and Dmitry Vyukov. *AddressSanitizer: A Fast Address Sanity Checker*. USENIX ATC 2012, pp. 309–318.

The paper investigates practical detection of C/C++ out-of-bounds accesses and use-after-free errors through compiler instrumentation and a runtime library. Its evaluation considers execution overhead, memory usage, detection experience, and configuration trade-offs.

Our formal quantitative objective is the execution-time comparison associated with Figure 2. Small intentional-error demonstrations provide supporting evidence for selected detection behavior.

## Core method

| Component | Paper explanation | Connection to our experiments |
| --- | --- | --- |
| Shadow memory, Section 3.1 and Figure 1 | One shadow byte describes an aligned eight-byte application region. The default mapping is `(Addr >> 3) + Offset`. Shadow values encode accessible bytes and poisoned regions. | Explains the checks used by the installed ASan runtime. Our experiments use the implementation supplied with Clang. |
| Compiler instrumentation, Section 3.2 | Checks are inserted around surviving memory loads and stores. An invalid access transfers control to diagnostic reporting. | Ordinary and ASan builds of the same source provide the performance comparison. |
| Redzones, Sections 3.3–3.4 | Poisoned regions around heap, stack, and global objects expose accesses beyond object boundaries. | The heap demonstration tests nearby invalid indices, while `asan_test.cpp` exercises a stack error. |
| Quarantine, Section 3.3 | Freed allocations are poisoned and reuse is delayed to help detect use-after-free. | Current demonstration sources do not establish use-after-free coverage. |
| Diagnostics and limits, Sections 3.5–3.6 | Reports identify invalid accesses. Detection depends on whether the accessed region is poisoned, with limitations for some unaligned accesses, distant overflows, and reused allocations. | Each test supports a conclusion about its executed case. |

## Final experiment goals and expected outcomes

### Runtime objective

Compare whole-process elapsed time for `ary3`, `heapsort`, and `matrix`, using the same fixed input, compiler, and common flags in ordinary and ASan builds.

Collect at least five valid measured pairs per program after warm-ups. The scientific expectation is that instrumentation adds overhead, with program-dependent ratios. Any measured ratio, including a value below 1, must be retained and interpreted with its variability and timing conditions.

### Output validity

Successful benchmark runs should preserve each program's reference stdout and exit with code 0. ASan diagnostics invalidate a performance run for this protocol. A valid pair requires both variants to pass output and metric checks.

### Detection objective

For Member 4's allocation of 16 integers, indices 0 and 15 are expected to pass. Indices 16 and 17 are expected to trigger `heap-buffer-overflow` and a nonzero exit.

The repository's separate stack-error smoke test is expected to trigger `stack-buffer-overflow`.

### Memory scope

VmPeak evaluation is deferred. Max RSS recorded by the existing script is supplementary.

The formal quantitative objective remains Figure 2 runtime overhead. Detection demonstrations support explanation of the method and remain distinct from quantitative benchmark results.

## Workload selection and reproduction scope

The original paper evaluates SPEC CPU2006. Our group lacks access to a licensed copy and therefore uses three public C benchmarks from LLVM test-suite.

The fixed source revision is:

```text
d3f64b96fe6176716771a2e172f799caf1239b5b
```

All three programs are located under:

```text
SingleSource/Benchmarks/Shootout/
```

| Program | Behavior | Fixed argument | Expected stdout |
| --- | --- | ---: | --- |
| `ary3.c` | Integer-array accumulation | 1500000 | `1000 1500000000` |
| `heapsort.c` | Heap sort | 8000000 | `0.999993` |
| `matrix.c` | Integer-matrix multiplication | 3000000 | `3355 13320 17865 23575` |

The project is a partial reproduction using substitute workloads. Its conclusions apply to these programs, inputs, and recorded configurations.

Source provenance, acquisition, compilation and execution instructions are provided in `README.md` and `WORKLOAD_HANDOFF.md`.

## Paper-to-experiment comparison

| Paper content | Original evaluation or result | Group experiment and available evidence | Coverage and conclusion |
| --- | --- | --- | --- |
| Figure 2, runtime | SPEC CPU2006, historical LLVM/Clang `-O2`, 64-bit Linux. Reported average slowdown 73%. | Three LLVM Shootout programs selected. `environment.md` and `results/check/` contain one WSL validation per build and program. `scripts/run_benchmark.sh` implements repeated collection. | Workload correctness validation is recorded. Five valid measured pairs per kernel are available in `formal_runs.csv` and `formal_logs.zip`. |
| Table 1, memory | VmPeak read from `/proc/self/status` at termination. Reported aggregate increase 3.37x. | Script leaves `vmpeak_kib` blank and records Max RSS separately. | Deferred. No measured VmPeak comparison is established. |
| Sections 3.3–3.4, bounds detection | Redzones protect heap, stack, and global objects. | `demo_results/actual_results.csv` and 12 individual logs record four heap indices with three runs each. `asan_test.log` records a stack error. | Selected heap and stack cases have supporting records. Global-error coverage is absent from the reviewed tests. |
| Section 3.3, use-after-free | Poisoning freed allocations and delayed reuse support detection. | Reviewed demonstration tests exercise bounds errors. | Use-after-free remains uncovered by these demonstrations. |
| Section 4.2, deployment | Large application testing, including Chromium. | Small kernels and controlled examples. | Application-scale detection effectiveness remains outside the group's evidence. |
| Section 4.3, tuning | Evaluation explores resource and accuracy settings. | Fixed modern runtime profile with leak detection disabled. | Configuration sweeps remain outside the current experiment. |

## Actual records reviewed

### WSL benchmark validation

The repository records Ubuntu Clang 18.1.3 on WSL2, Ubuntu 24.04.5 LTS, an AMD Ryzen 7 8845H, and 15 GiB visible RAM.

These environment values are contributor-reported in `environment.md`. The LLVM source revision matches the pinned workload selection.

| Program | Argument | Recorded stdout in both modes | Plain exit / comparison | ASan exit / comparison |
| --- | ---: | --- | --- | --- |
| ary3 | 1500000 | `1000 1500000000` | 0 / 0 | 0 / 0 |
| heapsort | 8000000 | `0.999993` | 0 / 0 | 0 / 0 |
| matrix | 3000000 | `3355 13320 17865 23575` | 0 / 0 | 0 / 0 |

The corresponding stderr files are empty. These six records establish successful execution for the tested inputs. They supply one validation execution per program and build mode.

Formal statistics are calculated separately from the uploaded formal data, as shown below.

The custom workload smoke logs also record matching checksum `13056000000` at input `100000 1024`. Its internal microsecond timings remain smoke-test observations.

### Codespaces detection demonstration

| Index | Recorded repeats | ASan report | Recorded exits | Agreement with expected outcome |
| --- | ---: | --- | --- | --- |
| 0 | 3 | None | 0, 0, 0 | All three agree |
| 15 | 3 | None | 0, 0, 0 | All three agree |
| 16 | 3 | heap-buffer-overflow | 1, 1, 1 | All three agree |
| 17 | 3 | heap-buffer-overflow | 1, 1, 1 | All three agree |

Sources are `demo_results/actual_results.csv`, `demo_results/logs/`, and `demo_results/environment.md`.

The environment record specifies Codespaces, Clang 18.1.3, and an `-O0` demonstration build. Its outcomes concern detection behavior. The benchmark performance protocol uses the separate `-O2` profile.

## Differences from the original study

| Dimension | Original paper | Current group evidence or protocol | Effect on interpretation |
| --- | --- | --- | --- |
| Workloads | SPEC CPU2006 | Three public LLVM kernels, selected because licensed SPEC access is unavailable | Conclusions are limited to this subset. |
| Hardware and host | HP Z600, two quad-core Xeon E5620 CPUs, 24 GB RAM, 64-bit Linux | WSL on AMD hardware for benchmark validation; Codespaces for heap demonstration | Host effects must be disclosed. |
| Compiler/runtime | Historical LLVM/ASan | Ubuntu Clang 18.1.3 in contributed records | Optimizations and runtime behavior differ. |
| Runtime settings | 32-byte redzones, disabled allocation/free stack unwinding, zero quarantine in the performance evaluation | `ASAN_OPTIONS=detect_leaks=0`, other installed defaults | Exact historical configuration has changed. |
| Memory metric | VmPeak | Supplementary Max RSS; VmPeak deferred | No Table 1 numerical comparison is available. |
| Evidence strength | Multi-program performance evaluation and deployed application testing | Output validation, controlled detection cases, and five valid timing pairs per kernel | Full-paper reproduction remains incomplete. |

## Formal measured results

The uploaded CSV has 72 rows for 36 executions, including six warm-ups and 30 measured executions. Each execution contributes a time row and an RSS row.

Five valid pairs exist for each kernel. Archived stdout, stderr, exit codes, diffs and metrics agree with the CSV. All stdout matches reference text, stderr is empty and exits are zero.

### Runtime results

| Program | Valid pairs | Baseline seconds, mean ± SD | ASan seconds, mean ± SD | Paired ratio, mean ± SD | Overhead |
| --- | ---: | --- | --- | --- | ---: |
| ary3 | 5 | 0.322 ± 0.004 | 2.152 ± 0.013 | 6.684 ± 0.086 | 568.41% |
| heapsort | 5 | 1.444 ± 0.009 | 2.180 ± 0.012 | 1.510 ± 0.011 | 50.97% |
| matrix | 5 | 0.524 ± 0.009 | 1.642 ± 0.011 | 3.134 ± 0.065 | 213.44% |

For each valid pair:

```text
r_i = ASan elapsed seconds_i / baseline elapsed seconds_i
```

The reported ratio is the arithmetic mean of the five paired ratios.

```text
Runtime overhead (%) = 100 × (mean(r) − 1)
```

All standard deviations are sample standard deviations with denominator `n − 1`. Warm-ups are excluded. Pairing uses program, pair ID and attempt.

For analysis of `formal_runs.csv`, select rows satisfying all of the following:

```text
claim_id = C1
measurement_kind = time
phase = measured
valid = true
pair_valid = true
```

### Supplementary Max RSS results

| Program | Baseline Max RSS, KiB, mean ± SD | ASan Max RSS, KiB, mean ± SD |
| --- | --- | --- |
| ary3 | 14031.2 ± 30.6 | 18725.6 ± 30.8 |
| heapsort | 64804.8 ± 7.2 | 75796.8 ± 91.9 |
| matrix | 2416.0 ± 43.4 | 5876.0 ± 57.2 |

Max RSS summarizes peak resident memory and is supplementary. VmPeak remains uncollected.

The paper's Table 1 evaluates peak virtual address space. The current RSS results therefore support a separate resident-memory observation.

## Result interpretation

The recorded ASan build takes longer than the baseline for all three selected kernels. The magnitude varies substantially by program.

- `ary3` has the highest measured overhead, with a mean paired ratio of 6.684x.
- `heapsort` has the lowest measured overhead, with a mean paired ratio of 1.510x.
- `matrix` has a mean paired ratio of 3.134x.

The original paper reports 73% average slowdown across SPEC CPU2006. Our observations concern three substitute kernels and their fixed inputs. The difference in workload selection limits direct numerical comparison with the paper's suite average.

Compiler transformations, memory-access patterns, runtime defaults, hardware and host conditions may contribute to the observed differences. The current experiments do not isolate the individual causal contributions of these factors.

The five pairs per program provide a small repeated sample. GNU time values are printed to hundredths of a second, which also limits timing precision.

## Coverage assessment and provenance limitations

The current evidence covers successful execution of the selected kernels, preservation of expected output under ASan, selected heap and stack bounds-error detection, and repeated runtime measurements.

It provides partial coverage of the paper's research topic. VmPeak evaluation, use-after-free demonstrations, global-error demonstrations, application-scale testing and runtime-configuration sweeps remain uncovered or deferred.

The formal CSV records WSL-style paths and configuration labels. The repository's detailed environment file describes earlier validation. A separate formal-run machine/compiler/source/binary snapshot is absent from the reviewed materials, limiting exact provenance.

Absolute CSV paths refer to the producer's machine. Their basenames can be mapped to the corresponding files under `formal_logs/` inside `formal_logs.zip`.

## Repository alignment findings

The reviewed README combines an older two-claim plan with later runtime-focused plans. The accompanying replacement README consolidates the formal objective into runtime measurement, reports the uploaded paired results and marks VmPeak evaluation as deferred.

The root-level `run_benchmark.sh` contains only whitespace. The implemented script is `scripts/run_benchmark.sh`. It expects six precompiled binaries under `build/plain` and `build/asan`.

The script's workload names and inputs match the selected kernels. The supplied source package and pinned acquisition instructions address the source handoff to Member 3.

Only `ASan_Benchmark_and_Logging_Templates_Member3_Final.xlsx` is present in the reviewed snapshot. The earlier concern about two templates should be checked against this current inventory. Numerical results in this document are recalculated from the CSV.

The additional trial-run subsection in the reviewed `environment.md` is already in English.

These findings refer to the reviewed commit. The replacement documents address the README consolidation. Later repository changes require comparison against the corresponding version.

## References

1. Original paper, Sections 3–4, Figure 1, Figure 2, and Table 1. [USENIX PDF](https://www.usenix.org/system/files/conference/atc12/atc12-final39.pdf)
2. Group repository snapshot. [Reviewed commit](https://github.com/potomin/asan_replication/tree/94f6473023d92bc1be71cdfe07589e7e679d7e9b)
3. Benchmark source provenance. [LLVM Shootout pinned revision](https://github.com/llvm/llvm-test-suite/tree/d3f64b96fe6176716771a2e172f799caf1239b5b/SingleSource/Benchmarks/Shootout)
