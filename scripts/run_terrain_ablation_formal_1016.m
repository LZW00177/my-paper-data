function run_terrain_ablation_formal_1016(NUM_RUNS, MAX_ITER, ARCH_SIZE, doSave, PAIRED)
% run_terrain_ablation_formal_1016 - formal terrain variant ablation (response to R2-1:
% the combined benefit of the two modules must be demonstrated by an ablation in the terrain scenarios)
% Variant mapping (authoritative source: algoDefs in runMOAblation_all.m lines 24-32; identical to Table 9 / Section 3.2.1):
%   A = MOALA-A  useMemory=false, useTdist=false   neither module (original ALA within the Pareto framework)
%   B = MOALA-B  useMemory=true,  useTdist=false   dual-layer memory only
%   C = MOALA-C  useMemory=false, useTdist=true    adaptive t-distribution only
%   D = MOALA-D  useMemory=true,  useTdist=true    full MO-ALA (the main algorithm of the paper)
%   The mapping follows algoDefs; do not invert it.
%
% Configuration: POP=30, T_max=500, 30 runs.
%   ARCH (archive capacity): the MO-ALA variants must use N_arch = 50 (Section 3.2.2 / Table 9);
%     see the "MOALA archive capacity fixed at 50" notes in runOneTask.m:56 and rerun_terrain_runtime.m:87.
%     Only the baselines use 100. The default here is ARCH = 50, consistent with the main experiment.
%
% Statistical convention: identical to Table 10 of the paper ("paired tests over 30 runs") -
%   paired two-sided Wilcoxon signed-rank test (alpha = 0.05); the unpaired two-sided ranksum test is
%   reported alongside as a cross-check.
% PAIRED (seeds): true = all four variants share the same random seed (CRN, same seed per run index),
%   so the paired test is genuinely paired; false = the variant index enters the seed. Default true.
%
% Reference front (fixed / external): whenever available, the 30-run union of the five baselines
%   (NSGAII/MOPSO/EALA/IALA/HALA) from expResult.mat is used as a FIXED reference (same convention as
%   the main terrain tables) and both IGD and HV are computed against it, avoiding a self-referential
%   variant-union reference; if expResult.mat is missing the script falls back to the four-variant union.
% Output: data/terrain_ablation_formal_1016.mat (incrementally written after each scene x variant)
%   summ.sX_VAR : mean +/- std of HV, IGD, front size, the four J values and runtime
%   raw.sX_VAR  : per-run PF, bestF, runtime, HV and IGD (for post-hoc pairing and statistics)
%   wilc.sX     : HV tests of D against A/B/C (pPaired / pUnpaired / cliffDelta)
%
% Usage (default 30 runs, ARCH = 50, PAIRED = true):
%   from the package root:       matlab -batch "cd scripts; run_terrain_ablation_formal_1016(30, 500, 50, true)"
%   from the dev workspace root: matlab -batch "run_terrain_ablation_formal_1016(30, 500, 50, true)"
%   run_terrain_ablation_formal_1016(30, 500, 50, true, false)  % unpaired seeds
% =========================================================================
% REQUIRES CODE THAT IS NOT PART OF THIS PACKAGE (patent restriction)
%   This experiment runs the core MO-ALA implementation on the terrain problem
%   class; both are withheld together with the calling harness (runOneTask.m /
%   runMOAblation_all.m) as stated in the Data Availability Statement.  To
%   re-run it you must obtain from the corresponding author and place on the
%   MATLAB path:
%       MOALA.m         (the algorithm; also needs ALAOperators.m / ArchiveManager.m)
%       UAVMultiObj.m   (the terrain multi-objective problem class)
%   Everything else used here -- terrainGeneration.m, threatField.m and
%   MetricsCalculator.m -- is included in this package (code/).  The numerical
%   results are archived as data/terrain_ablation_formal_1016.mat (and the
%   N_arch = 100 capacity check as data/terrain_ablation_formal_1016_ARCH100_keep.mat)
%   and back Table 15 and Section 3.4; they can be audited without re-running.
% =========================================================================

if nargin<1 || isempty(NUM_RUNS);  NUM_RUNS  = 30;  end
if nargin<2 || isempty(MAX_ITER);  MAX_ITER  = 500; end
if nargin<3 || isempty(ARCH_SIZE); ARCH_SIZE = 50;  end
if nargin<4 || isempty(doSave);    doSave    = true;end
if nargin<5 || isempty(PAIRED);    PAIRED    = true;end

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
need = {'MOALA','UAVMultiObj'};
miss = need(cellfun(@(f) isempty(which(f)), need));
if ~isempty(miss)
    error([mfilename ':WithheldCode', ...
        'This script needs the withheld core implementation (%s). See the ' ...
        'header of this file and the Data Availability Statement; the archived ' ...
        'results are data/terrain_ablation_formal_1016.mat.'], strjoin(miss, ', '));
end

POP_SIZE  = 30;
HV_SAMPLE = 50000; HV_FLOOR = 1e-6;
ALPHA_WILC = 0.05;
SCENARIOS = {'mountain','landslide'};
variants  = {'A','B','C','D'};
useMem    = [false, true,  false, true ];   % A,B,C,D
useTd     = [false, false, true,  true ];   % A,B,C,D

fprintf('===== formal terrain variant ablation =====\n');
fprintf('  NUM_RUNS=%d  MAX_ITER=%d  POP=%d  ARCH=%d  PAIRED=%d\n', NUM_RUNS, MAX_ITER, POP_SIZE, ARCH_SIZE, PAIRED);
fprintf('  variants: A=neither  B=memory only  C=t-dist only  D=full (main algorithm)\n');

% ---- Parallel pool (optional; falls back to serial on failure) ----
usePar = false;
try
    if isempty(gcp('nocreate')); parpool('local', min(feature('numcores'),4)); end
    usePar = true;
    fprintf('  parallel pool enabled\n');
catch ME
    fprintf('  no parallel pool, running serially: %s\n', ME.message);
end

totalTic = tic;
raw = struct();

% ================= main loop: scene x variant (incremental checkpointing) =================
for s = 1:2
    fprintf('\n===== [%s] =====\n', SCENARIOS{s});
    for vi = 1:4
        vname = variants{vi};
        vt = tic;
        out = cell(1, NUM_RUNS);
        if usePar
            parfor r = 1:NUM_RUNS
                out{r} = terrainVariantTask(s, vi, r, useMem(vi), useTd(vi), POP_SIZE, MAX_ITER, ARCH_SIZE, PAIRED);
            end
        else
            for r = 1:NUM_RUNS
                out{r} = terrainVariantTask(s, vi, r, useMem(vi), useTd(vi), POP_SIZE, MAX_ITER, ARCH_SIZE, PAIRED);
            end
        end
        PFs = cell(1, NUM_RUNS); bestF = nan(NUM_RUNS,4); rts = nan(1,NUM_RUNS);
        for r = 1:NUM_RUNS
            PFs{r}   = out{r}.PF;
            bestF(r,:)= out{r}.bestF;
            rts(r)   = out{r}.runtime;
        end
        raw.(sprintf('s%d_%s', s, vname)) = struct('PFs',{PFs}, 'bestF',{bestF}, 'runtime',{rts}, ...
            'useMemory',{useMem(vi)}, 'useTdist',{useTd(vi)});
        fprintf('  variant %s done  (%.1f min, mean %.1f s/run)\n', vname, toc(vt)/60, mean(rts));
        if doSave
            try
                save(fullfile(DATA,'terrain_ablation_formal_1016.mat'), 'raw', ...
                    'NUM_RUNS','MAX_ITER','ARCH_SIZE','SCENARIOS','variants','useMem','useTd', '-v7.3');
                    fprintf('    [ckpt] incrementally saved\n');
            catch ME
                fprintf('    [ckpt] save failed: %s\n', ME.message);
            end
        end
    end
end

% ================= fixed external reference front (the five baselines from the archived terrain run) =================
refCellExt = {{}, {}};
haveExt = false;
% In the release package the archived baseline fronts are shipped as
% data/terrain_metrics.mat; in the development workspace the same archive is
% results/expResult.mat (bit-identical allFronts cells, verified front-by-front
% over all 2 scenarios x 6 algorithms x 30 runs = 360 cells).
expFile = fullfile(DATA,'terrain_metrics.mat');
if ~exist(expFile,'file'); expFile = fullfile(DATA,'expResult.mat'); end
if exist(expFile,'file')
    try
        S = load(expFile);
        baseAlgs = {'NSGAII','MOPSO','EALA','IALA','HALA'};
        if isfield(S,'results')
            for s = 1:2
                sc = sprintf('scene%d', s);
                if isfield(S.results, sc)
                    g = S.results.(sc);
                    for ai = 1:numel(baseAlgs)
                        a = baseAlgs{ai};
                        if isfield(g,a) && isfield(g.(a),'allFronts')
                            af = g.(a).allFronts;
                            for k = 1:numel(af)
                                if ~isempty(af{k}); refCellExt{s}{end+1} = af{k}; end
                            end
                        end
                    end
                end
            end
        end
        haveExt = ~isempty(refCellExt{1}) && ~isempty(refCellExt{2});
        fprintf('\nexternal reference: loaded the five-baseline front from expResult.mat (ext=%d/%d)\n', numel(refCellExt{1}), numel(refCellExt{2}));
    catch ME
        fprintf('\nexternal reference could not be loaded: %s\n', ME.message);
    end
else
    fprintf('\nexpResult.mat not found; the reference front falls back to the four-variant union\n');
end

% ================= metric computation =================
fprintf('\n===== results (fixed reference front) =====\n');
summ = struct();
wilc = struct();
for s = 1:2
    % variant union (fallback reference)
    varCell = {};
    for vi = 1:4
        rr = raw.(sprintf('s%d_%s', s, variants{vi}));
        for r = 1:NUM_RUNS; if ~isempty(rr.PFs{r}); varCell{end+1} = rr.PFs{r}; end; end
    end
    if haveExt
        refCell = refCellExt{s};  refTag = 'external(5 baselines@expResult)';
    else
        refCell = varCell;        refTag = 'variant-union(fallback)';
    end
    unionF  = vertcat(refCell{:});
    igdRef  = MetricsCalculator.filterNonDominated(unionF);
    hvRange = MetricsCalculator.estimateHVRefPoint(refCell);
    fprintf('\n[%s] reference front=%s  (%d points)\n', SCENARIOS{s}, refTag, size(igdRef,1));

    Hmat = nan(NUM_RUNS,4); Imat = nan(NUM_RUNS,4);
    for vi = 1:4
        vname = variants{vi};
        rr = raw.(sprintf('s%d_%s', s, vname));
        H=[]; I=[]; FS=[];
        for r = 1:NUM_RUNS
            PF = rr.PFs{r};
            if isempty(PF) || size(PF,1)<2
                H(end+1)=HV_FLOOR; I(end+1)=Inf; FS(end+1)=1000; continue;
            end
            Pc = MetricsCalculator.pruneOutliers(PF, 0.99);
            Pn = MetricsCalculator.normalizeFront(Pc, hvRange);
            H(end+1) = max(MetricsCalculator.HV(Pn, ones(1,size(PF,2)), HV_SAMPLE), HV_FLOOR);
            I(end+1) = MetricsCalculator.IGD(PF, igdRef);
            FS(end+1)= min(MetricsCalculator.Spacing(PF), 1000);
        end
        Hmat(:,vi)=H(:); Imat(:,vi)=I(:);
        B = rr.bestF;
        summ.(sprintf('s%d_%s', s, vname)) = struct( ...
            'HV',mean(H),'HVstd',std(H),'IGD',mean(I),'IGDstd',std(I), ...
            'FS',mean(FS),'J',mean(B,1,'omitnan'),'Jstd',std(B,1,'omitnan'),'runtime',mean(rr.runtime));
        fprintf('  %s: HV=%.4f+/-%.4f  IGD=%.3f+/-%.3f  front=%d  J1=%.2f J2=%.2f J3=%.2f J4=%.2f  t=%.1fs\n', ...
            vname, mean(H), std(H), mean(I), std(I), mean(FS), ...
            mean(B(:,1),'omitnan'), mean(B(:,2),'omitnan'), mean(B(:,3),'omitnan'), mean(B(:,4),'omitnan'), mean(rr.runtime));
    end

    % Statistics: HV comparison of D (full) against A/B/C
    %   primary convention = paired two-sided Wilcoxon signed-rank (alpha = 0.05), consistent with
    %   Table 10 ("paired tests"); the unpaired two-sided ranksum test is shown alongside as a cross-check.
    pP = zeros(1,3); sgP = cell(1,3); pU = zeros(1,3); sgU = cell(1,3); dCl = zeros(1,3);
    for j = 1:3
        x = Hmat(:,4); y = Hmat(:,j);           % D vs variant j
        [pP(j),~] = signrank(x, y, 'Alpha', ALPHA_WILC);            % paired, two-sided
        [pU(j),~] = ranksum(x, y, 'Alpha', ALPHA_WILC, 'Tail','both'); % unpaired, two-sided
        sgP{j} = iff(pP(j)<ALPHA_WILC, iff(mean(x)>mean(y),'D better','D worse'), 'n.s.');
        sgU{j} = iff(pU(j)<ALPHA_WILC, iff(mean(x)>mean(y),'D better','D worse'), 'n.s.');
        dCl(j) = cliffDelta(x, y);              % P(D>v)-P(D<v); >0 means D has the better HV
        fprintf('  D vs %s : HV paired p=%.4f (%s) | unpaired p=%.4f (%s) | Cliff d=%+.3f\n', ...
            variants{j}, pP(j), sgP{j}, pU(j), sgU{j}, dCl(j));
    end
    wilc.(sprintf('s%d',s)) = struct('pPaired',{pP},'sigPaired',{sgP}, ...
                                     'pUnpaired',{pU},'sigUnpaired',{sgU},'cliffDelta',{dCl},'cmp',{{'A','B','C'}});
    rawH.(sprintf('s%d',s)) = Hmat; rawI.(sprintf('s%d',s)) = Imat;
end
fprintf('\ntotal elapsed: %.1f min\n', toc(totalTic)/60);

if doSave
    try
        save(fullfile(DATA,'terrain_ablation_formal_1016.mat'), 'summ','raw','rawH','rawI','wilc', ...
            'NUM_RUNS','MAX_ITER','ARCH_SIZE','PAIRED','SCENARIOS','variants','useMem','useTd','haveExt','refTag', '-v7.3');
        fprintf('saved %s\n', fullfile(DATA,'terrain_ablation_formal_1016.mat'));
    catch ME
        fprintf('final save failed: %s\n', ME.message);
    end
end
if usePar; try; delete(gcp('nocreate')); catch; end; end
end


% ================= subfunction: one run (executable on a parfor worker) =================
function R = terrainVariantTask(sceneIdx, vi, r, useM, useT, POP_SIZE, MAX_ITER, ARCH_SIZE, PAIRED)
    % Keep the path self-contained on parallel workers (addpath prepends, avoiding shadowing)
    % Layout: package code/ (release) or the development workspace root.
    pp = fileparts(mfilename('fullpath'));
    ppRoot = fileparts(pp);
    pCODE = fullfile(ppRoot,'code');
    if ~exist(pCODE,'dir'); pCODE = pp; end
    addpath(pCODE);
    for sub = {'algorithms','metrics','terrain'}
        d = fullfile(pCODE, sub{1});
        if exist(d,'dir'); addpath(d); end
    end
    % Rebuild terrain and problem exactly as runOneTask.m does (independent worker reproducibility)
    if sceneIdx == 1
        rng(2026 + 1*100);
        terrain = terrainGeneration([100,100],'scenario','mountain','minH',40,'maxH',120);
        prob = UAVMultiObj(terrain, threatField('mountain'));
        prob.startPoint=[5,5,50]; prob.endPoint=[95,95,50]; prob.numWaypoints=20;
    else
        rng(2026 + 2*100);
        terrain = terrainGeneration([100,100],'scenario','landslide','minH',40,'maxH',120);
        prob = UAVMultiObj(terrain, threatField('landslide'));
        prob.startPoint=[10,90,50]; prob.endPoint=[90,10,50]; prob.numWaypoints=20;
    end
    D = prob.dim; lb = prob.lb; ub = prob.ub;

    % Seeds: PAIRED=true -> all four variants share one seed (CRN, varies only with scene/run),
    %        so the paired test is valid; PAIRED=false -> the variant index enters the seed.
    if PAIRED
        seedBase = 2026 + sceneIdx*10*10000 + r*1000;
    else
        seedBase = 2026 + (sceneIdx*10 + vi)*10000 + r*1000;
    end
    rng(seedBase);
    o.N=POP_SIZE; o.T_max=MAX_ITER; o.D=D; o.lb=lb; o.ub=ub;
    o.N_arch=ARCH_SIZE; o.nu_max=20; o.nu_min=2;
    o.useMemory=useM; o.useTdist=useT;
    o.searchMode='original'; o.p_mix=0.5; o.distScale=0.02;
    algObj = MOALA(o);
    t0 = tic;
    [arch, ~] = algObj.optimize(prob, 'verbose', false);
    rt = toc(t0);
    F = arch.objectives;
    Fnd = MetricsCalculator.filterNonDominated(F);
    if isempty(Fnd); Fnd = zeros(0,4); end
    if ~isempty(Fnd)
        bestF = [min(Fnd(:,1)),min(Fnd(:,2)),min(Fnd(:,3)),min(Fnd(:,4))];
    else
        bestF = [inf inf inf inf];
    end
    R = struct('PF', Fnd, 'bestF', bestF, 'runtime', rt);
end


function s = iff(c,t,f); if c; s=t; else; s=f; end; end

function d = cliffDelta(x, y)
    % Cliff's delta = P(x>y) - P(x<y) (non-parametric effect size for independent samples)
    x = x(:); y = y(:); x = x(~isnan(x)); y = y(~isnan(y));
    if isempty(x) || isempty(y); d = NaN; return; end
    gt = sum(sum(x > y.')); lt = sum(sum(x < y.'));
    d = (gt - lt) / (numel(x)*numel(y));
end
