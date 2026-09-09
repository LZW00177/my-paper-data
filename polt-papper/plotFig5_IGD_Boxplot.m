function plotFig5_IGD_Boxplot()
% plotFig5_IGD_Boxplot — 论文图5：ZDT2 / DTLZ2 IGD 箱线图（9算法 × 30次）
% 数据源（与论文表9/表10 口径一致）：
%   results/ablation_final.mat（9/8 权威版：ZDT 行 TMAX=300 + DTLZ 行 TMAX 修正 + IALA Zheng 版）
%   行2 = ZDT2（bi），行5 = DTLZ2
% 风格：ZDT2 对数轴，DTLZ2 线性轴
clc; close all;
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);

S  = load(fullfile(root,'results','ablation_final.mat'));
R  = S.R;
algoNames = S.algoDefs(:,1);
nAlgo = size(R,2);

benchIdx   = [2 5];
benchTitle = {'(a) ZDT2 (bi-objective)', '(b) DTLZ2 (bi-objective)'};
% ZDT2：对数轴，截断上界 0.35（MOPSO/EALA/HALA 中位数超限，标▲）；DTLZ2：线性轴全显示
logFlags   = [true, false];
yCap       = [0.35, 1.5];   % 上界（DTLZ2 新口径下 EALA≈1.2 可全显）
yLow       = [0.005, 0.0];  % 下界

algoColors = [
    1.00 0.45 0.74;  % MOALA-A 粉
    0.47 0.67 0.19;  % MOALA-B 绿
    0.49 0.18 0.56;  % MOALA-C 紫
    0.85 0.33 0.10;  % MOALA-D 橙
    0.30 0.30 0.30;  % NSGAII 黑
    0.75 0.00 0.75;  % MOPSO 品红
    0.63 0.32 0.18;  % EALA 棕
    0.90 0.30 0.55;  % IALA 玫红
    0.00 0.55 0.55]; % HALA 青

fig = figure('Color','w','Position',[80 80 1100 520],'Name','Fig5 IGD boxplot');
tl = tiledlayout(fig, 1, 2, 'TileSpacing','compact','Padding','compact');

for bi = 1:2
    b = benchIdx(bi);
    vals = []; grp = []; meds = nan(nAlgo,1);
    for ai = 1:nAlgo
        m = R{b,ai};
        if isempty(m), continue; end
        v = m(:,2); v = v(~isnan(v));
        if isempty(v), continue; end
        vals = [vals; v(:)];
        grp  = [grp; repmat(ai, numel(v), 1)];
        meds(ai) = median(v);
    end

    ax = nexttile(tl);
    hb = boxplot(ax, vals, grp, 'Labels', algoNames, 'Colors', algoColors, ...
        'Symbol', 'k.', 'Widths', 0.5);
    grid(ax,'on'); box(ax,'on');
    set(hb, 'LineWidth', 0.9);
    ylabel(ax, 'IGD (lower is better)', 'FontSize', 12);
    title(ax, benchTitle{bi}, 'FontSize', 13, 'FontWeight','bold');
    ax.FontSize = 9;
    ax.XTickLabelRotation = 30;
    set(ax, 'YScale', 'linear');
    if logFlags(bi)
        set(ax, 'YScale', 'log');
    end
    ylim(ax, [yLow(bi), yCap(bi)]);

    % 无截断：数据全部显示，无需▲标注
    % ZDT2 子图：中位数超上界的算法标▲（截断提示）
    if logFlags(bi)
        for ai = 1:nAlgo
            if meds(ai) > yCap(bi)
                text(ax, ai, yCap(bi)*0.93, '▲', ...
                    'HorizontalAlignment','center','VerticalAlignment','bottom', ...
                    'FontSize', 9, 'Color', [0.7 0 0], 'Interpreter','none');
            end
        end
    end
end

outDir = fullfile(root, 'figures'); if ~exist(outDir,'dir'), mkdir(outDir); end
print(fig, fullfile(outDir, 'Fig5_IGD_boxplot.png'), '-dpng', '-r300');
print(fig, fullfile(outDir, 'Fig5_IGD_boxplot.eps'), '-depsc2', '-r300');
fprintf('[Fig5] saved: figures/Fig5_IGD_boxplot.png/.eps\n');
end
