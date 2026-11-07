#!/usr/bin/env bash
# Member 4: compile the ASan example and capture all 12 raw run logs.
# Run in WSL/Linux from the repository root: bash member4_run_demo.sh
set -u
set -o pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT" || exit 1
SOURCE="$ROOT/asan_heap_demo.cpp"
RESULTS="$ROOT/demo_results"
LOG_DIR="$RESULTS/logs"
TMP_BUILD="${TMPDIR:-/tmp}/asan_replication_member4_${UID}"
BINARY="$TMP_BUILD/asan_heap_demo"
OPTIONS='halt_on_error=1:abort_on_error=0:detect_leaks=0:symbolize=1'

if [[ ! -f "$SOURCE" ]]; then
    echo "ERROR: Cannot find $SOURCE. Place asan_heap_demo.cpp beside this script." >&2
    exit 2
fi

if command -v clang++ >/dev/null 2>&1; then
    CXX=clang++
elif command -v g++ >/dev/null 2>&1; then
    CXX=g++
else
    echo 'ERROR: Neither clang++ nor g++ was found. Install a C++ compiler in WSL.' >&2
    exit 2
fi

mkdir -p "$TMP_BUILD" "$LOG_DIR"

BUILD=("$CXX" -std=c++17 -O0 -g -fsanitize=address -fno-omit-frame-pointer "$SOURCE" -o "$BINARY")
{
    echo '# Member 4 compilation log'
    printf 'cwd: %s\n' "$ROOT"
    printf 'command: '
    printf '%q ' "${BUILD[@]}"
    printf '\n'
} > "$RESULTS/build.txt"

"${BUILD[@]}" >> "$RESULTS/build.txt" 2>&1
build_exit=$?
printf 'compile_exit_code: %s\n' "$build_exit" >> "$RESULTS/build.txt"
if (( build_exit != 0 )); then
    echo "Compilation failed (exit $build_exit). See demo_results/build.txt" >&2
    exit "$build_exit"
fi

commit='not-a-git-repository'
if command -v git >/dev/null 2>&1; then
    commit="$(git rev-parse HEAD 2>/dev/null || printf 'no-commit')"
fi
source_hash='not-available'
if command -v sha256sum >/dev/null 2>&1; then
    source_hash="$(sha256sum "$SOURCE" | awk '{print $1}')"
fi

{
    echo '# Member 4 environment and provenance'
    echo
    printf 'Run date: %s\n\n' "$(date -Is)"
    printf 'Working directory: `%s`\n\n' "$ROOT"
    printf 'Platform: `%s`\n\n' "$(uname -a)"
    printf 'Compiler: `%s`\n\n' "$("$CXX" --version | head -n 1)"
    printf 'Source file: `asan_heap_demo.cpp`\n\n'
    printf 'Source SHA256: `%s`\n\n' "$source_hash"
    printf 'Repository HEAD before this test: `%s`\n\n' "$commit"
    printf 'Build command: `'
    printf '%q ' "${BUILD[@]}"
    printf '`\n\n'
    printf 'ASAN_OPTIONS: `%s`\n\n' "$OPTIONS"
    echo 'Note: HEAD identifies the repository state before committing the new test files;'
    echo 'the source SHA256 identifies the exact file actually compiled.'
} > "$RESULTS/environment.md"

CSV="$RESULTS/actual_results.csv"
printf 'test_case,index,repeat,exit_code,asan_report,error_category,reported_source_location,log_path,meets_expectation\n' > "$CSV"

for index in 0 15 16 17; do
    for repetition in 1 2 3; do
        case "$index" in
            0) test_case=T1 ;;
            15) test_case=T2 ;;
            16) test_case=T3 ;;
            17) test_case=T4 ;;
        esac
        log_rel="demo_results/logs/index_${index}_run_${repetition}.txt"
        log_file="$ROOT/$log_rel"
        {
            printf 'test_case=%s index=%s repeat=%s\n' "$test_case" "$index" "$repetition"
            printf 'command: ASAN_OPTIONS=%q %q %q\n' "$OPTIONS" "$BINARY" "$index"
            echo '--- stdout and stderr ---'
        } > "$log_file"

        # Nonzero exit is expected for invalid indices. Do not use "set -e".
        ASAN_OPTIONS="$OPTIONS" "$BINARY" "$index" >> "$log_file" 2>&1
        exit_code=$?
        printf '\n--- process exit code: %d ---\n' "$exit_code" >> "$log_file"

        asan_report=no
        category=none
        if grep -q 'ERROR: AddressSanitizer: heap-buffer-overflow' "$log_file"; then
            asan_report=yes
            category=heap-buffer-overflow
        elif grep -q 'ERROR: AddressSanitizer:' "$log_file"; then
            asan_report=yes
            category=other-asan-error
        fi
        source_location="$(grep -Eo 'asan_heap_demo\.cpp:[0-9]+' "$log_file" | head -n 1 || true)"
        if [[ -z "$source_location" ]]; then source_location='not-reported'; fi

        meets_expectation=no
        if (( index < 16 )) && (( exit_code == 0 )) && [[ "$asan_report" == no ]]; then
            meets_expectation=yes
        elif (( index >= 16 )) && (( exit_code != 0 )) && [[ "$category" == heap-buffer-overflow ]]; then
            meets_expectation=yes
        fi

        printf '%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
          "$test_case" "$index" "$repetition" "$exit_code" "$asan_report" \
          "$category" "$source_location" "$log_rel" "$meets_expectation" >> "$CSV"
        printf 'index=%-2s run=%s exit=%-3s report=%-3s category=%-20s expected=%s\n' \
          "$index" "$repetition" "$exit_code" "$asan_report" "$category" "$meets_expectation"
    done
done

{
    echo '# Member 4: ASan heap-buffer-overflow demonstration results'
    echo
    echo '## 1. Expected results (defined before testing)'
    echo
    echo '| Case | Index | Expected access | Expected ASan report | Expected exit code |'
    echo '|---|---:|---|---|---|'
    echo '| T1 | 0 | In bounds | None | 0 |'
    echo '| T2 | 15 | In bounds | None | 0 |'
    echo '| T3 | 16 | Out of bounds | heap-buffer-overflow | Nonzero |'
    echo '| T4 | 17 | Out of bounds | heap-buffer-overflow | Nonzero |'
    echo
    echo '## 2. Actual results (collected by running the binary)'
    echo
    echo 'Each of the four indices was executed in a fresh process three times.'
    echo 'The values below come from `actual_results.csv` and the raw logs, not predictions.'
    echo
    echo '| Case | Index | Repeat | Actual exit code | ASan report? | Actual category | Source location | Matches expectation? |'
    echo '|---|---:|---:|---:|---|---|---|---|'
    while IFS=, read -r test_case index repetition exit_code asan_report category src log_path matches; do
        if [[ "$test_case" == 'test_case' ]]; then continue; fi
        printf '| %s | %s | %s | %s | %s | %s | %s | %s |\n' \
          "$test_case" "$index" "$repetition" "$exit_code" "$asan_report" "$category" "$src" "$matches"
    done < "$CSV"
    echo
    echo '## 3. How to reproduce'
    echo
    echo 'Run `bash member4_run_demo.sh` from the project root in WSL/Linux.'
    echo 'See `demo_results/environment.md` for compiler, options, source hash, and the exact build command.'
    echo 'See `demo_results/build.txt` for build output and compile exit code.'
    echo 'Every `demo_results/logs/index_*_run_*.txt` records the executed command,'
    echo 'combined stdout/stderr including any ASan diagnostics, and process exit code.'
    echo
    echo '## 4. Scope and limitations'
    echo
    echo 'This is a controlled heap out-of-bounds *read* demonstration, not a SPEC CPU2006 benchmark.'
    echo "It tests four selected indices only; it does not measure the paper's runtime or memory overhead."
    echo 'Results refer to the specific compiler, runtime, and host stated in `environment.md`.'
} > "$RESULTS/expected_vs_actual.md"

if grep -q ',no$' "$CSV"; then
    echo 'WARNING: At least one run did not meet its predicted outcome. Inspect the raw logs.' >&2
    exit 3
fi
printf '\nFinished. Files: %s\n' "$RESULTS"
