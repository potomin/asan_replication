
#!/usr/bin/env bash
# Run one warm-up and at least five valid measured runs.
# Record elapsed time, VmPeak and Max RSS.

set -uo pipefail

# Locate project root relative to this script.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

label=""
runs=5
output="results/workload_c.csv"

while (($#)); do
  case "$1" in
    --label)  label="${2:?Missing value for --label}"; shift 2 ;;
    --runs)   runs="${2:?Missing value for --runs}"; shift 2 ;;
    --output) output="${2:?Missing value for --output}"; shift 2 ;;
    --) shift; break ;;
    -h|--help)
      echo "Usage: bash scripts/run_benchmark.sh --label normal|asan [--runs 5] [--output results/workload_c.csv] -- command [args...]"
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

if [[ "$label" != "normal" && "$label" != "asan" ]]; then
  echo "ERROR: label must be normal or asan" >&2
  exit 2
fi

if ! [[ "$runs" =~ ^[0-9]+$ ]] || ((runs < 5)); then
  echo "ERROR: --runs must be at least 5" >&2
  exit 2
fi

if (($# == 0)); then
  echo "ERROR: provide a command after --" >&2
  exit 2
fi

command_to_run=("$@")

[[ "$output" = /* ]] || output="$REPO_ROOT/$output"
mkdir -p "$(dirname "$output")"

stem="${output%.*}"
log_dir="${stem}_logs"
mkdir -p "$log_dir"

if [[ ! -f "$output" ]]; then
  printf 'timestamp,label,phase,run,elapsed_seconds,vmpeak_kb,max_rss_kb,exit_code,valid,command,log_file\n' > "$output"
fi

command_text=""
printf -v command_text '%q ' "${command_to_run[@]}"
command_text="${command_text% }"

run_one() {
  local phase="$1"
  local run_number="$2"
  local timestamp run_log start_ns end_ns elapsed
  local pid vmpeak_kb max_rss_kb state exit_code valid

  timestamp="$(date --iso-8601=seconds)"
  run_log="${log_dir}/${label}_${phase}_${run_number}.log"

  echo "[$label $phase $run_number] $command_text"
  start_ns="$(date +%s%N)"

  "${command_to_run[@]}" >"$run_log" 2>&1 &
  pid=$!

  vmpeak_kb=""
  max_rss_kb=""

  while [[ -r "/proc/$pid/status" ]]; do
    vmpeak_kb="$(awk '/^VmPeak:/ {print $2; exit}' "/proc/$pid/status")"
    max_rss_kb="$(awk '/^VmHWM:/ {print $2; exit}' "/proc/$pid/status")"
    state="$(awk '/^State:/ {print $2; exit}' "/proc/$pid/status")"

    [[ "$state" == "Z" ]] && break
    sleep 0.01
  done

  wait "$pid"
  exit_code=$?

  end_ns="$(date +%s%N)"
  elapsed="$(awk -v s="$start_ns" -v e="$end_ns" \
    'BEGIN {printf "%.6f", (e-s)/1000000000}')"

  valid="true"
  if [[ -z "$vmpeak_kb" || -z "$max_rss_kb" || "$exit_code" -ne 0 ]]; then
    valid="false"
  fi

  csv_command="${command_text//\"/\"\"}"
  csv_log="${run_log//\"/\"\"}"

  printf '"%s","%s","%s",%d,%s,%s,%s,%d,%s,"%s","%s"\n' \
    "$timestamp" "$label" "$phase" "$run_number" "$elapsed" \
    "${vmpeak_kb:-NA}" "${max_rss_kb:-NA}" \
    "$exit_code" "$valid" "$csv_command" "$csv_log" >> "$output"

  echo "  elapsed=${elapsed}s VmPeak=${vmpeak_kb:-NA} kB MaxRSS=${max_rss_kb:-NA} kB valid=$valid"

  [[ "$valid" == "true" ]]
}

echo "=== Warm-up (not included in statistics) ==="
run_one "warmup" 1 || {
  echo "ERROR: warm-up failed." >&2
  exit 1
}

echo "=== Measured runs: $runs valid runs required ==="

valid_count=0
attempt=0
max_attempts=$((runs * 3))

while ((valid_count < runs && attempt < max_attempts)); do
  attempt=$((attempt + 1))

  if run_one "measured" "$attempt"; then
    valid_count=$((valid_count + 1))
  else
    echo "WARNING: invalid run. Retrying..."
  fi
done

if ((valid_count < runs)); then
  echo "ERROR: only $valid_count valid runs. Required: $runs." >&2
  exit 1
fi

echo "Finished: $valid_count valid measured runs."
echo "Results: $output"
echo "Logs: $log_dir"
