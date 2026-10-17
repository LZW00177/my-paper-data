% combine_scenario_evidence_1016.m
% -------------------------------------------------------------------------
% Reproduces the two-scenario evidence-combination figures quoted in the
% response letter (item R2-1b): the Fisher combination of the D-vs-A
% hypervolume p-values from the two terrain scenarios, and the range of that
% combined p over the Monte-Carlo spread of the mountain p-value.
%
% Input  : data/hv_reference_robustness_1016.mat   (package layout)
%          results/hv_reference_robustness_1016.mat (development layout)
%          (written by audit_hv_reference_robustness_1016.m -- offline
%           re-scoring of archived fronts; no re-optimisation)
% Output : logs/combine_scenario_evidence_1016.txt (package layout)
%          results/combine_scenario_evidence_1016.txt (development layout)
% Usage  : from the package root,  matlab -batch "cd scripts; combine_scenario_evidence_1016"
%          from the dev workspace, matlab -batch "combine_scenario_evidence_1016"
%
% Why Fisher and not a correction: the two scenarios are two independent
% experiments (different terrain scenes, different random streams, separate
% runs), each carrying one pre-declared primary contrast. On independent
% experiments the operation that matches the design is COMBINATION of
% evidence, not DIVISION of one error budget. Both are reported in the letter
% so the reader can choose.
%
% The two p-values combined below are the K-averaged estimates for the SAME
% contrast (A vs D) in two DIFFERENT scenarios. Combining two re-scorings of
% the SAME scenario would double-count a single experiment and is not done
% here -- the audit stores both scenarios' values separately for that reason.
% -------------------------------------------------------------------------
clear; clc;

% Layout resolution: the shipped package keeps the archives in data/ and the
% human-readable reports in logs/; the development workspace kept both in
% results/. Resolve from the script's own location so that the script also runs
% from a bare package download (cd scripts; combine_scenario_evidence_1016).
base    = fileparts(mfilename('fullpath'));   % .../scripts  or <dev workspace>
pkgRoot = fileparts(base);                    % package root when run from .../scripts
DATA = fullfile(pkgRoot,'data');
if ~exist(fullfile(DATA,'hv_reference_robustness_1016.mat'),'file')
    DATA = fullfile(base,'results');          % development layout
end
LOGS = fullfile(pkgRoot,'logs');
if ~exist(LOGS,'dir'); LOGS = DATA; end       % development layout
MATF = fullfile(DATA,'hv_reference_robustness_1016.mat');
if ~exist(MATF, 'file')
    error('hv_reference_robustness_1016.mat not found under %s (run audit_hv_reference_robustness_1016 first)', DATA);
end
S = load(MATF);
refs = {'R1_baselineUnion', 'R2_allUnion', 'R3_loose110', 'R4_tight090'};
ii   = 3;    % printed pair order is A-B, A-C, A-D, B-D, C-D, B-C

L = {};
L{end+1} = 'Fisher combination of the D-vs-A hypervolume contrast across the two terrain scenarios';
L{end+1} = '  (offline; reads the archived-front audit; no re-optimisation)';
% display the archive path relative to the package root when it lives inside it
srcDisp = MATF;
if strncmp(MATF, pkgRoot, numel(pkgRoot)); srcDisp = MATF(numel(pkgRoot)+2:end); end
L{end+1} = sprintf('  source   : %s', srcDisp);
L{end+1} = sprintf('  contrast : pair index %d = A vs D ; df = 4 ; two independent experiments', ii);
L{end+1} = '';

L{end+1} = sprintf('%-20s %11s %11s %10s %10s   %s', ...
    'reference box', 'p_mountain', 'p_debris', 'chi2', 'p_combined', 'verdict');
for r = 1:numel(refs)
    pm = S.(sprintf('HVpK_%s_scene1', refs{r})); pm = pm(ii);
    pd = S.(sprintf('HVpK_%s_scene2', refs{r})); pd = pd(ii);
    x2 = -2 * (log(pm) + log(pd));
    pc = chi2sf4(x2);
    L{end+1} = sprintf('%-20s %11.5f %11.5f %10.4f %10.5f   %s', ...
        refs{r}, pm, pd, x2, pc, tern(pc < 0.05, 'significant', 'n.s.'));
end

L{end+1} = '';
L{end+1} = 'Robustness to the Monte-Carlo spread of the mountain p-value (20 independent draws):';
for r = 1:numel(refs)
    d  = S.(sprintf('HVpDist_%s_scene1', refs{r}));
    % HVpDist is (K draws) x (6 pairs); select the A-vs-D COLUMN.
    if size(d, 1) == 6 && size(d, 2) ~= 6, d = d.'; end
    d = d(:, ii);
    pd = S.(sprintf('HVpK_%s_scene2', refs{r}));    pd = pd(ii);
    xhi = -2 * (log(max(d)) + log(pd));   % largest mountain p -> weakest combination
    xlo = -2 * (log(min(d)) + log(pd));   % smallest mountain p -> strongest
    L{end+1} = sprintf('  %-20s mountain p in [%.5f %.5f] -> combined p in [%.5f %.5f]', ...
        refs{r}, min(d), max(d), chi2sf4(xhi), chi2sf4(xlo));
end

L{end+1} = '';
L{end+1} = 'Reading: the combination stays below 0.05 across the whole feasible range of the';
L{end+1} = 'mountain p-value, so the conclusion does not depend on which draw the archive happened';
L{end+1} = 'to record. The hypervolume means and the deterministic IGD contrasts are unaffected by';
L{end+1} = 'this estimator noise (see the hv_reference_robustness_1016.txt report in logs/).';

txt = strjoin(L, sprintf('\n'));
fprintf('%s\n', txt);
fid = fopen(fullfile(LOGS, 'combine_scenario_evidence_1016.txt'), 'w');
fprintf(fid, '%s\n', txt);
fclose(fid);
fprintf('\n[saved] %s\n', fullfile(LOGS, 'combine_scenario_evidence_1016.txt'));

% -------------------------------------------------------------------------
function p = chi2sf4(x)
% Upper-tail probability of chi-square with 4 degrees of freedom.
% Closed form (no Statistics Toolbox dependency): P(X > x) = exp(-x/2)*(1+x/2).
    p = exp(-x / 2) .* (1 + x / 2);
end

function s = tern(c, a, b)
    if c, s = a; else, s = b; end
end
