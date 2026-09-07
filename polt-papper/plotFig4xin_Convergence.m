function plotFig4xin_Convergence()
% plotFig9_Convergence — 论文图5：ZDT2 / DTLZ2 HV 与 IGD 收敛曲线（9算法 × 30次均值±std）
% 数据源：results/convergence_zdt2_dtlz2.mat（新采集）
% 布局：2行2列 — 行1: HV；行2: IGD；列1: ZDT2；列2: DTLZ2
clc; close all;
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);

S = load(fullfile(root,'results','convergence_zdt2_dtlz2.mat'));
convData   = S.convData;
variants   = S.variants;
benchNames = S.benchNames;
NRUNS      = S.NRUNS;

nBench = numel(benchNames);
nAlgo  = size(variants,1);

% ========== 颜色与线型配置（主角鲜艳，配角灰色） ==========
% 假设 variants 列序：MOALA-A, MOALA-B, MOALA-C, MOALA-D, NSGAII, MOPSO, EALA, IALA, HALA
% 前4个为主角（MOALA家族），后5个为配角
nMain = 4;  % 主角数量

% 主角颜色：高饱和暖色
mainColors = [
    0.85 0.10 0.10;  % MOALA-A 红
    0.00 0.45 0.74;  % MOALA-B 蓝
    0.47 0.67 0.19;  % MOALA-C 绿
    0.49 0.18 0.56;  % MOALA-D 紫
];

% 配角颜色：灰色系
bgColors = [
    0.40 0.40 0.40;  % NSGAII
    0.50 0.50 0.50;  % MOPSO
    0.60 0.60 0.60;  % EALA
    0.45 0.45 0.45;  % IALA
    0.55 0.55 0.55;  % HALA
];

% 合并颜色
colors = [mainColors; bgColors];

% 线型：主角实线，配角虚线/点线
lineStyles = {'-','-','-','-', '--',':','-.','--',':'};
lineWidths = [1.8, 1.8, 1.8, 2.2, 1.0, 1.0, 1.0, 1.0, 1.0];

% ========== 绘图 ==========
fig = figure('Color','w','Position',[60 60 1400 850],'Name','Fig9 Convergence');
tl = tiledlayout(fig, 2, 2, 'TileSpacing','compact','Padding','compact');

metricDefs = {'HV', 'HV (higher is better)';
              'IGD', 'IGD (lower is better)'};

for mi = 1:2
    for bi = 1:nBench
        ax = nexttile(tl, (mi-1)*nBench + bi);
        hold(ax,'on'); grid(ax,'on'); box(ax,'on');
        
        % Y轴范围设置
        if mi == 1  % HV: 固定 0-1
            ylim(ax, [0 1]);
        else        % IGD: 手动设置上限，避免被离群算法拉高
            ylim(ax, [0 1.5]);  % 可根据实际数据调整
        end
        ax.FontSize = 10;

        for ai = 1:nAlgo
            runs = convData{bi,ai};
            if isempty(runs), continue; end
            
            % 提取数据
            maxLen = 0;
            for r = 1:numel(runs)
                if ~isempty(runs{r}), maxLen = max(maxLen, size(runs{r},1)); end
            end
            if maxLen == 0, continue; end
            
            allV = nan(NRUNS, maxLen);
            xAll = nan(NRUNS, maxLen);
            for r = 1:numel(runs)
                c = runs{r};
                if ~isempty(c) && size(c,1) > 0
                    xAll(r, 1:size(c,1)) = c(:,1);
                    allV(r, 1:size(c,1)) = c(:, mi+1);  % 列2=HV, 列3=IGD
                end
            end
            
            mn = nanmean(allV,1);
            sd = nanstd(allV,0,1);
            valid = ~isnan(mn);
            x = xAll(1, valid);
            if numel(x) < 2, continue; end

            % 绘制均值曲线
            plot(ax, x, mn(valid), lineStyles{ai}, 'Color', colors(ai,:), ...
                'LineWidth', lineWidths(ai), 'DisplayName', variants{ai,1});

            % 阴影带（1σ）：主角透明度稍高，配角透明度极低
            if ai <= nMain  % 主角（MOALA家族）
                alphaVal = 0.15;  % 保持适度可见
            else            % 配角（对比算法）
                alphaVal = 0.08;  % 降到极淡，仅保留趋势感
            end
            
            xPatch = [x, fliplr(x)];
            yPatch = [mn(valid)+sd(valid), fliplr(mn(valid)-sd(valid))];
            fill(ax, xPatch, yPatch, colors(ai,:), 'FaceAlpha', alphaVal, ...
                'EdgeColor','none', 'HandleVisibility','off');        
        end

        xlabel(ax, 'Iteration', 'FontSize',11);
        ylabel(ax, metricDefs{mi,2}, 'FontSize',11);
xlim(ax, [0 310]);
    end
end

% ========== 全局图例（放在图上方，所有子图共享） ==========
% 【修复】使用子图坐标轴创建图例，然后移到外部
firstAx = nexttile(tl, 1);
lg = legend(firstAx, variants(:,1), 'NumColumns', 5, 'FontSize', 9, 'Box', 'off');
lg.Location = 'northoutside';  % 放在图的上方外部

% ========== 导出 ==========
outDir = fullfile(root, 'figures'); 
if ~exist(outDir,'dir'), mkdir(outDir); end
print(fig, fullfile(outDir, 'Fig4_convergence_ZDT2_DTLZ2.png'), '-dpng', '-r300');
print(fig, fullfile(outDir, 'Fig4_convergence_ZDT2_DTLZ2.eps'), '-depsc2', '-r300');
fprintf('[Fig4] saved: figures/Fig4_convergence_ZDT2_DTLZ2.png/.eps\n');