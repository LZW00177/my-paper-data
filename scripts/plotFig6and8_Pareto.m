function plotFig6and8_Pareto()
    % 生成图6和图8：场景一与场景二的Pareto前沿对比图
    % 采用三维散点展示 J1, J2, J3，颜色映射 J4
    % 形状区分算法，颜色统一表示 J4

    base = fileparts(mfilename('fullpath'));
    root = fileparts(base);
    
    possiblePaths = {
        fullfile(base, '..', 'data', 'terrain_paths.mat');
        fullfile(root, 'data', 'terrain_paths.mat');
        fullfile(base, 'data', 'terrain_paths.mat');
    };
    
    dataFile = '';
    for i = 1:length(possiblePaths)
        if exist(possiblePaths{i}, 'file')
            dataFile = possiblePaths{i};
            break;
        end
    end
    
    if isempty(dataFile)
        error('Data file data/terrain_paths.mat not found.');
    end
    
    fprintf('Loading data from: %s\n', dataFile);
    S = load(dataFile);
    
    if isfield(S, 'pathData')
        pathData = S.pathData;
    elseif isfield(S, 'scene1') && isfield(S, 'scene2')
        pathData.scene1 = S.scene1;
        pathData.scene2 = S.scene2;
    else
        error('Unexpected data structure.');
    end

    parentDir = fileparts(base);
    RES = fullfile(parentDir, 'figures');
    if ~exist(RES, 'dir'); mkdir(RES); end
    % 算法定义
    ALG_KEYS  = {'MOALA', 'NSGAII', 'MOPSO', 'EALA', 'IALA', 'HALA'};
    ALG_NAMES = {'MO-ALA', 'NSGA-II', 'MOPSO', 'EALA', 'IALA', 'HALA'};
    ALG_MARKERS = {'p', 'o', 's', 'x', '^', 'd'};  % 形状区分算法
    ALG_SIZES   = [80, 50, 50, 40, 56, 58];         % 点大小

    X_LABEL = '$J_1$: Path Length (m)';
    Y_LABEL = '$J_2$: Energy Consumption';
    Z_LABEL = '$J_3$: Safety and Search Coverage Cost';
    C_LABEL = '$J_4$: Sensor Imaging Quality';

    drawFrontFigure(pathData.scene1, ALG_KEYS, ALG_NAMES, ALG_MARKERS, ALG_SIZES, ...
        RES, 'fig6_scene1_pareto', ...
        'Fig. 6 Mountain Rescue Scenario: Pareto Front Comparison', ...
        X_LABEL, Y_LABEL, Z_LABEL, C_LABEL);

    drawFrontFigure(pathData.scene2, ALG_KEYS, ALG_NAMES, ALG_MARKERS, ALG_SIZES, ...
        RES, 'fig8_scene2_pareto', ...
        'Fig. 8 Debris Flow Scenario: Pareto Front Comparison', ...
        X_LABEL, Y_LABEL, Z_LABEL, C_LABEL);

    fprintf('[saved] Fig. 6 & Fig. 8 have been saved to figures/\n');
end

function drawFrontFigure(sceneData, ALG_KEYS, ALG_NAMES, ALG_MARKERS, ALG_SIZES, ...
    RES, tag, ttl, xl, yl, zl, cl)
    
    fh = figure('Color', 'w', 'Position', [100, 100, 980, 680]);
    hold on; grid on; box on;
    set(gca, 'FontSize', 10, 'LineWidth', 1.2);

    % ====== 第一步：扫描所有算法的 J4 范围，统一颜色映射 ======
    minC = inf; maxC = -inf;
    for k = 1:length(ALG_KEYS)
        key = ALG_KEYS{k};
        if isfield(sceneData, key) && isfield(sceneData.(key), 'allRuns') && ...
           ~isempty(sceneData.(key).allRuns(1).F)
            F = sceneData.(key).allRuns(1).F;
            if size(F, 2) >= 4
                minC = min(minC, min(F(:,4)));
                maxC = max(maxC, max(F(:,4)));
            end
        end
    end
    if maxC == -inf
        minC = 0.5; maxC = 5.5;  % 保底范围
    end

    % ====== 第二步：绘制散点 ======
    % 先画对比算法（底层），再画 MO-ALA（顶层）
    draw_order = [2, 3, 4, 5, 6, 1];  % 最后画 MO-ALA
    
    h = gobjects(length(ALG_KEYS), 1);  % 存储图形句柄用于图例

    for i = 1:length(draw_order)
        k = draw_order(i);
        key = ALG_KEYS{k};
        
        if ~isfield(sceneData, key) || ~isfield(sceneData.(key), 'allRuns') || ...
           isempty(sceneData.(key).allRuns(1).F)
            continue;
        end
        
        F = sceneData.(key).allRuns(1).F;
        if size(F, 2) < 3, continue; end
        
        x = F(:,1); y = F(:,2); z = F(:,3);
        
        % 获取 J4 值，如果没有第4列则设为中值
        if size(F, 2) >= 4
            c = F(:,4);
        else
            c = ones(size(x)) * (minC + maxC) / 2;
        end
        
        % 关键修改：用 J4 作为颜色，用 marker 形状区分算法
        % scatter3(X, Y, Z, 点大小, 颜色, 标记形状, 'filled')
        h(k) = scatter3(x, y, z, ALG_SIZES(k), c, ALG_MARKERS{k}, ...
            'filled', ...
            'MarkerEdgeColor', 'k', 'LineWidth', 0.5, ...
            'DisplayName', ALG_NAMES{k});
    end

    % ====== 第三步：设置颜色映射 ======
    caxis([minC, maxC]);
    colormap(parula);  % 或 jet, turbo, viridis
    
    cb = colorbar;
    cb.Label.String = cl;
    cb.Label.Interpreter = 'latex';
    cb.Label.FontSize = 11;

    % ====== 第四步：视图与标注 ======
    view(-40, 20);
    xlabel(xl, 'Interpreter', 'latex', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel(yl, 'Interpreter', 'latex', 'FontSize', 12, 'FontWeight', 'bold');
    zlabel(zl, 'Interpreter', 'latex', 'FontSize', 12, 'FontWeight', 'bold');
    %title(ttl, 'Interpreter', 'none', 'FontSize', 14, 'FontWeight', 'bold');

    % ====== 第五步：图例 ======
    lgd = legend(h, ALG_NAMES, 'Location', 'northeastoutside');
    lgd.FontSize = 10;
    lgd.Box = 'on';

    % ====== 第六步：保存 ======
    saveas(fh, fullfile(RES, [tag '.png']));
    saveas(fh, fullfile(RES, [tag '.fig']));
    close(fh);
    fprintf(' [saved] %s\n', tag);
end