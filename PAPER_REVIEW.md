# Paper core content and experiment comparison

**Member 1** — Wang Yihan (王一涵), 1240012912  
**Review date** — 21 November 2026  
**Reviewed repository commit** — `192971584e957e6ecdca20d07841ef3450da6d77`

## Paper and research objective

Konstantin Serebryany, Derek Bruening, Alexander Potapenko, and Dmitry Vyukov. *AddressSanitizer: A Fast Address Sanity Checker*. USENIX ATC 2012, pp. 309–318.

The paper investigates practical detection of C/C++ out-of-bounds accesses and use-after-free errors through compiler instrumentation and a runtime library. Its evaluation considers execution overhead, memory usage, detection experience, and configuration trade-offs. Our formal quantitative objective is the execution-time comparison associated with Figure 2. Small intentional-error demonstrations provide supporting evidence for selected detection behavior.

## Core method

| Component | Paper explanation | Connection to our experiments |
| --- | --- | --- |
| Shadow memory, Section 3.1 and Figure 1 | One shadow byte describes an aligned eight-byte application region. The default mapping is `(Addr >> 3) + Offset`. Shadow values encode accessible bytes and poisoned regions. | Explains the checks used by the installed ASan runtime. Our experiments use the implementation supplied with Clang. |
| Compiler instrumentation, Section 3.2 | Checks are inserted around surviving memory loads and stores. An invalid access transfers control to diagnostic reporting. | Ordinary and ASan builds of the same source provide the performance comparison. |
| Redzones, Sections 3.3–3.4 | Poisoned regions around heap, stack, and global objects expose accesses beyond object boundaries. | The heap demonstration tests nearby invalid indices, while `asan_test.cpp` exercises a stack error. |
| Quarantine, Section 3.3 | Freed allocations are poisoned and reuse is delayed to help detect use-after-free. | Current demonstration sources do not establish use-after-free coverage. |
| Diagnostics and limits, Sections 3.5–3.6 | Reports identify invalid accesses. Detection depends on whether the accessed region is poisoned, with limitations for some unaligned accesses, distant overflows, and reused allocations. | Each test supports a conclusion about its executed case. |

## Final experiment goals and expected outcomes

**Runtime objective.** Compare whole-process elapsed time for `ary3`, `heapsort`, and `matrix`, using the same fixed input, compiler, and common flags in ordinary and ASan builds. Collect at least five valid measured pairs per program after warm-ups. The scientific expectation is that instrumentation adds overhead, with program-dependent ratios. Any measured ratio, including a value below 1, must be retained and interpreted with its variability and timing conditions.

**Output validity.** Successful benchmark runs should preserve each program's reference stdout and exit with code 0. ASan diagnostics invalidate a performance run for this protocol. A valid pair requires both variants to pass output and metric checks.

**Detection objective.** For Member 4's allocation of 16 integers, indices 0 and 15 are expected to pass. Indices 16 and 17 are expected to trigger `heap-buffer-overflow` and a nonzero exit. The repository's separate stack-error smoke test is expected to trigger `stack-buffer-overflow`.

**Memory scope.** VmPeak evaluation is deferred. Max RSS recorded by the existing script is supplementary. The formal quantitative claim remains Figure 2 runtime overhead. Detection demonstrations support explanation of the method and remain distinct from quantitative benchmark results.

## Paper-to-experiment comparison

| Paper content | Original evaluation or result | Group experiment and available evidence | Coverage and conclusion |
| --- | --- | --- | --- |
| Figure 2, runtime | SPEC CPU2006, historical LLVM/Clang `-O2`, 64-bit Linux. Reported average slowdown 73%. | Three LLVM Shootout programs selected. `environment.md` and `results/check/` contain one WSL validation per build and program. `scripts/run_benchmark.sh` implements repeated collection. | Workload correctness validation is recorded. Repeated formal timing results are pending in this snapshot. |
| Table 1, memory | VmPeak read from `/proc/self/status` at termination. Reported aggregate increase 3.37x. | Script leaves `vmpeak_kib` blank and records Max RSS separately. | Deferred. No measured VmPeak comparison is established. |
| Sections 3.3–3.4, bounds detection | Redzones protect heap, stack, and global objects. | `demo_results/actual_results.csv` and 12 individual logs record four heap indices with three runs each. `asan_test.log` records a stack error. | Selected heap and stack cases have supporting records. Global-error coverage is absent from the reviewed tests. |
| Section 3.3, use-after-free | Poisoning freed allocations and delayed reuse support detection. | Reviewed demonstration tests exercise bounds errors. | Use-after-free remains uncovered by these demonstrations. |
| Section 4.2, deployment | Large application testing, including Chromium. | Small kernels and controlled examples. | Application-scale detection effectiveness remains outside the group's evidence. |
| Section 4.3, tuning | Evaluation explores resource and accuracy settings. | Fixed modern runtime profile with leak detection disabled. | Configuration sweeps remain outside the current experiment. |

## Actual records reviewed

### WSL benchmark validation

The repository records Ubuntu Clang 18.1.3 on WSL2, Ubuntu 24.04.5 LTS, an AMD Ryzen 7 8845H, and 15 GiB visible RAM. These environment values are contributor-reported in `environment.md`. The LLVM source revision matches the pinned workload selection.

| Program | Argument | Recorded stdout in both modes | Plain exit / comparison | ASan exit / comparison |
| --- | ---: | --- | --- | --- |
| ary3 | 1500000 | `1000 1500000000` | 0 / 0 | 0 / 0 |
| heapsort | 8000000 | `0.999993` | 0 / 0 | 0 / 0 |
| matrix | 3000000 | `3355 13320 17865 23575` | 0 / 0 | 0 / 0 |

The corresponding stderr files are empty. These six records establish successful execution for the tested inputs. They supply one validation execution per cell. Formal mean, sample SD, and paired overhead remain unavailable from this validation set.

The custom workload smoke logs also record matching checksum `13056000000` at input `100000 1024`. Its internal microsecond timings remain smoke-test observations.

### Codespaces detection demonstration

| Index | Recorded repeats | ASan report | Recorded exits | Agreement with expected outcome |
| --- | ---: | --- | --- | --- |
| 0 | 3 | None | 0, 0, 0 | All three agree |
| 15 | 3 | None | 0, 0, 0 | All three agree |
| 16 | 3 | heap-buffer-overflow | 1, 1, 1 | All three agree |
| 17 | 3 | heap-buffer-overflow | 1, 1, 1 | All three agree |

Sources are `demo_results/actual_results.csv`, `demo_results/logs/`, and `demo_results/environment.md`. The environment record specifies Codespaces, Clang 18.1.3, and an `-O0` demonstration build. Its outcomes concern detection behavior. WSL performance experiments use the separate `-O2` profile.

## Differences from the original study

| Dimension | Original paper | Current group evidence or protocol | Effect on interpretation |
| --- | --- | --- | --- |
| Workloads | SPEC CPU2006 | Three public LLVM kernels, selected because licensed SPEC access is unavailable | Conclusions are limited to this subset. |
| Hardware and host | HP Z600, two quad-core Xeon E5620 CPUs, 24 GB RAM, 64-bit Linux | WSL on AMD hardware for benchmark validation; Codespaces for heap demonstration | Host effects must be disclosed. |
| Compiler/runtime | Historical LLVM/ASan | Ubuntu Clang 18.1.3 in contributed records | Optimizations and runtime behavior differ. |
| Runtime settings | 32-byte redzones, disabled allocation/free stack unwinding, zero quarantine in the performance evaluation | `ASAN_OPTIONS=detect_leaks=0`, other installed defaults | Exact historical configuration has changed. |
| Memory metric | VmPeak | Supplementary Max RSS; VmPeak deferred | No Table 1 numerical comparison is available. |
| Evidence strength | Multi-program performance evaluation and deployed application testing | Output validation, controlled detection cases, repeated runtime data pending | Full-paper reproduction remains incomplete. |

## Coverage assessment and remaining evidence

The current evidence covers the practical ability to compile the selected kernels, preserve expected output under ASan, and detect the tested heap and stack bounds errors. It offers partial coverage of the paper's main research topic. Quantitative runtime overhead still requires Member 3's formal data. Memory overhead, use-after-free demonstrations, global errors, and large application testing remain uncovered or deferred.

| Required next evidence | Responsible member | Acceptance for Member 1's final comparison |
| --- | --- | --- |
| Formal CSV, all attempt logs, exact environment and executable provenance | Member 3, with environment details from Member 2 | At least five valid measured pairs per program, excluding warm-ups and failed pairs |
| Final summary workbook linked to the same CSV | Member 3 | Per-build mean ± sample SD, valid n, and paired-ratio mean ± sample SD |
| Any newly added detection case and its actual logs | Member 2 or Member 4 | Source, build/run commands, diagnostic category, exit code, and actual host recorded |

For final timing summaries, use `C1` time rows where `phase=measured`, `valid=true`, and `pair_valid=true`. Match pairs by program, pair ID, and attempt. Compute each ASan/baseline time ratio before calculating its mean and sample SD. The report can then describe observed overhead for each kernel. Numerical agreement with the paper's SPEC average requires a separate comparability argument.

## Repository alignment findings

The reviewed README still combines an older two-claim plan with a later runtime-focused plan. The accompanying replacement README consolidates the formal objective into runtime measurement and marks memory evaluation as deferred.

The root-level `run_benchmark.sh` contains only whitespace. The implemented script is `scripts/run_benchmark.sh`; it expects six precompiled binaries under `build/plain` and `build/asan`. Its workload names and inputs already match the selected kernels. The supplied source package fills the missing-source handoff.

Only the `Final.xlsx` template is present in the reviewed snapshot. The earlier concern about two templates should be checked against this current inventory. The additional trial-run subsection in the reviewed `environment.md` is already in English.

These findings refer to the reviewed commit. Later repository changes require a fresh comparison.

## References

1. Original paper, Sections 3–4, Figure 1, Figure 2, and Table 1. [USENIX PDF](https://www.usenix.org/system/files/conference/atc12/atc12-final39.pdf)
2. Group repository snapshot. [Reviewed commit](https://github.com/potomin/asan_replication/tree/192971584e957e6ecdca20d07841ef3450da6d77)
3. Benchmark source provenance. [LLVM Shootout pinned revision](https://github.com/llvm/llvm-test-suite/tree/d3f64b96fe6176716771a2e172f799caf1239b5b/SingleSource/Benchmarks/Shootout)
