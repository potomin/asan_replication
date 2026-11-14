# Member 4: ASan heap-buffer-overflow demonstration results

## 1. Expected results (defined before testing)

| Case | Index | Expected access | Expected ASan report | Expected exit code |
|---|---:|---|---|---|
| T1 | 0 | In bounds | None | 0 |
| T2 | 15 | In bounds | None | 0 |
| T3 | 16 | Out of bounds | heap-buffer-overflow | Nonzero |
| T4 | 17 | Out of bounds | heap-buffer-overflow | Nonzero |

## 2. Actual results (collected by running the binary)

Each of the four indices was executed in a fresh process three times.
The values below come from `actual_results.csv` and the raw logs, not predictions.

| Case | Index | Repeat | Actual exit code | ASan report? | Actual category | Source location | Matches expectation? |
|---|---:|---:|---:|---|---|---|---|
| T1 | 0 | 1 | 0 | no | none | not-reported | yes |
| T1 | 0 | 2 | 0 | no | none | not-reported | yes |
| T1 | 0 | 3 | 0 | no | none | not-reported | yes |
| T2 | 15 | 1 | 0 | no | none | not-reported | yes |
| T2 | 15 | 2 | 0 | no | none | not-reported | yes |
| T2 | 15 | 3 | 0 | no | none | not-reported | yes |
| T3 | 16 | 1 | 1 | yes | heap-buffer-overflow | asan_heap_demo.cpp:41 | yes |
| T3 | 16 | 2 | 1 | yes | heap-buffer-overflow | asan_heap_demo.cpp:41 | yes |
| T3 | 16 | 3 | 1 | yes | heap-buffer-overflow | asan_heap_demo.cpp:41 | yes |
| T4 | 17 | 1 | 1 | yes | heap-buffer-overflow | asan_heap_demo.cpp:41 | yes |
| T4 | 17 | 2 | 1 | yes | heap-buffer-overflow | asan_heap_demo.cpp:41 | yes |
| T4 | 17 | 3 | 1 | yes | heap-buffer-overflow | asan_heap_demo.cpp:41 | yes |

## 3. How to reproduce

Run `bash member4_run_demo.sh` from the project root in GitHub Codespaces (Linux).
See `demo_results/environment.md` for compiler, options, source hash, and the exact build command.
See `demo_results/build.txt` for build output and compile exit code.
Every `demo_results/logs/index_*_run_*.txt` records the executed command,
combined stdout/stderr including any ASan diagnostics, and process exit code.

## 4. Scope and limitations

This is a controlled heap out-of-bounds *read* demonstration, not a SPEC CPU2006 benchmark.
It tests four selected indices only; it does not measure the paper's runtime or memory overhead.
Results refer to the specific compiler, runtime, and host stated in `demo_results/environment.md`.
