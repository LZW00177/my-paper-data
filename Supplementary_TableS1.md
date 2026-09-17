# Supplementary Table S1 — DTLZ1/DTLZ3 Scope Analysis with the SBX-Crossover MO-ALA Variant

**Associated manuscript:** MO-ALA: A Bio-Inspired Multi-Objective Artificial Lemming Algorithm with Dual-Layer Historical Memory and Adaptive *t*-Distribution Perturbation for Post-Disaster Mountain UAV Search-and-Rescue Path Planning (submitted to *Biomimetics*)

## 1. Purpose

Main-text Table 9 reports results obtained with the **original crossover-free ALA operator set**. On the two deceptive Rastrigin-based three-objective benchmarks (DTLZ1 and DTLZ3), MO-ALA and all other crossover-free metaheuristics compared in the paper fail to attain non-zero hypervolume, whereas NSGA-II — whose SBX recombination resamples distant parents — converges.

This supplementary table shows that this behaviour is a **scope boundary of crossover-free search operators**, not a structural defect of the MO-ALA framework: when a standard SBX crossover + polynomial mutation operator set (denoted `searchMode = 'v8'`, fully aligned with the NSGA-II search mechanism) is substituted, **all four MO-ALA variants converge and outperform NSGA-II on both benchmarks**, while the other ALA-derived/compared methods remain at zero hypervolume.

## 2. Configuration

| Item | Value |
|---|---|
| Population size *N* | 30 |
| Decision-variable dimension *D* | 10 |
| Iteration budget *T*max | 2000 (DTLZ1 and DTLZ3) |
| Archive size *N*arch | 100 |
| Independent runs | 30 per (algorithm, benchmark) |
| Random-seed set | `BASE_SEED + 4000·b_i + 100·a_i + r`, BASE_SEED = 20260812, *r* = 1…30 |
| Operators under test | SBX crossover + polynomial mutation (`searchMode = 'v8'`) for MO-ALA variants A–D |
| Comparison algorithms | Carried over unchanged from the main-text data set (no crossover variant available) |
| HV estimator | Corrected Monte-Carlo estimator (dominated-region sampling) |
| HV reference point | 1.05 × max(true Pareto front), consistent with main-text Table 9 |

Re-run only the four MO-ALA variants (A/B/C/D) with `searchMode = 'v8'`; the five comparison algorithms are taken from the main-text data set, since they are crossover-free by design and already attain HV = 0 on these two benchmarks.

## 3. Table S1. DTLZ1 and DTLZ3 results with the SBX-crossover MO-ALA variant (mean ± std, *n* = 30)

| Algorithm | DTLZ1 HV | DTLZ1 IGD | DTLZ3 HV | DTLZ3 IGD |
|---|---|---|---|---|
| MO-ALA-A (SBX) | 0.0998 ± 0.0012 | 0.0383 ± 0.0030 | 0.4944 ± 0.0100 | 0.0899 ± 0.0037 |
| MO-ALA-B (SBX) | 0.0997 ± 0.0014 | 0.0375 ± 0.0024 | 0.4913 ± 0.0114 | 0.0905 ± 0.0041 |
| MO-ALA-C (SBX) | 0.0998 ± 0.0014 | 0.0387 ± 0.0027 | 0.4905 ± 0.0118 | 0.0918 ± 0.0061 |
| **MO-ALA-D / MO-ALA (SBX)** | **0.0999 ± 0.0015** | **0.0379 ± 0.0026** | **0.4875 ± 0.0139** | **0.0914 ± 0.0049** |
| NSGA-II | 0.0617 ± 0.0384 | 0.2743 ± 0.4271 | 0.3985 ± 0.0593 | 0.1429 ± 0.0209 |
| MOPSO | 0.0000 ± 0.0000 | 39.5527 ± 4.5429 | 0.0000 ± 0.0000 | 63.6633 ± 25.1858 |
| EALA | 0.0000 ± 0.0000 | 89.3593 ± 9.3625 | 0.0000 ± 0.0000 | 169.4193 ± 16.8303 |
| IALA | 0.0000 ± 0.0000 | 35.5939 ± 7.4266 | 0.0000 ± 0.0000 | 107.7681 ± 17.2885 |
| HALA | 0.0000 ± 0.0000 | 39.7424 ± 14.3761 | 0.0000 ± 0.0000 | 57.0494 ± 26.2082 |

**Note.** With the original crossover-free operator set (main-text Table 9), MO-ALA attains HV = 0.0000 and IGD = 32.47 (DTLZ1) / 82.26 (DTLZ3), and NSGA-II attains HV = 0.0617 / 0.3985. The five comparison algorithms other than NSGA-II remain at HV = 0.0000 in both operator settings.

## 4. Reading

Under the SBX operator set, MO-ALA-D improves the DTLZ1 IGD from 0.2743 (NSGA-II) to 0.0379 (≈7.2× better) and the DTLZ3 IGD from 0.1429 to 0.0914 (≈1.6× better), while MOPSO/EALA/IALA/HALA still fail (HV = 0). The failure therefore localises to the *absence of a recombination operator capable of resampling the full decision-variable range*, not to the MO-ALA memory or perturbation components (which are identical across both operator settings). This is the basis for positioning DTLZ1/DTLZ3 as an explicitly stated applicability boundary of the crossover-free MO-ALA configuration in the Discussion.

## 5. Data and code files

| File | Content |
|---|---|
| `results/ablation_DTLZ13_v8_0829.mat` | Raw results: `R{6×9}` cell, valid for `bi = 4` (DTLZ1) and `bi = 6` (DTLZ3); each cell is 30 × 4 = [HV, IGD, Spacing, frontSize]; plus Friedman/Wilcoxon `stats` |
| `experiments/rerun_v8_DTLZ13_0829.m` | MATLAB script that re-runs the four MO-ALA variants with `searchMode = 'v8'` and reproduces the table (MATLAB R2024b) |

Both files are included in this supplementary package. Reproduce with:

```matlab
cd 'path to Supplementary_Materials'
addpath(genpath(pwd));
rerun_v8_DTLZ13_0829          % regenerates results/ablation_DTLZ13_v8_0829.mat
```

The main-text Table 9 is **unchanged**; this supplementary analysis provides the evidence for the applicability-boundary statement added to the Discussion.
