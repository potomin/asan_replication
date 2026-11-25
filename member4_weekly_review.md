# Member 4 Weekly Experiment Review

**Name:** 陈婉仪
**Student ID:** 1240002711
**Review Date:** 2026-11-25
**Project:** AddressSanitizer Paper Replication
**Role:** Member 4 - Error Detection Demo and Extension Experiment

## 1. Weekly Work

This week, I reviewed and verified the existing ASan heap
out-of-bounds detection experiment, its execution logs,
result tables, and environment documentation.

The original experiment was performed on November 14, 2026.
No new experimental runs were performed during this review.

## 2. Experiment Setup

- Platform: GitHub Codespaces, Linux x86_64
- Compiler: Clang 18.1.3
- Tool: AddressSanitizer (ASan)
- Source file: asan_heap_demo.cpp
- Array size: 16 integers
- Tested indices: 0, 15, 16, 17
- Repetitions: 3 per index
- Total runs: 12

## 3. Verified Results

| Index | Repetitions | ASan Report | Expected Result |
|-------|-------------|-------------|-----------------|
| 0     | 3           | No          | Matched         |
| 15    | 3           | No          | Matched         |
| 16    | 3           | Yes         | Matched         |
| 17    | 3           | Yes         | Matched         |

All 12 recorded runs matched the expected results.

For indices 16 and 17, ASan reported:
- Error type: heap-buffer-overflow
- Access type: READ of size 4
- Source location: asan_heap_demo.cpp:41

## 4. Evidence Checked

The following existing files were reviewed:

- asan_heap_demo.cpp
- member4_run_demo.sh
- extension_plan.md
- demo_results/actual_results.csv
- demo_results/expected_vs_actual.md
- demo_results/environment.md
- demo_results/build.txt
- 12 execution logs under demo_results/logs/

The experiment records were consistent with the expected
outcomes for the four selected indices.

## 5. Scope and Limitations

This experiment demonstrates ASan detection of selected
heap out-of-bounds reads.

It does not prove that ASan detects every memory error.
It does not measure runtime or memory overhead.
It is separate from the group's WSL performance benchmarks.

## 6. Weekly Conclusion

The existing experiment and documentation were reviewed.
All 12 recorded test outcomes matched expectations.
No changes to the original experimental code were required.

This review provides an additional record of Member 4's
work for the group presentation and project repository.
