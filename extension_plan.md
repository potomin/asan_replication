# Extension Experiment Plan

## Responsibility

Member 4: Design a safe memory-error demonstration and a controlled
extension experiment.

## Paper

AddressSanitizer: A Fast Address Sanity Checker.
USENIX ATC 2012.

https://www.usenix.org/system/files/conference/atc12/atc12-final39.pdf

## Demonstration

Create a small C++ program that allocates and initializes a heap array
of 16 integers.

Read one element using a command-line index and print the value.
An access to index 16 is outside the allocated array.

The demonstration will check whether an ASan-enabled build reports
a heap-buffer-overflow at the invalid access.

## Research Question

How does the accessed index affect ASan's detection of heap
out-of-bounds reads in this program?

## Independent Variable

The accessed index: 0, 15, 16, or 17.

## Controlled Conditions

Keep the following unchanged:
- Source code and array length
- Initialization and access type
- Hardware and operating system
- Compiler version and compilation options
- ASan runtime configuration

## Test Cases

| Case | Array length | Index | Expected behavior |
|---|---:|---:|---|
| T1 | 16 | 0 | Valid access; no ASan memory-error report |
| T2 | 16 | 15 | Valid access; no ASan memory-error report |
| T3 | 16 | 16 | Invalid access; expected heap-buffer-overflow report |
| T4 | 16 | 17 | Invalid access; expected heap-buffer-overflow report |

These are expectations, not measured results.

## Procedure

1. Use the environment documented by Member 2.
2. Compile the demonstration with ASan enabled.
3. Start a separate process for each test case.
4. Run each case at least three times.
5. Save the command, output, error report, and exit code for every run.
6. Compare observed behavior with the expected behavior.

## Measurements

Record:
- Test case and repetition number
- Source commit
- Environment and compiler version
- Build and run commands
- ASan runtime options
- Accessed index
- ASan report presence and error category
- Reported source location
- Exit code and raw log path

## Scope and Limitations

This is a small functional demonstration and extension experiment.
It does not reproduce the paper's SPEC CPU2006 performance results
or establish that ASan detects every memory error.

## Safety

Use only a locally written test program with ordinary user privileges.
The program requires no network access, system-file modification,
or kernel changes.

## Week 1 Status

Experiment design completed.
Implementation and execution are pending.