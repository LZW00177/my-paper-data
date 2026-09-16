classdef threatField < handle
    % ============================================================================
    %  threatField — 三维连续威胁势
    %  匹配论文式(2.2)(2.3)：水平一次指数衰减 + 全局最大值归一化
    % 仅适配 mapSize=100×100 仿真场景
    % ============================================================================
    properties
        threats(1,:) struct   % 威胁区列表
        threatType(1,:) cell  % 威胁类型标签（自动提取）
        maxTotalThreat(1,1) double = 1.0 % 全场景最大叠加威胁，用于归一化
    end

    methods
        function obj = threatField(scenario)
            if nargin < 1; scenario = 'mountain'; end
            switch scenario
                case 'mountain'
                    obj = obj.defineMountainThreats();
                case 'landslide'
                    obj = obj.defineLandslideThreats();
                otherwise
                    warning('threatField:UnknownScenario','未知场景，默认加载 mountain');
                    obj = obj.defineMountainThreats();
            end
            % 预计算全局最大叠加威胁，用于论文式(2.3)归一化
            obj.calcGlobalMaxThreat();
        end

        %% ===================== 山地威胁 =====================
        function obj = defineMountainThreats(obj)
            t = struct('center',[],'height',0,'rx',0,'ry',0,'eta_z',5,'type','','value',0);
            % 陡崖1
            t(1).center = [65,82]; t(1).height = 72; t(1).rx = 8; t(1).ry = 6;
            t(1).eta_z = 12; t(1).type = 'cliff'; t(1).value = 0.9;
            % 陡崖2
            t(2).center = [38,35]; t(2).height = 56; t(2).rx = 6; t(2).ry = 7;
            t(2).eta_z = 12; t(2).type = 'cliff'; t(2).value = 0.85;
            % 线缆1（带状rx<<ry）
            t(3).center = [20,50]; t(3).height = 64; t(3).rx = 4; t(3).ry = 40;
            t(3).eta_z = 8; t(3).type = 'powerline'; t(3).value = 0.8;
            % 线缆2
            t(4).center = [75,30]; t(4).height = 64; t(4).rx = 3; t(4).ry = 30;
            t(4).eta_z = 8; t(4).type = 'powerline'; t(4).value = 0.75;
            % 废墟
            t(5).center = [45,60]; t(5).height = 48; t(5).rx = 7; t(5).ry = 7;
            t(5).eta_z = 10; t(5).type = 'ruins'; t(5).value = 0.7;
            obj.threats = t(1:5);
            obj.threatType = unique({obj.threats.type});
        end

        %% ===================== 泥石流威胁 =====================
        function obj = defineLandslideThreats(obj)
            t = struct('center',[],'height',0,'rx',0,'ry',0,'eta_z',5,'type','','value',0);
            t(1).center = [35,80]; t(1).height = 80; t(1).rx = 12; t(1).ry = 10;
            t(1).eta_z = 16; t(1).type = 'airspace'; t(1).value = 0.95;
            t(2).center = [70,15]; t(2).height = 80; t(2).rx = 10; t(2).ry = 10;
            t(2).eta_z = 16; t(2).type = 'airspace'; t(2).value = 0.9;
            t(3).center = [55,50]; t(3).height = 56; t(3).rx = 8; t(3).ry = 6;
            t(3).eta_z = 12; t(3).type = 'nofly'; t(3).value = 1.0;
            obj.threats = t(1:3);
            obj.threatType = unique({obj.threats.type});
        end

        %% 预计算全场景最大叠加威胁（匹配论文式2.3分母）
        function calcGlobalMaxThreat(obj)
            res = 2;
            xRange = 1:res:100;
            yRange = 1:res:100;
            % 扫描 z 覆盖实际飞行带 [40, 120]（与 UAVMultiObj 飞行高度一致），
            % 并额外在每类威胁的 height 附近加密采样，确保 maxTotalThreat 不漏掉威胁峰值
            zRange = 40:4:120;
            for i = 1:length(obj.threats)
                h = obj.threats(i).height;
                zRange = unique([zRange, max(0,h-2):2:min(120,h+2)]);
            end
            zRange = sort(zRange);
            [X,Y,Z] = meshgrid(xRange,yRange,zRange);
            xV = X(:); yV = Y(:); zV = Z(:);
            rawThreat = zeros(size(xV));
            for i = 1:length(obj.threats)
                t = obj.threats(i);
                dx = (xV - t.center(1)) / t.rx;
                dy = (yV - t.center(2)) / t.ry;
                dr = sqrt(dx.^2 + dy.^2);
                dz = abs(zV - t.height) / t.eta_z;
                rawThreat = rawThreat + t.value * exp(-dr) .* exp(-dz);
            end
            obj.maxTotalThreat = max(rawThreat(:));
            if obj.maxTotalThreat < 1e-9
                obj.maxTotalThreat = 1;
            end
        end

        %% 三维威胁求值（完全匹配论文式2.2、2.3）
        function threat = evaluate(obj, x, y, z)
            x = x(:); y = y(:); z = z(:);
            if ~(length(x)==length(y) && length(y)==length(z))
                error('x,y,z 长度必须一致');
            end
            nPoints = length(x);
            rawThreat = zeros(nPoints, 1);
            for i = 1:length(obj.threats)
                t = obj.threats(i);
                dx = (x - t.center(1)) / t.rx;
                dy = (y - t.center(2)) / t.ry;
                dr = sqrt(dx.^2 + dy.^2); % 一次归一化距离，匹配论文d_r
                dz = abs(z - t.height) / t.eta_z;
                verticalDecay = exp(-dz);
                rawThreat = rawThreat + t.value * exp(-dr) .* verticalDecay;
            end
            % 论文式(2.3)全局最大值归一化
            threat = rawThreat / obj.maxTotalThreat;
            threat = max(min(threat, 1.0), 0.0);
        end

        %% 可视化：三维威胁场全景图（地形表面 + 威胁热力 + 椭圆边界 + 起终点）
        %  对齐论文图1 风格：低空地形 + 飞行高度威胁贴面 + 威胁椭圆边界 + 起终点
        %  Resolution 控制网格密度（默认 5m，分辨率高则慢）
        function plot(obj, terrain, varargin)
            p = inputParser;
            addParameter(p, 'Resolution', 5, @isnumeric);
            parse(p, varargin{:});
            res = p.Results.Resolution;
            xMin = min(terrain.map_x(:));
            xMax = max(terrain.map_x(:));
            yMin = min(terrain.map_y(:));
            yMax = max(terrain.map_y(:));
            [X, Y] = meshgrid(xMin:res:xMax, yMin:res:yMax);
            Zq = terrain.getHeight(X(:)', Y(:)');
            T = obj.evaluate(X(:)', Y(:)', Zq);
            T = reshape(T, size(X));

            fig = figure('Color','w', 'Position', [100 100 1100 800]);
            ax = axes('Parent', fig); hold(ax,'on'); grid(ax,'on'); axis(ax,'equal');

            % --- 地形表面（半透明灰） ---
            hTerrain = mesh(ax, terrain.map_x, terrain.map_y, terrain.map_z, ...
                'FaceAlpha', 0.45, 'EdgeColor', [0.6 0.6 0.6], ...
                'DisplayName', 'Terrain surface');

            % --- 威胁热力贴面（地形上方的半透明 hot 色） ---
            hThreat = surf(ax, X, Y, terrain.getHeight(X,Y), T, ...
                'FaceAlpha', 0.55, 'EdgeAlpha', 0, ...
                'DisplayName', 'Threat intensity $\mathcal{T}(x,y,z)$');

            % --- 威胁椭圆边界（按 type 配色） ---
            theta = linspace(0, 2*pi, 100);
            hEllipse = gobjects(0);
            for i = 1:length(obj.threats)
                t = obj.threats(i);
                xe = t.center(1) + t.rx * cos(theta);
                ye = t.center(2) + t.ry * sin(theta);
                ze = ones(size(theta)) * t.height;
                switch t.type
                    case 'powerline'
                        col = [1 0 0]; style = '-'; lw = 2.5;
                        lbl = sprintf('Powerline (h=%gm)', t.height);
                    case 'cliff'
                        col = [0 0 0]; style = '--'; lw = 1.8;
                        lbl = sprintf('Cliff (h=%gm)', t.height);
                    case 'ruins'
                        col = [0.8 0 0.8]; style = '-'; lw = 1.5;
                        lbl = sprintf('Ruin (h=%gm)', t.height);
                    case 'airspace'
                        col = [0.5 0.5 0.5]; style = ':'; lw = 1.8;
                        lbl = sprintf('Airspace (h=%gm)', t.height);
                    case 'nofly'
                        col = [0 0 0]; style = '-'; lw = 2.5;
                        lbl = sprintf('No-fly zone (h=%gm)', t.height);
                    otherwise
                        col = [0 0.5 0]; style = '-'; lw = 1.5;
                        lbl = sprintf('%s (h=%gm)', t.type, t.height);
                end
                hE = plot3(ax, xe, ye, ze, style, 'Color', col, 'LineWidth', lw, ...
                    'DisplayName', lbl);
                hEllipse = [hEllipse; hE];
                % 垂直投影到 z=0
                plot3(ax, xe, ye, zeros(size(xe)), ':', 'Color', col, 'LineWidth', 0.8);
                % 中心垂直线
                plot3(ax, [t.center(1) t.center(1)], [t.center(2) t.center(2)], ...
                    [0 t.height], ':', 'Color', col, 'LineWidth', 0.8);
            end

            % --- 空中域边界（z=120 上界） ---
            hBnd = plot3(ax, [0 100 100 0 0], [0 0 100 100 0], [120 120 120 120 120], ...
                'k--', 'LineWidth', 1.0, 'DisplayName', 'Airspace ceiling z=120');

            % --- 起点 / 终点 ---
            plot3(ax, 5,  5,  50, 'go', 'MarkerSize', 12, 'LineWidth', 2.5, ...
                'DisplayName', 'Start point');
            plot3(ax, 95, 95, 50, 'rs', 'MarkerSize', 12, 'LineWidth', 2.5, ...
                'DisplayName', 'Target point');

            colormap(ax, hot(256));
            caxis(ax, [0, 1]);
            cb = colorbar(ax, 'Location', 'eastoutside');
            cb.Label.String = 'Threat Intensity $\mathcal{T}(x,y,z)$';
            cb.Label.Interpreter = 'latex';
            cb.Label.FontSize = 12;

            xlabel(ax, 'X (m)', 'FontSize', 12, 'FontWeight', 'bold');
            ylabel(ax, 'Y (m)', 'FontSize', 12, 'FontWeight', 'bold');
            zlabel(ax, 'Z (m)', 'FontSize', 12, 'FontWeight', 'bold');
            title(ax, '3D Threat Field (mountain scenario)', 'FontSize', 14, 'FontWeight', 'bold');
            view(ax, -45, 30);
            xlim(ax, [0, 100]); ylim(ax, [0, 100]);
            zlim(ax, [0, 130]);
            ax.FontSize = 11;

            % --- 图例（去重） ---
            allHandles = [hTerrain; hThreat; hEllipse; hBnd];
            allHandles = allHandles(isgraphics(allHandles));
            legend(ax, allHandles, 'Location', 'northeast', ...
                'Interpreter', 'none', 'FontSize', 9);
        end
    end
end