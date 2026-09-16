classdef terrainGeneration < handle
    % ============================================================================
    %  terrainGeneration — 三维搜救地形生成
    %  新增矩形建筑障碍，完整匹配论文式(2.1)山体+建筑叠加模型
    % ============================================================================
    properties
        mapSize(1,2) double = [100, 100]
        minH(1,1) double = 40
        maxH(1,1) double = 120
        map_z
        map_x
        map_y
        peaks
        buildings % 新增：建筑结构体数组 [cx,cy,w,h,bHeight,buffer]
        scenario(1,:) char = 'mountain'
        interpF       % 缓存的高度插值器（griddedInterpolant），getHeight 复用避免每次重建
    end

    methods
        function obj = terrainGeneration(mapSize, varargin)
            p = inputParser;
            addRequired(p, 'mapSize', @(x) isnumeric(x) && isequal(size(x),[1,2]));
            addParameter(p, 'scenario', 'mountain', @ischar);
            addParameter(p, 'minH', 40, @isnumeric);
            addParameter(p, 'maxH', 120, @isnumeric);
            parse(p, mapSize, varargin{:});
            obj.mapSize = p.Results.mapSize;
            obj.minH    = p.Results.minH;
            obj.maxH    = p.Results.maxH;
            obj.scenario = p.Results.scenario;
            if obj.minH >= obj.maxH
                error('terrainGeneration:RangeErr','minH 必须严格小于 maxH');
            end
            switch p.Results.scenario
                case 'mountain'
                    obj = obj.generateMountain();
                case {'gully','landslide'}
                    obj = obj.generateLandslide();
                otherwise
                    warning('terrainGeneration:UnknownScene','未知场景，默认加载 mountain');
                    obj = obj.generateMountain();
            end
        end

        %% 山地场景：高斯山体 + 矩形建筑
        function obj = generateMountain(obj)
            [X, Y] = meshgrid(1:obj.mapSize(2), 1:obj.mapSize(1));
            Z = zeros(obj.mapSize);
            % 基底起伏
            Z = sin(Y + 10) + 0.2*sin(X) + 0.1*cos(0.6*sqrt(X.^2 + Y.^2)) ...
                + 1*cos(Y) + 1*sin(0.1*sqrt(X.^2 + Y.^2)) + 0.1*cos(Y);
            Z = (Z + 2) * 4;
            Z = terrainGeneration.gaussSmooth(Z, 3);
            % 高斯山峰求和（匹配论文）
            obj.peaks(1,:) = [65, 75, 14, 8, 6];
            cx1 = obj.peaks(1,1); cy1 = obj.peaks(1,2); h1 = obj.peaks(1,3); sx1 = obj.peaks(1,4); sy1 = obj.peaks(1,5);
            Z1 = h1 * exp(-((X - cx1)./sx1).^2 - ((Y - cy1)./sy1).^2);
            
            obj.peaks(2,:) = [25, 35, 10, 7, 7];
            cx2 = obj.peaks(2,1); cy2 = obj.peaks(2,2); h2 = obj.peaks(2,3); sx2 = obj.peaks(2,4); sy2 = obj.peaks(2,5);
            Z2 = h2 * exp(-((X - cx2)./sx2).^2 - ((Y - cy2)./sy2).^2);
            
            obj.peaks(3,:) = [50, 55, 8, 10, 8];
            cx3 = obj.peaks(3,1); cy3 = obj.peaks(3,2); h3 = obj.peaks(3,3); sx3 = obj.peaks(3,4); sy3 = obj.peaks(3,5);
            Z3 = h3 * exp(-((X - cx3)./sx3).^2 - ((Y - cy3)./sy3).^2);
            
            Z = Z + Z1 + Z2 + Z3;

            % ===================== 新增矩形建筑模块（论文式2.1示性项） =====================
            % 建筑结构体：[中心cx, 中心cy, 半宽w, 半高h, 建筑高度bH, 安全缓冲buf]
            bStruct = struct('cx',0,'cy',0,'w',0,'h',0,'bH',0,'buf',2);
            % 废墟建筑群1
            bStruct(1).cx = 45; bStruct(1).cy = 60; bStruct(1).w = 4; bStruct(1).h = 3; bStruct(1).bH = 12;
            % 村落建筑2
            bStruct(2).cx = 22; bStruct(2).cy = 32; bStruct(2).w = 5; bStruct(2).h = 4; bStruct(2).bH = 10;
            obj.buildings = bStruct;
            % 叠加建筑高度（示性函数1{区域内}=1）
            for b = obj.buildings
                mask = (abs(X - b.cx) <= b.w) & (abs(Y - b.cy) <= b.h);
                Z(mask) = Z(mask) + b.bH; % 论文式2.1 建筑附加高度项
            end
            % ==============================================================================

            Z = obj.normalizeToBand(Z);
            Z = obj.flattenNear(Z, [5,5], 8);
            Z = obj.flattenNear(Z, [95,95], 8);
            obj.map_z = Z;
            obj.map_x = 1:obj.mapSize(2);
            obj.map_y = 1:obj.mapSize(1);
            obj.buildInterp();
        end

        %% 泥石流场景（无建筑）
        function obj = generateLandslide(obj)
            [X, Y] = meshgrid(1:obj.mapSize(2), 1:obj.mapSize(1));
            Z = zeros(obj.mapSize);
            Z = 0.15 * X + 0.05 * Y + 6;
            Z_gully = 10 * exp(-((X - 30 - 0.5*Y)/8).^2 - ((Y - 20)/20).^2);
            Z = Z - Z_gully;
            Z_gully2 = 7 * exp(-((X - 70 - 0.3*Y)/6).^2 - ((Y - 60)/15).^2);
            Z = Z - Z_gully2;
            Z = Z + 0.5*randn(size(Z));
            Z = terrainGeneration.gaussSmooth(Z, 2);
            Z = obj.normalizeToBand(Z);
            Z = obj.flattenNear(Z, [10,90], 8);
            Z = obj.flattenNear(Z, [90,10], 8);
            obj.peaks = [];
            obj.buildings = []; % 泥石流场景无人工建筑
            obj.map_z = Z;
            obj.map_x = 1:obj.mapSize(2);
            obj.map_y = 1:obj.mapSize(1);
            obj.buildInterp();
        end

        %% 预构建高度插值器（linear，与原 interp2 数值一致，避免每次 getHeight 重建）
        function obj = buildInterp(obj)
            try
                obj.interpF = griddedInterpolant({obj.map_y, obj.map_x}, obj.map_z, 'linear');
            catch
                obj.interpF = [];  % 极老版本 MATLAB 无 griddedInterpolant 时退回 interp2
            end
        end

        function Z = normalizeToBand(obj, Z)
            zmin = min(Z(:)); zmax = max(Z(:));
            if zmax - zmin < 1e-6
                Z = ones(size(Z)) * (obj.minH + obj.maxH) / 2;
            else
                Z = obj.minH + (Z - zmin) / (zmax - zmin) * (obj.maxH - obj.minH);
            end
        end

        function Z = flattenNear(obj, Z, center, radius)
            [X, Y] = meshgrid(1:obj.mapSize(2), 1:obj.mapSize(1));
            d = sqrt((X - center(1)).^2 + (Y - center(2)).^2);
            mask = d <= radius;
            if any(mask(:))
                Z(mask) = min(Z(mask));
            end
        end

        %% 绘图（新增建筑轮廓绘制）
        function plot(obj, varargin)
            p = inputParser;
            addParameter(p, 'Path', [], @isnumeric);
            addParameter(p, 'Threats', [], @isstruct);
            addParameter(p, 'Title', '三维搜救地形', @ischar);
            parse(p, varargin{:});
            figure('Color','w');
            mesh(obj.map_x, obj.map_y, obj.map_z, 'FaceAlpha', 0.7);
            hold on; shading interp; colormap terrain; colorbar;
            xlabel('X (m)'); ylabel('Y (m)'); zlabel('Z (m)');
            title(p.Results.Title); grid on;

            % 绘制建筑矩形轮廓
            if ~isempty(obj.buildings)
                for b = obj.buildings
                    xBox = [b.cx-b.w, b.cx+b.w, b.cx+b.w, b.cx-b.w, b.cx-b.w];
                    yBox = [b.cy-b.h, b.cy-b.h, b.cy+b.h, b.cy+b.h, b.cy-b.h];
                    zBox = ones(size(xBox)) * b.bH;
                    plot3(xBox, yBox, zBox, 'k-','LineWidth',1.5);
                end
            end

            % 威胁椭圆
            if ~isempty(p.Results.Threats)
                T = p.Results.Threats;
                theta = linspace(0, 2*pi, 60);
                for i = 1:length(T)
                    cx = T(i).center(1); cy = T(i).center(2);
                    rx = T(i).rx; ry = T(i).ry; zh = T(i).height;
                    xe = cx + rx .* cos(theta);
                    ye = cy + ry .* sin(theta);
                    plot3(xe, ye, ones(size(xe))*zh, 'r-','LineWidth',1.2);
                end
            end

            % 航路
            if ~isempty(p.Results.Path)
                P = p.Results.Path;
                plot3(P(:,1), P(:,2), P(:,3), 'b-', 'LineWidth', 2);
                plot3(P(1,1), P(1,2), P(1,3), 'go', 'MarkerSize', 10, 'LineWidth', 2);
                plot3(P(end,1), P(end,2), P(end,3), 'rs', 'MarkerSize', 10, 'LineWidth', 2);
            end
            axis([1 obj.mapSize(2) 1 obj.mapSize(1) 0 obj.maxH+10]);
            view(-45, 30);
        end

        function H = getHeight(obj, x, y)
            % 地图坐标（0..mapSize）映射到网格索引（1..mapSize），越界 clamp 到边缘
            xi = min(max(x + 1, 1), obj.mapSize(2));
            yi = min(max(y + 1, 1), obj.mapSize(1));
            if ~isempty(obj.interpF)
                % 缓存插值器（数值与原 interp2 linear 一致，速度 ~30x）
                H = obj.interpF(yi, xi);
            else
                H = interp2(obj.map_x, obj.map_y, obj.map_z, xi, yi, 'linear');
            end
        end

        function feasible = isFeasiblePoint(obj, x, y, z)
            terrainH = obj.getHeight(x, y);
            safeGap = 1.0;
            lowerBound = max(terrainH + safeGap, obj.minH);
            feasible = (z >= lowerBound) & (z <= obj.maxH);
        end
    end

    methods (Static)
        function Z = gaussSmooth(Z, sigma)
            r = ceil(3 * sigma);
            [xx, yy] = ndgrid(-r:r, -r:r);
            kernel = exp(-(xx.^2 + yy.^2) / (2 * sigma^2));
            kernel = kernel / sum(kernel(:));
            Z = conv2(Z, kernel, 'same');
        end
    end
end