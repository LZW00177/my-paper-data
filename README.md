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

## Correspondence between Figures/Tables and Data Files

| Paper figure/table | Content | Data file |
|---|---|---|
| Fig.1 | Two-scenario 3D terrain + threat field | No data required (rebuilt on the fly, see terrain/) |
| Fig.3, Tables 9/10 | Friedman ranking radar chart / ablation statistics | `ablation_final.mat` |
| Fig.4 | ZDT2/DTLZ2 convergence curves | `convergence_zdt2_dtlz2.mat` |
| Fig.5 | ZDT2/DTLZ2 IGD box plots | `ablation_final.mat` |
| Fig.6/8, Tables 11/12 | Pareto front 3D projections / terrain metrics | `pathCoords.mat`, `expResult.mat` |
| Fig.7/9 | 3D paths + side-view profiles | `pathCoords.mat` + `terrain/` |
| Table 13 | Flight-altitude / threat-crossing statistics | `expResult.mat` |
| Table 14 | Running times | `runtime_rerun_par.mat` / `.csv` |
| Table 15 | Two-stage TOPSIS analysis | `topsis_twostage.mat` |
| Fig.10 | Parameter sensitivity | `paramSweep.mat` |

## Data Caliber Notes (Important)

- **Ablation experiments (Tables 9/10, Figs. 3/5)**: unified single source `ablation_final.mat` —
  6 benchmark rows (ZDT1/2/3 with TMAX=300; DTLZ1/3 with TMAX=2000; DTLZ2 with TMAX=500) ×
  9 algorithms (MO-ALA variants A/B/C/D, NSGA-II, MOPSO, EALA, IALA, HALA) × 30 runs,
  population N=30, decision-variable dimension D=10. Fully consistent with Tables 9/10 and Figs. 3/5.
- **Main terrain experiments (Tables 11–13, Figs. 6–9)**: `expResult.mat` + `pathCoords.mat`
  (2 scenarios × 6 algorithms × 30 runs, 500 generations) and `runtime_rerun_par.mat/.csv` (Table 14).
- **Two-stage TOPSIS analysis (Table 15)**: `topsis_twostage.mat`.
- **Fig.1**: the terrain contains ±0.5 m Gaussian micro-noise (`terrainGeneration.m`). Each run keeps
  the same macro-scale terrain but differs slightly at the micro scale, which does not affect the
  visual appearance or the statements in the paper.
- Superseded development-stage data files (older ablation files, `expResult_incremental.mat`,
  smoothing experiments, etc.) are kept under `results/_archive_旧版/` for traceability.

## Reproduction Verification

All plotting scripts in this folder have been actually run and verified in MATLAB R2024b
(scripts updated 2026-09-09, IALA = re-implementation following Zheng et al. 2026).
The generated figures are **pixel-identical** to the figures in the paper. The scripts have no
external file references — they read only the `results/` and `terrain/` folders inside this package
and write output to `figures/`.
