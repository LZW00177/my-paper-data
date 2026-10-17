function audit_hv_reference_robustness_1016(varargin)
% =========================================================================
% audit_hv_reference_robustness_1016 — offline robustness audit of the terrain
% ablation statistics (audit item E3).  Nothing is re-optimised; only archived
% fronts are re-scored.
%
% WHY THIS EXISTS
%   The terrain ablation (results/terrain_ablation_formal_1016.mat, campaign log
%   _formal_ablation_ARCH50_log.txt) reported D vs A hypervolume p = 0.0472 on
%   mountain and p = 0.0449 on debris flow, and the manuscript section 3.4 rests
%   on those two numbers.  Two things are wrong with taking them at face value:
%
%   Q1  reference-definition sensitivity.  The HV reference enters only through
%       the normalisation box used by MetricsCalculator.normalizeFront
%       (box.max = per-objective max of the pooled reference fronts x 1.05,
%        box.min = 0).  Nothing in the paper justifies that particular box over
%       its neighbours, and on these terrains the box is ~1e3 times the feasible
%       range of J1, so the choice is not obviously harmless.  Four boxes are
%       compared:
%         R1 baselineUnion : pooled 30-run fronts of the five baselines (published)
%         R2 allUnion      : R1 pooled together with the four MO-ALA variants
%         R3 loose110      : R1 box x 1.10   (generous)
%         R4 tight090      : R1 box x 0.90   (strict)
%
%   Q2  Monte-Carlo error of the estimator itself.  MetricsCalculator.HV draws
%       50 000 uniform samples and does not seed the generator, so a single call
%       carries sampling noise, and a reported p-value is therefore a random
%       variable.  Here every cell is scored K times with independent sample sets
%       (seeded by (repetition, run) only — common random numbers across the four
%       variants at a given run), and each contrast is reported BOTH as the
%       distribution of p over the K independent draws AND as the value obtained
%       from the K-averaged HV (which is the lowest-noise estimate available from
%       the archived fronts).  The distribution is the honest uncertainty on the
%       p-value that the original single-draw campaign printed.
%
%   IGD is computed against the reference *front* (non-dominated filter of the
%   baseline union), is box-independent and contains no sampling noise, so it is
%   recomputed here as a deterministic control.
%
%   All SIX pairwise contrasts among A, B, C, D are reported, not just D vs A:
%   the ablation's substantive question is which module drives the terrain
%   result, and that question is answered by A vs B and A vs C, not by D vs A.
%   Reporting every pair removes any suspicion of selective reporting.
%
%   Pair labels:  A vs B = memory effect,      A vs C = t-distribution effect,
%                 A vs D = joint effect,       B vs D = t added to memory,
%                 C vs D = memory added to t,  B vs C = memory vs t.
%   Sign convention: Cliff's d > 0 means the FIRST-named variant tends larger.
%   For HV (larger better) positive d favours the first; for IGD (smaller
%   better) negative d favours the first.
%
% USAGE
%   audit_hv_reference_robustness_1016                       % K=5, four references
%   audit_hv_reference_robustness_1016('K',20,'REFS',{'R1_baselineUnion'})
%
% OUTPUT
%   data/hv_reference_robustness_1016.mat   (numerical archive)
%   logs/hv_reference_robustness_1016.txt   (human-readable report)
% =========================================================================
    NUM_RUNS_DEF = 30; K = 5; HV_SAMPLE = 50000; HV_FLOOR = 1e-6;
    ALPHA = 0.05; SEED_BASE = 772100;
    SCENARIOS = {'mountain','landslide'};
    variants  = {'A','B','C','D'};
    baseAlgs  = {'NSGAII','MOPSO','EALA','IALA','HALA'};
    ALLREFS   = {'R1_baselineUnion','R2_allUnion','R3_loose110','R4_tight090'};
    refNames  = ALLREFS;
    PAIRS     = [1 2; 1 3; 1 4; 2 4; 3 4; 2 3];
    PAIRLAB   = {'A vs B','A vs C','A vs D','B vs D','C vs D','B vs C'};
    for i = 1:2:numel(varargin)
        if strcmpi(varargin{i},'K');    K = varargin{i+1};
        elseif strcmpi(varargin{i},'REFS'); refNames = varargin{i+1};
        end
    end

    % Dual-layout resolution: run either from the release package
    % (<pkg>/scripts/) or from the development workspace (repository root).
    base    = fileparts(mfilename('fullpath'));   % .../scripts  or <dev workspace>
    pkgRoot = fileparts(base);                    % package root when run from .../scripts
    DATA = fullfile(pkgRoot,'data');
    if ~exist(DATA,'dir'); DATA = fullfile(base,'results'); end          % development layout
    CODE = fullfile(pkgRoot,'code');
    if ~exist(CODE,'dir'); CODE = base; end                               % development layout
    LOGS = fullfile(pkgRoot,'logs');
    if ~exist(LOGS,'dir'); LOGS = DATA; end                               % development layout
    addpath(CODE);
    for sub = {'algorithms','metrics','terrain'}
        d = fullfile(CODE, sub{1});
        if exist(d,'dir'); addpath(d); end
    end
    rehash;

    A = load(fullfile(DATA,'terrain_ablation_formal_1016.mat'));
    % Archived baseline fronts.  In the release package these are shipped as
    % data/terrain_metrics.mat; in the development workspace the same archive
    % is results/expResult.mat.  The two files hold bit-identical allFronts
    % cells (verified front-by-front over all 2 scenarios x 6 algorithms x
    % 30 runs = 360 cells), so either source gives the same numbers.
    FP = fullfile(DATA,'terrain_metrics.mat');
    if ~exist(FP,'file'); FP = fullfile(DATA,'expResult.mat'); end
    if ~exist(FP,'file'); error('archived terrain fronts not found: %s', FP); end
    S = load(FP);
    raw = A.raw;
    NUM_RUNS = double(A.NUM_RUNS); if isempty(NUM_RUNS); NUM_RUNS = NUM_RUNS_DEF; end

    o = struct(); o.NUM_RUNS = NUM_RUNS; o.K = K; o.HV_SAMPLE = HV_SAMPLE;
    o.SEED_BASE = SEED_BASE; o.refNames = refNames; o.variants = variants;
    o.SCENARIOS = SCENARIOS; o.PAIRLAB = PAIRLAB; o.PAIRS = PAIRS;

    for s = 1:2
        sc = sprintf('scene%d', s);
        % ---- pooled baseline fronts (expResult.mat) ----
        baseCell = {};
        for ai = 1:numel(baseAlgs)
            a = baseAlgs{ai};
            if isfield(S.results.(sc), a) && isfield(S.results.(sc).(a),'allFronts')
                af = S.results.(sc).(a).allFronts;
                for k = 1:numel(af); if ~isempty(af{k}); baseCell{end+1} = af{k}; end; end
            end
        end
        % ---- pooled variant fronts (this ablation) ----
        varCell = {};
        for vi = 1:numel(variants)
            rr = raw.(sprintf('s%d_%s', s, variants{vi}));
            for r = 1:NUM_RUNS; if ~isempty(rr.PFs{r}); varCell{end+1} = rr.PFs{r}; end; end
        end

        boxB = MetricsCalculator.estimateHVRefPoint(baseCell).max;
        boxA = MetricsCalculator.estimateHVRefPoint([baseCell, varCell]).max;
        boxes = { boxB, boxA, boxB*1.10, boxB*0.90 };
        igdRef = MetricsCalculator.filterNonDominated(vertcat(baseCell{:}));
        o.(sprintf('nIGDref_scene%d', s)) = size(igdRef,1);

        % ---- IGD (deterministic control), all six contrasts ----
        Imat = nan(NUM_RUNS, numel(variants));
        for vi = 1:numel(variants)
            for r = 1:NUM_RUNS
                PF = raw.(sprintf('s%d_%s', s, variants{vi})).PFs{r};
                if isempty(PF) || size(PF,1) < 2; Imat(r,vi) = Inf; continue; end
                Imat(r,vi) = MetricsCalculator.IGD(PF, igdRef);
            end
        end
        pI = nan(1,6); sgI = cell(1,6); dI = nan(1,6);
        for q = 1:6
            [pI(q), sgI{q}, dI(q)] = pair_test(Imat, PAIRS(q,1), PAIRS(q,2), ALPHA, 'smaller', variants);
        end
        o.(sprintf('IGDmean_scene%d', s))  = mean(Imat,1,'omitnan');
        o.(sprintf('IGDp_scene%d', s))     = pI;
        o.(sprintf('IGDsig_scene%d', s))   = sgI;
        o.(sprintf('IGDd_scene%d', s))     = dI;

        % ---- HV under the selected boxes, K repetitions, all six contrasts ----
        for ri = 1:numel(refNames)
            rIdx = find(strcmp(ALLREFS, refNames{ri}), 1);
            box = boxes{rIdx};
            o.(sprintf('box_%s_scene%d', refNames{ri}, s)) = box;
            H = nan(NUM_RUNS, numel(variants), K);
            for k = 1:K
                for r = 1:NUM_RUNS
                    rng(SEED_BASE + k*10000 + r);   % identical samples for all four variants at this run
                    for vi = 1:numel(variants)
                        PF = raw.(sprintf('s%d_%s', s, variants{vi})).PFs{r};
                        if isempty(PF) || size(PF,1) < 2; H(r,vi,k) = HV_FLOOR; continue; end
                        Pc = MetricsCalculator.pruneOutliers(PF, 0.99);
                        Pn = MetricsCalculator.normalizeFront(Pc, struct('min',0,'max',box));
                        H(r,vi,k) = max(MetricsCalculator.HV(Pn, ones(1,size(PF,2)), HV_SAMPLE), HV_FLOOR);
                    end
                end
            end
            % p-value distribution over the K independent Monte-Carlo draws
            Pk = nan(K,6);
            for k = 1:K
                for q = 1:6
                    Pk(k,q) = pair_test(H(:,:,k), PAIRS(q,1), PAIRS(q,2), ALPHA, 'larger', variants);
                end
            end
            % K-averaged HV (lowest-noise estimate from the archived fronts)
            pK = nan(1,6); sgK = cell(1,6); dK = nan(1,6);
            for q = 1:6
                [pK(q), sgK{q}, dK(q)] = pair_test(mean(H,3), PAIRS(q,1), PAIRS(q,2), ALPHA, 'larger', variants);
            end
            o.(sprintf('HVmean_%s_scene%d', refNames{ri}, s)) = mean(mean(H,3),1);
            o.(sprintf('MCsd_%s_scene%d',   refNames{ri}, s)) = mean(std(H,0,3),1);
            o.(sprintf('HVpDist_%s_scene%d', refNames{ri}, s)) = Pk;      % K x 6
            o.(sprintf('HVpK_%s_scene%d',    refNames{ri}, s)) = pK;      % 1 x 6
            o.(sprintf('HVsigK_%s_scene%d',  refNames{ri}, s)) = sgK;
            o.(sprintf('HVdK_%s_scene%d',    refNames{ri}, s)) = dK;
        end
    end

    outFile = fullfile(DATA,'hv_reference_robustness_1016.mat');
    save(outFile,'-struct','o','-v7.3');
    fprintf('[saved] %s\n', outFile);
    writeTxt(fullfile(LOGS,'hv_reference_robustness_1016.txt'), o);
    printConsole(o);
end

% ------------------------------------------------------------------------
function [p, sg, d] = pair_test(M, i, j, ALPHA, direction, variants)
% Paired Wilcoxon of column i against column j of M, plus Cliff's delta.
% d > 0 means column i tends larger than column j.
    p = NaN; sg = 'n/a'; d = NaN;
    x = M(:,i); y = M(:,j);
    ok = ~isnan(x) & ~isnan(y) & ~isinf(x) & ~isinf(y);
    if nnz(ok) < 3; return; end
    xx = x(ok); yy = y(ok);
    [p,~] = signrank(xx, yy, 'Alpha', ALPHA);
    gt = 0; lt = 0;
    for t = 1:numel(xx); gt = gt + sum(xx(t) > yy); lt = lt + sum(xx(t) < yy); end
    d = (gt - lt) / (numel(xx) * numel(yy));
    if p < ALPHA
        if strcmp(direction,'larger'); better = mean(xx) > mean(yy); else; better = mean(xx) < mean(yy); end
        if better; sg = [variants{i} ' better']; else; sg = [variants{i} ' WORSE']; end
    else
        sg = 'n.s.';
    end
end

% ------------------------------------------------------------------------
function writeTxt(fname, o)
    fid = fopen(fname,'w'); if fid < 0; warning('cannot write %s', fname); return; end
    fprintf(fid,'Terrain ablation robustness audit (offline; no re-optimisation)\n');
    fprintf(fid,'runs=%d  Monte-Carlo repetitions K=%d  HV samples/call=%d  seed base=%d\n', ...
        o.NUM_RUNS, o.K, o.HV_SAMPLE, o.SEED_BASE);
    fprintf(fid,'HV reference enters ONLY through the normalisation box. IGD is computed against the reference\n');
    fprintf(fid,'front itself: box-independent, no sampling noise -> deterministic control.\n');
    fprintf(fid,'Pair labels: A vs B = memory effect, A vs C = t-dist effect, A vs D = joint effect,\n');
    fprintf(fid,'             B vs D = t added to memory, C vs D = memory added to t.\n');
    fprintf(fid,'Cliff d: >0 means the FIRST-named variant tends larger. HV larger better; IGD smaller better.\n');
    for s = 1:2
        sc = o.SCENARIOS{s};
        fprintf(fid,'\n================ %s ================\n', sc);
        fprintf(fid,'IGD reference front: %d points\n', o.(sprintf('nIGDref_scene%d',s)));

        fprintf(fid,'\n-- IGD (deterministic, box-independent control) --\n');
        m = o.(sprintf('IGDmean_scene%d',s));
        fprintf(fid,'   mean IGD: A=%.2f B=%.2f C=%.2f D=%.2f\n', m(1),m(2),m(3),m(4));
        p = o.(sprintf('IGDp_scene%d',s)); g = o.(sprintf('IGDsig_scene%d',s)); d = o.(sprintf('IGDd_scene%d',s));
        for q = 1:6
            fprintf(fid,'   %-7s: p=%-9.4g %-10s Cliff d=%+.3f\n', o.PAIRLAB{q}, p(q), g{q}, d(q));
        end

        for ri = 1:numel(o.refNames)
            rn = o.refNames{ri};
            b = o.(sprintf('box_%s_scene%d', rn, s));
            fprintf(fid,'\n-- HV, reference %s --\n', rn);
            fprintf(fid,'   box.max = [%.4g %.4g %.4g %.4g]\n', b(1),b(2),b(3),b(4));
            hm = o.(sprintf('HVmean_%s_scene%d', rn, s));
            sd = o.(sprintf('MCsd_%s_scene%d',   rn, s));
            fprintf(fid,'   mean HV: A=%.4f B=%.4f C=%.4f D=%.4f   (per-run MC sd %.1e..%.1e)\n', ...
                hm(1),hm(2),hm(3),hm(4), min(sd), max(sd));
            pK = o.(sprintf('HVpK_%s_scene%d', rn, s)); gK = o.(sprintf('HVsigK_%s_scene%d', rn, s));
            dK = o.(sprintf('HVdK_%s_scene%d', rn, s));
            Pk = o.(sprintf('HVpDist_%s_scene%d', rn, s));
            for q = 1:6
                col = Pk(:,q);
                fprintf(fid,'   %-7s: p over %d MC draws min=%-8.4g med=%-8.4g max=%-8.4g (frac<.05=%.2f) | K-avg p=%-9.4g %-10s | Cliff d=%+.3f\n', ...
                    o.PAIRLAB{q}, o.K, min(col), median(col), max(col), mean(col<0.05), pK(q), gK{q}, dK(q));
            end
        end
    end
    fclose(fid);
    fprintf('[saved] %s\n', fname);
end

% ------------------------------------------------------------------------
function printConsole(o)
    for s = 1:2
        fprintf('\n===== %s =====\n', o.SCENARIOS{s});
        m = o.(sprintf('IGDmean_scene%d',s));
        p = o.(sprintf('IGDp_scene%d',s)); g = o.(sprintf('IGDsig_scene%d',s));
        fprintf('IGD (deterministic, box-free): A=%.2f B=%.2f C=%.2f D=%.2f\n', m(1),m(2),m(3),m(4));
        for q = 1:6
            fprintf('   IGD %-7s p=%-9.4g %-10s\n', o.PAIRLAB{q}, p(q), g{q});
        end
        for ri = 1:numel(o.refNames)
            rn = o.refNames{ri};
            hm = o.(sprintf('HVmean_%s_scene%d', rn, s));
            pK = o.(sprintf('HVpK_%s_scene%d', rn, s));
            gK = o.(sprintf('HVsigK_%s_scene%d', rn, s));
            Pk = o.(sprintf('HVpDist_%s_scene%d', rn, s));
            fprintf('HV %-18s A=%.4f B=%.4f C=%.4f D=%.4f\n', rn, hm(1),hm(2),hm(3),hm(4));
            for q = 1:6
                col = Pk(:,q);
                fprintf('   HV %-7s p(range %.4g-%.4g, med %.4g, frac<.05 %.2f) | K-avg %-9.4g %-10s\n', ...
                    o.PAIRLAB{q}, min(col), max(col), median(col), mean(col<0.05), pK(q), gK{q});
            end
        end
    end
end
