function plotFig5and7_Pareto_allRuns()
    % 图5和图7：所有30次运行合并Pareto前沿对比
    % 形状区分算法，颜色表示 J4
    % 每个算法显示所有 runs 的非支配解合并集

    base = fileparts(mfilename('fullpath'));
    root = fileparts(base);
    
    possiblePaths = {
        fullfile(base, 'results', 'pathCoords.mat');
        fullfile(root, 'results', 'pathCoords.mat');
        fullfile(base, '..', 'results', 'pathCoords.mat');
        'pathCoords.mat'
    };
    
    dataFile = '';
    for i = 1:length(possiblePaths)
        if exist(possiblePaths{i}, 'file')
            dataFile = possiblePaths{i};
            break;
        end
    end
    
    if isempty(dataFile)
        error('Data file pathCoords.mat not found.');
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
    ALG_MARKERS = {'p', 'o', 's', 'x', '^', 'd'};
    ALG_SIZES   = [60, 40, 40, 34, 44, 46];

    X_LABEL = '$J_1$: Path Length (m)';
    Y_LABEL = '$J_2$: Energy Consumption';
    Z_LABEL = '$J_3$: Safety and Search Coverage Cost';
    C_LABEL = '$J_4$: Sensor Imaging Quality';

    % 场景一：山地救援
    drawFrontFigure_allRuns(pathData.scene1, ALG_KEYS, ALG_NAMES, ALG_MARKERS, ALG_SIZES, ...
        RES, 'fig5_scene1_pareto_allRuns', ...
        'Fig. 5 Mountain Rescue: Pareto Front (All 30 Runs Merged)', ...
        X_LABEL, Y_LABEL, Z_LABEL, C_LABEL);

    % 场景二：泥石流投放
    drawFrontFigure_allRuns(pathData.scene2, ALG_KEYS, ALG_NAMES, ALG_MARKERS, ALG_SIZES, ...
        RES, 'fig7_scene2_pareto_allRuns', ...
        'Fig. 7 Debris Flow: Pareto Front (All 30 Runs Merged)', ...
        X_LABEL, Y_LABEL, Z_LABEL, C_LABEL);

    fprintf('[saved] Fig. 5 & Fig. 7 (all runs merged) saved to figures/\n');
end

function drawFrontFigure_allRuns(sceneData, ALG_KEYS, ALG_NAMES, ALG_MARKERS, ALG_SIZES, ...
    RES, tag, ttl, xl, yl, zl, cl)
    
    fh = figure('Color', 'w', 'Position', [100, 100, 1020, 720]);
    hold on; grid on; box on;
    set(gca, 'FontSize', 10, 'LineWidth', 1.2);

    % ====== 第一步：合并所有30次运行的非支配解 ======
    mergedData = cell(length(ALG_KEYS), 1);
    
    for k = 1:length(ALG_KEYS)
        key = ALG_KEYS{k};
        
        if ~isfield(sceneData, key) || ~isfield(sceneData.(key), 'allRuns')
            mergedData{k} = [];
            continue;
        end
        
        nRuns = length(sceneData.(key).allRuns);
        allSolutions = [];
        
        for r = 1:nRuns
            if isfield(sceneData.(key).allRuns(r), 'F') && ~isempty(sceneData.(key).allRuns(r).F)
                allSolutions = [allSolutions; sceneData.(key).allRuns(r).F];
            end
        end
        
        if isempty(allSolutions)
            mergedData{k} = [];
            continue;
        end
        
        % 提取非支配解（对所有合并解做非支配排序，只保留第1前沿）
        % 注意：这里假设目标越小越好（最小化问题）
        n = size(allSolutions, 1);
        isDominated = false(n, 1);
        
        for i = 1:n
            for j = 1:n
                if i == j, continue; end
                % 如果 j 支配 i
                if all(allSolutions(j,1:3) <= allSolutions(i,1:3) + 1e-10) && ...
                   any(allSolutions(j,1:3) < allSolutions(i,1:3) - 1e-10)
                    isDominated(i) = true;
                    break;
                end
            end
        end
        
        mergedData{k} = allSolutions(~isDominated, :);
        fprintf('  %s: %d runs -> %d merged non-dominated solutions\n', ...
            ALG_NAMES{k}, nRuns, size(mergedData{k}, 1));
    end

    % ====== 第二步：扫描所有算法的 J4 范围 ======
    minC = inf; maxC = -inf;
    for k = 1:length(ALG_KEYS)
        if ~isempty(mergedData{k}) && size(mergedData{k}, 2) >= 4
            minC = min(minC, min(mergedData{k}(:,4)));
            maxC = max(maxC, max(mergedData{k}(:,4)));
        end
    end
    if maxC == -inf
        minC = 0.5; maxC = 5.5;
    end

    % ====== 第三步：绘制散点 ======
    % 先画对比算法，再画 MO-ALA
    draw_order = [2, 3, 4, 5, 6, 1];
    h = gobjects(length(ALG_KEYS), 1);

    for i = 1:length(draw_order)
        k = draw_order(i);
        data = mergedData{k};
        
        if isempty(data) || size(data, 2) < 3
            continue;
        end
        
        x = data(:,1); y = data(:,2); z = data(:,3);
        
        if size(data, 2) >= 4
            c = data(:,4);
        else
            c = ones(size(x)) * (minC + maxC) / 2;
        end
        
        % 用 J4 作为颜色，marker 形状区分算法
        h(k) = scatter3(x, y, z, ALG_SIZES(k), c, ALG_MARKERS{k}, ...
            'filled', ...
            'MarkerEdgeColor', 'k', 'LineWidth', 0.4, ...
            'DisplayName', sprintf('%s (%d)', ALG_NAMES{k}, size(data, 1)));
    end

    % ====== 第四步：颜色映射 ======
    caxis([minC, maxC]);
    colormap(parula);
    
    cb = colorbar;
    cb.Label.String = cl;
    cb.Label.Interpreter = 'latex';
    cb.Label.FontSize = 11;

    % ====== 第五步：视图与标注 ======
    view(-40, 20);
    xlabel(xl, 'Interpreter', 'latex', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel(yl, 'Interpreter', 'latex', 'FontSize', 12, 'FontWeight', 'bold');
    zlabel(zl, 'Interpreter', 'latex', 'FontSize', 12, 'FontWeight', 'bold');
    title(ttl, 'Interpreter', 'none', 'FontSize', 14, 'FontWeight', 'bold');

    % ====== 第六步：图例 ======
    lgd = legend(h, 'Location', 'northeastoutside');
    lgd.FontSize = 9;
    lgd.Box = 'on';

    % ====== 第七步：保存 ======
    saveas(fh, fullfile(RES, [tag '.png']));
    saveas(fh, fullfile(RES, [tag '.fig']));
    close(fh);
    fprintf(' [saved] %s\n', tag);
end