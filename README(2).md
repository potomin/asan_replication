# AddressSanitizer: Partial Reproduction with Selected LLVM Benchmarks

Member 1: Wang Yihan (王一涵)  
Deliverable: workload selection and installation/build/run documentation  
Updated: 7 November 2026

## 1. Original evaluation and our final workload decision

This project studies **AddressSanitizer: A Fast Address Sanity Checker**, by Konstantin Serebryany, Derek Bruening, Alexander Potapenko, and Dmitry Vyukov (USENIX ATC 2012).

Section 4 evaluates AddressSanitizer using C and C++ programs from **SPEC CPU2006**. The baseline uses regular LLVM/Clang with `-O2`. The original machine runs 64-bit Linux and has two quad-core Intel Xeon E5620 processors and 24 GB RAM. The study also uses historical runtime settings, including 32-byte redzones, disabled allocation/deallocation stack unwinding, and a zero-sized quarantine.

**Our group does not currently have access to an authorized copy of SPEC CPU2006.** SPEC distributes this suite under a license agreement; authorized access normally requires a purchased license or an applicable institutional license. This records our group's access constraint, not a verified claim that the university owns no license.

**Final decision:** use three publicly distributed C benchmarks from **LLVM test-suite, `SingleSource/Benchmarks/Shootout`**, as the main substitute workload: **`ary3`, `heapsort`, and `matrix`**. Keep Member 3's **`workload_c.cpp`** for environment smoke testing and optional supplementary measurements. The self-written program is no longer our only formal workload.

The LLVM test-suite provides public program sources and reference outputs. The selected programs can be obtained without the SPEC suite. We use only the stated public programs, not `External/SPEC`. Preserve the upstream license and source notices, and do not present the upstream programs as code written by our group.

**This is a partial reproduction with substitute workloads.** It retains the ordinary-build versus ASan-build comparison but changes the benchmarks, inputs, hardware, compiler version, and runtime configuration. Selecting three LLVM programs improves traceability and workload variety; it does not make this equivalent to SPEC CPU2006 or validate the paper's suite-wide numerical results. Acceptance of this reduced scope depends on the course requirements.

| Item | Original paper | This project |
| --- | --- | --- |
| Main workloads | C/C++ programs from SPEC CPU2006 | Three selected LLVM test-suite C programs |
| Supplementary workload | Not the group's custom program | `workload_c.cpp`, supplied by Member 3 |
| Main inputs | SPEC benchmark inputs | Explicit arguments listed below |
| Compiler and optimization | Historical LLVM/Clang, `-O2` | Installed Clang, `-O2` in both modes |
| Runtime | Historical ASan configuration | Installed ASan; leak detection disabled and other options left at installed defaults |
| Platform | Original Linux workstation | Group's 64-bit WSL/Ubuntu machine; actual details recorded |
| Claim scope | SPEC suite evaluation | Per-program comparison on a small public subset |

## 2. Selected programs and fixed inputs

All three source files are in `SingleSource/Benchmarks/Shootout/` of the upstream repository. They originate from the Programming Language Shootout, as described in the upstream directory README and source headers.

| Program | Source file | Behavior | Explicit run argument | Expected stdout |
| --- | --- | --- | --- | --- |
| `ary3` | `ary3.c` | Repeated integer-array accumulation | `1500000` (array length) | `1000 1500000000` |
| `heapsort` | `heapsort.c` | Heap-sorts a deterministic array of doubles | `8000000` (number of elements) | `0.999993` |
| `matrix` | `matrix.c` | Repeated multiplication of allocated 10-by-10 integer matrices | `3000000` (multiplication iterations) | `3355 13320 17865 23575` |

These arguments match the selected revision's normal, non-`SMALL_PROBLEM_SIZE` defaults; we pass them explicitly to avoid ambiguity. No external input files are required. Use `LC_ALL=C` for stable numeric formatting. Each successful process must exit with code `0`.

The three programs cover sequential array access, sorting, and matrix arithmetic. This remains a small selection of computational kernels, not a representative application suite. Allocation-heavy behavior is additionally explored by `workload_c.cpp`; keep that result separate from the three-program summary.

We compile these three files directly rather than running the complete LLVM CMake/lit harness. This is a group-defined experiment using upstream benchmark sources, not an official full-suite LLVM test result. The supplied reference files end with an `exit 0` harness marker that is not program stdout; Section 5 shows how to remove that marker for direct comparison.

## 3. Install tools and obtain a fixed source revision

Run these commands from the group repository root in **64-bit Ubuntu under WSL**. WSL/Ubuntu must already be installed. Keep `workload_c.cpp` alongside this README. Use a fresh dependency directory for the clone commands; do not overwrite an existing local checkout with uncommitted work.

```bash
sudo apt-get update
sudo apt-get install -y git clang build-essential time
mkdir -p third_party build/plain build/asan results/smoke results/check expected

git clone --depth 1 --filter=blob:none --sparse \
  https://github.com/llvm/llvm-test-suite.git third_party/llvm-test-suite
git -C third_party/llvm-test-suite sparse-checkout set \
  SingleSource/Benchmarks/Shootout
git -C third_party/llvm-test-suite fetch --depth 1 origin \
  d3f64b96fe6176716771a2e172f799caf1239b5b
git -C third_party/llvm-test-suite checkout --detach \
  d3f64b96fe6176716771a2e172f799caf1239b5b
git -C third_party/llvm-test-suite rev-parse HEAD
```

Pinned upstream commit: **`d3f64b96fe6176716771a2e172f799caf1239b5b`**. This revision and its source/reference files were inspected when preparing this README. Both modes must use this same checkout. Do not silently substitute a later `main` revision.

The sparse checkout includes the upstream root `LICENSE.TXT`, the Shootout README, source notices, and reference files. Retain them. The upstream root license describes Apache 2.0 with LLVM exceptions and identifies separately licensed material; retain any applicable component notices as well. Fetching the dependency locally avoids copying an entire third-party repository into our group repository.

Record the actual environment:

```bash
uname -a
cat /etc/os-release
lscpu
free -h
clang --version
clang++ --version
/usr/bin/time --version
git rev-parse HEAD
git -C third_party/llvm-test-suite rev-parse HEAD
sha256sum workload_c.cpp
sha256sum third_party/llvm-test-suite/SingleSource/Benchmarks/Shootout/ary3.c \
  third_party/llvm-test-suite/SingleSource/Benchmarks/Shootout/heapsort.c \
  third_party/llvm-test-suite/SingleSource/Benchmarks/Shootout/matrix.c
```

Put actual WSL/Ubuntu, CPU, RAM, compiler versions, repository revisions, source hashes, and runtime settings in `environment.md`. Do not substitute the paper's environment for ours.

## 4. Common configuration and compilation

Run all following command blocks in the same Bash session, or repeat these exports in each new session:

```bash
export LC_ALL=C
export ASAN_OPTIONS=detect_leaks=0
unset LSAN_OPTIONS
```

The selected experiment studies ASan address-checking overhead. `detect_leaks=0` explicitly disables the additional LeakSanitizer leak check, while retaining ASan address checks. Other sanitizer options use the installed runtime's defaults. This configuration is not a recreation of the 2012 runtime: in particular, the original redzone, stack-unwinding, and quarantine settings have not been reproduced. Record the complete setting for every run. Do not enable or disable options only for selected measured repetitions.

### Main public benchmarks

```bash
for name in ary3 heapsort matrix; do
  clang -std=c17 -O2 -g -fno-omit-frame-pointer \
    "third_party/llvm-test-suite/SingleSource/Benchmarks/Shootout/${name}.c" \
    -o "build/plain/${name}" -lm || break
  clang -std=c17 -O2 -g -fno-omit-frame-pointer -fsanitize=address \
    "third_party/llvm-test-suite/SingleSource/Benchmarks/Shootout/${name}.c" \
    -o "build/asan/${name}" -lm || break
done
```

Check that all six compilations succeeded before running. Use `clang` for these C sources and `clang++` for the custom C++ source. Common build flags are identical within each comparison; the instrumented build additionally uses `-fsanitize=address`. No special ASan exclusion lists or partial instrumentation are used.

### Custom smoke-test program

```bash
clang++ -std=c++17 -O2 -g -fno-omit-frame-pointer \
  workload_c.cpp -o build/workload_plain
clang++ -std=c++17 -O2 -g -fno-omit-frame-pointer \
  -fsanitize=address workload_c.cpp -o build/workload_asan
```

`workload_c.cpp` repeatedly allocates an unsigned-byte array, writes and reads its contents, accumulates a 64-bit checksum, and frees the array through `std::unique_ptr`. It prints `iterations`, `bytes_per_block`, `elapsed_us`, and `checksum`.

Its interface is `[iterations] [bytes_per_block]`, with defaults `100000 1024`. Use positive decimal inputs; the current implementation is not a general input-validation tool. At `100000 1024`, the mathematically expected checksum is **`13056000000`**. The source SHA-256 is:

```text
7f2239176b890e74b5cf71415e4748a5b1ae46aa9c3d8eea165ba9915fe887c4
```

## 5. Validate the public benchmarks before measurement

First prepare expected stdout from the upstream reference outputs:

```bash
for name in ary3 heapsort matrix; do
  sed '/^exit 0$/d' \
    "third_party/llvm-test-suite/SingleSource/Benchmarks/Shootout/${name}.reference_output" \
    > "expected/${name}.stdout.txt"
done
```

The following block runs both modes once and records stdout, stderr, exit code, and output comparison status. It is a **validation pass**, not the formal five-run experiment. Run it in interactive Bash without `set -e` so failed processes still have their status saved.

```bash
for spec in ary3:1500000 heapsort:8000000 matrix:3000000; do
  name=${spec%%:*}
  input=${spec#*:}
  for mode in plain asan; do
    prefix="results/check/${name}.${mode}"
    "./build/${mode}/${name}" "$input" \
      > "${prefix}.stdout.txt" 2> "${prefix}.stderr.txt"
    code=$?
    printf '%s\n' "$code" > "${prefix}.exit.txt"
    diff -u "expected/${name}.stdout.txt" "${prefix}.stdout.txt" \
      > "${prefix}.diff.txt"
    comparison=$?
    printf '%s\n' "$comparison" > "${prefix}.compare-exit.txt"
    printf '%s %s exit=%s comparison=%s\n' "$name" "$mode" "$code" "$comparison"
  done
done
```

Require process exit `0`, comparison status `0`, and no sanitizer-error report for every program in both modes. Inspect stderr as well as stdout. Do not treat matching output as proof of all-input correctness. Stop formal measurement and investigate any failure; do not remove a program solely because its ASan slowdown is large.

## 6. Member 2: custom workload smoke test


Run each binary once with exactly the same inputs. Run the blocks below in an interactive Bash session without `set -e`, so an unsuccessful process still has its exit code recorded.

```bash
./build/workload_plain 100000 1024 \
  > results/smoke/plain.stdout.txt 2> results/smoke/plain.stderr.txt
plain_exit=$?
printf '%s\n' "$plain_exit" > results/smoke/plain.exit.txt

./build/workload_asan 100000 1024 \
  > results/smoke/asan.stdout.txt 2> results/smoke/asan.stderr.txt
asan_exit=$?
printf '%s\n' "$asan_exit" > results/smoke/asan.exit.txt

cat results/smoke/plain.stdout.txt results/smoke/asan.stdout.txt
cat results/smoke/plain.exit.txt results/smoke/asan.exit.txt
cat results/smoke/plain.stderr.txt results/smoke/asan.stderr.txt
```

Expected successful behavior, to be checked against actual logs:

- Both exit codes are `0`.
- Both outputs report `iterations=100000` and `bytes_per_block=1024`.
- Both checksums are `13056000000`.
- No ASan memory-error report appears.
- `elapsed_us` is measured separately and is not expected to match between runs.

Matching checksums are a basic consistency check, not proof that all possible inputs are correct. This smoke test checks that the workload runs; **one run per build is not the formal performance experiment**.

Member 2 must add a **工作负载试运行 / Workload smoke test** subsection to `environment.md`, containing the actual compilation commands, run commands, input values, stdout/stderr, exit codes, checksum comparison, and environment. Actual results must be distinguished from the expectations above.

The shared configuration in Section 4 disables leak detection for this documented profile. If a different setting is tried, label that run separately and preserve the exact options. Member 2's original task remains the custom-program WSL smoke test; Member 3 must also validate the main public programs before formal measurements.

## 7. Formal experiment and script requirements for Member 3

### Research target and scope

The primary target is the runtime-overhead comparison studied in the paper's **Figure 2**, evaluated here on the three selected LLVM programs. We report each program separately, not a claim that the paper's SPEC average has been reproduced.

The paper's **Table 1** uses `VmPeak`, a different metric from Max RSS. Memory measurements are supplementary in the current plan. Unless target-process VmPeak collection is implemented and documented, mark the Table 1 reproduction as unavailable and report Max RSS under its own name.

### Collection protocol

1. Freeze the source commit, compiler/version, inputs in Section 2, flags, and runtime options before collecting data. Record input changes made during a pilot and restart the full measurement set afterward.
2. Run at least one unmeasured warm-up for each program/mode combination. Warm-ups must pass output validation but must not enter the summary statistics.
3. Collect at least **five valid runs for each of the three programs in each mode**: at least 30 valid measured executions, plus warm-ups. Alternate the order of plain/ASan within successive pairs and run sequentially on the same machine. Do not run these measurements in parallel.
4. Save the exact invocation, program/mode, input, sequence/attempt number, warm-up status, runtime options, stdout, stderr, exit code, reference-output comparison status, elapsed time, and Max RSS. Use unique filenames for every attempt.
5. A valid run exits `0`, matches the reference output, and has no sanitizer error. Retain invalid-attempt logs and exclusion reasons; collect replacements until at least five valid samples exist in each cell. Do not discard merely slow runs without a documented methodological reason.
6. Use **whole-process elapsed time** consistently for the three public programs. Report valid `n`, arithmetic mean, and sample standard deviation (`n-1` denominator) for each program/mode. Never mix a custom program's internal `elapsed_us` with a public program's whole-process time.
7. For each program, define `runtime_ratio = mean(ASan time) / mean(plain time)` and `overhead_percent = (runtime_ratio - 1) * 100`. If a combined summary is desired, additionally report the geometric mean of the three runtime ratios, label the three-program subset, and keep all individual results visible. Exclude the custom workload from this summary.

For one measured execution, use this command form after the warm-ups. The example is the first plain `ary3` observation; Member 3's script must generalize it to every program, mode, repetition, validity check, and unique attempt number:

```bash
mkdir -p results/formal
/usr/bin/time -f 'elapsed_s=%e\nmax_rss_kib=%M' \
  -o results/formal/ary3.plain.run01.metrics.txt \
  ./build/plain/ary3 1500000 \
  > results/formal/ary3.plain.run01.stdout.txt \
  2> results/formal/ary3.plain.run01.stderr.txt
code=$?
printf '%s\n' "$code" > results/formal/ary3.plain.run01.exit.txt
diff -u expected/ary3.stdout.txt \
  results/formal/ary3.plain.run01.stdout.txt \
  > results/formal/ary3.plain.run01.diff.txt
comparison=$?
printf '%s\n' "$comparison" \
  > results/formal/ary3.plain.run01.compare-exit.txt
```

GNU time `%e` has limited printed precision. If pilot timings are zero or too short to distinguish overhead reliably, use a documented higher-resolution whole-process timer consistently for both modes, or choose larger safe arguments and recompute/validate references before restarting measurements. Do not report ratios with a zero denominator. In particular, increasing `ary3` beyond the safe integer range can cause overflow; do not blindly scale its input.

### Memory metrics and interpretation

| Metric | Meaning | Current collection / restriction |
| --- | --- | --- |
| GNU time `elapsed_s` (`%e`) | Whole-process elapsed seconds | Main runtime comparison; includes process startup/shutdown |
| Custom `elapsed_us` | Microseconds inside the custom program's loop | Supplementary only; excludes startup and final shutdown |
| GNU time `max_rss_kib` (`%M`) | Peak resident memory in KiB on Linux | Available supplementary physical-memory metric |
| `VmPeak` from `/proc/<target-pid>/status` | Peak virtual address-space size | Paper's Table 1 metric; not emitted by the selected original programs |

**VmPeak and Max RSS must never share a column or label.** Reading `/proc/self/status` from the measuring shell measures the shell. Sampling a live target can miss a short-lived process; if used, state the sampling method and limitations. Program-side collection near termination is closer to the paper's method but changes the sources: document and apply the same instrumentation to both modes. If unavailable, use `N/A`, not `0`, for VmPeak. Modern ASan virtual-address reservations do not represent physical RAM consumption.

The Excel template must separate program, mode, inputs, warm-up/validity status, elapsed time, Max RSS, and optional VmPeak, with units. Include mean and sample standard deviation for valid measured runs only. Member 3 must publish the actual script filename and invocation when their script is updated; this README does not invent an existing script path.

### Files excluded from version control

Member 3 should merge these entries into the repository's `.gitignore` while preserving existing rules:

```gitignore
/build/
/third_party/llvm-test-suite/
```

Keep source code, this README, actual environment records, scripts, the Excel template, and the required raw experimental records in the group submission. Do not accidentally ignore all of `results/` if those logs are required. The dependency is reconstructible from the pinned commit and commands above; retain upstream notices if distributing copies.

## 8. Verification status and reproduction limits

The three public sources and their upstream reference outputs were inspected at the pinned commit. A separate local Linux/GCC 14.2.0 check compiled all three in plain and ASan modes using the common flags in Section 4, with `detect_leaks=0` for ASan. All six executions at the listed inputs exited `0`, produced the expected stdout in Section 2, and had empty stderr. This establishes a local feasibility check, **not** Member 2's WSL/Clang verification or formal statistical results. The Clang commands still need to run in the group's target environment.

The custom source was also checked separately under Linux/GCC: both modes produced checksum `13056000000` with leak detection disabled for the successful ASan retry. An initial default-ASan attempt encountered a LeakSanitizer/ptrace environment error; it is not counted as a successful run. These checks provide no formal timings in this README.

The scope remains limited by three small C programs, a synthetic supplementary C++ workload, different inputs/hardware, modern compiler optimization, modern ASan defaults, disabled leak detection, and whole-process timing. This cannot establish the original suite's 73% average slowdown or its 3.37x VmPeak increase. It does not validate every ASan bug-detection capability. Member 4's intentional-error demonstrations are a separate experiment.

The workload choice and instructions are complete. WSL execution records, the updated formal run script, Excel results, and demonstration logs must be supplied by the responsible members after actual execution. Expected outputs and protocol descriptions must not be presented as collected data.

## 9. Responsibilities and submission

| Member | Deliverable |
| --- | --- |
| 1: Wang Yihan | This `README.md`: SPEC access constraint, exact public substitute selection, source provenance, partial-reproduction scope, and installation/build/run instructions |
| 2: Cai Xiangmin | Actual WSL custom-workload smoke-test records in `environment.md`, including commands, options, outputs, exit codes, and checksum comparison |
| 3: Guo Yifan | Existing custom source; adapt scripts and Excel to the three main public programs plus separately labeled supplementary runs; warm-ups, five valid runs per mode/program, metric separation, `.gitignore`, and real script usage |
| 4: Chen Wanyi | Demonstration source and actual records for indices 0, 15, 16, 17, each run at least three times; expected and observed outcomes separated |

Save this file as **`README.md`** in the repository root. If a repository README already exists, merge these sections while preserving unrelated required information. The group must align Member 3's scripts and Excel with this updated selection before collecting formal data. Member 2 can continue the already assigned custom-program smoke test.

## References

1. Serebryany et al. *AddressSanitizer: A Fast Address Sanity Checker*. USENIX ATC 2012, Section 4, Figure 2 and Table 1. [Paper page](https://www.usenix.org/conference/atc12/technical-sessions/presentation/serebryany).
2. SPEC. [CPU2006 legal notices](https://www.spec.org/cpu2006/docs/legal.html) and [ordering/licensing information](https://www.spec.org/order/).
3. LLVM. [test-suite Guide](https://llvm.org/docs/TestSuiteGuide.html).
4. LLVM test-suite. [Pinned source revision](https://github.com/llvm/llvm-test-suite/tree/d3f64b96fe6176716771a2e172f799caf1239b5b/SingleSource/Benchmarks/Shootout), including `README.txt`, `ary3.c`, `heapsort.c`, `matrix.c`, and their `.reference_output` files. [Upstream license](https://github.com/llvm/llvm-test-suite/blob/d3f64b96fe6176716771a2e172f799caf1239b5b/LICENSE.TXT).
5. LLVM/Clang. [AddressSanitizer documentation](https://clang.llvm.org/docs/AddressSanitizer.html).
6. Group-provided `workload_c.cpp` (Member 3), used for the smoke test and optional supplementary experiments.
