#!/usr/bin/env bash
# Run a benchmark repeatedly and log elapsed time + VmPeak (Linux /proc).
# Usage:
#   bash scripts/run_benchmark.sh --label normal --runs 3 --output results/workload_c.csv -- ./path/to/benchmark arg1 arg2
#   bash scripts/run_benchmark.sh --label asan   --runs 3 --output results/workload_c.csv -- ./path/to/benchmark arg1 arg2
set -uo pipefail

label=""
runs=3
output="results/workload_c.csv"

while (($#)); do
  case "$1" in
    --label) label="${2:?Missing value for --label}"; shift 2 ;;
    --runs) runs="${2:?Missing value for --runs}"; shift 2 ;;
    --output) output="${2:?Missing value for --output}"; shift 2 ;;
    --) shift; break ;;
    -h|--help) sed -n '2,7p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$label" ]]; then
  echo "ERROR: provide --label normal or --label asan" >&2; exit 2
fi
if ! [[ "$runs" =~ ^[1-9][0-9]*$ ]]; then
  echo "ERROR: --runs must be a positive integer" >&2; exit 2
fi
if (($# == 0)); then
  echo "ERROR: provide a command after --" >&2; exit 2
fi

command_to_run=("$@")
mkdir -p "$(dirname "$output")"
stem="${output%.*}"
log_dir="${stem}_logs"
mkdir -p "$log_dir"

if [[ ! -f "$output" ]]; then
  printf 'timestamp,label,run,elapsed_seconds,vmpeak_kb,exit_code,command,log_file\n' > "$output"
fi

command_text=""
printf -v command_text '%q ' "${command_to_run[@]}"
command_text="${command_text% }"

for ((run=1; run<=runs; run++)); do
  timestamp="$(date --iso-8601=seconds)"
  run_log="${log_dir}/${label}_run${run}.log"
  echo "[$label run $run/$runs] $command_text"
  start_ns="$(date +%s%N)"

  "${command_to_run[@]}" >"$run_log" 2>&1 &
  pid=$!
  vmpeak_kb=""
  while true; do
    if [[ -r "/proc/$pid/status" ]]; then
      current_vmpeak="$(awk '/^VmPeak:/ {print $2; exit}' "/proc/$pid/status" 2>/dev/null || true)"
      state="$(awk '/^State:/ {print $2; exit}' "/proc/$pid/status" 2>/dev/null || true)"
      [[ -n "$current_vmpeak" ]] && vmpeak_kb="$current_vmpeak"
      [[ "$state" == "Z" ]] && break
    else
      break
    fi
    sleep 0.02
  done

  wait "$pid"
  exit_code=$?
  end_ns="$(date +%s%N)"
  elapsed="$(awk -v s="$start_ns" -v e="$end_ns" 'BEGIN {printf "%.6f", (e-s)/1000000000}')"

  if [[ -z "$vmpeak_kb" ]]; then
    vmpeak_kb="NA"
    echo "WARNING: VmPeak could not be sampled; see $run_log" >&2
  fi

  csv_command="${command_text//\"/\"\"}"
  csv_log="${run_log//\"/\"\"}"
  printf '"%s","%s",%d,%s,%s,%d,"%s","%s"\n' \
    "$timestamp" "$label" "$run" "$elapsed" "$vmpeak_kb" "$exit_code" "$csv_command" "$csv_log" >> "$output"

  echo "  elapsed=${elapsed}s VmPeak=${vmpeak_kb} kB exit_code=$exit_code log=$run_log"
  if ((exit_code != 0)); then
    echo "ERROR: run failed; inspect $run_log. Stopping to avoid misleading results." >&2
    exit "$exit_code"
  fi
done
echo "Results appended to: $output"
