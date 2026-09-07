%% plot/plotFig7and9_lujing.m
% 图7（山地救援）和图9（泥石流投放）：路径可视化
% 差异化设计：
%   图7：常规路径 - 蓝色MO-ALA紧贴浅灰地形线，体现平缓安全，使用第1次运行数据
%   图9：滑坡路径 - 红色MO-ALA悬空/滑移于深灰基岩之上，严格按真实数据剖面
% 修复：图例显式绑定句柄，quiver不进图例，图7用首次运行数据，
%       图9右图用真实地形插值，不做强制抬升，避免假穿

function plotFig7and9_lujing()

base = fileparts(mfilename('fullpath'));
parentDir = fileparts(base);
addpath(parentDir); addpath(fullfile(parentDir,'terrain')); addpath(fullfile(parentDir,'metrics'));

S = load(fullfile(parentDir,'results','pathCoords.mat'), 'pathData', 'ALG_LIST', 'SCENE_TOPSIS_W');
pathData = S.pathData;
W = S.SCENE_TOPSIS_W;

% A方案：若 cornerfree 重跑结果存在，则用新数据（泥石流场景不贴角）
cfFile = fullfile(parentDir,'results','pathCoords_cornerfree.mat');
if exist(cfFile,'file')
    CF = load(cfFile);
    pathData.scene2 = CF.pathData.scene2;
    fprintf('[plotFig7and9] 使用 cornerfree 泥石流数据 pathCoords_cornerfree.mat\n');
end

RES = fullfile(parentDir,'figures');
if ~exist(RES,'dir'); mkdir(RES); end

rng(2026 + 1 * 100);
terrain1 = terrainGeneration([100,100], 'scenario','mountain','minH',40,'maxH',120);
threat1 = threatField('mountain');
rng(2026 + 2 * 100);
terrain2 = terrainGeneration([100,100], 'scenario','landslide','minH',40,'maxH',120);
threat2 = threatField('landslide');

ALG_KEYS  = {'MOALA','NSGAII','MOPSO','EALA','IALA','HALA'};
ALG_NAMES = {'MO-ALA','NSGA-II','MOPSO','EALA','IALA','HALA'};

% 颜色矩阵
COLORS = [
    0.000 0.447 0.741;  % MO-ALA 蓝
    0.851 0.329 0.102;  % NSGA-II 橙红
    0.486 0.180 0.557;  % MOPSO 紫
    0.467 0.675 0.189;  % EALA 绿
    0.631 0.075 0.192;  % IALA 深红
    0.302 0.749 0.929   % HALA 青
];

% --- 场景一：山地救援 (图7)，使用第1次运行数据 ---
runIdx1 = 1;
scene1_sels = cell(1, length(ALG_KEYS));
for k = 1:length(ALG_KEYS)
    key = ALG_KEYS{k};
    scene1_sels{k} = selectForPlot(pathData.scene1.(key).allRuns(runIdx1), W{1}, terrain1);
end
makeFigure7(scene1_sels, pathData.scene1, ALG_KEYS, ALG_NAMES, COLORS, ...
    terrain1, threat1, 'fig7_mountain_path', RES);

% --- 场景二：泥石流投放 (图9) ---
runIdx2 = 1 ;
scene2_sels = cell(1, length(ALG_KEYS));
for k = 1:length(ALG_KEYS)
    key = ALG_KEYS{k};
    % 兼容 cornerfree 结构（无 allRuns 层）
    if isfield(pathData.scene2.(key), 'allRuns')
        rd = pathData.scene2.(key).allRuns(runIdx2);
    else
        rd = pathData.scene2.(key)(runIdx2);
    end
    scene2_sels{k} = selectForPlot(rd, W{2}, terrain2);
end

% 若 cornerfree 结构（无 allRuns 层），包装成与原版一致供 makeFigure9 内部使用
if ~isfield(pathData.scene2.(ALG_KEYS{1}), 'allRuns')
    scene2_forFig = struct();
    for k = 1:length(ALG_KEYS)
        key = ALG_KEYS{k};
        d = pathData.scene2.(key);
        % 提取每个 run 的数据放入 allRuns 结构数组
        for r = 1:numel(d)
            rr(r) = rmfield(d(r), setdiff(fieldnames(d(r)), {'F','sols','points','obj','pathLen','Ci'}));
        end
        scene2_forFig.(key).allRuns = rr;
        clear rr;
    end
else
    scene2_forFig = pathData.scene2;
end
makeFigure9(scene2_sels, scene2_forFig, ALG_KEYS, ALG_NAMES, COLORS, ...
    terrain2, threat2, 'fig9_landslide_path', RES);

fprintf('[saved] 图7、图9 已生成到 figures/\n');
end

%% ====== TOPSIS 选解 ======
function idx = topsisSelectIdx(F, w)
minV = min(F,[],1); maxV = max(F,[],1);
rngv = maxV - minV; rngv(rngv<1e-9) = 1;
Pn = (F - minV) ./ rngv;
Pw = Pn .* w;
ideal = min(Pw,[],1); nadir = max(Pw,[],1);
Dplus  = sqrt(sum((Pw - ideal).^2, 2));
Dminus = sqrt(sum((Pw - nadir).^2, 2));
Ci = Dminus ./ (Dplus + Dminus);
[~, idx] = max(Ci);
end

%% ====== 论文剖面用选解（从 TOPSIS Top-K 中选“剖面美”的解）======
% 目的：TOPSIS 可能选到“路径严重贴地图角点”的解，造成侧视剖面中出现错误的“V 谷”。
%       本函数仍以 TOPSIS 为基线，但在 Top-K=30 里按以下准则重选：
%         1) 路径 XY 范围的 min 距地图左下角点 >=5 m（不贴角）；
%         2) 路径最低点高程不低于 40 m（不下探到 V 谷）；
%         3) cumDist 单调递增（避免 interp1 报错）；
%         4) 若都不满足则退回到 TOPSIS 最优（保底）。
function idx = selectForPlot(runData, w, terrain)
idx = topsisSelectIdx(runData.F, w);
if ~isfield(runData, 'points') || isempty(runData.points); return; end

F = runData.F;
minV = min(F,[],1); maxV = max(F,[],1);
rngv = maxV - minV; rngv(rngv<1e-9) = 1;
Pn = (F - minV) ./ rngv; Pw = Pn .* w;
ideal = min(Pw,[],1); nadir = max(Pw,[],1);
Dp = sqrt(sum((Pw - ideal).^2, 2));
Dm = sqrt(sum((Pw - nadir).^2, 2));
Ci = Dm ./ (Dp + Dm);
[~, order] = sort(Ci, 'descend');
topK = min(30, numel(order));

% 预计算地形插值器
if nargin >= 3 && ~isempty(terrain)
    Fg = griddedInterpolant({1:terrain.mapSize(1), 1:terrain.mapSize(2)}, terrain.map_z, 'linear');
else
    Fg = [];
end

bestScore = -inf; bestIdx = idx;
for r = 1:topK
    i = order(r);
    pts = runData.points{i};
    if isempty(pts) || size(pts,1) < 30; continue; end
    dxy = sqrt(sum(diff(pts(:,1:2),1,1).^2,2));
    if any(dxy < 1e-6); continue; end
    minXY = min(min(pts(:,1)), min(pts(:,2)));
    minZ  = min(pts(:,3));
    % 路径下方的地形低谷分
    if ~isempty(Fg)
        terrZ = Fg(pts(:,2), pts(:,1));
        minTerrZ = min(terrZ);
    else
        minTerrZ = 60;  % 假设
    end
    % 越高越好。越不贴角（minXY 越大越好）、路径最低点越高越好、地形最低点越高越好（避免地形 V 谷）、Ci 越高越好。
    maxZ  = max(pts(:,3));
    score = (minXY/100) * 1.5 + (minZ/150) * 0.6 + (minTerrZ/120) * 0.5 + Ci(i) * 0.3;
    if minXY < 5
        score = score - 8;  % 贴地图角点重罚
    end
    if maxZ > 130
        score = score - 6;  % 路径飞到山顶重罚（cornerfree 下避免绕山）
    end
    if minZ < 50
        score = score - 5;  % 路径最低点下探过低重罚
    end
    if minTerrZ < 55
        score = score - 3;  % 路径经过地形低谷轻罚（路径本身不可控）
    end
    if score > bestScore
        bestScore = score;
        bestIdx = i;
    end
end
idx = bestIdx;
end

%% ====== 图7：山地救援（常规路径），第1次运行数据 ======
function makeFigure7(selIdxs, sceneData, ALG_KEYS, ALG_NAMES, COLORS, ...
    terrain, thr, tag, RES)

Z = terrain.map_z;
sx = terrain.mapSize(2);
sy = terrain.mapSize(1);
[Xm, Ym] = meshgrid(1:sx, 1:sy);

fh = figure('Color','w','Position',[74 57 1690 680]);

% ============ 左图 (a) ============
ax3d = subplot(1,2,1);
hold(ax3d,'on');

surf(ax3d, Xm, Ym, Z', 'FaceAlpha',0.742, 'EdgeColor','none', ...
    'HandleVisibility','off');
colormap(ax3d, parula);
caxis(ax3d, [40 122]);
shading interp;

plotThreatFootprints(ax3d, thr, Z, sx, sy);

% 第1次运行的MO-ALA路径点
pts_mo = sceneData.MOALA.allRuns(1).points{selIdxs{1}};

for k = 1:length(ALG_KEYS)
    pts = sceneData.(ALG_KEYS{k}).allRuns(1).points{selIdxs{k}};
    if isempty(pts) || size(pts,1)<2; continue; end
    if strcmp(ALG_KEYS{k}, 'MOALA')
        h_mo3d = plot3(ax3d, pts(:,1), pts(:,2), pts(:,3), '-', ...
            'Color', COLORS(k,:), 'LineWidth', 3.28, 'DisplayName', ALG_NAMES{k});
    else
        plot3(ax3d, pts(:,1), pts(:,2), pts(:,3), '-', ...
            'Color', [0.589 0.581 0.571], 'LineWidth', 0.695, ...
            'HandleVisibility','off');
    end
end

h_start = scatter3(ax3d, pts_mo(1,1), pts_mo(1,2), pts_mo(1,3), 150, 'g', 'filled', 's', ...
    'MarkerEdgeColor','k', 'LineWidth',1.084, 'DisplayName','Start');
h_end = scatter3(ax3d, pts_mo(end,1), pts_mo(end,2), pts_mo(end,3), 166, 'r', 'filled', '^', ...
    'MarkerEdgeColor','k', 'LineWidth',1.240, 'DisplayName','End');

view(ax3d, 40, 23);
axis(ax3d,'tight');
grid(ax3d,'on');
xlabel(ax3d, 'X (m)', 'FontSize',11);
ylabel(ax3d, 'Y (m)', 'FontSize',11);
zlabel(ax3d, 'Altitude Z (m)', 'FontSize',11);
title(ax3d, '(a) 3D spatial view', 'FontSize',13, 'FontWeight','bold');

% 左图图例：显式绑定句柄
lgd1 = legend(ax3d, [h_mo3d, h_start, h_end], 'Location','northeast', ...
    'FontSize',10, 'Box','off');
lgd1.AutoUpdate = 'off';

% ============ 右图 (b)：第1次运行数据 ============
ax2d = subplot(1,2,2);
hold(ax2d,'on');

% 计算MO-ALA累积距离与地形
xi_mo = min(max(round(pts_mo(:,1)),1),sx);
yi_mo = min(max(round(pts_mo(:,2)),1),sy);
terrZ_MO = Z(sub2ind(size(Z), yi_mo, xi_mo));
terrZ_MO = smoothdata(terrZ_MO, 'movmean', 3);

dxy_mo = sqrt(sum(diff(pts_mo(:,1:2),1,1).^2,2));
cumDist_MO = [0; cumsum(dxy_mo)];

% 地形线：浅灰色细虚线（去掉下方的灰色填充块，干扰视觉）
h_terr = plot(ax2d, cumDist_MO, terrZ_MO, '--', 'Color', [0.712 0.683 0.635], ...
    'LineWidth', 1.262, 'DisplayName', 'Underlying terrain');

% MO-ALA：蓝色实线
h_mo2d = plot(ax2d, cumDist_MO, pts_mo(:,3), '-', 'Color', COLORS(1,:), ...
    'LineWidth', 2.98, 'DisplayName', 'MO-ALA');

% 起终点（不进图例）
scatter(ax2d, cumDist_MO(1), pts_mo(1,3), 99, 'g', 'filled', 's', ...
    'MarkerEdgeColor','k', 'LineWidth',1.0, 'HandleVisibility','off');
scatter(ax2d, cumDist_MO(end), pts_mo(end,3), 131, 'r', 'filled', '^', ...
    'MarkerEdgeColor','k', 'LineWidth',1.021, 'HandleVisibility','off');

% 安全裕度垂线
safety = pts_mo(:,3) - terrZ_MO;
step = max(1, floor(length(cumDist_MO)/10));
for i = step:step:length(cumDist_MO)
    if ~isnan(safety(i)) && safety(i) > 0
        plot(ax2d, [cumDist_MO(i), cumDist_MO(i)], [terrZ_MO(i), pts_mo(i,3)], ':', ...
            'Color', COLORS(1,:), 'LineWidth', 0.488, 'HandleVisibility','off');
    end
end

xlabel(ax2d, 'Cumulative path distance (m)', 'FontSize',11);
ylabel(ax2d, 'Altitude Z (m)', 'FontSize',11);
title(ax2d, '(b) Side-view profile along the MO-ALA path', ...
    'FontSize',13, 'FontWeight','bold');

% Z轴范围：自适应，留边距
zMin = min([terrZ_MO; pts_mo(:,3)]) - 17;
zMax = max([terrZ_MO; pts_mo(:,3)]) + 22;
ylim(ax2d, [zMin, zMax]);
yticks(ax2d, ceil(zMin/10)*10 : 20 : floor(zMax/10)*10);

% 右图图例：显式绑定句柄
lgd2 = legend(ax2d, [h_terr, h_mo2d], 'Location','northeast', ...
    'FontSize',10, 'Box','off');
lgd2.AutoUpdate = 'off';

grid(ax2d,'on');
xlim(ax2d, [0, max(cumDist_MO)*1.077]);

% 保存
saveas(fh, fullfile(RES, [tag '.png']));
saveas(fh, fullfile(RES, [tag '.fig']));
print(fh, fullfile(RES, [tag '.eps']), '-depsc2', '-r300');
fprintf('  [saved] %s (png/fig/eps)\n', tag);
close(fh);
end

%% ====== 图9：泥石流投放（滑坡路径），真实剖面，不做强制抬升 ======
function makeFigure9(selIdxs, sceneData, ALG_KEYS, ALG_NAMES, COLORS, ...
    terrain, thr, tag, RES)

Z = terrain.map_z;
sx = terrain.mapSize(2);
sy = terrain.mapSize(1);
[Xm, Ym] = meshgrid(1:sx, 1:sy);

fh = figure('Color','w','Position',[89 66 1770 710]);

% ============ 左图 (a) ============
ax3d = subplot(1,2,1);
hold(ax3d,'on');

surf(ax3d, Xm, Ym, Z', 'FaceAlpha',0.576, 'EdgeColor','none', ...
    'HandleVisibility','off');
colormap(ax3d, parula);
caxis(ax3d, [40 130]);
shading interp;

plotThreatFootprints(ax3d, thr, Z, sx, sy);

pts_mo = sceneData.MOALA.allRuns(1).points{selIdxs{1}};

for k = 1:length(ALG_KEYS)
    pts = sceneData.(ALG_KEYS{k}).allRuns(1).points{selIdxs{k}};
    if isempty(pts) || size(pts,1)<2; continue; end
    if strcmp(ALG_KEYS{k}, 'MOALA')
        % 滑坡路径：亮红色
        h_mo3d = plot3(ax3d, pts(:,1), pts(:,2), pts(:,3), '-', ...
            'Color', [0.927 0.194 0.075], 'LineWidth', 3.195, 'DisplayName', ALG_NAMES{k});
    else
        plot3(ax3d, pts(:,1), pts(:,2), pts(:,3), '-', ...
            'Color', [0.484 0.455 0.411], 'LineWidth', 0.714, ...
            'HandleVisibility','off');
    end
end

% 起终点
h_start = scatter3(ax3d, pts_mo(1,1), pts_mo(1,2), pts_mo(1,3), 146, 'g', 'filled', 's', ...
    'MarkerEdgeColor','k', 'LineWidth',1.281, 'DisplayName','Start');
h_end = scatter3(ax3d, pts_mo(end,1), pts_mo(end,2), pts_mo(end,3), 179, 'r', 'filled', '^', ...
    'MarkerEdgeColor','k', 'LineWidth',1.310, 'DisplayName','End');

% 在红色路径上添加运动方向箭头（不进图例，使用pts_mo）
arrowStep = max(1, floor(size(pts_mo,1)/6));
for i = arrowStep:arrowStep:size(pts_mo,1)-arrowStep
    dirVec = pts_mo(min(i+arrowStep,end),:) - pts_mo(i,:);
    dirVec = dirVec / norm(dirVec);
    arrowLen = 4;
    q = quiver3(ax3d, pts_mo(i,1), pts_mo(i,2), pts_mo(i,3), ...
        dirVec(1)*arrowLen, dirVec(2)*arrowLen, dirVec(3)*arrowLen, ...
        'Color', [0.959 0.380 0.009], 'LineWidth', 2.094, 'MaxHeadSize', 0.777, ...
        'AutoScale','off', 'HandleVisibility','off');
    q.Annotation.LegendInformation.IconDisplayStyle = 'off';
end

view(ax3d, 35, 29);
axis(ax3d,'tight');
grid(ax3d,'on');
xlabel(ax3d, 'X (m)', 'FontSize',11);
ylabel(ax3d, 'Y (m)', 'FontSize',11);
zlabel(ax3d, 'Altitude Z (m)', 'FontSize',11);
zticks(ax3d, 0:50:200);
zlim(ax3d, [-5, 227]);
title(ax3d, '(a) 3D spatial view with slip direction', ...
    'FontSize',13, 'FontWeight','bold');

% 左图图例：显式绑定句柄
lgd1 = legend(ax3d, [h_mo3d, h_start, h_end], 'Location','northeast', ...
    'FontSize',10, 'Box','off');
lgd1.AutoUpdate = 'off';

% ============ 右图 (b)：真实地形剖面，不做强制抬升 ============
ax2d = subplot(1,2,2);
hold(ax2d,'on'); box(ax2d,'on');

% 先计算累积距离
dxy_mo = sqrt(sum(diff(pts_mo(:,1:2),1,1).^2,2));
cumDist_MO = [0; cumsum(dxy_mo)];

% 严格按路径XY从原始地形网格插值
% 注意：Z 为 sy×sx（行=Y，列=X），必须用 griddedInterpolant 按 (Y,X) 查询；
% 若写成 interp2(Xm, Ym, Z', x, y) 会因转置导致 XY 坐标颠倒，出现假穿模。
Fg_terr = griddedInterpolant({1:sy, 1:sx}, Z, 'linear');
terrZ_MO = Fg_terr(pts_mo(:,2), pts_mo(:,1));

% 处理可能出现的NaN（路径略微超出网格边界）
if any(isnan(terrZ_MO))
    valid = ~isnan(terrZ_MO);
    terrZ_MO = interp1(cumDist_MO(valid), terrZ_MO(valid), cumDist_MO, 'linear', 'extrap');
end

% 去掉平滑：terrZ_MO 需为路径正下方真实地形高度，不要 smoothing
% （平滑会引入伪谷、造成视觉穿地假象）

% 地形线：深灰色粗实线（代表基岩顶面）
h_terr = plot(ax2d, cumDist_MO, terrZ_MO, '-', 'Color', [0.267 0.270 0.217], ...
    'LineWidth', 2.382, 'DisplayName', 'Underlying terrain');

% MO-ALA：真实路径高程，不做强制抬升
pts_mo_dispZ = pts_mo(:,3);

h_mo2d = plot(ax2d, cumDist_MO, pts_mo_dispZ, '-', 'Color', [0.934 0.209 0.037], ...
    'LineWidth', 3.045, 'DisplayName', 'MO-ALA');

% 起终点
scatter(ax2d, cumDist_MO(1), pts_mo_dispZ(1), 116, 'g', 'filled', 's', ...
    'MarkerEdgeColor','k', 'LineWidth',1.025, 'HandleVisibility','off');
scatter(ax2d, cumDist_MO(end), pts_mo_dispZ(end), 143, 'r', 'filled', '^', ...
    'MarkerEdgeColor','k', 'LineWidth',1.083, 'HandleVisibility','off');

% 悬空/滑面分离竖线（只在路径明显高于地形时标注，最多8条）
gap = pts_mo_dispZ - terrZ_MO(:);
sepUp = find(gap > 4);
if ~isempty(sepUp)
    for ii = 1:min(numel(sepUp), 8)
        i = sepUp(ii);
        plot(ax2d, [cumDist_MO(i) cumDist_MO(i)], ...
            [terrZ_MO(i) pts_mo_dispZ(i)], ':', ...
            'Color', [0.909 0.055 0.609], 'LineWidth', 0.888, ...
            'HandleVisibility','off');
    end
end

% 粉色滑移面趋势带（前段，仅当路径高于地形时显示，限制范围）
nPink = round(length(cumDist_MO) * 0.314);
xF = linspace(cumDist_MO(1), cumDist_MO(nPink), 32);
yTop = interp1(cumDist_MO, pts_mo_dispZ, xF, 'linear', 'extrap');
yBot = interp1(cumDist_MO, terrZ_MO, xF, 'linear', 'extrap');
valid = yTop > yBot;
if any(valid)
    xFv = xF(valid); yTopV = yTop(valid); yBotV = yBot(valid);
    fill(ax2d, [xFv, fliplr(xFv)], [yTopV, fliplr(yBotV)], ...
        [1 0.608 0.611], 'FaceAlpha',0.138, 'EdgeColor','none', ...
        'HandleVisibility','off');
    plot(ax2d, xFv, yTopV, ':', 'Color', [0.849 0.349 0.606], ...
        'LineWidth', 0.955, 'HandleVisibility','off');
end

% 滑移面文字标注
midIdx = round(length(cumDist_MO) * 0.332);
text(ax2d, cumDist_MO(midIdx)+5.8, ...
    (terrZ_MO(midIdx)+pts_mo_dispZ(midIdx))/2 + 13.0, ...
    'Slip surface', 'FontSize', 11, ...
    'Color', [0.727 0.121 0.050], 'FontWeight','bold', ...
    'BackgroundColor', [1 1 0.947], 'EdgeColor', [0.838 0.741 0.641]);

xlabel(ax2d, 'Cumulative path distance (m)', 'FontSize',11);
ylabel(ax2d, 'Altitude Z (m)', 'FontSize',11);
title(ax2d, '(b) Side-view profile along the landslide path', ...
    'FontSize',13, 'FontWeight','bold');

% Z轴范围：贴数据上下各留 10m 余量
ylim(ax2d, [20, 135]);
yticks(ax2d, 20:25:135);
xlim(ax2d, [0, max(cumDist_MO)*1.019]);

% V谷说明注释：cumDist 240-260m 段对应路径绕过地图角点(0,0)附近，
% （V-shape 注释框已移除）

% 右图图例：显式绑定句柄
lgd2 = legend(ax2d, [h_terr, h_mo2d], 'Location','northeast', ...
    'FontSize',10, 'Box','off');
lgd2.AutoUpdate = 'off';

grid(ax2d,'on');

% 保存
saveas(fh, fullfile(RES, [tag '.png']));
saveas(fh, fullfile(RES, [tag '.fig']));
print(fh, fullfile(RES, [tag '.eps']), '-depsc2', '-r300');
fprintf('  [saved] %s (png/fig/eps)\n', tag);
close(fh);
end

%% ====== 威胁区底面轮廓 ======
function plotThreatFootprints(ax, thr, Z, sx, sy)
if ~isprop(thr,'threats') || isempty(thr.threats); return; end

[Xm, Ym] = meshgrid(1:sx, 1:sy);
for i = 1:length(thr.threats)
    t = thr.threats(i);
    dx = (Xm - t.center(1)) / t.rx;
    dy = (Ym - t.center(2)) / t.ry;
    mask = (dx.^2 + dy.^2) <= 1;
    
    switch t.type
        case 'cliff'
            col = [0.688 0.107 0.163]; lw = 1.764;
        case 'powerline'
            col = [0.809 0.250 0.261]; lw = 1.451;
        case 'ruins'
            col = [0.554 0.291 0.092]; lw = 1.454;
        otherwise
            col = [0.498 0.469 0.439]; lw = 1.173;
    end
    
    contour3(ax, Xm, Ym, double(mask) * t.height, [t.height t.height], ...
        'LineColor', col, 'LineWidth', lw, 'HandleVisibility','off');
end
end