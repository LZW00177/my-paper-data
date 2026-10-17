function rerun_Gschedule_1016(varargin)
% =========================================================================
% rerun_Gschedule_1016 — G(t) amplitude-envelope schedule ablation (item E5)
%
% WHY THIS EXPERIMENT EXISTS
%   Reviewer 4's central objection is that the linearly decaying amplitude
%   envelope G(t) = 2(1 - t/Tmax) is "artificial damping" that may be masking
%   oscillation (chattering) rather than removing it, and that the adaptive
%   t-distribution is therefore an "artificial freezing" of the search.
%   The manuscript currently answers this by argument only.  This ablation
%   turns the objection into evidence by varying the ONE quantity at issue —
%   the envelope G(t) — while holding everything else (memory layer, t-tail
%   schedule, archive, population, budget, seeds) exactly fixed.
%
%   Three arms of the same algorithm (all = full MO-ALA, i.e. variant D):
%     'linear' : G(t) = 2(1 - t/(Tmax-1))                  (the paper's rule)
%     'const'  : G(t) = 2                                  (no damping at all)
%     'floor'  : G(t) = 2(1 - 0.9 t/(Tmax-1))              (decays to 0.2, never 0)
%
%   Reading of the results:
%     * if 'const'/'floor' restore DTLZ1/DTLZ3 convergence but degrade the
%       non-deceptive ZDT/DTLZ2 fronts, the envelope is a trade-off rather
%       than a defect, and the contribution can be stated as such;
%     * if they are better everywhere, the envelope should be relaxed and the
%       manuscript must say so;
%     * if they are worse everywhere, the envelope is simply beneficial and
%       R4's charge is answered directly.
%   All three outcomes are publishable; the experiment cannot "backfire" the
%   way a claim can.
%
% PROTOCOL (identical to the other revision experiments, so numbers are
% directly comparable with Table 9 / Supplementary S2):
%   N = 30, Tmax = 500, dim = 10, Narch = 50, 30 runs,
%   seed = BASE_SEED + 4000*bi + 100*REF_AI + r   with REF_AI = 4.
%   Because REF_AI is the SAME for the three arms, the three arms share the
%   random stream run-by-run (true common random numbers): the only thing
%   that differs is G(t).  It also makes arm 'linear' seed-wise identical to
%   the MOALA-D(original) column of results/ablation_v8_degradation_1016.mat,
%   which the script cross-checks automatically when that file is present.
%
% COST (measured on this machine, MO-ALA D, N=30, single run, single thread):
%   ZDT2 T=500 = 7.1 s | DTLZ2 T=500 = 5.8 s | DTLZ1 T=500 = 5.5 s | DTLZ1 T=2000 = 17.6 s
%   Default run (6 benchmarks @ T=500 x 3 arms x 30 runs = 540 runs)
%     ~= 55-65 min of single-thread CPU  ->  ~12-20 min wall with parpool(5)
%     ->  ~1.0-1.2 h wall if the pool cannot be started (serial fallback)
%   Adding 'DTLZ13_T2000', true (+2 benchmarks x 3 arms x 30 runs = 180 runs
%     at 17.6 s) costs a further ~53 min CPU (~11-15 min wall on 5 workers).
%
% OUTPUT
%   data/g_schedule_ablation_1016.mat
%     R{arm, bench} : NRUNS x 4 = [HV IGD Spacing frontSize]
%     stats(bi)     : paired Wilcoxon (const vs linear, floor vs linear) and
%                     Cliff's delta / relative changes, per benchmark
%     provenance    : protocol struct (N, TMAX, NRUNS, BASE_SEED, REF_AI, gMode list)
%   logs/g_schedule_ablation_1016.txt : the same numbers, human readable
%
% USAGE
%   from the package root:       matlab -batch "cd scripts; rerun_Gschedule_1016"
%   from the dev workspace root: matlab -batch "rerun_Gschedule_1016"
%   matlab -batch "rerun_Gschedule_1016('FORCE',true)"          % ignore checkpoint
%   matlab -batch "rerun_Gschedule_1016('DTLZ13_T2000',true)"   % add T=2000 DTLZ1/3
% =========================================================================
% REQUIRES CODE THAT IS NOT PART OF THIS PACKAGE (patent restriction)
%   This experiment runs the core MO-ALA implementation on the six paper
%   benchmarks through the per-task runner ablationWorker.m; both are withheld
%   together with the calling harness as stated in the Data Availability
%   Statement.  To re-run it you must obtain from the corresponding author and
%   place on the MATLAB path:
%       MOALA.m          (the algorithm; also needs ALAOperators.m / ArchiveManager.m)
%       ZDTProblem.m     (the ZDT1-3 benchmark definitions)
%       DTLZProblem.m    (the DTLZ1-3 benchmark definitions)
%       ablationWorker.m (the per-task runner used by the parfor loop)
%   MetricsCalculator.m is included in this package (code/).  The numerical
%   results are archived as data/g_schedule_ablation_1016.mat with the
%   human-readable report in logs/g_schedule_ablation_1016.txt; they can be
%   audited without re-running.
% =========================================================================
    BASE_SEED = 20260812;
    NRUNS = 30; N = 30; DIM = 10; TMAX = 500;
    REF_AI = 4;                 % MOALA-D slot: same stream for all three arms (CRN)
    FORCE = false; ADD_T2000 = false;
    for i = 1:2:length(varargin)
        if strcmpi(varargin{i},'NRUNS');        NRUNS = varargin{i+1};
        elseif strcmpi(varargin{i},'N');        N = varargin{i+1};
        elseif strcmpi(varargin{i},'FORCE');    FORCE = varargin{i+1};
        elseif strcmpi(varargin{i},'DTLZ13_T2000'); ADD_T2000 = varargin{i+1};
        end
    end

    % Dual-layout resolution: the shipped package keeps data in data/, the
    % human-readable report in logs/ and the helper modules in code/; the
    % development workspace kept everything at the repository root.
    base    = fileparts(mfilename('fullpath'));   % .../scripts  or <dev workspace>
    pkgRoot = fileparts(base);                    % package root when run from .../scripts
    DATA = fullfile(pkgRoot,'data');
    if ~exist(DATA,'dir'); DATA = fullfile(base,'results'); end          % development layout
    LOGS = fullfile(pkgRoot,'logs');
    if ~exist(LOGS,'dir'); LOGS = DATA; end                               % development layout
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
    need = {'MOALA','ZDTProblem','DTLZProblem','ablationWorker'};
    miss = need(cellfun(@(f) isempty(which(f)), need));
    if ~isempty(miss)
        error([mfilename ':WithheldCode', ...
            'This script needs the withheld core implementation (%s). See the ' ...
            'header of this file and the Data Availability Statement; the archived ' ...
            'result is data/g_schedule_ablation_1016.mat.'], strjoin(miss, ', '));
    end

    % ---- benchmarks: the same six, at the same budget, as the v8 ablation ----
    benchmarks = {
        struct('name','ZDT1',  'type','ZDT', 'id',1,'TMAX',TMAX);
        struct('name','ZDT2',  'type','ZDT', 'id',2,'TMAX',TMAX);
        struct('name','ZDT3',  'type','ZDT', 'id',3,'TMAX',TMAX);
        struct('name','DTLZ1', 'type','DTLZ','id',1,'TMAX',TMAX);
        struct('name','DTLZ2', 'type','DTLZ','id',2,'TMAX',TMAX);
        struct('name','DTLZ3', 'type','DTLZ','id',3,'TMAX',TMAX);
    };
    if ADD_T2000
        benchmarks{end+1} = struct('name','DTLZ1_T2000', 'type','DTLZ','id',1,'TMAX',2000);
        benchmarks{end+1} = struct('name','DTLZ3_T2000', 'type','DTLZ','id',3,'TMAX',2000);
    end
    nB = numel(benchmarks);

    % ---- three arms of the SAME algorithm; only gMode differs ----
    arms = {
        'linear', struct('useMemory',true,'useTdist',true,'searchMode','original','gMode','linear');
        'const',  struct('useMemory',true,'useTdist',true,'searchMode','original','gMode','const');
        'floor',  struct('useMemory',true,'useTdist',true,'searchMode','original','gMode','floor');
        };
    nA = size(arms,1);
    metrics = {'HV','IGD','Spacing','frontSize'};

    R = cell(nA, nB);
    for a = 1:nA; for bi = 1:nB; R{a,bi} = nan(NRUNS,4); end; end

    % ---- checkpoint / resume ----
    ckptFile = fullfile(DATA,'ckpt_g_schedule_1016.mat');
    doneFlags = false(nA, nB);
    if exist(ckptFile,'file') && ~FORCE
        C = load(ckptFile,'R','doneFlags','ckNRUNS');
        if size(C.R,1) == nA && size(C.R,2) == nB && isfield(C,'ckNRUNS') && C.ckNRUNS == NRUNS
            R = C.R; doneFlags = C.doneFlags;
            fprintf('[checkpoint] skipping %d already-finished (arm,benchmark) cells\n', sum(doneFlags(:)));
        else
            fprintf('[checkpoint] shape or NRUNS mismatch (old run used different settings) - starting fresh\n');
        end
    elseif exist(ckptFile,'file') && FORCE
        fprintf('[FORCE] ignoring the existing checkpoint, recomputing everything\n');
    end

    try
        oldp = gcp('nocreate'); if ~isempty(oldp); delete(oldp); end
        parpool('local', min(feature('numcores'), 5));
    catch ME
        warning('parpool failed (%s); falling back to a serial loop', ME.message);
    end

    fprintf('\n=== G(t) schedule ablation | 3 arms x %d benchmarks x %d runs ===\n', nB, NRUNS);

    for bi = 1:nB
        bm = benchmarks{bi};
        fprintf('\n--- %s (bi=%d, TMAX=%d) ---\n', bm.name, bi, bm.TMAX);
        for a = 1:nA
            if doneFlags(a,bi)
                fprintf('   skip %-7s (already done)\n', arms{a,1});
                continue;
            end
            gname = arms{a,1}; opts = arms{a,2};
            t0 = tic;
            tmp = nan(NRUNS,4);
            parfor r = 1:NRUNS
                seed = BASE_SEED + 4000*bi + 100*REF_AI + r;
                tmp(r,:) = ablationWorker(bm.type, bm.id, DIM, 'MOALA', opts, N, bm.TMAX, seed);
            end
            R{a,bi} = tmp;
            fprintf('   %-7s done in %5.0fs | HV=%.4f IGD=%.6f Sp=%.4f n=%.0f\n', ...
                gname, toc(t0), nanmean(tmp(:,1)), nanmean(tmp(:,2)), nanmean(tmp(:,3)), nanmean(tmp(:,4)));
            doneFlags(a,bi) = true;
            ckNRUNS = NRUNS;
            save(ckptFile,'R','doneFlags','ckNRUNS','-v7.3');
        end
    end

    % ---- paired statistics: each non-default arm vs the paper's 'linear' arm ----
    fprintf('\n=== paired Wilcoxon (common random numbers) + Cliff''s delta ===\n');
    stats = struct();
    for bi = 1:nB
        bm = benchmarks{bi};
        lin = R{1,bi};
        stats(bi).name = bm.name;
        stats(bi).TMAX = bm.TMAX;
        stats(bi).HV_mean  = nan(1,nA);
        stats(bi).IGD_mean = nan(1,nA);
        for a = 1:nA
            stats(bi).HV_mean(a)  = nanmean(R{a,bi}(:,1));
            stats(bi).IGD_mean(a) = nanmean(R{a,bi}(:,2));
        end
        fprintf('[%s] HV : linear=%.4f const=%.4f floor=%.4f\n', ...
            bm.name, stats(bi).HV_mean(1), stats(bi).HV_mean(2), stats(bi).HV_mean(3));
        fprintf('[%s] IGD: linear=%.5f const=%.5f floor=%.5f\n', ...
            bm.name, stats(bi).IGD_mean(1), stats(bi).IGD_mean(2), stats(bi).IGD_mean(3));
        for a = 2:nA
            tag = arms{a,1};
            % HV larger is better; IGD smaller is better. Two-sided signed rank, 30 paired runs.
            [pHV , hHV ] = signrank(lin(:,1), R{a,bi}(:,1), 'alpha', 0.05);
            [pIGD, hIGD] = signrank(lin(:,2), R{a,bi}(:,2), 'alpha', 0.05);
            dHV  = (nanmean(R{a,bi}(:,1)) - nanmean(lin(:,1))) / nanmean(lin(:,1)) * 100;
            dIGD = (nanmean(R{a,bi}(:,2)) - nanmean(lin(:,2))) / nanmean(lin(:,2)) * 100;
            stats(bi).(tag) = struct( ...
                'HV_relPct',  dHV,  'IGD_relPct', dIGD, ...
                'wilcoxHV_p', pHV,  'wilcoxHV_h', hHV, ...
                'wilcoxIGD_p',pIGD, 'wilcoxIGD_h',hIGD, ...
                'cliffHV',    cliffsDelta(R{a,bi}(:,1), lin(:,1)), ...
                'cliffIGD',   cliffsDelta(R{a,bi}(:,2), lin(:,2)));
            fprintf('   %-6s vs linear: dHV=%+7.2f%% (p=%.3g%s)  dIGD=%+8.2f%% (p=%.3g%s)  Cliff dHV=%+.2f\n', ...
                tag, dHV, pHV, ternary(hHV,' *',''), dIGD, pIGD, ternary(hIGD,' *',''), stats(bi).(tag).cliffHV);
        end
    end

    % ---- optional cross-check against the archived v8 ablation (same seeds, arm 'linear') ----
    v8file = fullfile(DATA,'ablation_v8_degradation_1016.mat');
    if exist(v8file,'file')
        try
            V = load(v8file,'R','benchmarks');
            fprintf('\n=== seed-identity cross-check vs ablation_v8_degradation_1016 (MOALA-D original column) ===\n');
            for bi = 1:min(6,nB)
                ref = V.R{bi,1};                       % MATLAB cell: {benchmark, arm1} = MOALA-D, original operator
                got = R{1,bi};                         % this script's arm 1 = 'linear'
                m = min(size(ref,1), size(got,1));
                dH = max(abs(ref(1:m,1) - got(1:m,1)));
                dI = max(abs(ref(1:m,2) - got(1:m,2)));
                fprintf('  %-6s runs compared=%2d | max|dHV|=%.3g  max|dIGD|=%.3g\n', ...
                    benchmarks{bi}.name, m, dH, dI);
            end
            fprintf('  NOTE: exact identity is expected only when NRUNS=30, since the archived run used the same\n');
            fprintf('        seed rule and budget; a non-zero difference at NRUNS=30 means the code path changed.\n');
        catch ME
            warning('cross-check skipped: %s', ME.message);
        end
    end

    provenance = struct('N',N,'TMAX',TMAX,'NRUNS',NRUNS,'DIM',DIM, ...
        'BASE_SEED',BASE_SEED,'REF_AI',REF_AI, ...
        'seedRule','BASE_SEED + 4000*bi + 100*REF_AI + r, r=1..NRUNS (identical across arms: CRN)', ...
        'gModes',{{arms{:,1}}}, 'addedT2000',ADD_T2000);

    outMat = fullfile(DATA,'g_schedule_ablation_1016.mat');
    outTxt = fullfile(LOGS,'g_schedule_ablation_1016.txt');
    save(outMat,'R','benchmarks','arms','metrics','stats','provenance','-v7.3');
    fprintf('\n[saved] %s\n', outMat);

    writeSummary(outTxt, benchmarks, stats, provenance);
    fprintf('[saved] %s\n', outTxt);

    try; delete(gcp); end
    fprintf('done.\n');
end

% ------------------------------------------------------------------------
function d = cliffsDelta(a, b)
% Cliff's delta effect size between two samples (a vs b).
% d > 0 means a tends to be larger than b; |d| ~ 0.147 small, 0.33 medium, 0.474 large.
    a = a(~isnan(a)); b = b(~isnan(b));
    if isempty(a) || isempty(b); d = NaN; return; end
    gt = 0; lt = 0;
    for i = 1:numel(a)
        gt = gt + sum(a(i) > b);
        lt = lt + sum(a(i) < b);
    end
    d = (gt - lt) / (numel(a) * numel(b));
end

function s = ternary(c, yes, no)
    if c; s = yes; else; s = no; end
end

function writeSummary(fname, benchmarks, stats, pv)
    fid = fopen(fname,'w');
    if fid < 0; warning('cannot write %s', fname); return; end
    fprintf(fid, 'G(t) schedule ablation — summary\n');
    fprintf(fid, 'N=%d, Tmax=%d, dim=%d, runs=%d, BASE_SEED=%d, REF_AI=%d\n', ...
        pv.N, pv.TMAX, pv.DIM, pv.NRUNS, pv.BASE_SEED, pv.REF_AI);
    fprintf(fid, 'seed rule: %s\n', pv.seedRule);
    fprintf(fid, 'arms (all = full MO-ALA / variant D; only the envelope differs): %s\n', strjoin(pv.gModes,', '));
    fprintf(fid, '\narm definitions\n');
    fprintf(fid, '  linear : G(t) = 2(1 - t/(Tmax-1))        [the rule used in the manuscript]\n');
    fprintf(fid, '  const  : G(t) = 2                        [no damping]\n');
    fprintf(fid, '  floor  : G(t) = 2(1 - 0.9 t/(Tmax-1))    [decays to 0.2, never 0]\n');
    for bi = 1:numel(stats)
        s = stats(bi);
        fprintf(fid, '\n== %s (Tmax=%d) ==\n', s.name, s.TMAX);
        fprintf(fid, '  mean HV : linear=%.4f  const=%.4f  floor=%.4f\n', s.HV_mean(1), s.HV_mean(2), s.HV_mean(3));
        fprintf(fid, '  mean IGD: linear=%.6f const=%.6f floor=%.6f\n', s.IGD_mean(1), s.IGD_mean(2), s.IGD_mean(3));
        tags = fieldnames(s);
        for k = 1:numel(tags)
            t = tags{k};
            if any(strcmp(t, {'name','TMAX','HV_mean','IGD_mean'})); continue; end
            d = s.(t);
            fprintf(fid, '  %-6s vs linear: dHV=%+7.2f%% (p=%.3g, h=%d)  dIGD=%+8.2f%% (p=%.3g, h=%d)  CliffHV=%+.3f CliffIGD=%+.3f\n', ...
                t, d.HV_relPct, d.wilcoxHV_p, d.wilcoxHV_h, d.IGD_relPct, d.wilcoxIGD_p, d.wilcoxIGD_h, d.cliffHV, d.cliffIGD);
        end
    end
    fprintf(fid, '\nInterpretation: HV larger is better, IGD smaller is better. dHV>0 / dIGD<0 means the\narm improves on the manuscript rule. Paired two-sided Wilcoxon over %d common-random-number runs.\n', pv.NRUNS);
    fclose(fid);
end
