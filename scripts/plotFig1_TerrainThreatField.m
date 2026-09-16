function plotFig1_TerrainThreatField()
% plotFig2_TerrainThreatField — 论文图2：双场景三维地形+威胁场
% (a) 山地场景 3D 地形（绿色高程着色）+威胁源标注+图例
% (b) 泥石流场景 3D 地形（绿色高程着色）+威胁源标注+图例
% (c) 山地典型高度(z=64m)威胁水平截面热力图
% (d) 泥石流典型高度(z=56m)威胁水平截面热力图
clc; close all;
root = fileparts(fileparts(mfilename('fullpath')));   % = MOALA/
addpath(fullfile(root,'code'));
rehash;

%% 构建双场景
fprintf('构建场景...\n');
terrainM = terrainGeneration([100,100], 'scenario','mountain', 'minH',40, 'maxH',120);
threatM  = threatField('mountain');
terrainL = terrainGeneration([100,100], 'scenario','landslide', 'minH',40, 'maxH',120);
threatL  = threatField('landslide');

scenes = {terrainM, threatM, 'Mountain', 64; ...   % 山地：威胁高度带中心 64m
           terrainL, threatL, 'Debris flow', 56};   % 泥石流：禁飞区高度 56m

% 绿色高程渐变 colormap（低浅黄绿 → 高墨绿，高程层次感强）
greenMap = [0.92 0.96 0.62; 0.72 0.88 0.50; 0.45 0.72 0.35; ...
            0.20 0.52 0.22; 0.09 0.32 0.12; 0.04 0.18 0.06];
greenMap = interp1(linspace(0,1,size(greenMap,1)), greenMap, linspace(0,1,256));

fig = figure('Color','w','Position',[40 40 1500 950],'Name','Fig2 Terrain & Threat');
tl = tiledlayout(fig, 2, 2, 'TileSpacing','compact','Padding','compact');

for si = 1:2
    terrain = scenes{si,1}; threat = scenes{si,2};
    scenName = scenes{si,3}; zSlice = scenes{si,4};

    %% ---- 左列：3D 地形（绿色高程）+ 威胁源 ----
    ax3 = nexttile(tl);
    hold(ax3,'on'); grid(ax3,'on'); axis(ax3,'equal');
    xlabel(ax3,'x (m)','FontSize',11,'FontWeight','bold');
    ylabel(ax3,'y (m)','FontSize',11,'FontWeight','bold');
    zlabel(ax3,'z (m)','FontSize',11,'FontWeight','bold');

    % 地形 DEM：绿色高程着色（按海拔渐变）
    [Tx,Ty] = meshgrid(1:100,1:100);
    surf(ax3, Tx, Ty, terrain.map_z, terrain.map_z, ...
        'FaceAlpha',0.92, 'EdgeColor','none');
    colormap(ax3, greenMap);
    clim(ax3, [min(terrain.map_z(:)), max(terrain.map_z(:))]);

    % 威胁源椭圆标注（抬升到地形上方避免被遮挡），图例按类型去重
    theta = linspace(0, 2*pi, 100);
    legObjs = gobjects(0); legNames = {};
    seenType = {};
    for i = 1:numel(threat.threats)
        t = threat.threats(i);
        xe = t.center(1) + t.rx*cos(theta);
        ye = t.center(2) + t.ry*sin(theta);
        % 每个采样点取地形高度+偏移，保证椭圆始终在地表上方可见
        zBase = zeros(size(xe));
        for k = 1:numel(xe)
            zBase(k) = terrain.getHeight(xe(k), ye(k));
        end
        ze = zBase + t.height*0.25 + 2;  % 地表以上，略低于威胁高度带中心
        switch t.type
            case 'powerline'
                hE = plot3(ax3, xe, ye, ze, '-', 'Color',[0.85 0.15 0.15], 'LineWidth', 3.0);
            case 'cliff'
                hE = plot3(ax3, xe, ye, ze, '-', 'Color',[0.55 0.27 0.07], 'LineWidth', 3.0);
            case 'ruins'
                hE = plot3(ax3, xe, ye, ze, '-', 'Color',[0.75 0.15 0.75], 'LineWidth', 3.0);
            case 'airspace'
                hE = plot3(ax3, xe, ye, ze, '-', 'Color',[0.10 0.35 0.90], 'LineWidth', 3.0);
            case 'nofly'
                hE = plot3(ax3, xe, ye, ze, '-', 'Color',[0.95 0.70 0.10], 'LineWidth', 3.5);
        end
        if ~any(strcmp(seenType, t.type))
            legObjs(end+1) = hE; %#ok<AGROW>
            legNames{end+1} = t.type; %#ok<AGROW>
            seenType{end+1} = t.type; %#ok<AGROW>
        end
        plot3(ax3, t.center(1), t.center(2), ze(1), 'o', ...
            'MarkerSize', 10, 'MarkerFaceColor','w', 'MarkerEdgeColor','k', 'LineWidth', 1.5);
    end

    % 起终点
    if si == 1
        sp = [5 5 50]; ep = [95 95 50];
    else
        sp = [10 90 50]; ep = [90 10 50];
    end
    hS = plot3(ax3, sp(1), sp(2), sp(3), 'go', 'MarkerSize', 12, 'LineWidth', 2);
    hT = plot3(ax3, ep(1), ep(2), ep(3), 'rs', 'MarkerSize', 12, 'LineWidth', 2);
    text(ax3, sp(1), sp(2), sp(3)+5, 'S', 'FontSize', 12, 'FontWeight','bold', 'Color','g');
    text(ax3, ep(1), ep(2), ep(3)+5, 'T', 'FontSize', 12, 'FontWeight','bold', 'Color','r');
    legObjs(end+1) = hS; legNames{end+1} = 'Start point'; %#ok<AGROW>
    legObjs(end+1) = hT; legNames{end+1} = 'Target point'; %#ok<AGROW>

    title(ax3, sprintf('(%s) %s: 3D terrain and threat sources', char('a'+si-1), scenName), ...
        'FontSize', 13, 'FontWeight','bold');
    view(ax3, -42, 26);
    xlim(ax3, [0 105]); ylim(ax3, [0 105]); zlim(ax3, [0 130]);
    ax3.FontSize = 10;
    % 图例（northeastoutside，避开地形主体；白底半透明）
    lg = legend(ax3, legObjs, legNames, 'Location','northeastoutside', ...
        'FontSize', 8, 'Box','on', 'Color','w', 'EdgeColor',[0.5 0.5 0.5]);
    lg.Color = [1 1 1 0.75];

    %% ---- 右列：典型高度威胁水平截面热力图 ----
    ax2 = nexttile(tl);
    resXY = 1;
    xVec = 1:resXY:100; yVec = 1:resXY:100;
    [Xg,Yg,~] = meshgrid(xVec, yVec, zSlice);
    T2 = threat.evaluate(Xg(:), Yg(:), zSlice*ones(numel(Xg),1));
    T2 = reshape(T2, numel(yVec), numel(xVec));
    imagesc(ax2, xVec, yVec, T2, [0 1]);
    hold(ax2,'on'); colormap(ax2, hot(256));
    set(ax2, 'YDir','normal');
    axis(ax2, 'equal'); xlim(ax2, [1 100]); ylim(ax2, [1 100]);
    % 威胁源轮廓
    for i = 1:numel(threat.threats)
        t = threat.threats(i);
        xe = t.center(1) + t.rx*cos(theta);
        ye = t.center(2) + t.ry*sin(theta);
        switch t.type
            case 'powerline', plot(ax2, xe, ye, '-', 'Color',[0.85 0.15 0.15], 'LineWidth', 2.0);
            case 'cliff',     plot(ax2, xe, ye, '-', 'Color',[0.55 0.27 0.07], 'LineWidth', 2.0);
            case 'ruins',     plot(ax2, xe, ye, '-', 'Color',[0.75 0.15 0.75], 'LineWidth', 2.0);
            case 'airspace',  plot(ax2, xe, ye, '-', 'Color',[0.10 0.35 0.90], 'LineWidth', 2.0);
            case 'nofly',     plot(ax2, xe, ye, '-', 'Color',[0.95 0.70 0.10], 'LineWidth', 2.5);
        end
    end
    plot(ax2, sp(1), sp(2), 'go', 'MarkerSize', 9, 'LineWidth', 2);
    plot(ax2, ep(1), ep(2), 'rs', 'MarkerSize', 9, 'LineWidth', 2);
    xlabel(ax2, 'x (m)', 'FontSize', 11);
    ylabel(ax2, 'y (m)', 'FontSize', 11);
    title(ax2, sprintf('(%c) %s: threat slice at z=%d m', char('c'+si-1), scenName, zSlice), ...
        'FontSize', 13, 'FontWeight','bold');
    cb = colorbar(ax2, 'eastoutside');
    cb.Label.String = 'Threat intensity T(x,y,z)'; cb.Label.FontSize = 10;
    ax2.FontSize = 10;
end

outDir = fullfile(root, 'figures'); if ~exist(outDir,'dir'), mkdir(outDir); end
print(fig, fullfile(outDir, 'Fig1_TerrainThreatField.png'), '-dpng', '-r300');
print(fig, fullfile(outDir, 'Fig1_TerrainThreatField.eps'), '-depsc2', '-r300');
fprintf('[Fig1] saved: figures/Fig1_TerrainThreatField.png/.eps\n');
end
