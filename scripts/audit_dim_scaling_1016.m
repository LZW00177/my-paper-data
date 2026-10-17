function audit_dim_scaling_1016()
% audit_dim_scaling_1016 - wall-clock time scaling with problem dimension (response to R3-minor-1)
%
% The per-iteration cost of MO-ALA is O(M*N^2 + N*D + N_arch*log(N_arch)) (Eq. (22));
% the leading term M*N^2 does not depend on the dimension, so the per-run time is expected
% to grow approximately linearly with D = 3*N_w. This script uses the mountain scenario with
% N_w = 10/20/30 (D = 30/60/90) at N = 30, T_max = 500, N_arch = 50, one run each, and records
% the per-run wall-clock time together with HV.
% Usage: from the package root,  matlab -batch "cd scripts; audit_dim_scaling_1016"
%        from the dev workspace, matlab -batch "audit_dim_scaling_1016"
% Output: data/dim_scaling_1016.mat + a console table
% =========================================================================
% REQUIRES CODE THAT IS NOT PART OF THIS PACKAGE (patent restriction)
%   This experiment calls the core MO-ALA implementation and the terrain
%   problem class, which are withheld together with their calling harness as
%   stated in the Data Availability Statement.  To re-run it you must obtain
%   from the corresponding author and place on the MATLAB path:
%       MOALA.m         (the algorithm; also needs ALAOperators.m / ArchiveManager.m)
%       UAVMultiObj.m   (the terrain multi-objective problem class)
%   Everything else used here -- terrainGeneration.m, threatField.m and
%   MetricsCalculator.m -- is included in this package (code/).  The numerical
%   result is archived as data/dim_scaling_1016.mat and can be inspected, and
%   audited against Section 3.5 / Supplementary Table S5, without re-running.
% =========================================================================
    base    = fileparts(mfilename('fullpath'));   % .../scripts  or <dev workspace>
    pkgRoot = fileparts(base);                    % package root when run from .../scripts
    DATA = fullfile(pkgRoot,'data');
    if ~exist(DATA,'dir'); DATA = fullfile(base,'results'); end          % development layout
    CODE = fullfile(pkgRoot,'code');
    if ~exist(CODE,'dir'); CODE = base; end                               % development layout
    addpath(CODE);
    for sub = {'algorithms','metrics','terrain'}
        d = fullfile(CODE, sub{1});
        if exist(d,'dir'); addpath(d); end
    end
    rehash;

    % Preflight: fail fast with an actionable message instead of a cryptic
    % "Undefined function" once the optimisation is about to start.
    need = {'MOALA','UAVMultiObj'};
    miss = need(cellfun(@(f) isempty(which(f)), need));
    if ~isempty(miss)
        error([mfilename ':WithheldCode', ...
            'This script needs the withheld core implementation (%s). See the ' ...
            'header of this file and the Data Availability Statement; the archived ' ...
            'result is data/dim_scaling_1016.mat.'], strjoin(miss, ', '));
    end

    NW = [10 20 30];      % number of free waypoints -> D = 3*NW
    T  = 500; N = 30; NA = 50;
    fprintf('\n=== Wall-clock scaling with dimension (mountain, N=%d, T=%d, N_arch=%d) ===\n', N, T, NA);
    fprintf('%6s %6s %14s %12s %10s\n','N_w','D','time/s','time/it/ms','HV');

    res = struct('Nw',{},'D',{},'time',{},'HV',{},'archSize',{});
    for k = 1:numel(NW)
        nw = NW(k);
        rng(2026+1*100);
        terrain = terrainGeneration([100,100],'scenario','mountain','minH',40,'maxH',120);
        threat  = threatField('mountain');
        rng(2026+1*100);
        prob = UAVMultiObj(terrain, threat);
        prob.numWaypoints = nw;
        % D varies with numWaypoints: rebuild dim/lb/ub (the constructor default assumes 20 waypoints)
        prob.dim = 3*nw;
        prob.lb  = repmat(prob.lb(1:3), 1, nw);
        prob.ub  = repmat(prob.ub(1:3), 1, nw);
        prob.startPoint = [5,5,50]; prob.endPoint = [95,95,50];

        o.N = N; o.T_max = T; o.D = prob.dim; o.lb = prob.lb; o.ub = prob.ub;
        o.N_arch = NA; o.nu_max = 20; o.nu_min = 2;
        alg = MOALA(o);

        t0 = tic;
        [archive,~] = alg.optimize(prob,'verbose',false,'seed',2026+10000+1000);
        tt = toc(t0);

        archF = archive.objectives;
        hv = 0;
        if size(archF,1) >= 2
            try
                hvRef = MetricsCalculator.estimateHVRefPoint({archF});
                Pc = MetricsCalculator.pruneOutliers(archF, 0.99);
                Pn = MetricsCalculator.normalizeFront(Pc, hvRef);
                hv = MetricsCalculator.HV(Pn, ones(1,size(archF,2)), 50000);
            catch
                hv = 0;
            end
        end
        fprintf('%6d %6d %14.2f %12.3f %10.4f\n', nw, prob.dim, tt, 1000*tt/T, hv);
        res(k) = struct('Nw',nw,'D',prob.dim,'time',tt,'HV',hv,'archSize',size(archF,1));
    end

    save(fullfile(DATA,'dim_scaling_1016.mat'),'res');
    fprintf('[saved] %s\n', fullfile(DATA,'dim_scaling_1016.mat'));
end
