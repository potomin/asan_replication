# Reproduction Environment

**Contributor:** 蔡湘敏  
**Student ID:** 1240007751  
**Date:** 2026-10-25

## Host and operating system

- Host system: Windows running Ubuntu through WSL2
- Linux distribution: Ubuntu 24.04.5 LTS
- Linux kernel: 6.18.54.1-microsoft-standard-WSL2
- Architecture: x86_64
- CPU: AMD Ryzen 7 8845H with Radeon 780M Graphics
- Logical CPUs visible in WSL: 16
- Memory visible in WSL: 15 GiB
- Swap: 4.0 GiB

## Compiler and tools

- Clang: Ubuntu clang version 18.1.3 (1ubuntu1)
- Git: 2.43.0

## AddressSanitizer smoke test

- Compile command: `clang++ -O0 -g -fsanitize=address -fno-omit-frame-pointer asan_test.cpp -o asan_test`
- Result: ASan detection check passed (expected stack-buffer-overflow was detected)
- ASan report: `stack-buffer-overflow`
- The test intentionally reads beyond the end of a one-element stack array.
- Test source: `asan_test.cpp`
- Captured output: `asan_test.log`

This smoke test verifies that AddressSanitizer works in this environment. It is not a reproduction of the paper's benchmark results.

## Difference from the paper's evaluation environment

The paper evaluated SPEC CPU2006 in 64-bit Linux on an HP Z600 with two quad-core Intel Xeon E5620 CPUs and 24 GB of RAM. Our environment is different, and this difference must be considered when comparing results with the paper.

## Week 2 workload smoke test

- Date: 2026-11-08
- Compiler: Ubuntu clang version 18.1.3 (1ubuntu1)
- Input: 10000 iterations, 1024 bytes per block
- Normal build: `clang++ -O2 workload_c.cpp -o workload_normal`
- ASan build: `clang++ -O2 -g -fsanitize=address -fno-omit-frame-pointer workload_c.cpp -o workload_asan`
- Normal run: exit code 0; checksum 1305600000; elapsed time 5780 us
- ASan run: exit code 0; checksum 1305600000; elapsed time 41060 us
- Outcome: Both builds completed successfully and produced the same checksum.
- Limitation: This was one smoke-test run to check that both builds work. The times are not formal benchmark results.
