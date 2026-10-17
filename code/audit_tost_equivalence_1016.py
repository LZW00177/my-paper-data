# -*- coding: utf-8 -*-
"""audit_tost_equivalence_1016.py

Paired TOST equivalence testing for the benchmark ablation (Variant D, the full
model, vs Variant A, the un-augmented baseline) reported in Section 3.2.1 of the
revised manuscript and in the response letter (R2-1).

Offline analysis only: reads the released archive data/ablation_benchmark.mat
(no re-optimisation). The equivalence margin (+/-10 %) is pre-declared; it
matches the +/-10 % reference-box perturbation used in the reference-robustness
analysis accompanying Section 3.4.

Method: per benchmark, per-run log ratios y_i = ln(D_i / A_i) (i = 1..30);
two one-sided t-tests against the margins +/-ln(1.1); equivalence holds when
the 90 % confidence interval of the mean of y lies inside (-ln 1.1, +ln 1.1),
i.e. when the 90 % CI of the ratio of means lies inside (0.90, 1.10).
A Holm step-down over the family of TOST p-values is reported per metric.
The two-sided Wilcoxon signed-rank p (normal approximation, the manuscript's
convention) is printed as a cross-check.

Runs from the package layout (code/../data/ablation_benchmark.mat) or, as a
fallback, from the development layout (../results/ablation_benchmark.mat).
"""
import os
import numpy as np
from scipy import stats

try:
    import h5py
except ImportError:
    raise SystemExit("h5py is required (pip install h5py)")

HERE = os.path.dirname(os.path.abspath(__file__))
PKG = os.path.dirname(HERE)
CANDIDATES = [
    os.path.join(PKG, "data", "ablation_benchmark.mat"),
    os.path.join(PKG, "results", "ablation_benchmark.mat"),
]
MAT = next((c for c in CANDIDATES if os.path.exists(c)), None)
if MAT is None:
    raise SystemExit("ablation_benchmark.mat not found in data/ or results/ next to this script")

BENCH = ["ZDT1", "ZDT2", "ZDT3", "DTLZ1", "DTLZ2", "DTLZ3"]
A_IDX, D_IDX = 0, 3          # rows of the alg axis in archive cell R[alg, bench]
MARGIN = 0.10
LM = np.log(1.0 + MARGIN)

def holm(pvals):
    idx = sorted(range(len(pvals)), key=lambda k: pvals[k])
    out, m = [], len(pvals)
    for rank, k in enumerate(idx):
        thr = 0.05 / (m - rank)
        out.append((k, pvals[k], thr, pvals[k] <= thr))
        if pvals[k] > thr:
            break
    return out

def main():
    print("archive:", MAT)
    f = h5py.File(MAT, "r")
    R = f["R"]
    data = {}
    for i in range(R.shape[0]):
        for j in range(R.shape[1]):
            data[(i, j)] = np.array(f[R[i, j]])   # (4 metrics, 30 runs)

    for met_i, met in [(1, "IGD"), (0, "HV")]:
        print("=" * 96)
        print("== metric: %s | D vs A, n = 30 paired | TOST margin +/-%d%% on the log-ratio scale"
              % (met, round(MARGIN * 100)))
        rows = []
        for bi, b in enumerate(BENCH):
            A = data[(A_IDX, bi)][met_i, :]
            D = data[(D_IDX, bi)][met_i, :]
            pos = (A > 0) & (D > 0)
            if not pos.all():
                print("   %-6s TOST SKIPPED (non-positive values: min A = %.3g, min D = %.3g)%s"
                      % (b, A.min(), D.min(),
                         " -- all-arm HV = 0 by true-PF anchoring" if met == "HV" else ""))
                rows.append(None)
                continue
            y = np.log(D[pos] / A[pos])
            n = y.size
            m_ = y.mean()
            se = y.std(ddof=1) / np.sqrt(n)
            tc = stats.t.ppf(0.95, n - 1)
            ci_lo, ci_hi = m_ - tc * se, m_ + tc * se          # 90 % CI (TOST at alpha = .05)
            p1 = stats.ttest_1samp(y, -LM, alternative="greater").pvalue
            p2 = stats.ttest_1samp(y, +LM, alternative="less").pvalue
            p_tost = max(p1, p2)
            equiv = (ci_lo > -LM) and (ci_hi < LM)
            psr = stats.wilcoxon(A, D, method="approx", correction=False).pvalue
            rom = D.mean() / A.mean()
            print("   %-6s ratioOfMeans=%.4f  90%%CI[%.4f, %.4f]  pTOST=%.3g  %s"
                  % (b, rom, np.exp(ci_lo), np.exp(ci_hi), p_tost,
                     "EQUIVALENT" if equiv else "not established"))
            print("          signed-rank p=%.4g   meanA=%.4g meanD=%.4g"
                  % (psr, A.mean(), D.mean()))
            rows.append(dict(bench=b, p=float(p_tost)))
        ok = [r for r in rows if r]
        print("   -- Holm step-down at 0.05 over the %d TOST p-values:" % len(ok))
        surv = []
        for k, p, thr, is_ok in holm([r["p"] for r in ok]):
            print("      %-6s pTOST=%.3g  thr=%.5f  %s"
                  % (ok[k]["bench"], p, thr, "SURVIVES" if is_ok else "fails"))
            if is_ok:
                surv.append(ok[k]["bench"])
        print("   => TOST survivors after Holm:", surv if surv else "NONE")
        print()

    print("Expected anchors: IGD ZDT1 meanA=0.008616 meanD=0.009441 signed-rank p=1.734e-06;")
    print("                  DTLZ3 signed-rank p=2.564e-02; HV survivors ZDT1/ZDT2/ZDT3/DTLZ2.")

if __name__ == "__main__":
    main()
