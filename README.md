# Supplementary Materials — Reproduction Data and Plotting Code

This repository contains the numerical results and the MATLAB plotting scripts that reproduce
Figures 1 and 3–10 and the statistics reported in Tables 9–15 of the manuscript:

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
├── code/                    ← runtime dependencies of the plotting scripts
│   ├── terrainGeneration.m      synthetic Gaussian-hill / gully DEM generator
│   ├── threatField.m            threat-field construction (no-fly, cliffs, power lines, ruins)
│   ├── BsplineSmooth.m          cubic B-spline path smoothing
│   └── MetricsCalculator.m      HV / IGD / Spacing / Spread (no toolbox)
├── data/                    ← all numerical results (6 .mat files + manifest)
│   ├── ablation_benchmark.mat   Table 9, Table 10, Figure 3, Figure 5
│   ├── convergence.mat          Figure 4
│   ├── terrain_metrics.mat      Table 11, Table 12, Table 13
│   ├── terrain_paths.mat        Figures 6, 7, 8, 9
│   ├── param_sweep.mat          Figure 10
│   ├── runtime_topsis.mat       Table 14, Table 15, Section 3.5
│   └── MANIFEST.txt
├── scripts/                 ← plotting scripts (function name = file name)
│   ├── plotFig1_TerrainThreatField.m
│   ├── plotFig3_ablation_radar.m
│   ├── plotFig4xin_Convergence.m
│   ├── plotFig5_IGD_Boxplot.m
│   ├── plotFig6and8_Pareto.m
│   ├── plotFig7and9_lujing.m
│   └── plotFig10_ParamSweep_Combined_v2.m
└── figures/                 ← script output (.png raster, .eps vector, .fig editable)
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

The algorithm order is identical in every file:

```
MOALA-A, MOALA-B, MOALA-C, MOALA-D, NSGAII, MOPSO, EALA, IALA, HALA
```

where `MOALA-A … MOALA-D` are the four ablation variants defined in Section 3.2.1
(A: original ALA in the multi-objective framework; B: fixed-scale Gaussian perturbation;
C: original ALA position update instead of dual-layer memory; D: complete MO-ALA).

All results refer to `N = 30` population, decision-variable dimension `dim = 10`, and the shared seed
rule `seed_r = 20260812 + 4000·b_i + 100·a_i + r` (`r = 1..30`), so that every algorithm is evaluated
on exactly the same 30 runs.

---

## 4. Provenance and metric conventions

| Data file | Source of record | Notes |
|---|---|---|
| `data/ablation_benchmark.mat` | 6-benchmark ablation results (ZDT1/2/3, DTLZ1/2/3) with the corrected HV reference-point convention | Matches Table 9 / Table 10 cell by cell. Iteration budget: `T = 300` for ZDT1–ZDT3 **and DTLZ2**, `T = 2000` for DTLZ1/DTLZ3. The HV direction was corrected on 2026-09-12 (samples ≥ PF; ZDT reference point (1,1) with no margin; DTLZ reference point 1.05 × true-PF maximum). |
| `data/convergence.mat` | ZDT2 / DTLZ2 convergence re-sampling | `T = 300`, `NRUNS = 30`, `NRPT = 10`. Re-collected on 2026-09-16 with the **same shared seed rule as the ablation** (`20260812 + 4000·b_i + 100·a_i + r`), so the last point of every curve coincides with the corresponding final-archive value in Table 9. The earlier recording bug of NSGA-II and MOPSO (spurious periodic zero drops) had been repaired on 2026-09-15. |
| `data/terrain_metrics.mat` | Terrain scenarios | `MAX_ITER = 500`, `POP_SIZE = 30`, `ARCH_SIZE = 100`, `NUM_RUNS = 30`. |
| `data/terrain_paths.mat` | Terrain path coordinates | 6 algorithms × 30 runs per scenario. |
| `data/param_sweep.mat` | Parameter sweeps | HV / IGD convention identical to `ablation_benchmark.mat`; default points `Narch = 50`, `νmax = 20`, `N = 30`. |
| `data/runtime_topsis.mat` | Runtime and TOPSIS | Two-stage TOPSIS (search stage / relief-delivery stage). |

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

For Figure 4 the convergence trajectories were collected with the shared seed rule, so their
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
reasonable request.
