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

### README规定参数的补充试运行

- 日期：2026-11-08
- 编译器：Ubuntu clang version 18.1.3 (1ubuntu1)
- 输入：100000 iterations，1024 bytes per block
- ASan设置：`ASAN_OPTIONS=detect_leaks=0`；`LSAN_OPTIONS` 未设置；`LC_ALL=C`
- 普通版编译命令：`clang++ -std=c++17 -O2 -g -fno-omit-frame-pointer workload_c.cpp -o build/workload_plain`
- ASan版编译命令：`clang++ -std=c++17 -O2 -g -fno-omit-frame-pointer -fsanitize=address workload_c.cpp -o build/workload_asan`
- 运行命令：`./build/workload_plain 100000 1024` 和 `./build/workload_asan 100000 1024`
- 普通版运行：退出码 0；输出 `iterations=100000`、`bytes_per_block=1024`、`elapsed_us=46118`、`checksum=13056000000`；错误输出为空。
- ASan版运行：退出码 0；输出 `iterations=100000`、`bytes_per_block=1024`、`elapsed_us=335609`、`checksum=13056000000`；错误输出为空。
- 结果：两种构建都成功运行，校验和一致。这是一次试运行，不是正式性能实验结果。
