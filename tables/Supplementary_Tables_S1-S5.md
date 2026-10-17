# MO-ALA (MS 4584712) - Supplementary Tables S1-S5 (revision, 2026-10-16)

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

The base late-stage weight vector w = (0.1, 0.1, 0.6, 0.2) has its risk weight w(J3) swept over {0.2 ... 0.7}; the remaining weights are renormalised to sum to 1-w(J3). Means over the 30 runs.

| w(J3) | Mountain: J1 (/m) | Mountain: J3 | Mountain: C_i | Debris flow: J1 (/m) | Debris flow: J3 | Debris flow: C_i |
|---|---|---|---|---|---|---|
| 0.20 | 221.17 | 462.82 | 0.7319 | 229.99 | 378.28 | 0.7184 |
| 0.30 | 248.18 | 218.27 | 0.7515 | 247.85 | 188.19 | 0.7486 |
| 0.40 | 248.71 | 209.04 | 0.7967 | 250.33 | 171.12 | 0.7979 |
| 0.50 | 257.08 | 181.28 | 0.8407 | 251.16 | 165.29 | 0.8413 |
| 0.60 | 256.91 | 171.95 | 0.8797 | 258.34 | 150.42 | 0.8804 |
| 0.70 | 267.02 | 160.90 | 0.9136 | 258.25 | 142.55 | 0.9143 |

*Reading:* raising w(J3) shifts the selected solution monotonically from short/high-risk to long/low-risk while the closeness coefficient stays high, i.e. the mission-stage interface is monotone and smooth rather than a knife-edge.


## Table S4. Consistently selected solution per algorithm (TOPSIS, late-stage weights w = (0.1, 0.1, 0.6, 0.2)); mean +/- std over the 30 runs

| Scenario | Algorithm | J1 (/m) | J2 | J3 | J4 (/rad) | C_i |
|---|---|---|---|---|---|---|
| Mountain (S1) | MOALA | 281.43 +/- 68.34 | 2.223 +/- 0.702 | 183.70 +/- 84.23 | 2.661 +/- 0.707 | 0.8443 |
| Mountain (S1) | NSGAII | 375.61 +/- 75.01 | 2.502 +/- 0.766 | 335.23 +/- 68.53 | 2.528 +/- 0.664 | 0.7021 |
| Mountain (S1) | MOPSO | 533.24 +/- 163.79 | 4.300 +/- 1.072 | 557.19 +/- 285.95 | 3.241 +/- 1.694 | 0.5875 |
| Mountain (S1) | EALA | 386.01 +/- 204.41 | 3.121 +/- 1.770 | 782.16 +/- 105.03 | 2.490 +/- 1.502 | 0.6289 |
| Mountain (S1) | IALA | 270.32 +/- 37.46 | 2.018 +/- 0.290 | 158.22 +/- 34.33 | 2.721 +/- 0.392 | 0.9287 |
| Mountain (S1) | HALA | 201.63 +/- 59.43 | 1.319 +/- 0.612 | 90.19 +/- 64.34 | 2.018 +/- 1.027 | 0.8172 |
| Debris flow (S2) | MOALA | 271.39 +/- 87.12 | 2.149 +/- 0.789 | 159.91 +/- 74.26 | 2.609 +/- 0.739 | 0.8401 |
| Debris flow (S2) | NSGAII | 378.81 +/- 71.20 | 2.535 +/- 0.588 | 295.43 +/- 81.04 | 2.702 +/- 0.663 | 0.6791 |
| Debris flow (S2) | MOPSO | 569.56 +/- 145.83 | 4.482 +/- 0.973 | 506.20 +/- 283.21 | 3.448 +/- 1.486 | 0.6059 |
| Debris flow (S2) | EALA | 465.84 +/- 223.39 | 3.766 +/- 1.959 | 826.10 +/- 88.25 | 2.820 +/- 1.587 | 0.5413 |
| Debris flow (S2) | IALA | 227.60 +/- 40.01 | 1.742 +/- 0.319 | 107.44 +/- 24.68 | 2.690 +/- 0.448 | 0.9403 |
| Debris flow (S2) | HALA | 181.37 +/- 53.99 | 1.271 +/- 0.589 | 73.64 +/- 35.99 | 1.985 +/- 0.958 | 0.8443 |

*Reading:* each row is one consistently selected trajectory per run, so the length-versus-safety trade-off can be read within a row - unlike per-objective minima, which may belong to different members of the front.


## Table S5. Wall-clock time vs. problem dimension (MO-ALA, mountain scenario)

N = 30, T = 500, N_arch = 50, one run per dimension.

| N_w (waypoints) | D = 3 N_w | Wall-clock (s) | Per-iteration (ms) | HV |
|---|---|---|---|---|
| 10 | 30 | 33.79 | 67.576 | 0.1386 |
| 20 | 60 | 52.97 | 105.942 | 0.1106 |
| 30 | 90 | 66.31 | 132.619 | 0.0662 |

*Reading:* tripling the decision dimension (30 -> 90) raises the wall-clock only 1.96x (33.79 s -> 66.31 s), i.e. the cost grows sub-linearly in D under a fixed generation budget. The HV loss with dimension reflects the fixed 500-generation budget rather than a change in asymptotic behaviour.

