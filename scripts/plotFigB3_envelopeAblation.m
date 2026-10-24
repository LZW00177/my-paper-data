function plotFigB3_envelopeAblation()
% =========================================================================
% plotFigB3_envelopeAblation — Figure B.3 of the manuscript (Appendix B)
%
% WHAT THIS IS
%   The figure reproduced in Appendix B of the manuscript (labelled B.3 in
%   the appendix and captioned "Figure B.3" in the manuscript).  It shows the
%   envelope-only ablation of Reviewer 4's "artificial damping" objection:
%   mean HV (top) and mean IGD (bottom, log scale) for the three envelope
%   schedules of scripts/rerun_Gschedule_1016.m, on the six benchmarks.
%
% WHY IT IS REPRODUCIBLE FROM THIS PACKAGE ALONE
%   The numbers are read from the archived console log
%       logs/g_schedule_ablation_1016.txt
%   which is the human-readable output of the ablation run (and is itself
%   reproduced verbatim in the manuscript as the Appendix B.2 excerpt).  The
%   script parses that log; it does not re-run the optimisation and it does
%   not transcribe any number by hand.  A reader can therefore confirm that
%   every bar in the figure is a number printed in the log.
%
%   The three arms and their envelope definitions (as printed in the log):
%       linear : G(t) = 2(1 - t/(Tmax-1))   the manuscript rule
%       const  : G(t) = 2                   no amplitude contraction
%       floor  : G(t) = 2(1 - 0.9 t/(Tmax-1))   decays to 0.2, never 0
%
% OUTPUT
%   figures/FigureB3_envelopeAblation.png   (300 dpi)
%   figures/FigureB3_envelopeAblation.eps   (vector)
%
% USAGE
%   from the package root:  matlab -batch "cd scripts; plotFigB3_envelopeAblation"
%   from anywhere:          matlab -batch "addpath('<pkg>/scripts'); plotFigB3_envelopeAblation"
% =========================================================================
    base = fileparts(mfilename('fullpath'));
    pkgRoot = fileparts(base);                       % .../scripts -> package root
    LOGF = fullfile(pkgRoot, 'logs', 'g_schedule_ablation_1016.txt');
    if ~exist(LOGF, 'file')
        % development layout: the log sits next to the script
        LOGF = fullfile(base, 'g_schedule_ablation_1016.txt');
    end
    if ~exist(LOGF, 'file')
        error('plotFigB3_envelopeAblation:LogNotFound', ...
            'Cannot find logs/g_schedule_ablation_1016.txt (looked in %s).', pkgRoot);
    end

    FIGDIR = fullfile(pkgRoot, 'figures');
    if ~exist(FIGDIR, 'dir'); FIGDIR = fullfile(base, 'figures'); end
    if ~exist(FIGDIR, 'dir'); mkdir(FIGDIR); end

    [names, HV, IGD] = parseLog(LOGF);

    arms = {'linear', 'const', 'floor'};
    cols = [0.20 0.40 0.75; 0.90 0.50 0.15; 0.55 0.55 0.55];
    nB = numel(names);
    nA = numel(arms);
    w  = 0.8 / nA;                       % grouped bars, one group per benchmark
    xo = ((0:nA-1) - (nA-1)/2) * w;      % offsets inside a group (one per arm)

    fig = figure('Color', 'w', 'Position', [100 100 1080 720]);
    tl = tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

    % ---- top: mean HV ----
    ax1 = nexttile(tl);
    hold(ax1, 'on');
    for a = 1:nA
        bar(ax1, (1:nB) + xo(a), HV(a, :), w, 'FaceColor', cols(a, :), 'EdgeColor', 'none');
    end
    set(ax1, 'XTick', 1:nB, 'XTickLabel', names);
    ylabel(ax1, 'Mean HV');
    xlim(ax1, [0.5 nB + 0.5]);
    grid(ax1, 'on');
    box(ax1, 'on');
    legend(ax1, arms, 'Location', 'northwest', 'Box', 'off');
    title(ax1, '', 'FontWeight', 'normal');
    text(ax1, 1.0, 1.0, 'HV = 0 for all arms on DTLZ1/DTLZ3', ...
        'Units', 'normalized', 'Position', [0.99 0.99], ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
        'FontName', 'Italic', 'FontSize', 9, 'Parent', ax1);

    % ---- bottom: mean IGD (log scale) ----
    ax2 = nexttile(tl);
    hold(ax2, 'on');
    for a = 1:nA
        bar(ax2, (1:nB) + xo(a), IGD(a, :), w, 'FaceColor', cols(a, :), 'EdgeColor', 'none');
    end
    set(ax2, 'XTick', 1:nB, 'XTickLabel', names);
    ylabel(ax2, 'Mean IGD (log scale)');
    xlim(ax2, [0.5 nB + 0.5]);
    set(ax2, 'YScale', 'log');
    grid(ax2, 'on');
    box(ax2, 'on');

    exportgraphics(fig, fullfile(FIGDIR, 'FigureB3_envelopeAblation.png'), 'Resolution', 300);
    try; exportgraphics(fig, fullfile(FIGDIR, 'FigureB3_envelopeAblation.eps'), 'ContentType', 'vector'); end
    fprintf('[saved] %s\n', fullfile(FIGDIR, 'FigureB3_envelopeAblation.png'));
    fprintf('[saved] %s\n', fullfile(FIGDIR, 'FigureB3_envelopeAblation.eps'));
end

% ------------------------------------------------------------------------
function [names, HV, IGD] = parseLog(fname)
% parseLog — read the archived console log of the envelope ablation.
%   The log has the block structure
%       == <BENCH> (Tmax=<T>) ==
%         mean HV : linear=<h1>  const=<h2>  floor=<h3>
%         mean IGD: linear=<i1>  const=<i2>  floor=<i3>
%   so the two "mean" lines of each block give the three arm values in the
%   order linear, const, floor.  Nothing is hard-coded here.
    fid = fopen(fname, 'r');
    if fid < 0
        error('plotFigB3_envelopeAblation:LogUnreadable', 'Cannot open %s.', fname);
    end
    names = {}; HV = []; IGD = [];
    cur = '';
    while true
        line = fgetl(fid);
        if ~ischar(line); break; end
        t = strtrim(line);
        if isempty(t); continue; end
        if startsWith(t, '== ')
            p = strsplit(t, ' ');
            cur = strrep(p{2}, '(', '');
            continue;
        end
        if startsWith(t, 'mean HV :')
            v = sscanf(t, 'mean HV : linear=%f  const=%f  floor=%f');
            if numel(v) ~= 3
                error('plotFigB3_envelopeAblation:Parse', 'Bad "mean HV" line: %s', t);
            end
            names{end+1} = cur; HV(end+1, :) = v;
            continue;
        end
        if startsWith(t, 'mean IGD:')
            v = sscanf(t, 'mean IGD: linear=%f const=%f floor=%f');
            if numel(v) ~= 3
                error('plotFig3:Parse', 'Bad "mean IGD" line: %s', t);
            end
            IGD(end+1, :) = v;
            continue;
        end
    end
    fclose(fid);
    if isempty(names) || size(HV,1) ~= numel(names) || size(IGD,1) ~= numel(names)
        error('plotFigB3_envelopeAblation:Parse', ...
            'Parsed %d benchmark blocks (HV rows %d, IGD rows %d) from %s.', ...
            numel(names), size(HV,1), size(IGD,1), fname);
    end
    HV = HV'; IGD = IGD';   % rows -> arms x benchmarks
end
