%% plot/plotFig10_ParamSweep_Combined.m
% 图10：参数敏感性合并图（1×3 布局，tiledlayout + yyaxis 双轴）
%   (a) N_arch 扫描 (20/30/50/70/100) — HV/IGD 变化曲线
%   (b) nu_max 扫描 (10/15/20/30/50) — HV/IGD 变化曲线
%   (c) N 种群扫描 (12/20/30/40/50) — HV/IGD 变化曲线
% 数据源：paramSweep.mat（NRUNS=15/配置，ZDT2 + DTLZ2）
% 双 y 轴：HV 左轴（实线 o-），IGD 右轴（虚线 s--）；ZDT2 蓝 / DTLZ2 橙红
% 灰色竖虚线标注论文默认参数
% 修改：N 和 N_arch 中的 N 显示为斜体（LaTeX 解释器）
clc; close all;
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root); addpath(fullfile(root,'metrics'));

PS = load(fullfile(root,'results','paramSweep.mat'));
N_arch_list = PS.N_arch_list;      % [20 30 50 70 100]
nu_max_list = PS.nu_max_list;      % [10 15 20 30 50]
N_list      = PS.N_list;           % [12 20 30 40 50]
hvArch  = PS.hvArch;   igdArch = PS.igdArch;   % {15x5} x2 (ZDT2, DTLZ2)
hvNu    = PS.hvNu;     igdNu   = PS.igdNu;
hvN     = PS.hvN;      igdN    = PS.igdN;

nB = 2;
benchNames = {'ZDT2', 'DTLZ2'};
cZ = [0.00 0.45 0.74];   % ZDT2 蓝
cD = [0.85 0.33 0.10];   % DTLZ2 橙红
cols = [cZ; cD];

% 辅助：提取均值±std
meanStd = @(X) deal(nanmean(X,1), nanstd(X,0,1));

fig = figure('Color','w','Position',[40 80 1600 490],'Name','Fig10 Parameter sensitivity');
tl = tiledlayout(fig, 1, 3, 'TileSpacing','compact','Padding','compact');

%% 面板定义：(xlist, hvCell, igdCell, xlabel, defaultX, defaultLabel, title)
% 使用 LaTeX 语法：\mathit{N} 使 N 斜体，\mathrm{arch} 使下标 arch 正体
panels = {
    N_arch_list, hvArch, igdArch, '$\mathit{N}_{\mathrm{arch}}$', 50, '$\mathit{N}_{\mathrm{arch}}=50$', '(a) $\mathit{N}_{\mathrm{arch}}$ sensitivity';
    nu_max_list, hvNu,   igdNu,   '$\nu_{\max}$',                 20, '$\nu_{\max}=20$',             '(b) $\nu_{\max}$ sensitivity';
    N_list,      hvN,    igdN,    '$\mathit{N}$',                 30, '$\mathit{N}=30$',             '(c) $\mathit{N}$ sensitivity';
};

for p = 1:size(panels,1)
    xlist   = panels{p,1};
    hvCell  = panels{p,2};
    igdCell = panels{p,3};
    xlab    = panels{p,4};
    defX    = panels{p,5};
    defLab  = panels{p,6};
    ttl     = panels{p,7};

    ax = nexttile(tl);
    ax.Toolbar.Visible = 'off';
    
    % ---- 左轴：HV ----
    yyaxis(ax,'left'); 
    hold(ax,'on'); grid(ax,'on'); box(ax,'on');
    hvLn = gobjects(1,nB);
    for bi = 1:nB
        [m,s] = meanStd(hvCell{bi});
        hvLn(bi) = errorbar(ax, xlist, m, s, 'o-', 'LineWidth', 1.8, ...
            'MarkerSize', 7, 'Color', cols(bi,:), 'MarkerFaceColor', cols(bi,:));
        hvLn(bi).DisplayName = [benchNames{bi} ' (HV)'];
    end
    ylabel(ax, 'HV', 'FontSize', 12, 'Color', 'k');
    ax.YAxis(1).Color = 'k';
    
    % ---- 右轴：IGD ----
    yyaxis(ax,'right');
    igdLn = gobjects(1,nB);
    for bi = 1:nB
        [m,s] = meanStd(igdCell{bi});
        igdLn(bi) = errorbar(ax, xlist, m, s, 's--', 'LineWidth', 1.6, ...
            'MarkerSize', 6, 'Color', cols(bi,:), 'MarkerFaceColor', 'none');
        igdLn(bi).DisplayName = [benchNames{bi} ' (IGD)'];
    end
    ylabel(ax, 'IGD', 'FontSize', 12);
    ax.YAxis(2).Color = [0.35 0.35 0.35];
    
    % ---- 坐标轴与标题（设置 LaTeX 解释器） ----
    xlabel(ax, xlab, 'FontSize', 12, 'Interpreter', 'latex');
    ax.XAxis.TickLabelInterpreter = 'latex';  % X 轴刻度标签解释器
    ax.YAxis(1).TickLabelInterpreter = 'latex';  % 左 Y 轴刻度标签解释器
    ax.YAxis(2).TickLabelInterpreter = 'latex';  % 右 Y 轴刻度标签解释器
    
    xticks(ax, xlist);
    
    % ---- 默认参数竖虚线 + 标注 ----
    xline(ax, defX, '--', 'Color', [0.3 0.3 0.3], 'LineWidth', 1.2);
    text(ax, defX, ax.YLim(2)*0.93, [' default ' defLab], 'FontSize', 9, ...
        'HorizontalAlignment', 'left', 'VerticalAlignment', 'top', ...
        'Color', [0.25 0.25 0.25], 'Interpreter', 'latex');
    
    title(ax, ttl, 'FontSize', 13, 'FontWeight', 'bold', 'Interpreter', 'latex');
    
    % ---- 图例 ----
    lg = legend(ax, [hvLn(1) hvLn(2) igdLn(1) igdLn(2)], ...
        'Location', 'eastoutside', 'FontSize', 9, 'Box', 'on');
    lg.Interpreter = 'latex';
    
    % 调整子图宽度为图例腾出空间
    ax.Position(3) = ax.Position(3) * 0.75;
    ax.FontSize = 11;
end

% sgtitle(fig, 'Parameter Sensitivity (ZDT2 / DTLZ2)', 'FontSize', 14, 'FontWeight','bold');

outDir = fullfile(root, 'figures'); 
if ~exist(outDir,'dir'), mkdir(outDir); end
print(fig, fullfile(outDir, 'Fig10_ParamSweep_Combined.png'), '-dpng', '-r300');
print(fig, fullfile(outDir, 'Fig10_ParamSweep_Combined.eps'), '-depsc2', '-r300');
fprintf('[图10] 已保存 figures/Fig10_ParamSweep_Combined.png/.eps\n');