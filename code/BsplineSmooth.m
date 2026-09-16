classdef BsplineSmooth < handle
    % ============================================================================
    %  BsplineSmooth — B 样条轨迹平滑器
    %  对应论文第 2 章 2.4.2 节 B 样条轨迹平滑后处理
    %  模型公式 eq:bspline：C(u) = Σ_i N_{i,p}(u) · B_i
    %  p=3次B样条，splineOrder=4；开放均匀节点，弦长参数化，强制插值航路端点
    %  双接口分工：
    %    smooth()：完整标准B样条 + 地形高度修正，绘图输出完整轨迹
    %    smoothSimple()：轻量化无地形，供UAVMultiObj约束校验专用
    %  优化清单：
    %    1. 修正开放均匀节点向量构造逻辑，消除浮点精度隐患
    %    2. 增加控制点数量前置校验防节点数组越界
    %    3. 控制点数量匹配时跳过重采样，提升批量迭代性能
    %    4. bsplineEval增加判空容错
    %    5. 新增航路维度校验，防止错误输入
    %    6. 修正uTarget边界钳位策略，适配B样条基函数区间定义
    % ============================================================================
    properties
        splineOrder(1,1) double = 4    % 样条阶，p = order-1 = 3（三次B样条）
        numControlPts(1,1) int32 = 20  % 默认目标控制点数量
        maxDeltaH(1,1) double = 5.0     % 平滑后相邻航点最大高度差 m
        safeClearance(1,1) double = 1.0 % 地形安全高度余量（对齐UAV h_min）
    end

    methods
        function obj = BsplineSmooth(varargin)
            p = inputParser;
            addParameter(p, 'splineOrder', 4, @(x)isscalar(x)&&x>=2&&mod(x,1)==0);
            addParameter(p, 'numControlPts', 20, @(x)isscalar(x)&&x>3&&mod(x,1)==0);
            addParameter(p, 'maxDeltaH', 5.0, @isnumeric);
            addParameter(p, 'safeClearance', 1.0, @isnumeric);
            parse(p, varargin{:});

            obj.splineOrder = p.Results.splineOrder;
            obj.numControlPts = int32(p.Results.numControlPts);
            obj.maxDeltaH = p.Results.maxDeltaH;
            obj.safeClearance = p.Results.safeClearance;

            % 构造器参数校验
            if obj.splineOrder < 2
                error('splineOrder 至少为2（一次B样条），论文固定取值4(3次)');
            end
            if obj.numControlPts <= 3
                error('控制点数量必须大于3');
            end
        end

        %% 完整标准B样条：支持地形高度修正，用于绘图输出
        function smoothPath = smooth(obj, waypoints, varargin)
            p = inputParser;
            addParameter(p, 'numPoints', 500, @(x)x>1);
            addParameter(p, 'terrain', [], @(x) isempty(x) || isa(x,'terrainGeneration'));
            parse(p, varargin{:});
            numPoints = p.Results.numPoints;
            terrain = p.Results.terrain;

            wpNum = size(waypoints, 1);
            dimNum = size(waypoints, 2);
            % 新增：航路维度校验，必须 N×3
            if dimNum ~= 3
                error('waypoints 输入必须为 N×3 三维航路矩阵 [x, y, z]');
            end

            smoothPath = zeros(numPoints, 3, 'double');
            if wpNum < 2
                smoothPath(1:wpNum,:) = waypoints;
                return;
            end

            targetCP = double(obj.numControlPts);
            p_deg = obj.splineOrder - 1;
            % 控制点数量前置校验
            if wpNum <= p_deg
                error('B样条阶p=%d，控制点数量必须大于%d，当前仅%d', p_deg, p_deg, wpNum);
            end
            % 控制点数量匹配则跳过重采样
            if wpNum ~= targetCP
                waypoints = obj.resampleCP(waypoints, targetCP);
            end
            nCP = size(waypoints, 1);

            % 弦长参数化
            diffs = diff(waypoints, 1, 1);
            chordLen = sqrt(sum(diffs.^2, 2));
            cumLen = [0; cumsum(chordLen)];
            totalLen = cumLen(end);
            if totalLen < eps
                u = linspace(0, 1, nCP)';
            else
                u = cumLen / totalLen;
            end
            uTarget = linspace(0, 1, numPoints)';
            % 优化：去除1-eps，标准区间钳位 [0,1]
            uTarget = max(min(uTarget, 1.0), 0.0);

            % ========== 标准开放均匀节点向量 ==========
            knots = zeros(1, nCP + p_deg + 1);
            knots(1:p_deg+1) = 0;
            innerNum = nCP - p_deg - 1;
            if innerNum > 0
                innerKnots = linspace(0, 1, innerNum + 2);
                innerKnots = innerKnots(2:end-1);
                knots(p_deg+2 : end-(p_deg+1)) = innerKnots;
            end
            knots(end-p_deg:end) = 1;
            knots = max(min(knots, 1.0), 0.0); % 浮点精度钳位

            % 三轴分别插值
            for dim = 1:3
                smoothPath(:,dim) = BsplineSmooth.bsplineEval(knots, waypoints(:,dim), p_deg, uTarget);
            end

            % 地形高度约束修正
            if ~isempty(terrain)
                smoothPath = obj.terrainConstraint(smoothPath, terrain);
            end

            % 强制首尾航点完全不变
            smoothPath(1,:) = waypoints(1,:);
            smoothPath(end,:) = waypoints(end,:);
        end

        %% 轻量化标准B样条（无地形，UAV评估专用）
        function smoothPath = smoothSimple(obj, waypoints, numPoints)
            if nargin < 3 || isempty(numPoints); numPoints = 100; end
            wpNum = size(waypoints,1);
            smoothPath = zeros(numPoints, 3, 'double');
            if wpNum < 2
                smoothPath(1:wpNum,:) = waypoints;
                return;
            end
            % 复用标准B样条，废弃内置分段spline，模型与论文统一
            smoothPath = obj.smooth(waypoints, 'numPoints', numPoints, 'terrain', []);
        end

        %% 控制点弦长均匀重采样（替代简单线性插值）
        function newWP = resampleCP(~, waypoints, N)
            oldN = size(waypoints,1);
            if oldN == N
                newWP = waypoints;
                return;
            end
            diffs = diff(waypoints,1,1);
            segL = sqrt(sum(diffs.^2,2));
            cumL = [0; cumsum(segL)];
            t_old = cumL / max(cumL(end), eps);
            t_new = linspace(0, 1, N);
            newWP = zeros(N,3);
            for d = 1:3
                newWP(:,d) = interp1(t_old, waypoints(:,d), t_new, 'linear','extrap');
            end
        end

        %% 地形高度抬升 + 相邻高度突变平滑
        function correctedPath = terrainConstraint(obj, path, terrain)
            correctedPath = path;
            safeH = obj.safeClearance;
            maxD = obj.maxDeltaH;
            % 第一步：所有航点抬高至地形安全高度以上
            for i = 1:size(correctedPath,1)
                x = correctedPath(i,1);
                y = correctedPath(i,2);
                groundH = terrain.getHeight(x, y);
                minSafeH = groundH + safeH;
                if correctedPath(i,3) < minSafeH
                    correctedPath(i,3) = minSafeH;
                end
            end
            % 正向高度平滑
            for i = 2:size(correctedPath,1)
                dh = correctedPath(i,3) - correctedPath(i-1,3);
                if abs(dh) > maxD
                    correctedPath(i,3) = correctedPath(i-1,3) + sign(dh)*maxD;
                end
            end
            % 反向消除阶梯突变
            for i = size(correctedPath,1)-1:-1:1
                dh = correctedPath(i,3) - correctedPath(i+1,3);
                if abs(dh) > maxD
                    correctedPath(i,3) = correctedPath(i+1,3) + sign(dh)*maxD;
                end
            end
        end
    end

    methods (Static)
        % Cox-de Boor 标准递推求值（论文B样条核心算法）
        function yVal = bsplineEval(knots, ctrlPts, p, uQuery)
            % 输入判空容错
            if isempty(knots) || isempty(ctrlPts) || isempty(uQuery)
                yVal = zeros(size(uQuery));
                return;
            end
            m = length(uQuery);
            nCP = length(ctrlPts);
            N = zeros(m, nCP, p+1);

            % 0阶基函数 N_{j,0}(u) = 1 if knots(j) <= u < knots(j+1)
            for j = 1:nCP
                L = knots(j);
                R = knots(j+1);
                N(:,j,1) = (uQuery >= L) & (uQuery < R);
            end

            % 递推计算p阶基函数
            for r = 1:p
                for j = 1:(nCP - r)
                    d1 = knots(j+r) - knots(j);
                    d2 = knots(j+r+1) - knots(j+1);
                    term1 = 0;
                    term2 = 0;
                    if abs(d1) > eps
                        term1 = (uQuery - knots(j)) / d1 .* N(:,j,r);
                    end
                    if abs(d2) > eps
                        term2 = (knots(j+r+1) - uQuery) / d2 .* N(:,j+1,r);
                    end
                    N(:,j,r+1) = term1 + term2;
                end
            end

            Basis = N(:, 1:nCP, p+1);
            yVal = Basis * ctrlPts(:);
        end
    end
end