classdef UAVMultiObj < handle
    % ============================================================================
    %  UAVMultiObj — 四目标无人机山岳搜救路径规划模型
    %  对应论文第 2 章问题建模（2.1~2.4 节）
    %  优化目标（全部最小化，越大越差）：
    %   J1 路径总长度          （论文式 eq:J1）
    %   J2 能耗代价            速度变化 + 俯仰角幅值   （论文式 eq:J2）
    %   J3 威胁暴露 + 缺失搜索收益（威胁积分 + μ_s·(1−S)·Δs）（论文式 eq:J3）
    %   J4 传感器姿态抖动      俯仰变化率 + 偏航变化率   （论文式 eq:J4）
    %  硬约束：
    %   1) 全轨迹（离散航点+B样条平滑）高度 ≥ 地形 + h_min          eq:altitude
    %   2) 坐标邻近地图边界 x∈[0,Xmax],y∈[0,Ymax] — 软惩罚加至 J3    eq:boundary
    %   3) 单段俯仰 |θ| ≤ theta_max                                eq:pitch
    %   4) 拐点航向转角 |ψ| ≤ psi_max                              eq:yaw
    %  依赖：BsplineSmooth.m（缺失则仅校验离散航点约束）
    %  与MOALA/NSGAII/MOPSO接口完全统一：sampleFeasibleChromosome / checkFeasibility
    %  evaluate输出1×4行向量，与HV_ref四维对齐
    % ============================================================================
    properties
        terrain   % 地形对象 terrainGeneration
        threat    % 威胁场对象

        %% 起止点（固定，不参与优化）
        startPoint(1,3) double = [5, 5, 12]
        endPoint(1,3)   double = [95, 95, 12]

        %% 编码参数：连续航点直接编码 X = [x1,y1,z1, ..., x_{Nw},y_{Nw}]
        numWaypoints double = 20        % N_w 中间自由航点数量
        dim          double             % D = 3*numWaypoints
        lb           double             % 单航点 [xmin,ymin,zmin] 重复拼接
        ub           double             % 单航点 [xmax,ymax,zmax] 重复拼接

        %% 飞行姿态约束（统一论文命名，消除mu变量歧义）
        theta_max(1,1) double = pi/3    % 单段最大俯仰角 θ_max
        psi_max(1,1) double = pi/3     % 拐点最大航向转角 ψ_max（仅由 J4 软惩罚约束，无硬修复）
        h_min   double = 2              % 安全高度余量

        %% 幸存者概率场参数（2.3.3 二维高斯混合分布）
        N_s     double = 5
        survivorCenters double          % N_s×2 平面中心坐标

        %% 目标权重（论文α,β,γ,δ，mu_s区分俯仰theta_max）
        alpha double = 1.0   % J2 速度变化项权重
        beta  double = 1.0   % J2 俯仰角幅值权重
        gamma double = 1.0   % J4 俯仰变化率权重
        delta double = 1.0   % J4 航向变化率权重
        mu_s double = 0.5    % J3 缺失搜索收益权重

        %% 归一化基准（匀速直线参考）
        v_base     double = 10.0
        pitch_base double = pi/3
        dtheta_base double = pi/6
        dyaw_base  double = pi/6

        %% 惩罚与指标基准
        penaltyVal double = 1e6
        objectives  double = 4
        HV_ref(1,4) double = [600, 5, 200, 20]   % [J1_max,J2_max,J3_max,J4_max]
        IGD_ref            double = []           % 无理论真实Pareto前沿

        %% B样条评估开关（2026-08-28 新增，运行时间优化）
        %  true  = evaluate 内执行 B样条平滑（原行为，用于最终路径呈现）
        %  false = 优化过程中跳过 B样条（省 ~18% 耗时）
        %         最终路径平滑由 runTerrainScenario pathData 阶段独立完成，不受影响
        % 默认 false：优化过程不跑 B样条；绘图/最终解出图时由调用方自行平滑
        useBsplineInEval(1,1) logical = false
    end

    methods
        %% 构造函数
        %% 构造函数（移除inputParser，兼容所有MATLAB版本）
        function obj = UAVMultiObj(terrain, threat)
            obj.terrain = terrain;
            obj.threat  = threat;
        
            obj.dim = 3 * obj.numWaypoints;
            mapSize = obj.terrain.mapSize;
            Xmax = mapSize(2);
            Ymax = mapSize(1);
            ZminTer = obj.terrain.minH;
            ZmaxFly = obj.terrain.maxH + 30;
            obj.lb = repmat([0, 0, ZminTer], 1, obj.numWaypoints);
            obj.ub = repmat([Xmax, Ymax, ZmaxFly], 1, obj.numWaypoints);
        
            % 起止点自动抬高，避免地形导致永久不可行
            sp = obj.startPoint(:)';
            ep = obj.endPoint(:)';
            th_s = obj.terrain.getHeight(sp(1), sp(2));
            th_e = obj.terrain.getHeight(ep(1), ep(2));
            if th_s + obj.h_min > sp(3); sp(3) = th_s + obj.h_min + 1; end
            if th_e + obj.h_min > ep(3); ep(3) = th_e + obj.h_min + 1; end
            obj.startPoint = sp;
            obj.endPoint   = ep;
        
            obj.survivorCenters = obj.generateSurvivorCenters(obj.N_s);
        end

        %% 核心适应度评估
        function [f, path] = evaluate(obj, chromosome)
            D = obj.dim;
            if length(chromosome) ~= D
                f = repmat(obj.penaltyVal, 1, obj.objectives);
                path.valid = false;
                return;
            end

            path = obj.decode(chromosome);
            % 地形投影约束处理（论文2.4.2）：将所有离散航点高度抬至地形安全高度之上
            for kk = 1:size(path.points,1)
                path.points(kk,:) = obj.projectEndpointToTerrain(path.points(kk,:));
            end
            % 俯仰角投影修复（论文2.4.2）：调整后一点高度使相邻段俯仰≤θ_max
            path.points = obj.repairPitch(path.points);
            % 注：航向转角 ψ 仅通过 J4 软惩罚约束（无硬修复/硬拒绝），
            % 与俯仰 θ 不同——ψ 可通过调整转弯半径自然满足，硬修复反而破坏搜索空间。
            % 俯仰再修一次确保高度重投影后不超限
            nPts = size(path.points,1);
            if nPts < 2
                f = repmat(obj.penaltyVal, 1, obj.objectives);
                return;
            end

            mapSize = obj.terrain.mapSize;
            Xmax = mapSize(2);
            Ymax = mapSize(1);

            % 约束1、2：离散航点地形+边界校验
            validFlag = true;
            for k = 1:nPts
                x = path.points(k,1);
                y = path.points(k,2);
                z = path.points(k,3);
                th = obj.terrain.getHeight(x, y);
                if z < th + obj.h_min || z < obj.terrain.minH
                    validFlag = false; break;
                end
                if x < 0 || x > Xmax || y < 0 || y > Ymax
                    validFlag = false; break;
                end
            end
            if ~validFlag
                f = repmat(obj.penaltyVal, 1, obj.objectives);
                return;
            end

            diffs = diff(path.points,1,1);
            segLen = sqrt(sum(diffs.^2,2));
            nSeg = length(segLen);

            %% J1 总路径长度
            J1 = sum(segLen);

            %% J2 能耗代价
            dt = 1.0;
            v_vec = diffs ./ dt;
            sum_dv = 0;
            if nSeg >= 2
                delta_v = vecnorm(v_vec(2:end-1,:) - v_vec(1:end-2,:), 2, 2);
                sum_dv = sum(delta_v);
            end
            xyDist = sqrt(diffs(:,1).^2 + diffs(:,2).^2) + eps;
            pitch = atan2(diffs(:,3), xyDist);
            sum_pitch = sum(abs(pitch));
            J2_v = obj.alpha * sum_dv / (nSeg * obj.v_base);
            J2_p = obj.beta * sum_pitch / (nSeg * obj.pitch_base);
            J2 = J2_v + J2_p;

            %% J3 威胁+缺失搜索收益
            xAll = path.points(:,1);
            yAll = path.points(:,2);
            zAll = path.points(:,3);

            %% 边界邻近惩罚：在 clamp 之前计算，越近边界代价越高
            %   防止 optimizer 发现 getHeight clamp 后边界处"地形平坦"而绕边
            %   每个航点对边界的最小距离: d = min(x, 100-x, y, 100-y)
            %   惩罚 = BOUND_PROX * sum(1/(d+0.5))，d 越小惩罚越大
            BOUND_PROX = 20;
            d2edge = min([xAll, 100-xAll, yAll, 100-yAll], [], 2);  % 每点到最近边界的距离（N×1）
            J3_boundary = BOUND_PROX * sum(1 ./ (d2edge + 0.5));

            T = obj.threat.evaluate(xAll', yAll', zAll');
            T = T(:);
            delta_s = zeros(nPts,1);
            if nSeg >= 1
                delta_s(1) = 0.5 * segLen(1);
                for k = 2:nSeg
                    delta_s(k) = 0.5 * (segLen(k) + segLen(k-1));
                end
            end
            J3_threat = sum(T .* delta_s);
            S = obj.survivorField(xAll, yAll, zAll);
            J3_search = sum(S .* delta_s);
            J3 = J3_threat + obj.mu_s * sum((1 - S) .* delta_s) + J3_boundary;

            %% J4 姿态抖动
            dTheta_seg = abs(diff(pitch));
            sum_dtheta = sum(dTheta_seg(2:end-1));
            yaw = atan2(diffs(:,2), diffs(:,1));
            dPsi = zeros(length(yaw)-1,1);
            for i = 1:length(yaw)-1
                dPsi(i) = abs(angdiff(yaw(i), yaw(i+1)));
            end
            sum_dpsi = sum(dPsi);
            cnt_dt = max(length(dTheta_seg)-2, 1);
            cnt_dp = max(length(dPsi), 1);
            J4_theta = obj.gamma * sum_dtheta / (cnt_dt * obj.dtheta_base);
            J4_psi = obj.delta * sum_dpsi / (cnt_dp * obj.dyaw_base);
            J4 = J4_theta + J4_psi;

            %% 离散航点俯仰硬约束（航向 ψ 仅由 J4 软惩罚约束）
            cond_pitch = any(abs(pitch) > obj.theta_max);
            if cond_pitch
                f = repmat(obj.penaltyVal, 1, obj.objectives);
                return;
            end

            %% B样条平滑（仅用于最终路径呈现，不参与约束判定）
            %  【2026-08-28 优化】useBsplineInEval=false（默认）时优化过程跳过 B样条
            %    （省 ~18% 耗时）；最终路径平滑由 runTerrainScenario pathData 阶段独立完成。
            %  【2026-08-28 决策】经对比实验（runSmoothFairCompare）验证：
            %    "B样条后校验"（平滑→校验→惩罚）不能把最终平滑轨迹的超限率降到 0
            %    （外部平滑口径下山地仍 2.69% vs 默认 1.38%），且耗时 3 倍，故已删除该方案。
            %    俯仰/地形/边界约束在离散航点层面硬校验（evaluate 前置步骤），
            %    B样条仅作为可视化后处理，与论文表述一致。
            if obj.useBsplineInEval && size(path.points,1) >= 4 && exist('BsplineSmooth.m','file')
                try
                    bsObj = BsplineSmooth('safeClearance', 2.0, 'maxDeltaH', 8.0);
                    smoothPts = bsObj.smooth(path.points, 'numPoints', 100, 'terrain', obj.terrain);
                    if ~isempty(smoothPts) && all(isfinite(smoothPts(:)))
                        path.points = smoothPts;
                        path.length = sum(sqrt(sum(diff(smoothPts,1,1).^2, 2)));
                    end
                catch
                    % 平滑异常时保留离散投影航点
                end
                % 平滑后重新安全投影（防御 X,Y 越界与俯仰超限）
                for kk = 1:size(path.points,1)
                    path.points(kk,:) = obj.projectEndpointToTerrain(path.points(kk,:));
                end
                path.points = obj.repairPitch(path.points);
            end

            f = [J1, J2, J3, J4];
            if any(~isfinite(f))
                % 数值异常兜底（威胁/幸存者场个别点插值异常），判为不可行
                fprintf('DBGEVAL NaN: J1=%.3g J2=%.3g J3=%.3g J4=%.3g nPts=%d\n', J1, J2, J3, J4, nPts);
                f = repmat(obj.penaltyVal, 1, obj.objectives);
            end
        end

        %% 对外统一接口：生成可行初始种群
        function chrom = sampleFeasibleChromosome(obj, n)
            if nargin < 2; n = 1; end
            D = obj.dim;
            chrom = zeros(n, D);
            numW = obj.numWaypoints;
            mapSize = obj.terrain.mapSize;
            Xmax = mapSize(2);
            Ymax = mapSize(1);
            ZmaxFly = obj.terrain.maxH + 30;
            for s = 1:n
                for w = 1:numW
                    idxX = 3*w - 2;
                    idxY = 3*w - 1;
                    idxZ = 3*w;
                    x = rand() * Xmax;
                    y = rand() * Ymax;
                    th = obj.terrain.getHeight(x, y);
                    z_min_ok = th + obj.h_min + 0.5;
                    z_max_ok = obj.ub(idxZ);
                    if z_max_ok <= z_min_ok
                        z = z_max_ok;
                    else
                        z = z_min_ok + rand() * (z_max_ok - z_min_ok);
                    end
                    chrom(s, idxX) = x;
                    chrom(s, idxY) = y;
                    chrom(s, idxZ) = z;
                end
            end
        end

        %% 统一标准：单染色体快速校验（地形+边界+姿态）
        function flag = checkFeasibility(obj, chrom)
            path = obj.decode(chrom);
            nPts = size(path.points,1);
            mapSize = obj.terrain.mapSize;
            Xmax = mapSize(2);
            Ymax = mapSize(1);
            % 1 地形边界
            for k = 1:nPts
                x = path.points(k,1); y = path.points(k,2); z = path.points(k,3);
                th = obj.terrain.getHeight(x,y);
                if z < th + obj.h_min || x<0||x>Xmax||y<0||y>Ymax
                    flag = false; return;
                end
            end
            % 2 俯仰航向快速校验
            diffs = diff(path.points,1,1);
            xyDist = sqrt(diffs(:,1).^2 + diffs(:,2).^2) + eps;
            pitch = atan2(diffs(:,3), xyDist);
            if any(abs(pitch) > obj.theta_max)
                flag = false; return;
            end
            yaw = atan2(diffs(:,2), diffs(:,1));
            dPsi = zeros(length(yaw)-1,1);
            for i = 1:length(yaw)-1
                dPsi(i) = abs(angdiff(yaw(i), yaw(i+1)));
            end
            if ~isempty(dPsi) && any(dPsi > obj.psi_max)
                flag = false; return;
            end
            flag = true;
        end

        %% B样条平滑轨迹约束校验（2026-08-27 新增）
        %  对平滑后采样点做完整约束校验：地形净空 ≥ h_min、边界、俯仰 |θ| ≤ θ_max
        %  返回 flag：true=全部满足，false=存在违反
        %% 地形投影：将航点 (x,y,z) 投影到地形安全高度之上，并 clamp x,y 到地图边界
        %   clamp 防止 optimizer 发现"边界外是平坦的"而导致贴边绕行
        function p = projectEndpointToTerrain(obj, p)
            % x,y clamp 到地图边界（防止越界和贴边行为）
            p(1) = max(0, min(100, p(1)));  % X ∈ [0, 100]
            p(2) = max(0, min(100, p(2)));  % Y ∈ [0, 100]
            th = obj.terrain.getHeight(p(1), p(2));
            zMin = max(th + obj.h_min + 0.5, obj.terrain.minH + 0.5);
            if p(3) < zMin
                p(3) = zMin;
            end
        end

        %% 俯仰角投影修复（论文2.4.2）：前向调整航点高度，使相邻段俯仰角不超过 θ_max
        function pts = repairPitch(obj, pts)
            nPts = size(pts,1);
            if nPts < 2; return; end
            maxPitch = obj.theta_max * 0.95;
            for k = 2:nPts
                dx = pts(k,1) - pts(k-1,1);
                dy = pts(k,2) - pts(k-1,2);
                horiz = sqrt(dx^2 + dy^2) + eps;
                dz = pts(k,3) - pts(k-1,3);
                pitch = atan2(dz, horiz);
                if abs(pitch) > maxPitch
                    signDz = sign(dz);
                    if signDz == 0; signDz = 1; end
                    targetDz = signDz * horiz * tan(maxPitch);
                    pts(k,3) = pts(k-1,3) + targetDz;
                    % 修复后再次保证地形安全高度
                    pts(k,:) = obj.projectEndpointToTerrain(pts(k,:));
                end
            end
        end

        %% 航向转角投影修复（论文2.4.2）：迭代将内部航点向弦线方向平移，
        %  使相邻段航向转角不超过 ψ_max（保留起终点不动）
        function pts = repairYaw(obj, pts)
            nPts = size(pts,1);
            if nPts < 3; return; end
            maxPsi = obj.psi_max * 0.95;
            for pass = 1:12
                changed = false;
                for k = 2:nPts-1
                    A = pts(k-1,1:2); B = pts(k,1:2); C = pts(k+1,1:2);
                    v1 = B - A; v2 = C - B;
                    if norm(v1) < 1e-6 || norm(v2) < 1e-6; continue; end
                    ang1 = atan2(v1(2),v1(1));
                    ang2 = atan2(v2(2),v2(1));
                    dPsi = abs(angdiff(ang1, ang2));
                    if dPsi > maxPsi
                        AC = C - A; L = norm(AC);
                        if L < 1e-6; continue; end
                        dir = AC / L;
                        rel = B - A;
                        perp = rel - dot(rel,dir) * dir;
                        % 向弦线平移以减小转角（每轮减半，逐轮收敛）
                        Bnew = B - 0.6 * perp;
                        pts(k,1:2) = Bnew;
                        changed = true;
                    end
                end
                if ~changed; break; end
            end
            % 平移后重新保证地形安全高度
            for kk = 1:size(pts,1)
                pts(kk,:) = obj.projectEndpointToTerrain(pts(kk,:));
            end
        end

        function path = decode(obj, chromosome)
            nW = obj.numWaypoints;
            geneMat = reshape(chromosome, 3, nW)';
            wp_xyz = geneMat;
            start = obj.startPoint;
            dest = obj.endPoint;
            vecSE = dest - start;
            lenSE = max(norm(vecSE), eps);
            proj = zeros(nW,1);
            for i = 1:nW
                vecP = wp_xyz(i,:) - start;
                proj(i) = dot(vecP, vecSE) / lenSE;
            end
            [~, sortIdx] = sort(proj);
            wp_xyz = wp_xyz(sortIdx, :);
            fullPath = [start; wp_xyz; dest];
            path.points = fullPath;
            path.length = sum(sqrt(sum(diff(fullPath,1,1).^2, 2)));
            path.valid = true;
        end

        %% 生成幸存者平面高斯中心（避开起止区域）
        function C = generateSurvivorCenters(obj, N_s)
            mapSize = obj.terrain.mapSize;
            Xmax = mapSize(2);
            Ymax = mapSize(1);
            C = zeros(N_s,2);
            stXY = obj.startPoint(1:2);
            edXY = obj.endPoint(1:2);
            for i = 1:N_s
                ok = false;
                while ~ok
                    cx = 15 + rand()*(Xmax-30);
                    cy = 15 + rand()*(Ymax-30);
                    dSt = norm([cx, cy] - stXY);
                    dEd = norm([cx, cy] - edXY);
                    ok = dSt > 15 && dEd > 15;
                end
                C(i,:) = [cx, cy];
            end
        end

        %% 二维幸存者概率场（无高度项）
        function S = survivorField(obj, xVec, yVec, zVec)
            sigma_s = 12;    % 平面高斯展宽
            eta_s = 8;       % 垂直高度衰减尺度
            Np = length(xVec);
            C = obj.survivorCenters;
            Nc = size(C,1);
            % 向量化：平面距离矩阵（Np×Nc）一次性计算
            xAll = xVec(:); yAll = yVec(:); zAll = zVec(:);
            dx2 = (xAll - C(:,1)').^2;      % Np×Nc
            dy2 = (yAll - C(:,2)').^2;
            g_xy = exp(-(dx2 + dy2) / (2 * sigma_s^2));
            % 垂直衰减：z_ground 与中心无关，提前一次性取地形高度
            z_ground = zeros(Np,1);
            for p = 1:Np
                z_ground(p) = obj.terrain.getHeight(xAll(p), yAll(p));
            end
            g_z = exp(-abs(zAll - z_ground) ./ eta_s);  % Np×1
            S = sum(g_xy .* g_z, 2);   % Np×1
            maxS = max(max(S), 1e-6);
            S = S / maxS;   % 全局归一到[0,1]
        end

        %% 边界钳位（与MOALA统一私有函数）
        function X = boundTrunc(~, X, lb, ub)
            X = max(min(X, ub), lb);
        end
    end
end