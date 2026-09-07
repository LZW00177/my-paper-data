function plotFig3_ablation_radar()
% 消融实验 Friedman 排名雷达图
% 每条线 = 一个算法；值 = Friedman 平均排名（rank，越小越优，从中心向外增大）
% 数据源（2026-09-06 修正，与论文表10 口径一致）：
%   ZDT1/2/3 <- ablation_par.mat（旧，8/18，ZDT 系列论文数据源）
%   DTLZ1/2/3 <- ablation_DTLZ_all.mat（修正口径：DTLZ1/3 TMAX=2000, DTLZ2 TMAX=500）
%   合并为 6 基准 stats 后绘制，与表10/正文 4.2 节一致
clc; close all;
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);

Sold = load(fullfile(root,'results','ablation_par.mat'));        % ZDT1/2/3 行
Snew = load(fullfile(root,'results','ablation_DTLZ_all.mat'));   % DTLZ1/2/3 行

% 合并 stats：ZDT1/2/3(1:3) 取旧；DTLZ1/2/3(4:6) 取新
stats = Sold.stats;
fn = fieldnames(stats);   % 以旧 stats 字段模板为基础
for b = 4:6
    % 逐字段复制新文件的 rankOrder/friedmanP 等（rankOrder 字段两版本都存在）
    stats(b).rankOrder   = Snew.stats(b).rankOrder;
    if isfield(Snew.stats(b),'friedmanP');  stats(b).friedmanP  = Snew.stats(b).friedmanP;  end
    if isfield(Snew.stats(b),'friedmanChi2'); stats(b).friedmanChi2 = Snew.stats(b).friedmanChi2; end
end

algoNames = Sold.algoDefs(:,1);
nAlgo = numel(algoNames);
benchNames = {'ZDT1','ZDT2','ZDT3','DTLZ1','DTLZ2','DTLZ3'};
nBench = numel(benchNames);

% ---- 构建 rank 矩阵 [nBench x nAlgo]，rank=1 最优 ----
rankMat = zeros(nBench, nAlgo);
for b = 1:nBench
    ro = stats(b).rankOrder;      % 排序后算法名 cell（最优在前）
    for r = 1:numel(ro)
        idx = find(strcmp(algoNames, ro{r}));
        if ~isempty(idx), rankMat(b, idx) = r; end
    end
end

% ---- 颜色与线型：MO-ALA 家族暖色实线（D 最醒目），对比算法冷色虚线 ----
lineSpec = struct('color',{}, 'style',{}, 'width',{});
% palette 顺序 = algoNames 列序：MOALA-A, MOALA-B, MOALA-C, MOALA-D, NSGAII, MOPSO, EALA, IALA, HALA
palette = [ ...
    0.00 0.45 0.74;   % MOALA-A 蓝
    0.47 0.67 0.19;   % MOALA-B 绿
    0.49 0.18 0.56;   % MOALA-C 紫
    0.85 0.33 0.10;   % MOALA-D 红（主角）
    0.30 0.30 0.30;   % NSGAII 深灰
    0.75 0.00 0.75;   % MOPSO 洋红
    0.63 0.32 0.18;   % EALA 棕
    0.90 0.30 0.55;   % IALA 粉
    0.00 0.55 0.55 ]; % HALA 青
moalaIdx = [1 2 3 4];  % A B C D 的顺序（按 algoNames 列序）
for a = 1:nAlgo
    lineSpec(a).color = palette(a,:);
    if ismember(a, moalaIdx)
        lineSpec(a).style = '-';
        lineSpec(a).width = (a==4)*1.8 + (a~=4)*1.3;  % D 加粗
    else
        lineSpec(a).style = '--';
        lineSpec(a).width = 1.0;
    end
end

% ---- 雷达图绘制 ----
fig = figure('Color','w','Position',[80 80 820 700],'Name','Ablation Friedman Rank Radar');
hold on; axis equal; axis off;

nRings = 4;                 % 网格环数
maxRank = nAlgo;            % 外圈 = 最差排名 9
ringValues = [1 3 5 7 9];   % 网格环对应的 rank
angles = linspace(90, 90-360, nBench+1) * pi/180;  % 从顶部顺时针
R = maxRank;

% 网格环
for ri = 1:numel(ringValues)
    rv = ringValues(ri);
    x = rv * cos(angles); y = rv * sin(angles);
    plot(x, y, '-', 'Color', [0.82 0.82 0.82], 'LineWidth', 0.6);
    if ri == numel(ringValues)
        text(rv*cos(angles(1))*1.03, rv*sin(angles(1))*1.03, sprintf('%d', rv), ...
            'FontSize', 8, 'Color', [0.45 0.45 0.45], 'HorizontalAlignment','center');
    end
end

% 轴辐条 + 轴标签
for b = 1:nBench
    plot([0 maxRank*cos(angles(b))], [0 maxRank*sin(angles(b))], '-', ...
        'Color', [0.85 0.85 0.85], 'LineWidth', 0.6);
    lx = (maxRank+0.8)*cos(angles(b));
    ly = (maxRank+0.8)*sin(angles(b));
    text(lx, ly, benchNames{b}, 'FontSize', 12, 'FontWeight','bold', ...
        'HorizontalAlignment','center', 'VerticalAlignment','middle');
end

% 各算法多边形
for a = 1:nAlgo
    rv = rankMat(:, a).';       % [1 x nBench] 行向量
    x = rv .* cos(angles(1:end-1)); y = rv .* sin(angles(1:end-1));
    x = [x, x(1)]; y = [y, y(1)];
    plot(x, y, lineSpec(a).style, 'Color', lineSpec(a).color, ...
        'LineWidth', lineSpec(a).width);
    % 顶点标记（仅主角与最优基线，避免过密）
    if a == 4 || a == 5   % MOALA-D 与 NSGAII
        plot(x(1:end-1), y(1:end-1), 'o', 'Color', lineSpec(a).color, ...
            'MarkerFaceColor', lineSpec(a).color, 'MarkerSize', 4);
    end
end

% 中心标注
text(0, 0, 'rank=1 Optimal', 'FontSize', 8, 'Color', [0.4 0.4 0.4], ...
    'HorizontalAlignment','center','VerticalAlignment','middle');

% 图例（分两列，MO-ALA 家族与对比算法）
hLeg = [];
for a = 1:nAlgo
    hLeg(a) = plot(nan, nan, lineSpec(a).style, 'Color', lineSpec(a).color, ...
        'LineWidth', lineSpec(a).width);
end
lg = legend(hLeg, algoNames, 'Location','eastoutside', 'FontSize', 9, ...
    'Box','off', 'NumColumns', 1);
title(lg, 'Algorithm', 'FontSize', 9);

xlim([-maxRank-2.5, maxRank+4.0]); ylim([-maxRank-1.5, maxRank+1.5]);

outDir = fullfile(root, 'figures'); if ~exist(outDir,'dir'), mkdir(outDir); end
print(fig, fullfile(outDir, 'Fig3_ablation_friedman_radar.png'), '-dpng', '-r300');
print(fig, fullfile(outDir, 'Fig3_ablation_friedman_radar.eps'), '-depsc2', '-r300');
fprintf('[图3雷达图] 已保存 figures/Fig3_ablation_friedman_radar.png/.eps\n');
end
