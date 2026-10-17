function plotFigSx_perturbScale()
% =========================================================================
% plotFigSx_perturbScale - analytic figure for the amplitude-scaling mechanism of the
%                          t-distribution perturbation (Supplementary Figure S1; no simulation)
%
% Purpose: to answer R1-2 / R2-5 ("give/specify the perturbation scale") directly, by showing
%   in one analytic plot how nu controls the tail shape while G(t) controls the amplitude:
%     early G ~ 2 -> large amplitude (long exploratory steps); late G -> 0 -> the absolute
%     amplitude is damped overall, but nu -> 2 makes the tail heavier (wider quantile band),
%
% Formulas (consistent with algorithms/ALAOperators.m and MOALA.m):
%   ν(t)  = ν_max·(ν_min/ν_max)^(t/T_max),  ν_max=20, ν_min=2      (Eq.19)
%   G(t)  = 2*(1 - t/T_max),              linear envelope, G: 2 -> 0
%   s     = 0.02                           fixed decision-space scale
%   dx    = G(t)*s*t_nu,   t_nu ~ t(nu)    t-distributed with nu(t) degrees of freedom
%   quantile bands: q-quantile of |t_nu| = tinv((1+q)/2, nu)  ->  95%/99% envelopes
%
% Output (release package)      : figures/FigureS1_perturbScale.png / .eps
% Output (development workspace): figSx_out/FigureS1_perturbScale.png / .eps
% Usage:
%   from the package root      : matlab -batch "cd scripts; plotFigSx_perturbScale"
%   from the dev workspace root: matlab -batch "plotFigSx_perturbScale"
% =========================================================================
    base    = fileparts(mfilename('fullpath'));   % .../scripts  or <dev workspace>
    pkgRoot = fileparts(base);
    FIGDIR = fullfile(pkgRoot,'figures');                          % release package
    if ~exist(FIGDIR,'dir'); FIGDIR = fullfile(base,'figSx_out'); end   % dev layout
    if ~exist(FIGDIR,'dir'); mkdir(FIGDIR); end
    FIGBASE = 'FigureS1_perturbScale';   % published name of Supplementary Figure S1

    nu_max = 20; nu_min = 2; s = 0.02; Tmax = 500;
    t = 0:Tmax;
    ratio = t / Tmax;
    nu = nu_max .* (nu_min/nu_max).^ratio;   % 20 -> 2
    G  = 2 .* (1 - ratio);                    % 2 -> 0
    env = G .* s;                             % deterministic amplitude envelope 0.04 -> 0

    % 95% / 99% quantiles of |t_nu| (symmetric t: quantile = tinv((1+q)/2, nu))
    q95 = zeros(size(nu)); q99 = zeros(size(nu));
    for i = 1:numel(nu)
        q95(i) = tinv(0.975, nu(i));
        q99(i) = tinv(0.995, nu(i));
    end
    band95 = env .* q95;
    band99 = env .* q99;

    f = figure('Color','w','Position',[100 100 760 460]); hold on;
    fill([t fliplr(t)]/Tmax, [band99 fliplr(band95)], [0.80 0.86 0.95], ...
         'EdgeColor','none','FaceAlpha',0.6,'DisplayName','|\Deltax| 99% envelope');
    plot(t/Tmax, band95, '--', 'Color',[0.25 0.45 0.75], 'LineWidth',1.2, ...
         'DisplayName','|\Deltax| 95% envelope');
    plot(t/Tmax, env, '-', 'Color',[0.85 0.20 0.15], 'LineWidth',2.0, ...
         'DisplayName','deterministic envelope G(t)\cdots');
    xlabel('normalized iteration  t / T_{max}');
    ylabel('perturbation magnitude  |\Deltax|');
    title('Amplitude scaling of the t-distribution perturbation');
    xlim([0 1]); grid on; box on;
    legend('Location','northeast');
    ylim([0 max(band99)*1.05]);

    % Numeric values for the caption (can be quoted in the text or the figure caption)
    fprintf('t/Tmax=0.0 : G=%.3f  nu=%.1f  95%%=%.4f  99%%=%.4f\n', G(1),  nu(1),  band95(1),  band99(1));
    fprintf('t/Tmax=0.5 : G=%.3f  nu=%.2f  95%%=%.4f  99%%=%.4f\n', G(251),nu(251),band95(251),band99(251));
    fprintf('t/Tmax=1.0 : G=%.3f  nu=%.2f  95%%=%.4f  99%%=%.4f\n', G(end),nu(end),band95(end),band99(end));

    exportgraphics(f, fullfile(FIGDIR,[FIGBASE '.png']), 'Resolution', 300);
    try; exportgraphics(f, fullfile(FIGDIR,[FIGBASE '.eps']), 'ContentType','vector'); end
    % Second export: MATLAB rasterises the axes toolbar on the first export; repeating the export removes it
    try, f.ToolBar.Visible = 'off'; catch, end
    try, disableDefaultInteractivity(f.CurrentAxes); catch, end
    exportgraphics(f, fullfile(FIGDIR,[FIGBASE '.png']), 'Resolution', 300);
    try; exportgraphics(f, fullfile(FIGDIR,[FIGBASE '.eps']), 'ContentType','vector'); end
    fprintf('[saved] %s\n', fullfile(FIGDIR,[FIGBASE '.png']));
end
