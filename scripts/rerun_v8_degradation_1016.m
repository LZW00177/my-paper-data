function rerun_v8_degradation_1016(varargin)
% =========================================================================
% rerun_v8_degradation_1016 - the v8-degradation re-run required by theme C (Route B+)
%
% Purpose (2026-10-16, for the revised Supplementary Material):
%   Reviewer 3 allows one of two routes: "explicitly reposition the contribution as scoped to
%   non-deceptive fronts". We had observed that the SBX-hybrid operator (v8) restores convergence
%   on DTLZ1/3 but degrades on non-deceptive fronts (ZDT/DTLZ2). To turn "why it is not integrated"
%   into a data-backed decision, the formal degradation figures of v8 on the non-deceptive
%   benchmarks are required.
%   The script covers all six benchmarks (ZDT1-3 + DTLZ1-3) and runs the original operator
%   (MOALA-D) as a same-seed reference, producing two kinds of numbers in one pass:
%     - degradation (ZDT1-3, DTLZ2: v8 is worse than the original);
%     - convergence recovery (DTLZ1, DTLZ3: v8 raises HV from ~0 to non-zero).
%   Protocol: T = 500 for all six benchmarks, matching the main configuration reported in
%   Table 8 / Section 3.1, so no mixed-protocol numbers are produced.
%
% Protocol (consistent with Table 9):
%   - Run from the MOALA_UAV_code directory so that the fixed DTLZProblem / MetricsCalculator
%     (HV_ref = max(trueF)*1.05) are loaded, matching the paper's setting.
%   - All metrics are reused from ablationWorker (HV/IGD/Spacing/frontSize).
%   - Seeds: seed = BASE_SEED + 4000*bi + 100*ai + r
%       bi: benchmark index (ZDT1=1, ZDT2=2, ZDT3=3, DTLZ2=5)
%       ai: fixed at 4 (the MOALA-D slot) so that the original and the v8 arm share the same
%           seed and are seed-paired with the MOALA-D rows of Table 9.
%       r : run index 1..30
%   - TMAX: 500 for all six benchmarks (main configuration, Table 8 / Section 3.1).
%           Note: the script that generated Table 9 used TMAX = 300, and the older v8_DTLZ13
%           file used T = 2000; those numbers must not be compared across files. This script
%           adopts the main-configuration T = 500.
%
% Executed as reviewed on 2026-10-16: rerunBi = [1..6], all six benchmarks at T = 500, so that
%   the convergence recovery (DTLZ1/3) and the degradation figures (ZDT1-3/DTLZ2) share one protocol.
%
% Output: data/ablation_v8_degradation_1016.mat
%   R(6x2 cell): column 1 = MOALA-D (original), column 2 = MOALA-D (v8); rows bi in rerunBi
%   each cell is 30x4 = [HV IGD Spacing frontSize]
%   stats: paired Wilcoxon (signrank) of v8 vs original per benchmark, plus mean differences
%
% Usage:
%   from the package root:       matlab -batch "cd scripts; rerun_v8_degradation_1016"
%   from the dev workspace root: matlab -batch "rerun_v8_degradation_1016"
%   matlab -batch "rerun_v8_degradation_1016('FORCE',true)"   % full re-run
% Expected runtime: 2 arms (MOALA-D original + v8) x 6 benchmarks x 30 runs x 500 generations, approx. 45-90 min
% =========================================================================
% REQUIRES CODE THAT IS NOT PART OF THIS PACKAGE (patent restriction)
%   This experiment runs the core MO-ALA implementation on the six paper
%   benchmarks through the per-task runner ablationWorker.m; both are withheld
%   together with the calling harness as stated in the Data Availability
%   Statement.  To re-run it you must obtain from the corresponding author and
%   place on the MATLAB path:
%       MOALA.m          (the algorithm; also needs ALAOperators.m / ArchiveManager.m)
%       DTLZProblem.m    (the DTLZ1-3 benchmark definitions)
%       ZDTProblem.m     (the ZDT1-3 benchmark definitions)
%       ablationWorker.m (the per-task runner used by the parfor loop)
%   MetricsCalculator.m is included in this package (code/).  The numerical
%   results are archived as data/ablation_v8_degradation_1016.mat and back
%   Section 4.4 and Supplementary Table S2; they can be audited without re-running.
% =========================================================================
    BASE_SEED = 20260812;
    NRUNS = 30; N = 30;
    FORCE = false;
    for i = 1:2:length(varargin)
        if strcmpi(varargin{i},'NRUNS'); NRUNS = varargin{i+1};
        elseif strcmpi(varargin{i},'N'); N = varargin{i+1};
        elseif strcmpi(varargin{i},'FORCE'); FORCE = varargin{i+1}; end
    end

    % Dual-layout resolution: the shipped package keeps data in data/ and the helper
    % modules in code/; the development workspace kept both at the repository root
    % (data in results/, helpers alongside the scripts).
    base    = fileparts(mfilename('fullpath'));   % .../scripts  or <dev workspace>
    pkgRoot = fileparts(base);                    % package root when run from .../scripts
    DATA = fullfile(pkgRoot,'data');
    if ~exist(DATA,'dir'); DATA = fullfile(base,'results'); end          % development layout
    CODE = fullfile(pkgRoot,'code');
    if ~exist(CODE,'dir'); CODE = base; end                               % development layout
    addpath(CODE);
    for sub = {'algorithms','metrics','terrain'}
        d = fullfile(CODE, sub{1});
        if exist(d,'dir'); addpath(d); end
    end
    rehash;

    % Preflight: fail fast with an actionable message instead of a cryptic
    % "Undefined function" once the optimisation is about to start.
    need = {'MOALA','DTLZProblem','ZDTProblem','ablationWorker'};
    miss = need(cellfun(@(f) isempty(which(f)), need));
    if ~isempty(miss)
        error([mfilename ':WithheldCode', ...
            'This script needs the withheld core implementation (%s). See the ' ...
            'header of this file and the Data Availability Statement; the archived ' ...
            'result is data/ablation_v8_degradation_1016.mat.'], strjoin(miss, ', '));
    end

    % ---- Six benchmark definitions: all six at TMAX = 500 (main configuration, Section 3.1 / Table 8) ----
    benchmarks = {
        struct('name','ZDT1',  'type','ZDT', 'id',1,'dim',10,'TMAX',500,'NRUNS',30);
        struct('name','ZDT2',  'type','ZDT', 'id',2,'dim',10,'TMAX',500,'NRUNS',30);
        struct('name','ZDT3',  'type','ZDT', 'id',3,'dim',10,'TMAX',500,'NRUNS',30);
        struct('name','DTLZ1', 'type','DTLZ','id',1,'dim',10,'TMAX',500,'NRUNS',30);
        struct('name','DTLZ2', 'type','DTLZ','id',2,'dim',10,'TMAX',500,'NRUNS',30);
        struct('name','DTLZ3', 'type','DTLZ','id',3,'dim',10,'TMAX',500,'NRUNS',30);
    };
    % ---- Two arms: column 1 = MOALA-D (original, reference), column 2 = MOALA-D (v8, to be characterised) ----
    % ai is fixed at slot 4 so that both arms share a seed and align with MOALA-D of Table 9
    algoDefs = {
        'MOALA-D(original)', struct('useMemory',true,'useTdist',true ,'searchMode','original'), true;
        'MOALA-D(v8)',       struct('useMemory',true,'useTdist',true ,'searchMode','v8'),       true;
    };
    nAlgo = size(algoDefs,1);
    metrics = {'HV','IGD','Spacing','frontSize'};
    rerunBi = [1, 2, 3, 4, 5, 6]; % all six benchmarks: ZDT1-3 + DTLZ1-3 (unified T = 500)
    REF_AI  = 4;                 % algorithm index fixed to the MOALA-D slot in the seed formula

    R = cell(6, nAlgo);
    for bi = 1:6; for ai = 1:nAlgo; R{bi,ai} = nan(NRUNS, 4); end; end

    % ---- Resume from checkpoint ----
    ckptFile = fullfile(DATA,'ckpt_v8_degradation_1016.mat');
    doneFlags = false(6, nAlgo);
    if exist(ckptFile,'file') && ~FORCE
        C = load(ckptFile, 'R', 'doneFlags');
        R = C.R; doneFlags = C.doneFlags;
        fprintf('[checkpoint] skipped %d completed (benchmark, algorithm) combinations\n', sum(doneFlags(:)));
    elseif exist(ckptFile,'file') && FORCE
        fprintf('[FORCE] ignoring the old checkpoint, full re-run\n');
    end

    try
        oldp = gcp('nocreate'); if ~isempty(oldp); delete(oldp); end
        parpool('local', min(feature('numcores'), 5));
    catch ME
        warning('parpool failed: %s', ME.message);
    end

    fprintf('\n=== v8 degradation re-run (non-deceptive benchmarks, NRUNS=%d, N=%d) ===\n', NRUNS, N);

    for bi = rerunBi
        bm = benchmarks{bi};
        fprintf('\n--- %s (bi=%d, TMAX=%d) ---\n', bm.name, bi, bm.TMAX);
        for ai = 1:nAlgo
            if doneFlags(bi,ai)
                fprintf('  skipping %s (already complete)\n', algoDefs{ai,1});
                continue;
            end
            ad = algoDefs{ai,1}; opts = algoDefs{ai,2};
            fprintf('  running %-18s ...', ad);
            t0 = tic;
            tmp = nan(NRUNS, 4);
            parfor r = 1:NRUNS
                % Key: ai = REF_AI (=4) so that the original and v8 arms are seed-paired
                seed = BASE_SEED + 4000*bi + 100*REF_AI + r;
                tmp(r,:) = ablationWorker(bm.type, bm.id, bm.dim, 'MOALA', opts, N, bm.TMAX, seed);
            end
            R{bi,ai} = tmp;
            fprintf(' completed %.0fs | HV=%.4f IGD=%.4f Sp=%.4f n=%.0f\n', toc(t0), ...
                nanmean(R{bi,ai}(:,1)), nanmean(R{bi,ai}(:,2)), nanmean(R{bi,ai}(:,3)), nanmean(R{bi,ai}(:,4)));
            doneFlags(bi,ai) = true;
            save(ckptFile, 'R', 'doneFlags', '-v7.3');
            fprintf('    [checkpoint saved]\n');
        end
    end

    % ---- Paired Wilcoxon (same-seed arms) + degradation magnitude ----
    fprintf('\n=== v8 vs original, paired test (same seed, IGD/HV) ===\n');
    stats = struct();
    for bi = rerunBi
        bm = benchmarks{bi};
        orig = R{bi,1}(:, [1 2]);   % [HV IGD]
        v8   = R{bi,2}(:, [1 2]);
        % IGD: lower is better; HV: higher is better
        [pIGD, hIGD] = signrank(orig(:,2), v8(:,2), 'alpha', 0.05);
        [pHV , hHV ] = signrank(orig(:,1), v8(:,1), 'alpha', 0.05);
        dHV  = (nanmean(v8(:,1)) - nanmean(orig(:,1))) / nanmean(orig(:,1)) * 100;  % relative HV change of v8 vs original, %
        dIGD = (nanmean(v8(:,2)) - nanmean(orig(:,2))) / nanmean(orig(:,2)) * 100;  % relative IGD change of v8 vs original, %
        stats(bi).name = bm.name;
        stats(bi).HV_mean   = [nanmean(orig(:,1)), nanmean(v8(:,1))];
        stats(bi).IGD_mean  = [nanmean(orig(:,2)), nanmean(v8(:,2))];
        stats(bi).HV_relPct = dHV;
        stats(bi).IGD_relPct = dIGD;
        stats(bi).wilcoxHV_p = pHV;  stats(bi).wilcoxHV_h = hHV;
        stats(bi).wilcoxIGD_p = pIGD; stats(bi).wilcoxIGD_h = hIGD;
        fprintf('[%s] orig HV=%.4f IGD=%.4f | v8 HV=%.4f IGD=%.4f\n', ...
            bm.name, nanmean(orig(:,1)), nanmean(orig(:,2)), nanmean(v8(:,1)), nanmean(v8(:,2)));
        fprintf('       dHV=%+.1f%% (p=%.3g)   dIGD=%+.1f%% (p=%.3g)   [v8 worse iff dHV<0 or dIGD>0]\n', ...
            dHV, pHV, dIGD, pIGD);
    end

    outFile = fullfile(DATA,'ablation_v8_degradation_1016.mat');
    save(outFile, 'R', 'benchmarks', 'algoDefs', 'metrics', 'NRUNS', 'N', 'BASE_SEED', 'rerunBi', 'REF_AI', 'stats', '-v7.3');
    fprintf('\n[saved] %s\n', outFile);
    try; delete(gcp); end
    fprintf('Done. load(''%s'') to inspect; stats holds the per-benchmark degradation of v8 vs original (%%) for the Supplementary Material.\n', outFile);
end
