# Workload C: Memory Allocation Benchmark

## Purpose
This program repeatedly allocates a memory block, writes to and reads from every byte, and releases the block. It is a small performance workload for comparing a normal build with an AddressSanitizer (ASan) build.

This is **not** an intentional memory-error demonstration. It measures this particular allocation-and-access workload, not all real-world programs.

## Inputs
The program accepts two optional positive integer arguments:
- `iterations`: number of allocation/use/release cycles (default: `100000`)
- `bytes_per_block`: bytes in each allocated block (default: `1024`)

Use the same values for normal and ASan builds.

## Build environment
Run these commands in the team's agreed Linux/WSL2 environment with Clang installed.

Check compiler:
```bash
clang++ --version
```

## Compile normal version
```bash
clang++ -O2 -std=c++17 -Wall -Wextra workload_c.cpp -o workload_c_normal
```

## Compile ASan version
```bash
clang++ -O2 -g -std=c++17 -Wall -Wextra -fno-omit-frame-pointer -fsanitize=address workload_c.cpp -o workload_c_asan
```

## Run both versions
```bash
./workload_c_normal 100000 1024
./workload_c_asan 100000 1024
```

The program prints the inputs, elapsed time in microseconds, and a checksum. The checksum should match between builds.

## Suggested repeated runs
Run each build at least three times and save output:
```bash
mkdir -p logs
for i in 1 2 3; do ./workload_c_normal 100000 1024; done | tee logs/normal.txt
for i in 1 2 3; do ./workload_c_asan 100000 1024; done | tee logs/asan.txt
```

## Measurement notes
- Official measurements should run on the team's designated WSL2 machine.
- Use identical source and input values for both builds.
- Avoid running other heavy workloads during timing.
- Record compiler version, build commands, and input values.
- If the team agrees, do a warm-up run before recorded trials.
- Do not generalize the result of this microbenchmark to every program.
