%% run_all_figs.m -- regenerate every paper figure from MOALA/data (integration test)
clear; clc;
base = fileparts(mfilename('fullpath'));   % MOALA/
addpath(fullfile(base,'scripts'));
addpath(fullfile(base,'code'));
out = fopen(fullfile(base,'run_all_figs.txt'),'w','n','UTF-8');
pr = @(varargin) fprintf(out, varargin{:});

scripts = {
 'plot_Fig1_terrain_threat','plotFig1_TerrainThreatField'
 'plot_Fig3_radar','plotFig3_ablation_radar'
 'plot_Fig4_convergence','plotFig4xin_Convergence'
 'plot_Fig5_IGD_boxplot','plotFig5_IGD_Boxplot'
 'plot_Fig6_Fig8_pareto','plotFig6and8_Pareto'
 'plot_Fig7_Fig9_paths','plotFig7and9_lujing'
 'plot_Fig10_paramsweep','plotFig10_ParamSweep_Combined_v2'};

for i=1:size(scripts,1)
    fn = scripts{i,1}; fname = scripts{i,2};
    pr('\n===== [%d/%d] %s =====\n', i, size(scripts,1), fn);
    fprintf('===== [%d/%d] %s =====\n', i, size(scripts,1), fn);
    try
        fh = str2func(fname);
        fh();
        pr('  OK\n');
    catch ME
        pr('  FAILED: %s\n', ME.message);
        fprintf('  FAILED: %s\n', ME.message);
        for k=1:numel(ME.stack)
            pr('    at %s line %d\n', ME.stack(k).name, ME.stack(k).line);
        end
    end
    close all force;
end
fclose(out);
disp('DONE run_all_figs');
