function rerun_v8_DTLZ13_0829(varargin)
% =========================================================================
% rerun_v8_DTLZ13_0829 — 用 -0829 修复口径重跑 DTLZ1/3 的 MOALA-v8 证据
%
% 目的（2026-09-12）：
%   生成放进修订稿 Supplementary 的"v8 收敛证据"，证明 MO-ALA 在欺骗性
%   Rastrigin-g 基准(DTLZ1/3)上的失败是 scope 边界而非结构缺陷。
%   原 rerun_DTLZ13_only.m 依赖 searchMode='auto'→v8，但 -0829 已禁用 'auto'
%   (MOALA.m 强制 original)，故本脚本显式传 searchMode='v8' 绕过该限制。
%
% 口径（务必与 ablation_final_v2.mat 一致）：
%   - 在 -0829 目录运行 → 自动加载修复版 DTLZProblem(HV_ref=max(trueF)*1.05)
%     与修复版 MetricsCalculator，因此本脚本算出的 DTLZ1/3 HV 与正文
%     ablation_final_v2.mat 中 NSGA-II 的 DTLZ1/3 HV(0.0617/0.3985) 直接可比。
%   - 指标计算完全复用 ablationWorker（HV/IGD/Spacing/frontSize 同口径）。
%   - 种子: seed = BASE_SEED + 4000*bi + 100*ai + r (bi: DTLZ1=4,DTLZ3=6; ai 1..9)
%   - 仅重跑 MOALA-A/B/C/D (searchMode='v8')；其余 5 算法从
%     ablation_final_v2.mat 原样复制（它们在 DTLZ1/3 本就 HV=0，无需重跑）。
%
% 输出: results/ablation_DTLZ13_v8_0829.mat
%   R(6x9 cell, 仅 bi=4,6 有效, 每格 30x4=[HV IGD Sp nF]) + stats
%
% 用法（必须在 MOALA_UAV_code -0829 目录下执行）：
%   matlab -batch "rerun_v8_DTLZ13_0829"
%   matlab -batch "rerun_v8_DTLZ13_0829('FORCE',true)"   % 忽略断点全量重跑
% 预计耗时: 仅 MOALA 4变体 × 2基准 × 30次 × 2000代 ≈ 30~50 分钟
% =========================================================================
    BASE_SEED = 20260812;
    NRUNS = 30; N = 30;
    TMAX1 = 2000; TMAX3 = 2000;
    FORCE = false;
    for i = 1:2:length(varargin)
        if strcmpi(varargin{i},'NRUNS'); NRUNS = varargin{i+1};
        elseif strcmpi(varargin{i},'N'); N = varargin{i+1};
        elseif strcmpi(varargin{i},'TMAX1'); TMAX1 = varargin{i+1};
        elseif strcmpi(varargin{i},'TMAX3'); TMAX3 = varargin{i+1};
        elseif strcmpi(varargin{i},'FORCE'); FORCE = varargin{i+1}; end
    end

    base = fileparts(mfilename('fullpath'));
    addpath(base); addpath(fullfile(base,'algorithms')); addpath(fullfile(base,'metrics')); addpath(fullfile(base,'terrain')); rehash;

    % ---- 6 基准定义（仅 bi=4 DTLZ1、bi=6 DTLZ3 有效，其余占位） ----
    benchmarks = {
        struct('name','ZDT1','type','ZDT','id',1,'dim',10,'TMAX',300,'NRUNS',30);
        struct('name','ZDT2','type','ZDT','id',2,'dim',10,'TMAX',300,'NRUNS',30);
        struct('name','ZDT3','type','ZDT','id',3,'dim',10,'TMAX',300,'NRUNS',30);
        struct('name','DTLZ1','type','DTLZ','id',1,'dim',10,'TMAX',TMAX1,'NRUNS',NRUNS);
        struct('name','DTLZ2','type','DTLZ','id',2,'dim',10,'TMAX',500,'NRUNS',NRUNS);
        struct('name','DTLZ3','type','DTLZ','id',3,'dim',10,'TMAX',TMAX3,'NRUNS',NRUNS);
    };
    % ---- 9 算法定义；MOALA-A/B/C/D 显式 searchMode='v8'，其余为 [] (从 v2 复制) ----
    algoDefs = {
        'MOALA-A', struct('useMemory',false,'useTdist',false,'searchMode','v8'), true;
        'MOALA-B', struct('useMemory',true ,'useTdist',false,'searchMode','v8'), true;
        'MOALA-C', struct('useMemory',false,'useTdist',true ,'searchMode','v8'), true;
        'MOALA-D', struct('useMemory',true ,'useTdist',true ,'searchMode','v8'), true;
        'NSGAII' , [], false;
        'MOPSO'  , [], false;
        'EALA'   , [], false;
        'IALA'   , [], false;
        'HALA'   , [], false;
    };
    nAlgo = size(algoDefs,1);
    metrics = {'HV','IGD','Spacing','frontSize'};
    rerunBi = [4, 6];          % DTLZ1, DTLZ3
    rerunAlgo = [1, 2, 3, 4];  % 仅 MOALA-A/B/C/D 重跑（v8）
    copyAlgo = [5, 6, 7, 8, 9];% 其余从 ablation_final_v2 复制

    R = cell(6, nAlgo);
    for bi = 1:6; for ai = 1:nAlgo; R{bi,ai} = nan(NRUNS, 4); end; end

    % ---- 从 ablation_final_v2.mat 复制其余 5 算法的 DTLZ1/3 行 ----
    v2file = fullfile(base,'results','ablation_final_v2.mat');
    if ~exist(v2file,'file')
        error('未找到 ablation_final_v2.mat，请先完成 9/12 的基准全量重跑。');
    end
    V = load(v2file, 'R', 'benchmarks', 'algoDefs');
    for bi = rerunBi
        for ai = copyAlgo
            if ~isempty(V.R{bi,ai})
                R{bi,ai} = V.R{bi,ai};
            end
        end
    end
    fprintf('[copy] 已从 ablation_final_v2.mat 复制 %d 个算法 (DTLZ1/3) 的 original 结果\n', numel(copyAlgo));

    % ---- 断点续跑 ----
    ckptFile = fullfile(base,'results','ckpt_v8_DTLZ13_0829.mat');
    doneFlags = false(6, nAlgo);
    if exist(ckptFile,'file') && ~FORCE
        C = load(ckptFile, 'R', 'doneFlags');
        R = C.R; doneFlags = C.doneFlags;
        fprintf('[checkpoint] 已跳过 %d 个已完成 (基准,算法) 组合\n', sum(doneFlags(:)));
    elseif exist(ckptFile,'file') && FORCE
        fprintf('[FORCE] 忽略旧 checkpoint，全量重跑 MOALA-v8 (DTLZ1/3)\n');
    end

    try
        oldp = gcp('nocreate'); if ~isempty(oldp); delete(oldp); end
        parpool('local', min(feature('numcores'), 5));
    catch ME
        warning('parpool failed: %s', ME.message);
    end

    fprintf('\n=== DTLZ1/3 MOALA-v8 重跑 (-0829 口径, T1=%d/T3=%d, NRUNS=%d, N=%d) ===\n', TMAX1, TMAX3, NRUNS, N);

    for bi = rerunBi
        bm = benchmarks{bi};
        fprintf('\n--- %s (bi=%d, TMAX=%d) ---\n', bm.name, bi, bm.TMAX);
        for ai = rerunAlgo
            if doneFlags(bi,ai)
                fprintf('  跳过 %s (已完成)\n', algoDefs{ai,1});
                continue;
            end
            ad = algoDefs{ai,1}; opts = algoDefs{ai,2};
            fprintf('  运行 %-8s (ai=%d, searchMode=v8) ...', ad, ai);
            t0 = tic;
            tmp = nan(NRUNS, 4);
            parfor r = 1:NRUNS
                seed = BASE_SEED + 4000*bi + 100*ai + r;
                tmp(r,:) = ablationWorker(bm.type, bm.id, bm.dim, ad, opts, N, bm.TMAX, seed);
            end
            R{bi,ai} = tmp;
            fprintf(' 完成 %.0fs | HV=%.4f IGD=%.4f Sp=%.4f n=%.0f\n', toc(t0), ...
                nanmean(R{bi,ai}(:,1)), nanmean(R{bi,ai}(:,2)), nanmean(R{bi,ai}(:,3)), nanmean(R{bi,ai}(:,4)));
            doneFlags(bi,ai) = true;
            save(ckptFile, 'R', 'doneFlags', '-v7.3');
            fprintf('    [checkpoint saved]\n');
        end
    end

    % ---- 与正文 NSGA-II (DTLZ1/3) 对比打印 ----
    fprintf('\n=== v8 收敛对照（正文 ablation_final_v2 NSGA-II 为 original） ===\n');
    for bi = rerunBi
        bm = benchmarks{bi};
        mvD = R{bi,4}; nsv = V.R{bi,5};
        fprintf('[%s] MOALA-D(v8): HV=%.4f IGD=%.4f | NSGA-II(orig): HV=%.4f IGD=%.4f\n', ...
            bm.name, nanmean(mvD(:,1)), nanmean(mvD(:,2)), nanmean(nsv(:,1)), nanmean(nsv(:,2)));
    end

    % ---- Friedman + Wilcoxon（MOALA-D 第4列基准，IGD 列）----
    fprintf('\n=== 统计检验 ===\n');
    stats = struct();
    for bi = rerunBi
        bm = benchmarks{bi};
        data = zeros(NRUNS, nAlgo);
        for ai = 1:nAlgo; data(:,ai) = R{bi,ai}(:,2); end
        if any(isnan(data(:))); data(isnan(data)) = 1e6; end
        stats(bi).name = bm.name;
        stats(bi).friedmanP = nan; stats(bi).friedmanChi2 = nan;
        stats(bi).rankOrder = cell(1, nAlgo);
        stats(bi).wilcoxP = nan(1, nAlgo); stats(bi).sigChar = cell(1, nAlgo);
        [friedP, friedTable] = friedman(data, 1, 'off');
        stats(bi).friedmanP = friedP; stats(bi).friedmanChi2 = friedTable{2,5};
        [~, friedOrder] = sort(nanmean(data,1));
        for k = 1:nAlgo; stats(bi).rankOrder{k} = algoDefs{friedOrder(k),1}; end
        fprintf('%s: Friedman p=%.3e  排名:', bm.name, friedP);
        for k = 1:nAlgo; fprintf(' %s', stats(bi).rankOrder{k}); end
        fprintf('\n');
        for ai = 1:nAlgo
            if ai == 4; stats(bi).sigChar{ai} = '-'; continue; end
            [p, h] = signrank(data(:,4), data(:,ai), 'alpha', 0.05);
            stats(bi).wilcoxP(ai) = p;
            if h == 0; stats(bi).sigChar{ai} = '=';
            elseif mean(data(:,4)) < mean(data(:,ai)); stats(bi).sigChar{ai} = '+';
            else; stats(bi).sigChar{ai} = '-'; end
        end
        fprintf('  Wilcoxon vs D:');
        for ai = 1:nAlgo; fprintf(' %s:%s', algoDefs{ai,1}, stats(bi).sigChar{ai}); end
        fprintf('\n');
    end

    outFile = fullfile(base,'results','ablation_DTLZ13_v8_0829.mat');
    save(outFile, 'R', 'benchmarks', 'algoDefs', 'metrics', 'NRUNS', 'TMAX1', 'TMAX3', 'N', 'BASE_SEED', 'rerunBi', 'stats', '-v7.3');
    fprintf('\n[saved] %s\n', outFile);
    try; delete(gcp); end
    fprintf('完成。load(''%s'') 查看；MOALA-v8 的 HV/IGD 可直接用于 Supplementary 的 DTLZ1/3 收敛证据。\n', outFile);
end
