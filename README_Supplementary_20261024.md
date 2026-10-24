# MO-ALA (MS 4584712) — Supplementary Material, revision 2026-10-24

This package is the **2026-10-24 revision** of the supplementary material originally
submitted on 2026-09-15.
It is a strict **superset** of the original package and of the previous revision package: every
original file is retained unmodified, and the artefacts added for the revisions are listed in
section 3. Relative to the previous package, this revision updates
`tables/Supplementary_Tables_S1-S5.docx` (Tables S3 and S4 regenerated with the per-front
min–max normalization of Section 3.6, so that the w(J3) = 0.60 row of Table S3 reproduces
J1* = 265.92 / J3* = 178.55), `code/make_supp_tables.py` (same normalization, so the tables are
byte-reproducible), this README, and the change log.

The revision was finalised on **24 October 2026**. Six passes were made on that date, and none
of them touches the manuscript. The first corrected the reference numbers quoted in the Revised column of
the change log and the word count quoted for the revised manuscript (17,943 words, against the
17,907 of the preceding build), and brought the abstract count carried by the companion documents
into line with the manuscript (208 words). The second put every document that accompanies the
revision on one date: the cover letter, the four Reviewer response letters and the
response to the editorial checklist were all re-dated to 24 October 2026, so that every document
that accompanies the revision now carries one date; the checklist's own statement of
the word count of the revised manuscript was corrected to 17,943 words in the same pass. A third
pass added to the Record of Changes the entry for Section 2.2.5 that its item sequence had been missing,
which took that record from 29 to 30 items and settled its count of changed blocks at 49; the item
count quoted in the checklist followed. A fourth pass corrected three inaccurate statements in
this README and in the change log itself and touched nothing else. A fifth pass corrected the provenance notes of Supplementary Table S1 and the letter citations in the data manifest, declared the omission of the all-zero out-of-bound column, aligned the generator script with the published table and corrected this README's description of the package's table editions. A sixth pass added a PDF edition of the supplementary tables, rendered from the Word edition and shipped beside it, after setting the rows of the five tables not to split across pages so that no row breaks in the rendered file, and updated this README's description of the package's table editions accordingly. Sections S, T, U, V, W and X of the change log record the six passes item by item. The pass before them, on 22 October, had touched the abstract
(rewritten in full, to 208 words on the measure used throughout these documents, from 263 in
the revision as first compiled), the reference list (two author strings
corrected), the variant definitions that open Section 3.4 (32 words added, so that the labels B and
C carry the mechanism each one stands for, as Section 3.2.1 already does), the cover letter and the
packaging itself: a second, superseded change log that duplicated this one was dropped, Word
editions of the change log and of this README were added, and one wrong entry in the table below
was corrected. Over that pass the manuscript moved from 17,929 to 17,907 words: 57 words came out of
the abstract, and 35 went into the reference list and Section 3.4. No data archive, table, script or
numerical result changed on that date; Section N of the change log records that pass item by item.

**Baseline and target of the revision.** The manuscript this revision is submitted against — the
baseline — is the file the submission system holds for MS 4584712, `biomimetics-4584712.docx`
(received 9 September 2026; the build now in the system was re-saved and re-uploaded by the
authors on 17 September 2026, and it is that build the referees read). The revised manuscript
submitted with this revision is `biomimetics-4584712_Revised_v2_20261024_clean.docx`; apart from
the revision colouring it carries the same text as
`biomimetics-4584712_Revised_v2_20261024_marked.docx`. Those two files are the whole
comparison; no third version forms part of the submission.

Companion documents (not part of this package):

| File | What it is |
|---|---|
| `biomimetics-4584712.docx` | the build the submission system holds — the baseline of this revision (received 9 September 2026, re-saved by the authors 17 September 2026) |
| `biomimetics-4584712_Revised_v2_20261024_clean.docx` | revised manuscript submitted with this revision (clean) |
| `biomimetics-4584712_Revised_v2_20261024_marked.docx` | same, revised text in blue |
| `Response_to_Reviewer1_MDPI_20261024.docx` — `Response_to_Reviewer4_MDPI_20261024.docx` | four point-by-point response letters, dated 24 October 2026 |
| `Response_to_Editor_Checklist_20261024.docx` | response to the editorial checklist and to the four referee reports, dated 24 October 2026 |
| `ChangeRecord_vs_InReview_Version_20261024.docx` | Record of Changes: the baseline-to-target comparison, item by item |
| `Cover_Letter_Revision_20261024.docx` | cover letter, dated 24 October 2026 |

---

## 1. Directory structure

```
code/       mission model, terrain and utility helper modules + the supplementary-table generator
data/       all archived numerical results (*.mat) and their manifests
figures/    the nine data-driven paper figures (Figs. 1, 3-10) + Supplementary Figure S1
                                + the envelope-ablation figure of Appendix B (Figure B.3);
                                each figure is supplied as eps and png, except Figs. 6 and 8,
                                which are supplied as .fig (MATLAB native) and png
logs/       console logs of the reported runs
scripts/    experiment, audit and figure-generation scripts
tables/     Supplementary Tables S1–S5 (Word + PDF)
ChangeLog_20261024.docx / .pdf  revision log: baseline -> target, paragraph by paragraph, with the
                                20-24 October passes in the addendum
README.docx / .pdf              this file
                                The three documents above are delivered in Word and PDF. The Markdown
                                sources from which the Word editions were generated are retained in
                                the authors' revision folder and are not part of this package.
run_all_figs.m   driver that regenerates the paper figures from data/; it writes its own
                                console transcript to `run_all_figs.txt` in the package root,
                                which is why that file is not listed under logs/
```

## 2. How to reproduce the results

Every reported number is produced by one of the scripts below; nothing is transcribed
by hand.

**Invocation.** Every script resolves its own input and output paths from
`mfilename('fullpath')` (MATLAB) or `__file__` (Python), so nothing has to be edited
before use and no script depends on the current working directory. From the root of
this package:

```
matlab -batch "cd scripts; <scriptname>"      % the eight revision scripts
matlab -batch "run_all_figs"                  % all seven legacy figure scripts
python code/make_supp_tables.py               % Supplementary Tables S1-S5
python code/audit_tost_equivalence_1016.py    % TOST equivalence analysis (Section 3.2.1)
```

**Run matrix.** The scripts fall into three classes.

| # | Script | Needs code beyond this package | Runs as shipped | Re-run reproduces |
|---|---|---|---|---|
| 1 | `scripts/audit_paths_violation_1016.m` | no (`terrainGeneration.m` is in `code/`) | **yes**, ~1 min | console table identical; `data/path_feasibility_audit_1016.mat` identical except the MAT-file creation timestamp |
| 2 | `scripts/audit_hv_reference_robustness_1016.m` | no (`MetricsCalculator.m` is in `code/`; the baseline fronts are read from `data/terrain_metrics.mat`) | **yes**, ~9 min single-threaded | `logs/hv_reference_robustness_1016.txt` byte-identical; all 75 fields of `data/hv_reference_robustness_1016.mat` identical |
| 3 | `scripts/combine_scenario_evidence_1016.m` | no (reads the output of #2) | **yes**, seconds | `logs/combine_scenario_evidence_1016.txt` identical except the recorded source path |
| 4 | `scripts/plotFigSx_perturbScale.m` | no (fully analytic) | **yes**, seconds | `figures/FigureS1_perturbScale.png` pixel-identical |
| 5 | `scripts/plotFigB3_envelopeAblation.m` | no (parses the archived log; no simulation) | **yes**, seconds | `figures/FigureB3_envelopeAblation.png` and `.eps`; all 36 plotted values re-read from `logs/g_schedule_ablation_1016.txt` |
| 5 | `run_all_figs.m` + the seven legacy `scripts/plotFig*.m` | no | **yes**, ~1 min | the nine PNG figures of Figs. 1 and 3-10 pixel-identical (0 differing pixels); see the byte-level caveat below |
| 6 | `code/make_supp_tables.py` | no (Python 3 + numpy + h5py) | **yes**, seconds | the Markdown source of the tables byte-identical (the Markdown master is kept outside this package); the Word edition in this package typesets that source, with the subscripts in the table headers set as equation objects; the PDF edition in this package is rendered from the Word edition and carries the same content |
| 7 | `code/audit_tost_equivalence_1016.py` | no (Python 3 + numpy + h5py + scipy) | **yes**, seconds | console report identical (TOST CIs, p-values, Holm survivors; signed-rank p reproduced in the manuscript's normal-approximation convention) |
| 8 | `scripts/run_terrain_ablation_formal_1016.m` | **`MOALA.m`** | no — preflight error | n/a |
| 9 | `scripts/audit_dim_scaling_1016.m` | **`MOALA.m`** | no — preflight error | n/a |
| 10 | `scripts/rerun_v8_degradation_1016.m` | **`MOALA.m`, `ZDTProblem.m`, `DTLZProblem.m`, `ablationWorker.m`** | no — preflight error | n/a |
| 11 | `scripts/rerun_Gschedule_1016.m` | **`MOALA.m`, `ZDTProblem.m`, `DTLZProblem.m`, `ablationWorker.m`** | no — preflight error | n/a |

**Byte-level caveat for row 5.** The nine PNG figures regenerate pixel-identically (0
differing pixels), but the exported files are not byte-identical: MATLAB writes a `tIME`
chunk and a `tEXt` (`Creation Time`) chunk into every PNG on export, so those two chunk
types always differ. Strip them and the remaining bytes of all nine PNG figures match
exactly. The EPS exports are byte-identical in their vector body for Figs. 1, 3, 4, 5 and
10; for Figs. 7 and 9 the embedded rasterisation differs by one device pixel (the `CT`
scaling matrix differs in the fifth decimal, e.g. `0.60125` vs `0.60117`), which is the
1/72-inch quantisation of the EPS rasteriser and not a change in any plotted value.

The canvas sizes are pinned inside the plotting scripts themselves (`figure('Position',
...`), so the output dimensions depend only on those constants — not on the screen
resolution or the display scaling of the machine that runs the scripts. All five canvas
sizes requested by the legacy scripts agree with the archived figures.

Rows 1–7 were executed on a clean copy of this package before release; the outputs
listed in the last column are what was observed. Rows 8–11 are the four experiments
that call the core MO-ALA implementation. That implementation, the two benchmark
classes and the per-task runner are withheld under the patent restriction described
in the Data Availability Statement, so those four scripts cannot be executed from the
package alone (the terrain mission model `UAVMultiObj.m` is included in this revision,
in `code/`, so the two terrain experiments — rows 8–9 — now lack only `MOALA.m`).
Each of them states the required files in its header and **aborts with
an explicit `:WithheldCode` error before doing any work** if they are not on the
MATLAB path — they never fail later with a cryptic "Undefined function". Their
numerical results are archived in `data/` and are auditable without re-running:
`audit_hv_reference_robustness_1016.m` (row 2) re-derives the §3.4 statistics from
`data/terrain_ablation_formal_1016.mat` plus `data/terrain_metrics.mat`,
`make_supp_tables.py` (row 6) re-derives Tables S1–S5, and `run_all_figs` (row 5)
re-draws every paper figure.

What each script produces:

| Result | Script | Archive written |
|---|---|---|
| Table 9, Table 10, Fig. 3, Fig. 5 | legacy (2026-09-15 package) | `data/ablation_benchmark.mat` |
| Fig. 4 | legacy | `data/convergence.mat` |
| Tables 11–13 | legacy | `data/terrain_metrics.mat` |
| Figs. 6–9 | legacy | `data/terrain_paths.mat` |
| Fig. 10 | legacy | `data/param_sweep.mat` |
| Table 14, Table 16, §3.6 | legacy | `data/runtime_topsis.mat` |
| **Table 15, §3.4** | `scripts/run_terrain_ablation_formal_1016.m` | `data/terrain_ablation_formal_1016.mat` |
| **§3.1 capacity check** | same script, `ARCH = 100` | `data/terrain_ablation_formal_1016_ARCH100_keep.mat` |
| **§3.4 statistics audit** (all six A/B/C/D contrasts, four reference boxes, K = 20 Monte-Carlo draws) | `scripts/audit_hv_reference_robustness_1016.m` | `data/hv_reference_robustness_1016.mat` (+ `logs/hv_reference_robustness_1016.txt`) |
| **R2-1b two-scenario evidence combination** (Fisher across the two independent scenarios) | `scripts/combine_scenario_evidence_1016.m` | `logs/combine_scenario_evidence_1016.txt` |
| **R4 mechanism check / R1-2** (G(t)-envelope ablation: `linear` / `const` / `floor`) | `scripts/rerun_Gschedule_1016.m` | `data/g_schedule_ablation_1016.mat` (+ `logs/g_schedule_ablation_1016.txt`) |
| **§2.1.5 / §3.3 / Table S1** | `scripts/audit_paths_violation_1016.m` | `data/path_feasibility_audit_1016.mat` |
| **§4.4 / Table S2** | `scripts/rerun_v8_degradation_1016.m` | `data/ablation_v8_degradation_1016.mat` |
| **§3.5 wall-clock / Table S5** | `scripts/audit_dim_scaling_1016.m` | `data/dim_scaling_1016.mat` |
| **Figure S1** | `scripts/plotFigSx_perturbScale.m` | `figures/FigureS1_perturbScale.{png,eps}` |
| **Figure B.3** (Appendix B; envelope ablation) | `scripts/plotFigB3_envelopeAblation.m` | `figures/FigureB3_envelopeAblation.{png,eps}` |
| **Tables S1–S5** | `code/make_supp_tables.py` | `tables/Supplementary_Tables_S1-S5.{docx,pdf}` |

**Two cosmetic notes for anyone re-running the MATLAB scripts.** (i) The authors'
own MATLAB installation carries two stale entries in its `pathdef.m`, so a MATLAB
session started there prints two `Warning: Name is nonexistent or not a directory`
lines mentioning `...\Desktop\papper\...` before any script output. They come from the
local installation, not from this package, and do not affect any result. (ii) A
re-run rewrites the archives it owns, so the MAT-file headers carry the new creation
timestamp and the EPS files carry the new `%%CreationDate`; the numerical content is
unchanged, as the last column of the run matrix records.

## 3. What this revision adds

**New data archives** (full descriptions in `data/MANIFEST_revision_20261024.txt`):

- `data/terrain_ablation_formal_1016.mat` — variant A/B/C/D ablation in both terrain
  scenarios (N = 30, T = 500, N_arch = 50, 30 runs, **common random numbers**, fixed
  external reference front). Backs Table 15 and §3.4.
- `data/terrain_ablation_formal_1016_ARCH100_keep.mat` — the same ablation at
  N_arch = 100, kept as the capacity-robustness check. **No number in the manuscript
  is taken from this file.**
- `data/path_feasibility_audit_1016.mat` — hard-constraint audit of the published
  trajectories of all six algorithms, both scenarios, all 30 runs. Backs the §2.1.5
  audit paragraph, §3.3 and Supplementary Table S1.
- `data/ablation_v8_degradation_1016.mat` — SBX-hybrid (v8) vs the original
  memory-guided operator on six benchmarks, T = 500, 30 runs, same seed for both arms.
  Backs §4.4 and Supplementary Table S2.
- `data/dim_scaling_1016.mat` — wall-clock time vs decision-variable dimension.
  Backs the §3.5 "Wall-clock scaling" paragraph and Supplementary Table S5.
- `data/hv_reference_robustness_1016.mat` — **offline** robustness audit of the terrain
  statistics: the archived 30-run fronts of both scenarios are re-scored under four
  reference boxes and K = 20 independent Monte-Carlo draws of the hypervolume
  estimator, and **all six** A/B/C/D pairwise contrasts are reported (IGD as a
  deterministic, box-independent control). No re-optimisation is involved, so it
  re-runs in about nine minutes. It is the evidence behind two statements in §3.4:
  that the debris-flow separation is carried by the deterministic IGD columns, and
  that no mountain contrast can be quoted because the hypervolume *p*-value there
  moves between 0.039 and 0.077 with the estimator's own sampling noise.
- `data/g_schedule_ablation_1016.mat` — ablation of the **amplitude envelope `G(t)`** alone.
  Three arms of the same algorithm (all = full MO-ALA, variant D) differing *only* in the
  envelope: `linear` (`G(t) = 2(1 − t/(Tmax−1))`, the rule used in the manuscript), `const`
  (`G ≡ 2`, no amplitude contraction) and `floor` (decays to 0.2, never 0). Six benchmarks, T = 500, 30 runs,
  true common random numbers across arms (all three share `REF_AI = 4`, so the `linear` arm is
  seed-identical to the archived `MOALA-D(original)` column of `ablation_v8_degradation_1016.mat`;
  the script verifies this element-wise). 21 min 17 s wall on five workers. The result is that the
  envelope is **functional but not a universal optimum**: reducing the contraction (`floor`) degrades
  the deterministic IGD significantly on three benchmarks (ZDT1, ZDT3, DTLZ2; *p* ≤ 0.014), and
  removing it (`const`) does so on DTLZ2 (*p* = 0.045), while on ZDT1 the undamped schedule is
  **significantly better on both metrics** (IGD −5.40 %, *p* = 3.1 × 10⁻⁵; HV +0.18 %, *p* = 0.0023).
  Every number quoted here, including that counter-example, is printed unedited in the log. Quote the
  direction the data supports, not a blanket "the contraction is necessary" — on ZDT1 the data points the
  other way, which is exactly why the manuscript's §5.2 lists a convergence-adaptive envelope as
  future work rather than claiming the linear schedule is optimal.

**New scripts:** the eight `.m` files listed in section 2 plus `code/make_supp_tables.py` and `code/audit_tost_equivalence_1016.py`.
All of them carry **English** comments. All of them resolve their own paths (see the
invocation note in section 2), so none has to be edited to run; the four that call the
withheld core implementation say so in their header and stop with an explicit
`:WithheldCode` error instead of failing halfway through.

**New code:** `code/UAVMultiObj.m` is the four-objective terrain mission model
(J1–J4 objectives, the hard terrain/attitude constraints and the feasibility
sampling/checking interface) that every archived trajectory was evaluated with. It
predates the revision (dated 2026-08-28) and is shipped byte-identical to the file that
produced the archived results; like the other pre-revision artefacts, its comments are
in Chinese. With it, the two terrain experiments (rows 8–9 of the run matrix)
lack only the withheld core algorithm `MOALA.m`.

**New logs:** `logs/path_audit.log`, `logs/dim_scaling.log`,
`logs/terrain_ablation_ARCH50.log`, `logs/terrain_ablation_ARCH100.log`,
`logs/v8_degradation.log`, `logs/figsx.log`, `logs/hv_reference_robustness_1016.txt`,
`logs/combine_scenario_evidence_1016.txt`, `logs/g_schedule_ablation_1016.txt`.
The MATLAB logs are unedited captures. The two `[警告: 名称不存在或不是目录: ...]` lines
at the head of `terrain_ablation_ARCH50.log` and `terrain_ablation_ARCH100.log` are MATLAB
`path` warnings about directories that existed only on the machine that ran the campaign
(a stale workspace folder); they are printed before the run starts and have no effect on the
results. The `MATLAB:mir_warning` / Chinese comment strings elsewhere in this package are
original artefacts and are shipped byte-identical, as stated above.

**Note on scope.** `data/g_schedule_ablation_1016.mat` and
`logs/combine_scenario_evidence_1016.txt` were produced *after* the manuscript revision was
assembled. The first is the mechanism check that answers reviewer 4's "artificial damping"
objection and reviewer 1's convergence-stability question; it is cited in the response letter under
**R1-2** (with its ZDT1 counter-example stated) and **R4-2**, and it motivates the new §5.2
future-work paragraph on a convergence-adaptive envelope. The second reproduces the
evidence-combination figure quoted in the response letter (item R2-1b). Neither is needed to
reproduce a number printed in the manuscript; both are included so that the two arguments can be
re-derived from the archived data rather than taken on trust.

**New tables / figure:** `tables/Supplementary_Tables_S1-S5.{docx,pdf}` and `figures/FigureS1_perturbScale.{png,eps}`. Tables S3 and S4 were regenerated for the
2026-10-20 revision: the TOPSIS selection now uses the **per-front min–max normalization of
Section 3.6** (the `topsisSelectIdx` convention of the manuscript code) instead of the vector
normalization used in the earlier build of these tables. The w(J3) = 0.60 row of Table S3 therefore
reproduces J1* = 265.92 / J3* = 178.55 from Section 3.6; under vector normalization the same
weight vector gave 256.91 / 171.95. The table notes state which normalization is used, and
`code/make_supp_tables.py` reproduces the table source byte for byte (verified on a clean
copy of this package before release; the Markdown master is kept outside this package);
the shipped `.docx` typesets that source, with the subscripts in the table headers set as equation objects; the shipped .pdf is rendered from that .docx and carries the same content.

**The figure of Appendix B.** The manuscript reproduces the envelope-ablation figure in
Appendix B (labelled B.3 in the appendix, captioned "Figure B.3" in the manuscript). This
package now ships that figure twice: `figures/FigureB3_envelopeAblation.{png,eps}` is
regenerated by `scripts/plotFigB3_envelopeAblation.m` from the archived log
`logs/g_schedule_ablation_1016.txt` (all 36 plotted values were read back from that log and
checked against it), and `figures/FigureB3_envelopeAblation_published.png` is the exact
raster embedded in the submitted manuscript, so a reader can compare the two. They carry the
same data; the manuscript copy is the one the appendix shows. The two files differ in pixel
dimensions and colour type (1839 x 1280 RGBA for the manuscript raster, 3126 x 2138 RGB for
the 300 dpi export) because one was rasterised on typesetting and the other was written
directly by the script; the 36 plotted values are identical in both, and the regenerated
figure is the one to inspect for numbers.

## 4. Conventions and caveats

- The audit thresholds are `theta_max = pi/3`, minimum clearance `h_min = 2 m` and a
  `[0, 100] x [0, 100]` flight box, as in Table 2 of the paper.
- Trajectories are split into the B-spline-smoothed ones (`>= 50` points) and the
  discrete-waypoint fallback (`<= 30` points, i.e. the optimiser's own output). The
  fallback subset is the one that matters for the feasibility claim.
- Three pitch-rate definitions are distinguished in Supplementary Table S1 and in the
  response letter: **overall** (all published segments), **smoothed** (smoothed subset
  only) and **fallback** (optimiser's own waypoints). §2.1.5 quotes the overall rate.
- The V8/SBX-hybrid operator remains an **exploratory** operator: it is reported in
  §4.4 and Table S2 only to justify *not* integrating it into MO-ALA, and it is used
  for no result of the proposed method.
- `MetricsCalculator.HV` estimates hypervolume by 50 000 uniform Monte-Carlo samples
  and does **not** seed the generator, so a single call carries sampling noise
  (~2 × 10⁻³ per run on the terrain fronts). Means and standard deviations are
  unaffected at the precision quoted in the paper, but a *paired* significance test
  that consumes those per-run values is: near-tied pairs can exchange rank under a
  perturbation of that size. `scripts/audit_hv_reference_robustness_1016.m` quantifies
  this and is the reason §3.4 reports the debris-flow conclusion on the IGD columns
  and quotes no mountain conclusion.
- The `G(t)`-schedule ablation is the one place where the data does **not** point wholly in the
  authors' favour: on ZDT1 the undamped arm (`const`) is marginally better than the manuscript
  rule on both metrics (−5.40 % IGD, *p* = 3.1 × 10⁻⁵). The defensible reading is therefore that
  the envelope is a functional component with a problem-dependent optimal rate — reducing or
  removing it degrades the deterministic IGD on four of six benchmarks — and not that a particular
  decay rate is optimal. It is also an independent reproduction of the §3.1 reference-anchoring
  floor: hypervolume is identically 0 for all three arms on DTLZ1 and DTLZ3.
- Files dated 2026-09-15 are the authors' original submission artefacts and are
  reproduced unmodified; some of their comments are in Chinese.
- **Terminology note on the raw logs.** The experiment harness internally labelled
  Scenario 2 as `landslide`; the manuscript and this README call the same scenario
  **debris flow** (relief-material delivery over gully terrain). The logs are published
  byte-for-byte as produced — they are the provenance record against which re-runs are
  compared — so the internal label was left untouched rather than rewritten. Whenever a
  console log prints `[landslide]` or a `landslide` scenario name, it refers to exactly
  the scenario the paper calls *debris flow* (Scenario 2); Scenario 1 is `mountain`
  throughout.
