#!/usr/bin/env bash
# Formal runtime/RSS collection for the three LLVM Shootout benchmarks.
# Run from any directory; paths are resolved relative to the repository root.

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

runs=5
output="results/formal/formal_runs.csv"
max_pair_attempts=""

usage() {
  cat <<'USAGE'
Usage:
  bash scripts/run_benchmark.sh [--runs 5] [--output PATH]

Options:
  --runs N       Number of valid PAIRED runs required per program (minimum 5).
  --output PATH  Raw CSV output path. The file must not already exist.
  -h, --help     Show this help.

The script runs ary3, heapsort, and matrix in baseline/plain and ASan modes.
It performs one validated warm-up per program/mode, then alternates run order
within successive pairs. Failed attempts and their logs are retained.

Expected stdout files:
  expected/ary3.stdout.txt
  expected/heapsort.stdout.txt
  expected/matrix.stdout.txt
USAGE
}

while (($#)); do
  case "$1" in
    --runs)
      [[ $# -ge 2 ]] || { echo "ERROR: --runs needs a value." >&2; exit 2; }
      runs="$2"; shift 2 ;;
    --output)
      [[ $# -ge 2 ]] || { echo "ERROR: --output needs a path." >&2; exit 2; }
      output="$2"; shift 2 ;;
    -h|--help)
      usage
      exit 0 ;;
    *)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 2 ;;
  esac
done

if ! [[ "$runs" =~ ^[0-9]+$ ]] || (( runs < 5 )); then
  echo "ERROR: --runs must be an integer >= 5." >&2
  exit 2
fi

# A bounded retry limit prevents an endless experiment if a configuration fails.
max_pair_attempts=$((runs * 3))

if [[ "$output" != /* ]]; then
  output="$REPO_ROOT/$output"
fi
OUTPUT_DIR="$(dirname "$output")"
mkdir -p "$OUTPUT_DIR"

if [[ -e "$output" ]]; then
  echo "ERROR: output already exists: $output" >&2
  echo "Choose a new --output path or move the old CSV first." >&2
  exit 2
fi

if [[ ! -x /usr/bin/time ]] || ! /usr/bin/time --version 2>&1 | grep -q 'GNU'; then
  echo "ERROR: GNU /usr/bin/time is required." >&2
  exit 2
fi

export LC_ALL=C
export ASAN_OPTIONS=detect_leaks=0
unset LSAN_OPTIONS

LOG_DIR="${OUTPUT_DIR}/formal_logs"
mkdir -p "$LOG_DIR"

# Fixed workloads and arguments from the project README.
programs=(ary3 heapsort matrix)
declare -A inputs=(
  [ary3]=1500000
  [heapsort]=8000000
  [matrix]=3000000
)

for program in "${programs[@]}"; do
  for variant in baseline asan; do
    binary="build/plain/${program}"
    [[ "$variant" == "asan" ]] && binary="build/asan/${program}"

    if [[ ! -x "$binary" ]]; then
      echo "ERROR: missing executable: $binary" >&2
      echo "Build all six binaries using the README instructions first." >&2
      exit 2
    fi
  done

  expected="expected/${program}.stdout.txt"
  if [[ ! -f "$expected" ]]; then
    echo "ERROR: missing reference stdout: $expected" >&2
    echo "Prepare expected files using the README Section 5 commands first." >&2
    exit 2
  fi
done

# CSV-quote every field, including paths and commands.
csv_row() {
  local first=1 field
  for field in "$@"; do
    field="${field//\"/\"\"}"
    if (( first )); then
      printf '"%s"' "$field"
      first=0
    else
      printf ',"%s"' "$field"
    fi
  done
  printf '\n'
}

# The two measurement-kind rows keep elapsed time and Max RSS distinct.
# VmPeak is deliberately blank: this script does not claim to collect it.
cat > "$output" <<'CSV'
claim_id,workload_id,input_id,config_id,measurement_kind,pair_id,variant,elapsed_s,vmpeak_kib,max_rss_kib,valid,exit_code,collector,capture_scope,notes,phase,attempt,program,input_arg,command,stdout_file,stderr_file,exit_file,diff_file,compare_exit,metrics_file,pair_valid
CSV

# Results from the most recent execution, indexed by variant.
declare -A R_valid R_exit R_elapsed R_rss R_compare R_notes
declare -A R_command R_stdout R_stderr R_exitfile R_diff R_metrics

run_one() {
  local program="$1"
  local variant="$2"       # baseline or asan
  local phase="$3"         # warmup or measured
  local pair_id="$4"
  local attempt="$5"

  local mode_dir binary input expected prefix
  local exit_code compare_exit elapsed_s max_rss_kib
  local asan_error="false"
  local valid="true"
  local notes=""

  mode_dir="plain"
  [[ "$variant" == "asan" ]] && mode_dir="asan"
  binary="build/${mode_dir}/${program}"
  input="${inputs[$program]}"
  expected="expected/${program}.stdout.txt"

  prefix="${LOG_DIR}/${program}.${variant}.${phase}.${pair_id}.attempt${attempt}"
  local stdout_file="${prefix}.stdout.txt"
  local stderr_file="${prefix}.stderr.txt"
  local exit_file="${prefix}.exit.txt"
  local diff_file="${prefix}.diff.txt"
  local metrics_file="${prefix}.metrics.txt"

  local command_text
  printf -v command_text 'LC_ALL=C ASAN_OPTIONS=detect_leaks=0 /usr/bin/time -f %q -o %q %q %q' \
    $'elapsed_s=%e\\nmax_rss_kib=%M' "$metrics_file" "$binary" "$input"

  echo "[$program | $variant | $phase | $pair_id] $command_text"
    # GNU time measures the complete process and records peak resident memory.
  /usr/bin/time \
    -f $'elapsed_s=%e\nmax_rss_kib=%M' \
    -o "$metrics_file" \
    "$binary" "$input" \
    > "$stdout_file" 2> "$stderr_file"
  exit_code=$?
  printf '%s\n' "$exit_code" > "$exit_file"

  diff -u "$expected" "$stdout_file" > "$diff_file"
  compare_exit=$?

  elapsed_s="$(sed -n 's/^elapsed_s=//p' "$metrics_file" | head -n 1)"
  max_rss_kib="$(sed -n 's/^max_rss_kib=//p' "$metrics_file" | head -n 1)"

  if [[ "$variant" == "asan" ]] &&
     grep -Eqi 'ERROR: AddressSanitizer|AddressSanitizer:DEADLYSIGNAL|ERROR: LeakSanitizer' "$stderr_file"; then
    asan_error="true"
  fi

  if (( exit_code != 0 )); then
    valid="false"
    notes+="nonzero_exit;"
  fi
  if (( compare_exit != 0 )); then
    valid="false"
    notes+="reference_output_mismatch;"
  fi
  if [[ "$asan_error" == "true" ]]; then
    valid="false"
    notes+="sanitizer_error;"
  fi
  if ! [[ "$elapsed_s" =~ ^[0-9]+([.][0-9]+)?$ ]] ||
     ! [[ "$max_rss_kib" =~ ^[0-9]+$ ]]; then
    valid="false"
    notes+="missing_or_invalid_time_metrics;"
  elif awk -v t="$elapsed_s" 'BEGIN {exit !(t > 0)}'; then
    :
  else
    valid="false"
    notes+="elapsed_rounded_to_zero_use_higher_resolution_timer;"
  fi

  [[ -n "$notes" ]] || notes="run_passed_validation;VmPeak_not_collected;Max_RSS_is_supplementary"

  R_valid["$variant"]="$valid"
  R_exit["$variant"]="$exit_code"
  R_elapsed["$variant"]="$elapsed_s"
  R_rss["$variant"]="$max_rss_kib"
  R_compare["$variant"]="$compare_exit"
  R_notes["$variant"]="$notes"
  R_command["$variant"]="$command_text"
  R_stdout["$variant"]="$stdout_file"
  R_stderr["$variant"]="$stderr_file"
  R_exitfile["$variant"]="$exit_file"
  R_diff["$variant"]="$diff_file"
  R_metrics["$variant"]="$metrics_file"

  echo "  exit=$exit_code compare=$compare_exit elapsed=${elapsed_s:-NA}s MaxRSS=${max_rss_kib:-NA} KiB valid=$valid"
}

append_rows() {
  local program="$1"
  local variant="$2"
  local phase="$3"
  local pair_id="$4"
  local attempt="$5"
  local pair_valid="$6"

  local workload_id="llvm_shootout_${program}"
  local input_id="${program}_${inputs[$program]}"
  local config_id="clang_O2_${variant}_detect_leaks_off"
  local valid="${R_valid[$variant]}"
  local common_notes="${R_notes[$variant]}"
  local claim_id

  # Time row: elapsed_s populated; memory fields remain separate.
  claim_id="C1"
  csv_row \
    "$claim_id" "$workload_id" "$input_id" "$config_id" "time" \
    "$pair_id" "$variant" "${R_elapsed[$variant]}" "" "" \
    "$valid" "${R_exit[$variant]}" "/usr/bin/time GNU time %e" \
    "whole_process" "$common_notes" "$phase" "$attempt" "$program" \
    "${inputs[$program]}" "${R_command[$variant]}" \
    "${R_stdout[$variant]}" "${R_stderr[$variant]}" \
    "${R_exitfile[$variant]}" "${R_diff[$variant]}" \
    "${R_compare[$variant]}" "${R_metrics[$variant]}" "$pair_valid" \
    >> "$output"

  # Supplementary memory row: Max RSS populated; VmPeak remains blank.
  claim_id="SUPP_RSS"
  csv_row \
    "$claim_id" "$workload_id" "$input_id" "$config_id" "memory" \
    "$pair_id" "$variant" "" "" "${R_rss[$variant]}" \
    "$valid" "${R_exit[$variant]}" "/usr/bin/time GNU time %M" \
    "whole_process" "Max_RSS_supplementary;VmPeak_not_collected" \
    "$phase" "$attempt" "$program" "${inputs[$program]}" \
    "${R_command[$variant]}" "${R_stdout[$variant]}" \
    "${R_stderr[$variant]}" "${R_exitfile[$variant]}" \
    "${R_diff[$variant]}" "${R_compare[$variant]}" \
    "${R_metrics[$variant]}" "$pair_valid" >> "$output"
}
# ------------------------------------------------------------
# Main experiment procedure
# ------------------------------------------------------------

echo
echo "============================================================"
echo "Starting formal ASan benchmark experiment"
echo "Programs: ary3, heapsort, matrix"
echo "Valid paired runs required per program: $runs"
echo "Output CSV: $output"
echo "Logs directory: $LOG_DIR"
echo "============================================================"
echo

for program in "${programs[@]}"; do
  echo
  echo "############################################################"
  echo "Program: $program"
  echo "############################################################"

  # ----------------------------------------------------------
  # Step 1: One warm-up for each variant.
  # Warm-ups are recorded but excluded from measured statistics.
  # ----------------------------------------------------------

  echo
  echo "[$program] Running baseline warm-up..."
  run_one "$program" "baseline" "warmup" "WARMUP" 1
  append_rows "$program" "baseline" "warmup" "WARMUP" 1 "warmup"

  if [[ "${R_valid[baseline]}" != "true" ]]; then
    echo "ERROR: baseline warm-up failed for $program." >&2
    echo "Check the corresponding files in: $LOG_DIR" >&2
    exit 1
  fi

  echo
  echo "[$program] Running ASan warm-up..."
  run_one "$program" "asan" "warmup" "WARMUP" 1
  append_rows "$program" "asan" "warmup" "WARMUP" 1 "warmup"

  if [[ "${R_valid[asan]}" != "true" ]]; then
    echo "ERROR: ASan warm-up failed for $program." >&2
    echo "Check the corresponding files in: $LOG_DIR" >&2
    exit 1
  fi

  # ----------------------------------------------------------
  # Step 2: Collect the required number of valid paired runs.
  # A pair is valid only when BOTH baseline and ASan pass.
  # The execution order alternates between successive pairs.
  # ----------------------------------------------------------

  valid_pairs=0
  pair_attempt=0

  while (( valid_pairs < runs )); do
    pair_attempt=$((pair_attempt + 1))

    if (( pair_attempt > max_pair_attempts )); then
      echo "ERROR: reached retry limit for $program." >&2
      echo "Valid pairs collected: $valid_pairs / $runs" >&2
      echo "Check the failed-attempt logs in: $LOG_DIR" >&2
      exit 1
    fi

    pair_id="${program}_pair$((valid_pairs + 1))"

    echo
    echo "------------------------------------------------------------"
    echo "[$program] Pair $((valid_pairs + 1)) / $runs"
    echo "Attempt: $pair_attempt"
    echo "------------------------------------------------------------"

    # Alternate execution order to reduce systematic order effects.
    if (( pair_attempt % 2 == 1 )); then
      run_one "$program" "baseline" "measured" "$pair_id" "$pair_attempt"
      run_one "$program" "asan" "measured" "$pair_id" "$pair_attempt"
    else
      run_one "$program" "asan" "measured" "$pair_id" "$pair_attempt"
      run_one "$program" "baseline" "measured" "$pair_id" "$pair_attempt"
    fi

    pair_valid="true"
    if [[ "${R_valid[baseline]}" != "true" ]] ||
       [[ "${R_valid[asan]}" != "true" ]]; then
      pair_valid="false"
    fi

    # Keep every attempt, including failed pairs.
    append_rows "$program" "baseline" "measured" "$pair_id" "$pair_attempt" "$pair_valid"
    append_rows "$program" "asan" "measured" "$pair_id" "$pair_attempt" "$pair_valid"

    if [[ "$pair_valid" == "true" ]]; then
      valid_pairs=$((valid_pairs + 1))
      echo "[$program] Valid paired runs: $valid_pairs / $runs"
    else
      echo "[$program] Pair invalid; retaining logs and retrying."
    fi
  done

  echo
  echo "[$program] Completed: $valid_pairs valid paired runs."
done

echo
echo "============================================================"
echo "All benchmark experiments completed successfully."
echo "Raw CSV: $output"
echo "Detailed logs: $LOG_DIR"
echo
echo "Reminder:"
echo "- elapsed_s is whole-process elapsed time."
echo "- max_rss_kib is supplementary Max RSS."
echo "- vmpeak_kib is intentionally blank; VmPeak was not collected."
echo "- Warm-up and failed attempts are retained in the CSV."
echo "============================================================"
