# Member 4 deliverables — setup and submission

This package implements the pre-existing `extension_plan.md` in the team's `asan_replication` repository.

## Copy into GitHub repository

Copy **both** `asan_heap_demo.cpp` and `member4_run_demo.sh` into the root of your local `asan_replication` folder. The script automatically creates `demo_results/` when run. Do not copy this instruction file unless you wish to.

On Windows, if the local repository is `E:\asan_replication`, open **WSL** (Ubuntu) and run:

```bash
cd /mnt/e/asan_replication
bash member4_run_demo.sh
```

If a C++ compiler is missing, install `clang` or `g++` inside your WSL distribution before rerunning. Run `git pull`/GitHub Desktop **Fetch origin → Pull origin** before adding your files to avoid conflicts with teammates.

## Check the resulting files

The script creates:

- `demo_results/build.txt`: compilation command, compiler output, compilation exit code.
- `demo_results/environment.md`: host, compiler, SHA256, git HEAD, and ASAN_OPTIONS.
- `demo_results/actual_results.csv`: exactly 12 rows with recorded outcomes.
- `demo_results/expected_vs_actual.md`: predicted results and a separate table of actual results.
- `demo_results/logs/index_0_run_1.txt` etc.: 12 raw stdout/stderr + command + exit-code logs.

For a successful demonstration, tests 0 and 15 should normally exit 0 without an ASan report; tests 16 and 17 should normally exit nonzero with `heap-buffer-overflow`. The actual data may differ and must not be fabricated or replaced with the predictions.

## Commit in GitHub Desktop

1. Open the `asan_replication` repository in GitHub Desktop.
2. Review changed files. Select the two source/script files and the generated `demo_results/` files.
3. Do **not** commit compiled executables. This script places the binary under `/tmp`, outside the repository.
4. Commit using summary `Member 4: implement ASan heap demo and record 12 runs`.
5. Push origin, then verify that the files appear on GitHub.

Optional, after successful local tests: append a **Week 2 Status** section to the existing `extension_plan.md` and link to `demo_results/expected_vs_actual.md`. Preserve the existing Week 1 plan.

## Important attribution

Logs generated on the assistant's environment (if provided separately) are not a substitute for runs on the team member's host. Run the script on your own computer or on the team's specified experimental machine and upload **those** raw logs.
