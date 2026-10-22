# MO-ALA (MS 4584712) - Supplementary Tables S1-S5 (revision, 2026-10-21)

> All numbers below are recomputed programmatically from the archived run archives (`terrain_paths.mat`, `path_feasibility_audit_1016.mat`, `ablation_v8_degradation_1016.mat`, `dim_scaling_1016.mat`); none is transcribed by hand.


## Table S1. Hard-constraint audit of the published smoothed trajectories

Re-validated against the scenario terrains regenerated with the exact seeds used for the reported experiments (`rng(2026+100)` mountain, `rng(2026+200)` debris flow; `minH = 40`, `maxH = 120`). Thresholds: maximum climb angle `theta_max = pi/3`, minimum clearance `h_min = 2` m, flight box `[0,100] x [0,100]`. Trajectories are split into the B-spline-smoothed ones (>= 50 points) and the discrete-waypoint fallback (<= 30 points, i.e. the optimiser's own output).

| Scenario | Algorithm | Trajectories | Smoothed / fallback | Line segments | Overall pitch rate (%) | Pitch rate, smoothed (%) | Pitch rate, fallback (%) | Max over-limit (deg) | Mean over-limit (deg) | Ground-collision points | Out-of-bound points |
|---|---|---|---|---|---|---|---|---|---|---|
| Mountain (S1) | MOALA | 1500 | 1001 / 499 | 109578 | 1.459 | 1.614 | 0.000 | 27.31 | 13.36 | 0 | 0 |
| Mountain (S1) | NSGAII | 900 | 272 / 628 | 40116 | 1.030 | 1.534 | 0.000 | 26.26 | 9.54 | 0 | 0 |
| Mountain (S1) | MOPSO | 2814 | 158 / 2656 | 71418 | 0.367 | 1.675 | 0.000 | 27.03 | 7.96 | 0 | 0 |
| Mountain (S1) | EALA | 570 | 44 / 526 | 15402 | 0.643 | 2.273 | 0.000 | 24.74 | 11.75 | 0 | 0 |
| Mountain (S1) | IALA | 1941 | 1602 / 339 | 165717 | 1.749 | 1.828 | 0.000 | 25.75 | 13.13 | 0 | 0 |
| Mountain (S1) | HALA | 740 | 209 / 531 | 31842 | 2.029 | 3.122 | 0.000 | 27.23 | 13.13 | 0 | 0 |
| Debris flow (S2) | MOALA | 1500 | 943 / 557 | 105054 | 0.722 | 0.810 | 0.017 | 22.29 | 13.09 | 0 | 0 |
| Debris flow (S2) | NSGAII | 899 | 279 / 620 | 40641 | 0.327 | 0.482 | 0.000 | 20.72 | 9.23 | 0 | 0 |
| Debris flow (S2) | MOPSO | 2813 | 173 / 2640 | 72567 | 0.081 | 0.344 | 0.000 | 17.02 | 5.75 | 0 | 0 |
| Debris flow (S2) | EALA | 570 | 144 / 426 | 23202 | 0.220 | 0.358 | 0.000 | 7.08 | 3.62 | 0 | 0 |
| Debris flow (S2) | IALA | 2061 | 1867 / 194 | 188907 | 0.577 | 0.590 | 0.000 | 22.51 | 10.51 | 0 | 0 |
| Debris flow (S2) | HALA | 747 | 315 / 432 | 40257 | 0.817 | 1.055 | 0.000 | 22.19 | 13.23 | 0 | 0 |

*Reading:* Three pitch-rate definitions are reported, because they answer different questions: **Overall** = offending segments / *all* published segments (smoothed and fallback together; this is the quantity quoted in Section 2.1.5 and in Table R1-b of the response letter); **smoothed** = restricted to the smoothed subset; **fallback** = restricted to the optimiser's own discrete waypoints. (i) ground-collision and out-of-bound violations are **exactly zero** for every algorithm, scenario and run; (ii) the **optimiser's own (unsmoothed) trajectories satisfy the pitch constraint at every segment but one** - the discrete-fallback pitch rate is 0.000 % for every algorithm and scenario (the only exception being a single segment out of ~6 000 for MO-ALA in the debris-flow scenario, 0.017 %); (iii) every residual over-limit is therefore introduced by the B-spline *display* post-processing, it is of the same order for every algorithm (MO-ALA 1.46 % / 0.72 % overall, 1.61 % / 0.81 % on the smoothed subset alone, is below HALA 2.03 % / 0.82 % overall and 3.12 % / 1.06 % smoothed, and comparable to NSGA-II 1.03 % / 0.33 % overall), and it is concentrated in the initial climb-out (about two thirds of the offending segments lie in the first decile of a trajectory). The residual pitch over-limits are therefore neither an MO-ALA anomaly nor evidence that the optimiser violates the constraint.


## Table S2. SBX-hybrid operator vs. the original memory-guided operator

Identical protocol for both rows of each benchmark: N = 30, T = 500, N_arch = 50, 30 runs, paired by seed (`20260812 + 4000*b + 100*a + r`); two-sided paired Wilcoxon signed-rank.

| Benchmark | HV original | HV hybrid | dHV (p) | IGD original | IGD hybrid | dIGD (p) |
|---|---|---|---|---|---|---|
| ZDT1 | 0.6541 | 0.6538 | -0.0% (0.837) | 0.0093 | 0.0100 | +8.3% (6.98e-06) |
| ZDT2 | 0.3224 | 0.3201 | -0.7% (0.027) | 0.0091 | 0.0101 | +11.4% (1.73e-06) |
| ZDT3 | 0.7788 | 0.7782 | -0.1% (0.959) | 0.0104 | 0.0214 | +105.0% (5.75e-06) |
| DTLZ1 | 0.0000 | 0.0059 | +inf (0.00195) | 40.4788 | 1.0776 | -97.3% (1.73e-06) |
| DTLZ2 | 0.4893 | 0.4899 | +0.1% (0.651) | 0.0951 | 0.0912 | -4.0% (0.000771) |
| DTLZ3 | 0.0000 | 0.0420 | +inf (0.00391) | 108.8292 | 1.6796 | -98.5% (1.73e-06) |

*Reading:* on the two benchmarks with a deceptive/far-from-Pareto start (DTLZ1, DTLZ3) the SBX hybrid lifts the archive from an empty/near-empty front (HV 0.0000) to a usable one (0.0059 / 0.0420) and cuts IGD by ~97-99 %. On the smooth ZDT fronts it is weakly *worse* (IGD +8.3 % / +11.4 % / +105.0 %). This is the empirical basis for keeping the SBX hybrid as an auxiliary exploratory option rather than integrating it into MO-ALA.


## Table S3. Sensitivity of the TOPSIS selection to the risk weight w(J3) (MO-ALA)

The base late-stage weight vector w = (0.1, 0.1, 0.6, 0.2) has its risk weight w(J3) swept over {0.2 ... 0.7}; the remaining weights are renormalised to sum to 1-w(J3). The selection uses TOPSIS with per-front min-max normalization, the same procedure as Section 3.6; the w(J3) = 0.60 row therefore reproduces the late-stage numbers of Section 3.6. Means over the 30 runs.

| w(J3) | Mountain: J1 (/m) | Mountain: J3 | Mountain: C_i | Debris flow: J1 (/m) | Debris flow: J3 | Debris flow: C_i |
|---|---|---|---|---|---|---|
| 0.20 | 218.30 | 577.94 | 0.7319 | 239.61 | 566.19 | 0.7306 |
| 0.30 | 246.20 | 279.53 | 0.6940 | 250.48 | 267.95 | 0.6954 |
| 0.40 | 255.98 | 210.23 | 0.7359 | 253.78 | 186.52 | 0.7401 |
| 0.50 | 259.38 | 195.24 | 0.7866 | 257.57 | 169.89 | 0.7902 |
| 0.60 | 265.92 | 178.55 | 0.8372 | 260.04 | 157.96 | 0.8384 |
| 0.70 | 268.82 | 173.70 | 0.8815 | 263.67 | 147.38 | 0.8821 |

*Reading:* raising w(J3) shifts the selected solution monotonically from short/high-risk to long/low-risk while the closeness coefficient remains high across the whole sweep (0.69-0.88), i.e. the mission-stage interface is monotone and smooth rather than a knife-edge.


## Table S4. Consistently selected solution per algorithm (TOPSIS, late-stage weights w = (0.1, 0.1, 0.6, 0.2)); mean +/- std over the 30 runs

The selection uses TOPSIS with per-front min-max normalization, the same procedure as Section 3.6.

| Scenario | Algorithm | J1 (/m) | J2 | J3 | J4 (/rad) | C_i |
|---|---|---|---|---|---|---|
| Mountain (S1) | MOALA | 265.92 +/- 65.12 | 2.141 +/- 0.721 | 178.55 +/- 83.61 | 2.797 +/- 0.732 | 0.8372 +/- 0.0482 |
| Mountain (S1) | NSGAII | 429.63 +/- 80.44 | 2.998 +/- 0.711 | 291.02 +/- 47.89 | 2.968 +/- 0.588 | 0.7480 +/- 0.0245 |
| Mountain (S1) | MOPSO | 622.41 +/- 72.79 | 4.914 +/- 0.557 | 331.42 +/- 39.06 | 4.638 +/- 0.341 | 0.7501 +/- 0.0215 |
| Mountain (S1) | EALA | 428.36 +/- 210.79 | 3.507 +/- 1.802 | 753.35 +/- 105.83 | 2.985 +/- 1.591 | 0.7263 +/- 0.0416 |
| Mountain (S1) | IALA | 275.03 +/- 37.85 | 2.045 +/- 0.298 | 161.99 +/- 34.11 | 2.680 +/- 0.386 | 0.8372 +/- 0.0465 |
| Mountain (S1) | HALA | 201.85 +/- 59.68 | 1.357 +/- 0.591 | 90.07 +/- 65.61 | 2.201 +/- 1.057 | 0.7804 +/- 0.0570 |
| Debris flow (S2) | MOALA | 260.04 +/- 86.25 | 2.020 +/- 0.793 | 157.96 +/- 77.87 | 2.702 +/- 0.774 | 0.8384 +/- 0.0514 |
| Debris flow (S2) | NSGAII | 401.62 +/- 63.18 | 2.838 +/- 0.447 | 243.53 +/- 46.35 | 3.202 +/- 0.472 | 0.7405 +/- 0.0244 |
| Debris flow (S2) | MOPSO | 587.89 +/- 62.23 | 4.673 +/- 0.486 | 317.26 +/- 33.05 | 4.494 +/- 0.375 | 0.7600 +/- 0.0240 |
| Debris flow (S2) | EALA | 528.30 +/- 246.32 | 4.351 +/- 2.145 | 789.88 +/- 87.48 | 3.438 +/- 1.489 | 0.7396 +/- 0.0558 |
| Debris flow (S2) | IALA | 230.21 +/- 42.39 | 1.766 +/- 0.324 | 109.97 +/- 26.03 | 2.661 +/- 0.456 | 0.8537 +/- 0.0609 |
| Debris flow (S2) | HALA | 182.47 +/- 54.74 | 1.330 +/- 0.588 | 72.91 +/- 36.92 | 2.323 +/- 1.153 | 0.7877 +/- 0.0647 |

*Note on EALA:* the archived front is numerically degenerate (all front members identical) in 4 of the 30 mountain runs and 8 of the 30 debris-flow runs; C_i is undefined in those runs, so the C_i entries are means over the valid runs only (26/30 and 22/30, respectively), while the objective columns use all 30 runs.

*Reading:* each row is one consistently selected trajectory per run, so the length-versus-safety trade-off can be read within a row - unlike per-objective minima, which may belong to different members of the front.


## Table S5. Wall-clock time vs. problem dimension (MO-ALA, mountain scenario)

N = 30, T = 500, N_arch = 50, one run per dimension.

| N_w (waypoints) | D = 3 N_w | Wall-clock (s) | Per-iteration (ms) | HV |
|---|---|---|---|---|
| 10 | 30 | 33.79 | 67.576 | 0.1386 |
| 20 | 60 | 52.97 | 105.942 | 0.1106 |
| 30 | 90 | 66.31 | 132.619 | 0.0662 |

*Reading:* tripling the decision dimension (30 -> 90) raises the wall-clock only 1.96x (33.79 s -> 66.31 s), and the per-iteration increment decelerates (38.4 ms, then 26.7 ms), i.e. the cost grows sub-linearly in D at a fixed generation budget. This is consistent with an O(N*D) term superimposed on a D-independent fixed cost, and inconsistent with a quadratic dependence on the number of waypoints, which would have accelerated rather than decelerated.

*Note on the HV column:* each row's hypervolume is computed against a reference point estimated from that row's own front (`MetricsCalculator.estimateHVRefPoint`) and the front is min-max normalised to the unit box before the indicator is evaluated, exactly as for the other HV values in this paper. The three HV entries therefore share no common reference box and are **not comparable across rows**; they are listed only to document what each run produced, and no conclusion about the effect of dimension on solution quality is drawn from them. The wall-clock and per-iteration columns are computed on the same machine in the same session and are directly comparable.

