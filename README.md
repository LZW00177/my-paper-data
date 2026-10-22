# Supplementary Materials — Reproduction Data and Plotting Code

This repository contains the numerical results and the MATLAB plotting scripts that reproduce
Figures 1 and 3–10 and the statistics reported in Tables 9–15 of the manuscript, together with the
audit scripts, run logs, data archives and supplementary analyses added in the 2026-10-16 revision
(Section 8):

> **Bioinspired Multi-Objective Artificial Lemming Algorithm with Dual-Layer Historical Memory and
> Adaptive t-Distribution Perturbation for Post-Disaster Mountain Terrain UAV SAR Path Planning**

Everything needed to regenerate the figures is self-contained. No third-party toolbox is required
(HV / IGD / Spacing are implemented from scratch in `code/MetricsCalculator.m`).

---

## 1. Repository layout

```
.
├── README.md                ← this file (layout / mapping / reproduction / provenance)
├── run_all_figs.m           ← reproduces all manuscript figures in one command
├── code/                    ← runtime dependencies of the plotting scripts, the mission model + audit utilities
│   ├── terrainGeneration.m      synthetic Gaussian-hill / gully DEM generator
│   ├── threatField.m            threat-field construction (no-fly, cliffs, power lines, ruins)
│   ├── BsplineSmooth.m          cubic B-spline path smoothing
│   ├── MetricsCalculator.m      HV / IGD / Spacing / Spread (no toolbox)
│   ├── UAVMultiObj.m            four-objective mission model (J1–J4 objectives + hard constraints)
│   ├── audit_tost_equivalence_1016.py   TOST equivalence audit of the benchmark ablation (Python)
│   └── make_supp_tables.py      builds the revision-era supplementary tables (Python)
├── data/                    ← all numerical results, 2 provenance manifests + revision-era archives
│   ├── ablation_benchmark.mat   Table 9, Table 10, Figure 3, Figure 5
│   ├── convergence.mat          Figure 4
│   ├── terrain_metrics.mat      Table 11, Table 12, Table 13
│   ├── terrain_paths.mat        Figures 6, 7, 8, 9
│   ├── param_sweep.mat          Figure 10
│   ├── runtime_topsis.mat       Table 14, Table 15, Section 3.5
│   ├── MANIFEST.txt
│   └── …                        7 revision-era archives + 2 manifests (Section 8)
├── scripts/                 ← plotting + audit scripts (function name = file name)
│   ├── plotFig1_TerrainThreatField.m
│   ├── plotFig3_ablation_radar.m
│   ├── plotFig4xin_Convergence.m
│   ├── plotFig5_IGD_Boxplot.m
│   ├── plotFig6and8_Pareto.m
│   ├── plotFig7and9_lujing.m
│   ├── plotFig10_ParamSweep_Combined_v2.m
│   └── …                        8 revision-era audit/experiment scripts (Section 8)
├── experiments/             ← original-submission Table S1: SBX-crossover variant on DTLZ1/DTLZ3
│   └── rerun_v8_DTLZ13_0829.m
├── results/                 ← raw data for the original-submission Table S1 analysis
│   └── ablation_DTLZ13_v8_0829.mat
├── Supplementary_TableS1.md ← legacy Table S1 of the original submission (see banner inside;
│                                superseded by tables/Supplementary_Tables_S1-S5.md)
├── logs/                    ← run logs of the reproduction and revision-era audits/experiments
├── tables/                  ← revision-era supplementary tables
│   ├── Supplementary_Tables_S1-S5.md
│   └── Supplementary_Tables_S1-S5.docx
└── figures/                 ← script output (.png raster, .eps vector, .fig editable), incl. Figure S1
```

**Storage rules.** Scripts read and write only relative paths inside this repository
(`root = fileparts(fileparts(mfilename('fullpath')))`, i.e. one level above `scripts/`); they never
reference external directories. Data live in `data/` without date/version suffixes (version notes go
into `data/MANIFEST.txt`); all figures are written to `figures/`. Each script file name equals the
function it defines, as required by MATLAB.

---

## 2. Reproduction

```matlab
cd('<repository root>')
run_all_figs          % runs the 7 scripts in turn and regenerates every manuscript figure
```

Command-line equivalent:

```bat
matlab -batch "run_all_figs"
```

Progress is logged to `run_all_figs.txt`; all 7 scripts are expected to finish with `OK`.
Environment: MATLAB R2024b, base toolbox only.

---

## 3. Data file ↔ manuscript item mapping

| Data file | Content | Manuscript items |
|---|---|---|
| `data/ablation_benchmark.mat` | 6 benchmarks × 9 algorithms, 30 independent runs (HV / IGD / Spacing / front size), plus Friedman ranks and Wilcoxon signs | **Table 9, Table 10, Figure 3, Figure 5** |
| `data/convergence.mat` | HV / IGD convergence trajectories on ZDT2 and DTLZ2 (mean ± std over 30 runs, sampled every 10 generations) | **Figure 4** |
| `data/terrain_metrics.mat` | J1–J4, safety indicators (minimum / mean flight altitude, threat-zone crossings), HV / IGD for both terrain scenarios, 30 runs | **Table 11, Table 12, Table 13** |
| `data/terrain_paths.mat` | Three-dimensional flight paths (100 points), path lengths, objective values and TOPSIS weights for 30 runs per algorithm and scenario | **Figures 6, 7, 8, 9** |
| `data/param_sweep.mat` | Parameter sweeps over archive capacity `Narch`, `νmax` and population size `N` (HV and IGD) | **Figure 10** |
| `data/runtime_topsis.mat` | Wall-clock runtime (2 scenarios × 6 algorithms × 30 runs) and the two-stage TOPSIS results | **Table 14, Table 15, Section 3.5** |
| `results/ablation_DTLZ13_v8_0829.mat` + `experiments/rerun_v8_DTLZ13_0829.m` | SBX-crossover (`searchMode = 'v8'`) operator variant on DTLZ1/DTLZ3, MO-ALA variants A–D, 30 runs | **Supplementary Table S1** |

The algorithm order is identical in every file:

```
MOALA-A, MOALA-B, MOALA-C, MOALA-D, NSGAII, MOPSO, EALA, IALA, HALA
```

where `MOALA-A … MOALA-D` are the four ablation variants defined in Section 3.2.1
(A: original ALA in the multi-objective framework; B: fixed-scale Gaussian perturbation;
C: original ALA position update instead of dual-layer memory; D: complete MO-ALA).

All results refer to `N = 30` population and decision-variable dimension `dim = 10`. The benchmark
ablation uses one fixed seed rule with a common base seed, `seed_r = 20260812 + 4000·b_i + 100·a_i + r`
(`r = 1..30`; `b_i`, `a_i` index benchmark and algorithm). Because `a_i` enters the seed, the random
streams are algorithm-specific; what is shared is the base seed together with the 30 run indices, so
run `r` is matched across algorithms and the reported mean ± std are run-to-run statistics over those
paired run indices. Where a strictly paired design is required, common random numbers (seeds that do
not depend on the variant) are used instead: the terrain module ablation uses
`2026 + 10·scene·10000 + 1000·r` and the SBX-hybrid operator comparison uses
`20260812 + 4000·b_i + 100·a_ref + r`, so in both experiments the paired arms share the same random
stream. The terrain main experiment keeps the terrain realisation fixed for every algorithm
(`rng(2026 + 1·100)`, `rng(2026 + 2·100)`) and draws per-run seeds as `2026 + 10000·a_i + 1000·r`.

---

## 4. Provenance and metric conventions

| Data file | Source of record | Notes |
|---|---|---|
| `data/ablation_benchmark.mat` | 6-benchmark ablation results (ZDT1/2/3, DTLZ1/2/3) with the corrected HV reference-point convention | Matches Table 9 / Table 10 cell by cell. Iteration budget: `T = 300` for ZDT1–ZDT3 **and DTLZ2**, `T = 2000` for DTLZ1/DTLZ3. The HV direction was corrected on 2026-09-12 (samples ≥ PF; ZDT reference point (1,1) with no margin; DTLZ reference point 1.05 × true-PF maximum). |
| `data/convergence.mat` | ZDT2 / DTLZ2 convergence re-sampling | `T = 300`, `NRUNS = 30`, `NRPT = 10`. Re-collected on 2026-09-16 with the **same seed rule as the benchmark ablation** (`20260812 + 4000·b_i + 100·a_i + r`), so the last point of every curve coincides with the corresponding final-archive value in Table 9. The earlier recording bug of NSGA-II and MOPSO (spurious periodic zero drops) had been repaired on 2026-09-15. |
| `data/terrain_metrics.mat` | Terrain scenarios | `MAX_ITER = 500`, `POP_SIZE = 30`, `ARCH_SIZE = 100`, `NUM_RUNS = 30`. |
| `data/terrain_paths.mat` | Terrain path coordinates | 6 algorithms × 30 runs per scenario. |
| `data/param_sweep.mat` | Parameter sweeps | HV / IGD convention identical to `ablation_benchmark.mat`; default points `Narch = 50`, `νmax = 20`, `N = 30`. |
| `data/runtime_topsis.mat` | Runtime and TOPSIS | Two-stage TOPSIS (search stage / relief-delivery stage). |
| `results/ablation_DTLZ13_v8_0829.mat` | Supplementary Table S1 | SBX crossover + polynomial mutation (`searchMode = 'v8'`) for MO-ALA variants A–D, `T = 2000`, 30 runs; comparison algorithms carried over from the main-text data set. Generated 2026-09-12. See `Supplementary_TableS1.md`. |

**Metric conventions.** HV is computed on the normalised front with reference point `(1,1)` for the ZDT
family and `1.05 ×` the true-Pareto-front maximum for the DTLZ family; IGD uses 1000 uniformly sampled
reference points on the true front. Absolute HV values depend on the reference point and are meaningful
only for cross-algorithm comparison under identical settings. The Friedman ranking and the Wilcoxon
signed-rank test in Table 10 use the IGD column, with variant D as the reference for the sign test
(`α = 0.05`).

---

## 5. Verification

`run_all_figs` was executed end-to-end under MATLAB R2024b and all 7 scripts returned `OK`. Byte-level
comparison of the regenerated PNGs against the images embedded in the manuscript gives 0 differing
pixels for Figures 3, 4, 5, 6, 7, 8, 9 and 10; Figure 1 agrees in content (the manuscript embeds a
down-scaled copy, so the raster dimensions differ).

For Figure 4 the convergence trajectories were collected with the same seed rule as the benchmark
ablation, so their
endpoints reproduce the Table 9 values (e.g. ZDT2 MOALA-D: HV 0.3222, IGD 0.0091; DTLZ2 MOALA-D:
HV 0.4855, IGD 0.0978).

---

## 6. Figure notes

- **Figures 6 and 8** — Pareto fronts on the path-length / safety-and-coverage plane for Scenario 1
  (mountain rescue) and Scenario 2 (debris-flow relief delivery), for all six algorithms.
- **Figures 7 and 9** — three-dimensional flight paths and side-view profiles. The MO-ALA route is drawn
  with a heavy line; the five comparison algorithms are drawn as thin grey lines and are intentionally
  left out of the legend so that the MO-ALA route stays legible.
- **Figure 3** — Friedman-rank radar chart. The radial axis encodes rank (rank 1 = best).
- **Figure 5** — IGD box plots on ZDT2 (log scale) and DTLZ2 (linear scale).

---

## 7. Availability of the algorithm source code

The original numerical results and all plotting scripts required to reproduce Figures 1 and 3–10 are
provided here. The core MO-ALA source code and the detailed implementation files are **not** included
because the work is under a patent application; they are available from the corresponding author on
reasonable request. The four-objective mission model that defines J1–J4 and the hard
constraints (`code/UAVMultiObj.m`) **is** included, so the archived trajectories in `data/` can be
re-evaluated with the exact objective implementation; the withheld part is the search engine itself.

---

## 8. Revision-era additions (2026-10-16 revision)

The following files support the analyses added in the revision; each `_1016` archive is produced by
the script listed against it. Byte manifests of the original data set and of this revision set are
`data/MANIFEST_20260915_original.txt` and `data/MANIFEST_revision_20261016.txt`.

| Added script | Purpose | Output archive |
|---|---|---|
| `scripts/run_terrain_ablation_formal_1016.m` | Variant A/B/C/D ablation in the two terrain scenarios (paired common random numbers, fixed external reference front, ARCH = 50) | `data/terrain_ablation_formal_1016.mat` |
| `scripts/rerun_v8_degradation_1016.m` | SBX-hybrid operator vs. the original memory-guided operator under one unified protocol (six benchmarks, `T = 500`, paired by seed) | `data/ablation_v8_degradation_1016.mat` |
| `scripts/rerun_Gschedule_1016.m` | Amplitude-envelope *G*(*t*) ablation (three arms differing only in the envelope) | `data/g_schedule_ablation_1016.mat` |
| `scripts/audit_paths_violation_1016.m` | Hard-constraint audit of the published smoothed trajectories (pitch / terrain collision / boundary) | `data/path_feasibility_audit_1016.mat` |
| `scripts/audit_hv_reference_robustness_1016.m` | Offline re-computation of the fixed external terrain reference front | `data/hv_reference_robustness_1016.mat` |
| `scripts/audit_dim_scaling_1016.m` | Dimension-scaling audit | `data/dim_scaling_1016.mat` |
| `scripts/combine_scenario_evidence_1016.m` | Cross-scenario evidence combination for the terrain ablation | log `logs/combine_scenario_evidence_1016.txt` |
| `scripts/plotFigSx_perturbScale.m` | Perturbation-scale figure | `figures/FigureS1_perturbScale.png/.eps` |

Supporting files:

- `data/terrain_ablation_formal_1016_ARCH100_keep.mat` — archive-capacity (ARCH = 100) sensitivity
  copy of the terrain ablation.
- `code/audit_tost_equivalence_1016.py` — reproduces the equivalence-testing analysis of the benchmark
  ablation from the released `data/ablation_benchmark.mat` (offline; no re-optimisation).
- `code/make_supp_tables.py` — builds `tables/Supplementary_Tables_S1-S5.md/.docx`.
- `code/UAVMultiObj.m` — the four-objective terrain mission model (J1–J4 objectives, hard
  constraints, feasibility sampling/checking) used to evaluate every archived trajectory; shipped
  byte-identical to the version that produced the archived results.
- `logs/` — run logs of every audit and experiment above, plus the end-to-end figure reproduction log.
- The root-level `Supplementary_TableS1.md` is the original-submission version, retained for
  provenance only (see the banner inside the file); the revision-era tables are
  `tables/Supplementary_Tables_S1-S5.md/.docx`.
