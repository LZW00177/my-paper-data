function plotFig3_ablation_radar()
% 消融实验 Friedman 排名雷达图（仿 EALA 论文 Fig2/Fig3 风格）
% 每条线 = 一个算法；值 = Friedman 平均排名（rank，越小越优，从中心向外增大）
% 数据源（2026-09-08，IALA 按 Zheng2026 重写重跑，最终数据源）:
%   results/ablation_final.mat（make_ablation_final.m 生成，公开/投稿用）
%   6 基准 IGD Friedman 排名; ZDT TMAX=300; DTLZ1/3 TMAX=2000; DTLZ2 TMAX=500
clc; close all;
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);

% 单一干净数据源: ablation_final.mat（make_ablation_final.m 生成）
F = load(fullfile(root,'results','ablation_final.mat'));
algoNames = F.algoDefs(:,1);
benchNames = {'ZDT1','ZDT2','ZDT3','DTLZ1','DTLZ2','DTLZ3'};
nAlgo  = numel(algoNames);
nBench = numel(benchNames);

% ---- 构建 rank 矩阵 [nBench x nAlgo]，rank=1 最优 ----
rankMat = zeros(nBench, nAlgo);
for b = 1:nBench
    ro = F.stats(b).rankOrder;      % 排序后算法名 cell（最优在前）
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
    0.95 0.20 0.55;   % IALA 粉红（强调，加标记）
    0.00 0.55 0.55 ]; % HALA 青
% 淡化非主角对比算法的颜色，缓解中心区重叠
fade = @(c) c*0.55 + 0.45;   % 向白混合 45%，降饱和提亮
moalaIdx = [1 2 3 4];  % A B C D 的顺序（按 algoNames 列序）
for a = 1:nAlgo
    if ismember(a, moalaIdx)
        lineSpec(a).color = palette(a,:);
        lineSpec(a).style = '-';
        lineSpec(a).width = (a==4)*2.2 + (a~=4)*1.4;  % D 加粗
    elseif a == 8
        lineSpec(a).color = palette(a,:);   % IALA 保持饱和（变更焦点）
        lineSpec(a).style = '--';
        lineSpec(a).width = 1.4;
    else
        lineSpec(a).color = fade(palette(a,:));
        lineSpec(a).style = '--';
        lineSpec(a).width = 0.9;
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
    % 顶点标记：主角 MOALA-D 与对比焦点 IALA 加圆点/方块，NSGAII 加圆点
    if a == 4
        plot(x(1:end-1), y(1:end-1), 'o', 'Color', lineSpec(a).color, ...
            'MarkerFaceColor', lineSpec(a).color, 'MarkerSize', 4.5);
    elseif a == 5
        plot(x(1:end-1), y(1:end-1), 'o', 'Color', lineSpec(a).color, ...
            'MarkerFaceColor', lineSpec(a).color, 'MarkerSize', 3.5);
    elseif a == 8
        plot(x(1:end-1), y(1:end-1), 's', 'Color', lineSpec(a).color, ...
            'MarkerFaceColor', lineSpec(a).color, 'MarkerSize', 4);
    end
end

% 中心标注
text(0, 0, 'rank 1 = best', 'FontSize', 8, 'Color', [0.4 0.4 0.4], ...
    'HorizontalAlignment','center','VerticalAlignment','middle');

% 图例（分两列，MO-ALA 家族与对比算法）
hLeg = [];
for a = 1:nAlgo
    hLeg(a) = plot(nan, nan, lineSpec(a).style, 'Color', lineSpec(a).color, ...
        'LineWidth', lineSpec(a).width);
end
lg = legend(hLeg, algoNames, 'Location','eastoutside', 'FontSize', 9, ...
    'Box','off', 'NumColumns', 1);
title(lg, 'Algorithm', 'FontSize', 9, 'FontWeight','bold');

xlim([-maxRank-2.5, maxRank+4.0]); ylim([-maxRank-1.5, maxRank+1.5]);

outDir = fullfile(root, 'figures'); if ~exist(outDir,'dir'), mkdir(outDir); end
% -batch 无显示环境下保证 fig 句柄有效: 先 drawnow 再逐张导出
set(fig, 'Visible','off'); drawnow;
print(fig, fullfile(outDir, 'Fig3_ablation_friedman_radar.png'), '-dpng', '-r300');
print(fig, fullfile(outDir, 'Fig3_ablation_friedman_radar.eps'), '-depsc2', '-r300');
fprintf('[radar] saved figures/Fig3_ablation_friedman_radar.png/.eps\n');
end
