%% polt-papper/plotFig10_ParamSweep_Combined_v2.m
% =========================================================================
% 图10（修复版）：参数敏感性合并图（1×3，tiledlayout + yyaxis 双轴）
%   (a) N_arch 扫描 (20/30/50/70/100)
%   (b) nu_max 扫描 (10/15/20/30/50)
%   (c) N 种群扫描 (12/20/30/40/50)
% 数据源：results/paramSweep_v2.mat（2026-09-12 修复版 HV/IGD 口径）
%   —— 与 ablation_final_v2.mat / Table 9 同口径；ZDT2 HV≈0.32（旧版错值 0.66）
% 输出：figures/Fig10_ParamSweep_Combined_v2.png / .eps
% 用法：matlab -batch "cd('...\polt-papper'); plotFig10_ParamSweep_Combined_v2"
% =========================================================================
clc; close all;
root = fileparts(fileparts(mfilename('fullpath')));   % = MOALA/
addpath(root); addpath(fullfile(root,'code'));

matFile = fullfile(root,'data','param_sweep.mat');
if ~exist(matFile,'file')
    error(['缺少 %s\n请先运行: matlab -batch "runParamSweep_v2"'], matFile);
end
PS = load(matFile);
N_arch_list = PS.N_arch_list;
nu_max_list = PS.nu_max_list;
N_list      = PS.N_list;
hvArch = PS.hvArch;  igdArch = PS.igdArch;
hvNu   = PS.hvNu;    igdNu   = PS.igdNu;
hvN    = PS.hvN;     igdN    = PS.igdN;

nB = 2;
benchNames = {'ZDT2', 'DTLZ2'};
cZ = [0.00 0.45 0.74];
cD = [0.85 0.33 0.10];
cols = [cZ; cD];

meanStd = @(X) deal(nanmean(X,1), nanstd(X,0,1));

fig = figure('Color','w','Position',[40 80 1600 490],'Name','Fig10 Parameter sensitivity (v2)');
tl = tiledlayout(fig, 1, 3, 'TileSpacing','compact','Padding','compact');

panels = {
    N_arch_list, hvArch, igdArch, '$\mathit{N}_{\mathrm{arch}}$', 50, '$\mathit{N}_{\mathrm{arch}}=50$', '(a) $\mathit{N}_{\mathrm{arch}}$ sensitivity';
    nu_max_list, hvNu,   igdNu,   '$\nu_{\max}$',                 20, '$\nu_{\max}=20$',             '(b) $\nu_{\max}$ sensitivity';
    N_list,      hvN,    igdN,    '$\mathit{N}$',                 30, '$\mathit{N}=30$',             '(c) $\mathit{N}$ sensitivity';
};

for p = 1:size(panels,1)
    xlist = panels{p,1}; hvCell = panels{p,2}; igdCell = panels{p,3};
    xlab = panels{p,4}; defX = panels{p,5}; defLab = panels{p,6}; ttl = panels{p,7};

    ax = nexttile(tl);
    ax.Toolbar.Visible = 'off';

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

    xlabel(ax, xlab, 'FontSize', 12, 'Interpreter', 'latex');
    ax.XAxis.TickLabelInterpreter = 'latex';
    ax.YAxis(1).TickLabelInterpreter = 'latex';
    ax.YAxis(2).TickLabelInterpreter = 'latex';
    xticks(ax, xlist);

    xline(ax, defX, '--', 'Color', [0.3 0.3 0.3], 'LineWidth', 1.2);
    text(ax, defX, ax.YLim(2)*0.93, [' default ' defLab], 'FontSize', 9, ...
        'HorizontalAlignment','left','VerticalAlignment','top', ...
        'Color',[0.25 0.25 0.25], 'Interpreter','latex');

    title(ax, ttl, 'FontSize', 13, 'FontWeight', 'bold', 'Interpreter', 'latex');

    lg = legend(ax, [hvLn(1) hvLn(2) igdLn(1) igdLn(2)], ...
        'Location','eastoutside','FontSize',9,'Box','on');
    lg.Interpreter = 'latex';

    ax.Position(3) = ax.Position(3) * 0.75;
    ax.FontSize = 11;
end

% 输出目录：优先 polt-papper/figures，其次根 figures
outDir = fullfile(fileparts(mfilename('fullpath')), 'figures');
if ~exist(outDir,'dir'); outDir = fullfile(root,'figures'); end
if ~exist(outDir,'dir'); mkdir(outDir); end
print(fig, fullfile(outDir, 'Fig10_ParamSweep_Combined_v2.png'), '-dpng', '-r300');
print(fig, fullfile(outDir, 'Fig10_ParamSweep_Combined_v2.eps'), '-depsc2', '-r300');
fprintf('[图10 v2] 已保存 %s\n', fullfile(outDir,'Fig10_ParamSweep_Combined_v2.png'));
