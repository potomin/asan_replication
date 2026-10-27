# AddressSanitizer: Reproduction Plan

**Role:** 王一涵1240012912
**Revised:** 27 October 2026
**Status:** Week\-one plan; no experimental results reported\.

## Paper and research question

K\. Serebryany, D\. Bruening, A\. Potapenko and D\. Vyukov, *AddressSanitizer: A Fast Address Sanity Checker*, USENIX ATC 12 &#40;2012&#41;, pp\. 309\-318\.

Can C/C\+\+ memory\-access errors be detected with manageable runtime and memory overhead? ASan combines compiler checks, shadow memory, redzones and delayed reuse of freed memory\.

## Selected scope: exactly two claims

|ID|One source figure/table|Selected paper claim                                                                        |Planned evidence                                                                             |
|--|-----------------------|--------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------|
|C1|Figure 2, PDF p. 7     |Reads-and-writes instrumentation has reported average runtime 1.73x baseline (73% overhead).|Paired baseline/ASan times and time ratios, as mean ± sample SD.                             |
|C2|Table 1, PDF p. 6      |Memory overhead is reported as 3.37x overall, using VmPeak under the paper’s settings.      |Paired VmPeak measurements and ratios, as mean ± sample SD; qualify historical comparability.|

Writes\-only performance and bug\-detection coverage are outside scope\. Subsets or substitutes are partial reproduction\. Table 1’s printed totals give `24467/8171 = 2.994x`, not its reported `3.37x`; preserve both and resolve the original normalization before claiming an exact match\.

## Experiment protocol

1. Fix workload/source revision, input/hash, expected output and configuration\. Record OS, CPU, RAM, compiler/runtime, commands and ASan settings\. Prefer original SPEC CPU2006 workloads where available\.
2. Use identical inputs, dependencies, architecture and `-O2` for baseline and ASan builds; add `-fsanitize=address` at compilation/linking for ASan\. The paper used 64\-bit Linux, 32\-byte redzones, disabled malloc/free stack unwinding and zero quarantine\. Record deviations and additional checks\.
3. Use one unreported warm\-up per variant, then **at least five valid pairs per workload/input/configuration and measurement kind**, in fresh processes\. Alternate run order\. Separate timing and memory runs if collection affects timing\.
4. Require correct outputs, successful exits and valid metrics\. Keep failed\-run reasons and collect replacement pairs; missing data are never zero\.

## Statistics: mean ± sample standard deviation

```text
mean(x) = sum(x_i) / n
SD(x) = sqrt(sum((x_i - mean(x))^2) / (n - 1))
r_i = time_ASan,i / time_baseline,i
q_i = VmPeak_ASan,i / VmPeak_baseline,i
```

Report each variant’s time &#40;seconds&#41; and VmPeak &#40;MiB&#41; as **mean ± SD**, with valid `n`\. Report paired ratios as `mean(r) ± SD(r)` and `mean(q) ± SD(q)`\. Runtime overhead is `100*(mean(r)-1)%`, with SD `100*SD(r)` percentage points\. Median and range are supplementary only\. SD is not standard error or a confidence interval\.

Never pool different workloads\. For K workloads repeated in each round, define `S_i = sum(r_j,i)/K` and report `mean(S) ± SD(S)` across rounds\. Document this chosen aggregation rather than assuming the paper used it\. Do not substitute ratios of means or medians for these paired ratios\.

## Shared memory contract for Members 1 and 3

- **Required:** `vmpeak_kib`, peak virtual memory, for C2/Table 1\.
- **Optional:** `max_rss_kib`, maximum resident set size, as a separate supplementary column\. **Max RSS is not VmPeak and cannot be converted into it\.**
- Capture VmPeak inside the benchmark at a documented checkpoint before normal exit, using the same hook in both builds\. Read `/proc/self/status` there; external collectors use `/proc/<benchmark_pid>/status`\. Polling results must record interval/coverage and be labeled as observed lower bounds that can miss the final peak\.
- Preserve raw values/units\. Normalize Linux status kB to KiB; report `MiB = KiB/1024`\. Linux `getrusage().ru_maxrss` is in KiB; check other collectors\. Keep process scope identical\. Verify the paper’s MB convention before absolute\-value comparisons\.
- Keep existing Max RSS values separate\. Add `vmpeak_kib`; mark RSS\-only rows `needs_vmpeak_rerun` and leave VmPeak missing\. Collect five valid memory pairs before C2 summaries\. Updating the original Member 3 table and collecting missing data remain pending; that table was not supplied here\.
- Current 64\-bit ASan maps very large virtual address ranges\. VmPeak is not physical RAM; matching metric names alone does not establish comparability with the 2012 runtime\.

## Data format and delivery

Raw CSV header; one row per variant, pair and measurement kind:

```csv
claim_id,workload_id,input_id,config_id,measurement_kind,pair_id,variant,elapsed_s,vmpeak_kib,max_rss_kib,valid,exit_code,collector,capture_scope,notes
```

Use `measurement_kind=time|memory` and `variant=baseline|asan`; link configuration/input IDs to recorded settings/hashes\. Summaries must contain separate mean, SD and valid\-count columns for time, VmPeak and paired ratios; optional Max RSS stays separate\.