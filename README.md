# Supplementary Materials — Reproduction Data and Plotting Code for the Paper Figures

This folder contains the plotting code and required data for **all data figures (Fig.1–Fig.10)** of the manuscript (submitted to Biomimetics). Reviewers/readers need only MATLAB plus this folder to reproduce every figure in the paper; no original experimental code or additional dependencies are required.

## Folder Structure

```
Supplementary_Materials/
├── results/         Data files underlying the paper figures (.mat / .csv)
├── polt-papper/     Plotting scripts (8 files, covering paper Fig.1–10)
├── terrain/         Terrain/threat-field generation functions (runtime dependency of Fig.1 and Fig.7/9)
└── figures/         Output directory (figures are generated automatically when the scripts are run)
```

## Usage (MATLAB R2024b, no third-party toolboxes required)

```matlab
cd 'path to Supplementary_Materials'
addpath(genpath(pwd));     % add all subfolders to the path
% Then run the scripts one by one (or run all of them together):
plotFig1_TerrainThreatField    % -> Fig.1  Two-scenario 3D terrain + threat field (figures/Fig1_TerrainThreatField.png/.eps)
plotFig3_ablation_radar        % -> Fig.3  Radar chart of average Friedman rankings
plotFig4xin_Convergence        % -> Fig.4  ZDT2/DTLZ2 convergence curves (HV/IGD)
plotFig5_IGD_Boxplot           % -> Fig.5  ZDT2/DTLZ2 IGD box plots
plotFig6and8_Pareto            % -> Fig.6/8  Mountain/debris-flow Pareto front 3D projections
plotFig7and9_lujing            % -> Fig.7/9  Mountain/debris-flow 3D paths + side-view profiles
plotFig10_ParamSweep_Combined  % -> Fig.10 Parameter sensitivity analysis
```

> Note: `plotFig5and7_Pareto_allRuns.m` is a backup plotting script from the development stage
> (merged fronts over 30 runs). It was not used in the paper and can be ignored.

## Correspondence between Figures and Data Files

| Paper figure | Content | Data file |
|---|---|---|
| Fig.1 | Two-scenario 3D terrain + threat field | No data required (rebuilt on the fly, see terrain/) |
| Fig.3 | Friedman ranking radar chart | `ablation_par.mat` (ZDT rows) + `ablation_DTLZ_all.mat` (DTLZ rows) |
| Fig.4 | ZDT2/DTLZ2 convergence curves | `convergence_zdt2_dtlz2.mat` |
| Fig.5 | ZDT2/DTLZ2 IGD box plots | `ablation_par.mat` + `ablation_DTLZ_all.mat` |
| Fig.6/8 | Pareto front 3D projections | `pathCoords.mat` |
| Fig.7/9 | 3D paths + side-view profiles | `pathCoords.mat` + `terrain/` |
| Fig.10 | Parameter sensitivity | `paramSweep.mat` |

## Data Caliber Notes (Important)

- **Ablation experiments (Tables 9/10, Figs. 3/5) use a hybrid data caliber**: the ZDT1-3 rows come from `ablation_par.mat` (TMAX=1500/2500, n=30), and the DTLZ1-3 rows come from `ablation_DTLZ_all.mat` (DTLZ1/3: TMAX=2000; DTLZ2: TMAX=500, n=30) — fully consistent with the main text and Tables 9/10 of the paper.
- **Main terrain experiments (Tables 11–14, Figs. 6–9)**: `expResult_incremental.mat` (2 scenarios × 6 algorithms × 30 runs, 500 generations) + `runtime_rerun_par.csv` (running times).
- **Two-stage TOPSIS analysis (Table 15)**: `topsis_twostage.mat`.
- **Fig.1**: the terrain contains ±0.5 m Gaussian micro-noise (`terrainGeneration.m`). Each run keeps the same macro-scale terrain but differs slightly at the micro scale, which does not affect the visual appearance or the statements in the paper.

## Reproduction Verification

All plotting scripts in this folder have been actually run and verified in MATLAB R2024b.
The generated figures are **pixel-identical** to the figures in the paper. The scripts have no external file references — they read only the `results/` and `terrain/` folders inside this package and write output to `figures/`.
