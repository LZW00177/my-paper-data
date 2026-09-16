classdef MetricsCalculator
    % ============================================================================
    %  MetricsCalculator — 多目标优化评价指标
    % ----------------------------------------------------------------------------
    %  对应论文第 4 章 4.1.3 节评价指标
    %
    %   - HV      (Hypervolume)        超体积，越大越好（论文主指标）
    %   - IGD     (Inverted Generational Distance)  反向世代距离，越小越好
    %   - NormalizedIGD 归一化IGD（≠标准IGD+，注意区分）
    %   - Spacing                         分布均匀性，越小越好
    %   - Spread (Δ, Schott 1995)         分布广度，越小越好
    %
    %  约定：全部目标为最小化优化问题
    % ============================================================================

    methods (Static)
        %% ----------------------- HV 超体积（蒙特卡洛估计） -----------------------
        function hv = HV(ParetoFront, refPoint, nSample)
            % HV：被 PF 支配且与 refPoint 围成的超体积（越大越好）
            % 输入PF：可行前沿（可含被支配解，内部自动精简）；refPoint：归一化上界 1×M
            %
            % 最小化问题的标准定义：
            %   HV = vol{ x : ∃p∈PF, p ≼ x ≼ refPoint }
            % 由于样本取自 [0, refPoint]，条件 s ≤ refPoint 自动满足，
            % 故样本被计入当且仅当  ∃p∈PF:  all(p ≤ s)  即  all(s >= p)。
            %
            % 【2026-09-12 修复·方向性错误】原实现写的是 all(samples <= PF(i,:))，
            %   统计的是"比前沿更优"的区域（曲线下方），而非被前沿支配的区域，
            %   导致 HV 与标准定义相反：
            %     PF={(0,0)}（理想点）→ 原给 0.0000（标准 1.0）
            %     PF={(1,1)}（最差点）→ 原给 1.0000（标准 0.0）
            %     ZDT2 真前沿整体变差 +0.15 后 HV 反而上升（破坏单调性）
            %   地形主实验实测：存储 HV 排名与标准 HV 排名完全倒序（Spearman = -1.0）
            %
            % 【2026-08-28 修复】发散解处理：任一维超出 refPoint 的解不参与支配判断
            %   （旧实现 min(max(PF,0),ref) 把发散解 clamp 到参考点边界，
            %     使其"支配"参考点附近大片区域 → HV 虚高，DTLZ3 实测单点 0.93/1.16）
            if nargin < 3; nSample = 20000; end
            if isempty(ParetoFront)
                hv = 0; return;
            end
            % 精简：只保留非支配解
            PF = MetricsCalculator.filterNonDominated(ParetoFront);
            if isempty(PF)
                hv = 0; return;
            end
            [~, M] = size(PF);
            % 剔除发散解：任一维超出 refPoint 或小于 0 的解不参与支配（不计入体积）
            okRows = all(PF >= 0, 2) & all(PF <= refPoint, 2);
            PF = PF(okRows, :);
            if isempty(PF)
                hv = 0; return;
            end
            samples = rand(nSample, M) .* refPoint;
            dominated = false(nSample, 1);
            for i = 1:size(PF,1)
                % 样本 s 落入 [PF(i,:), refPoint] 盒 ⇔ PF(i,:) ≤ s ≤ refPoint
                % 即 all(s >= PF(i,:))（refPoint 上界由采样范围隐含保证）
                dominated = dominated | all(samples >= PF(i,:), 2);
            end
            hv = (sum(dominated) / nSample) * prod(refPoint);
        end

        %% ----------------------- IGD 反向世代距离 -----------------------
        function igd = IGD(ParetoFront, truePF)
            % IGD = mean_{p*∈truePF} min_{p∈PF} ||p* - p||_2
            if isempty(truePF) || isempty(ParetoFront)
                igd = inf; return;
            end
            PF = MetricsCalculator.filterNonDominated(ParetoFront);
            % truePF 已在问题构造时预过滤（见 ZDTProblem/DTLZProblem 构造函数），
            % 此处不再重复 O(N^2) 支配过滤，避免每代对 2000 点真值前沿重算（原先单次 ~0.86s）。
            tPF = truePF;
            if isempty(PF) || isempty(tPF)
                igd = inf; return;
            end
            [N, ~] = size(tPF);
            minDists = zeros(N, 1);
            for i = 1:N
                diff = tPF(i,:) - PF;
                minDists(i) = min(sqrt(sum(diff.^2, 2)));
            end
            igd = mean(minDists);
        end

        %% ----------------------- 归一化IGD（原IGD_plus，更名避免歧义） -----------------------
        function normIgd = NormalizedIGD(ParetoFront, truePF)
            % 仅目标量纲归一化后计算标准IGD，≠文献IGD+
            if isempty(truePF) || isempty(ParetoFront)
                normIgd = inf; return;
            end
            allObj = [ParetoFront; truePF];
            minVals = min(allObj, [], 1);
            maxVals = max(allObj, [], 1);
            range = max(maxVals - minVals, 1e-9);
            pf_norm  = (ParetoFront - minVals) ./ range;
            tpf_norm = (truePF - minVals) ./ range;
            normIgd = MetricsCalculator.IGD(pf_norm, tpf_norm);
        end

        %% ----------------------- Spacing 分布均匀性 -----------------------
        function spacing = Spacing(ParetoFront)
            % 原始定义使用曼哈顿距离；本实现采用欧氏距离（论文中需注明）
            PF = MetricsCalculator.filterNonDominated(ParetoFront);
            N = size(PF,1);
            if N < 2
                spacing = inf; return;
            end
            distances = zeros(N,1);
            for i = 1:N
                others = PF;
                others(i,:) = [];
                diff = PF(i,:) - others;
                dists = sqrt(sum(diff.^2, 2));
                distances(i) = min(dists);
            end
            d_mean = mean(distances);
            spacing = sqrt(sum((distances - d_mean).^2) / (N - 1));
        end

        %% ----------------------- Spread Δ (Schott, 1995) 原版实现 -----------------------
        function spread = Spread(ParetoFront)
            PF = MetricsCalculator.filterNonDominated(ParetoFront);
            N = size(PF,1);
            if N < 2
                spread = inf; return;
            end
            [~, M] = size(PF);
            % 归一化
            minVals = min(PF,[],1);
            maxVals = max(PF,[],1);
            rng = max(maxVals - minVals, 1e-9);
            pf_norm = (PF - minVals) ./ rng;

            % 按第一目标升序排序（多目标通用排序策略）
            [~, sortIdx] = sort(pf_norm(:,1));
            pf_sorted = pf_norm(sortIdx,:);

            % 相邻距离
            dists = zeros(N-1,1);
            for i = 1:N-1
                dists(i) = norm(pf_sorted(i+1,:)-pf_sorted(i,:));
            end
            d_mean = mean(dists);

            % 寻找前沿极值点（各维度最值）
            idxMin = zeros(1,M);
            idxMax = zeros(1,M);
            for m = 1:M
                [~,idxMin(m)] = min(pf_norm(:,m));
                [~,idxMax(m)] = max(pf_norm(:,m));
            end
            allExtIdx = unique([idxMin, idxMax]);
            extPoints = pf_norm(allExtIdx,:);

            % d_f：起点到最近极值；d_l：终点到最近极值
            d_f = min(vecnorm(pf_sorted(1,:) - extPoints,2,2));
            d_l = min(vecnorm(pf_sorted(end,:) - extPoints,2,2));

            denom = d_f + d_l + (N-1)*d_mean;
            if denom < 1e-12
                spread = 0;
            else
                spread = (d_f + d_l + sum(abs(dists - d_mean))) / denom;
            end
        end

        %% ----------------------- HV参考范围自动估计 -----------------------
        function refRange = estimateHVRefPoint(allFronts)
            % 参考点估计：取所有前沿并集的每维最大值 × 1.05 余量。
            % 并集 max 保证单个算法的 PF 不会超出参考点（避免归一化塌缩），
            % 1.05 余量（原 1.1）收紧以减少异常大值（如MOPSO发散解）对HV的虚高。
            unionF = [];
            for i = 1:length(allFronts)
                F = allFronts{i};
                if ~isempty(F)
                    unionF = [unionF; F];
                end
            end
            if isempty(unionF)
                M = 4;
                refRange.min = zeros(1,M);
                refRange.max = ones(1,M);
                return;
            end
            M = size(unionF,2);
            refRange.min = zeros(1,M);
            for m = 1:M
                colMax = max(unionF(:,m));
                hi = colMax * 1.05;
                if hi <= 0; hi = 1; end
                refRange.max(m) = hi;
            end
        end

        %% ----------------------- 异常退化解裁剪（逐目标99分位） -----------------------
        function PFc = pruneOutliers(PF, qHi)
            if nargin < 2; qHi = 0.99; end
            if size(PF,1) < 3
                PFc = PF; return;
            end
            M = size(PF,2);
            hi = zeros(1,M);
            for m = 1:M
                col = sort(PF(:,m));
                pos = min(length(col), ceil(qHi * length(col)));
                hi(m) = col(pos);
            end
            keep = true(size(PF,1),1);
            for m = 1:M
                keep = keep & (PF(:,m) <= hi(m));
            end
            PFc = PF(keep, :);
        end

        %% ----------------------- 前沿归一化 [0,1] -----------------------
        function PFn = normalizeFront(PF, refRange)
            rng_ = max(refRange.max - refRange.min, 1e-9);
            PFn = (PF - refRange.min) ./ rng_;
            PFn = min(max(PFn, 0), 1);
        end

        %% ----------------------- 内部工具：过滤保留非支配解（最小化） -----------------------
        function ndPF = filterNonDominated(PF)
            if size(PF,1) <= 1
                ndPF = PF; return;
            end
            N = size(PF,1);
            keep = true(N,1);
            for i = 1:N
                for j = 1:N
                    if i==j || ~keep(j); continue; end
                    if MetricsCalculator.dominates(PF(j,:), PF(i,:))
                        keep(i) = false;
                        break;
                    end
                end
            end
            ndPF = PF(keep,:);
        end

        %% ----------------------- 支配判断（最小化） -----------------------
        function flag = dominates(obj1, obj2)
            flag = all(obj1 <= obj2) && any(obj1 < obj2);
        end
    end
end