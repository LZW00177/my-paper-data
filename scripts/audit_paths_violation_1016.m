function audit_paths_violation_1016()
% audit_paths_violation_1016 - hard-constraint violation audit (all algorithms / all 30 runs / all archived solutions)
%
% Purpose (response to R2-3 / R3-M3): discrete waypoint checks cannot prove that the path between
% waypoints is collision-free, and the 1.32% pitch over-limit rate was reported for MO-ALA only.
% This script re-validates every hard constraint on the PUBLISHED smoothed trajectories stored in
% terrain_paths.mat (3xN samples per solution, N=100 when B-spline smoothing succeeded and N=22 for
% the discrete fallback), covering all six algorithms, both scenarios and all 30 runs:
%   (a) pitch     : per-segment |atan2(dz,dxy)| > theta_max
%   (b) collision : per-point z < max(terrain(x,y)+h_min, minH)
%   (c) boundary  : per-point x/y outside the flight box
% The counting convention is identical to runSmoothConstraintExp.m / runSmoothFairCompare.m.
% Usage: matlab -batch "audit_paths_violation_1016"
% Output: data/path_feasibility_audit_1016.mat + a console table
% =========================================================================
% Dual-layout resolution: run either from the release package
% (<pkg>/scripts/) or from the development workspace (repository root).
    base    = fileparts(mfilename('fullpath'));   % .../scripts  or <dev workspace>
    pkgRoot = fileparts(base);                    % package root when run from .../scripts
    DATA = fullfile(pkgRoot,'data');
    if ~exist(fullfile(DATA,'terrain_paths.mat'),'file')
        DATA = fullfile(base,'results');          % development layout
    end
    CODE = fullfile(pkgRoot,'code');
    if ~exist(CODE,'dir'); CODE = base; end       % development layout
    addpath(CODE);
    for sub = {'algorithms','metrics','terrain'}
        d = fullfile(CODE, sub{1});
        if exist(d,'dir'); addpath(d); end
    end
    rehash;

    % terrain_paths.mat: release package data/ first, then the 09-17 supplementary
    % package copy that was used when the audit was originally produced.
    P = fullfile(DATA,'terrain_paths.mat');
    if ~exist(P,'file')
        P = fullfile(base,'biomimetics-4584712_Supplementary_Material_Updated_20260917', ...
                     'data','terrain_paths.mat');
    end
    if ~exist(P,'file'); error('terrain_paths.mat not found: %s', P); end
    S = load(P);

    % Terrain reconstruction: seeds identical to runTerrainScenario.m
    rng(2026+1*100); T1 = terrainGeneration([100,100],'scenario','mountain','minH',40,'maxH',120);
    rng(2026+2*100); T2 = terrainGeneration([100,100],'scenario','landslide','minH',40,'maxH',120);
    TER = {T1,T2};

    Xmax = 100; Ymax = 100;
    theta_max = pi/3; h_min = 2;

    ALG = S.ALG_LIST;
    if iscell(ALG) && iscell(ALG{1}); ALG = cellfun(@(c) c{1}, ALG, 'UniformOutput', false); end
    Scenes = {'scene1','scene2'};

    fprintf('\n=== Hard-constraint audit on published smoothed trajectories ===\n');
    fprintf('%-7s %-8s | %7s %9s | %7s %9s | %9s\n', ...
            'scene','alg','nPath','pitchViol%','nSeg','collViol%','boundaryViol%');
    RES = struct();
    for si = 1:2
        terr = TER{si};
        for ai = 1:numel(ALG)
            a = ALG{ai};
            ar = S.pathData.(Scenes{si}).(a).allRuns;
            nSeg = 0; nViol = 0; nColl = 0; nBnd = 0; nPath = 0; nPt = 0;
            overSum = 0; overMax = 0;
            posHead = 0; posMid = 0; posTail = 0;   % violating segments in first / middle / last decile
            % Split by trajectory family: smoothed (>=50 points) vs discrete fallback (<=30 points)
            nSmooth = 0; nFallback = 0; violSmooth = 0; violFallback = 0; segSmooth = 0; segFallback = 0;
            for r = 1:numel(ar)
                if isempty(ar(r).points); continue; end
                for j = 1:numel(ar(r).points)
                    P0 = ar(r).points{j};
                    if ~isnumeric(P0) || size(P0,1) < 2; continue; end
                    nPath = nPath + 1;
                    isSmooth = size(P0,1) >= 50;
                    if isSmooth; nSmooth = nSmooth + 1; else; nFallback = nFallback + 1; end
                    % ---- pitch ----
                    d = diff(P0,1,1);
                    dxy = sqrt(d(:,1).^2 + d(:,2).^2) + eps;
                    pitch = atan2(d(:,3), dxy);
                    nSeg = nSeg + numel(pitch);
                    viol = abs(pitch) > theta_max;
                    nViol = nViol + sum(viol);
                    if isSmooth
                        segSmooth = segSmooth + numel(pitch); violSmooth = violSmooth + sum(viol);
                    else
                        segFallback = segFallback + numel(pitch); violFallback = violFallback + sum(viol);
                    end
                    if any(viol)
                        ov = (abs(pitch(viol)) - theta_max) * 180/pi;   % over-limit magnitude (deg)
                        overSum = overSum + sum(ov);
                        overMax = max(overMax, max(ov));
                        if ~isempty(P0)   % === positional distribution ===
                            ns = numel(pitch);
                            k = find(viol);
                            q = (k-1)/max(ns-1,1);
                            posHead = posHead + sum(q <= 0.10);
                            posTail = posTail + sum(q >= 0.90);
                            posMid  = posMid  + sum(q > 0.10 & q < 0.90);
                        end
                    end
                    % ---- collision & boundary (per point) ----
                    for k = 1:size(P0,1)
                        nPt = nPt + 1;
                        th = terr.getHeight(P0(k,1), P0(k,2));
                        if ~isfinite(th); th = 0; end
                        zlow = max(th + h_min, terr.minH);
                        if P0(k,3) < zlow; nColl = nColl + 1; end
                        if P0(k,1) < 0 || P0(k,1) > Xmax || P0(k,2) < 0 || P0(k,2) > Ymax
                            nBnd = nBnd + 1;
                        end
                    end
                end
            end
            pr = 100*nViol/max(nSeg,1);
            cr = 100*nColl/max(nPt,1);
            br = 100*nBnd/max(nPt,1);
            meanOver = overSum/max(nViol,1);
            fprintf('%-7s %-8s | %7d %8.3f%% | %7d %8.3f%% | %8.3f%% | over max %.2f mean %.2f | head/mid/tail %d/%d/%d | smooth(%d paths) %.3f%% vs fallback(%d) %.3f%%\n', ...
                    Scenes{si}, a, nPath, pr, nSeg, cr, br, overMax, meanOver, posHead, posMid, posTail, ...
                    nSmooth, 100*violSmooth/max(segSmooth,1), nFallback, 100*violFallback/max(segFallback,1));
            RES.(Scenes{si}).(a) = struct('nPath',nPath,'nSeg',nSeg,'nPts',nPt, ...
                'pitchViol',nViol,'pitchRate',pr,'collPts',nColl,'collRate',cr, ...
                'bndPts',nBnd,'bndRate',br,'overMaxDeg',overMax,'overMeanDeg',meanOver, ...
                'posHead',posHead,'posMid',posMid,'posTail',posTail, ...
                'nSmooth',nSmooth,'nFallback',nFallback, ...
                'rateSmooth',100*violSmooth/max(segSmooth,1), ...
                'rateFallback',100*violFallback/max(segFallback,1));
        end
    end

    out = RES; outM = struct('theta_max',theta_max,'h_min',h_min,'Xmax',Xmax,'Ymax',Ymax);
    save(fullfile(DATA,'path_feasibility_audit_1016.mat'), 'out', 'outM');
    fprintf('[saved] %s\n', fullfile(DATA,'path_feasibility_audit_1016.mat'));
end
