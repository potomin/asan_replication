# Member 4 environment and provenance

Run date: 2026-11-14T16:23:05+00:00

Working directory: `/workspaces/asan_replication`

Platform: `Linux codespaces-148e22 6.8.0-1070-azure #78~22.04.1-Ubuntu SMP Thu Sep 24 18:46:45 UTC 2026 x86_64 x86_64 x86_64 GNU/Linux`

Compiler: `Ubuntu clang version 18.1.3 (1ubuntu1)`

Source file: `asan_heap_demo.cpp`

Source SHA256: `e2dc6ffbf06e66f5785f9830c903d9825fb33d7a46c49de6cc37897934ef61e6`

Repository HEAD before this test: `11123c34d9e1b5b35375fad6995fc90fee1001c8`

Build command: `clang++ -std=c++17 -O0 -g -fsanitize=address -fno-omit-frame-pointer /workspaces/asan_replication/asan_heap_demo.cpp -o /tmp/asan_replication_member4_1000/asan_heap_demo `

ASAN_OPTIONS: `halt_on_error=1:abort_on_error=0:detect_leaks=0:symbolize=1`

Note: HEAD identifies the repository state before committing the new test files;
the source SHA256 identifies the exact file actually compiled.
