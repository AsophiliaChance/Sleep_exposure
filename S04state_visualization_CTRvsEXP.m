clc; clear
cd('G:\study2\results');

filename={'S001control_IG_pre_nsubavg.mat','S002_IG_pre_nsubavg.mat','S001control_IG_post_nsubavg.mat','S002_IG_post_nsubavg.mat'};

% -------- 导入数据 --------
for md = 1:4
    load(filename{md});   % 载入 Diff_avg, STD_avg, DEV_avg
    
    % 每个文件的被试数和条件数自动获取
    nsub = size(Diff_avg,1);
    ndev = size(Diff_avg,2);
    
    for isub = 1:nsub
        for idev = 1:ndev
            Diff{md,isub,idev} = Diff_avg{isub,idev};
            STD{md,isub,idev}  = STD_avg{isub,idev};
            DEV{md,isub,idev}  = DEV_avg{isub,idev};
        end
    end
    fprintf('已导入 %s: %d subjects, %d conditions\n', filename{md}, nsub, ndev);
end

eeglab;

% ======================================================
% ============ FieldTrip Cluster Permutation ===========
% ======================================================
% 数据: Diff{md,isub,idev}, md=1..4, idev=1..2
% 每个单元已是 ft_timelockanalysis 输出结构（含 avg/time/label 等）

% ------- 邻接关系（基于布局）-------
layout = 'GSN-HydroCel-128.mat';   % ← 按你的实际文件名修改
cfg_neigh = [];
cfg_neigh.method = 'distance';
cfg_neigh.layout = layout;
neighbours = ft_prepare_neighbours(cfg_neigh);

% ------- 统计配置模板 -------
cfg_template = [];
cfg_template.channel           = 'all';
cfg_template.latency           = 'all';
cfg_template.parameter         = 'avg';
cfg_template.method            = 'montecarlo';
cfg_template.statistic         = 'depsamplesT';
cfg_template.correctm          = 'cluster';
cfg_template.clusteralpha      = 0.01;
cfg_template.clusterstatistic  = 'maxsum';
cfg_template.mcorrect          = 'no';
cfg_template.tail              = 0;
cfg_template.clustertail       = 0;
cfg_template.alpha             = 0.005;
cfg_template.numrandomization  = 5000;
cfg_template.neighbours        = neighbours;
cfg_template.layout            = layout;
cfg_template.minnbchan         = 2;

% ======================================================
% 按 idev 和 md 配对跑统计
% 注意：md1 vs md2 有 21 个被试，md3 vs md4 有 19 个被试
% ======================================================
stats = {};
labels_ = {};

for idev = 1:2
    % ---------- md1 vs md2 ----------
    nSub12 = min([sum(~cellfun(@isempty,Diff(1,:,idev))), ...
                  sum(~cellfun(@isempty,Diff(2,:,idev)))]);
    cfg12 = cfg_template;
    design = zeros(2,2*nSub12);
    design(1,:) = repmat(1:nSub12,1,2);
    design(2,1:nSub12) = 1; design(2,nSub12+1:end) = 2;
    cfg12.design = design; cfg12.uvar = 1; cfg12.ivar = 2;
    inputs = cell(1,2*nSub12);
    for s = 1:nSub12
        inputs{s}       = Diff{1,s,idev};
        inputs{nSub12+s}= Diff{2,s,idev};
    end
    st12 = ft_timelockstatistics(cfg12, inputs{:});
    stats{end+1} = st12;
    labels_{end+1} = sprintf('idev=%d, md1vsmd2 (%d subs)',idev,nSub12);

    % ---------- md3 vs md4 ----------
    nSub34 = min([sum(~cellfun(@isempty,Diff(3,:,idev))), ...
                  sum(~cellfun(@isempty,Diff(4,:,idev)))]);
    cfg34 = cfg_template;
    design = zeros(2,2*nSub34);
    design(1,:) = repmat(1:nSub34,1,2);
    design(2,1:nSub34) = 1; design(2,nSub34+1:end) = 2;
    cfg34.design = design; cfg34.uvar = 1; cfg34.ivar = 2;
    inputs = cell(1,2*nSub34);
    for s = 1:nSub34
        inputs{s}       = Diff{3,s,idev};
        inputs{nSub34+s}= Diff{4,s,idev};
    end
    st34 = ft_timelockstatistics(cfg34, inputs{:});
    stats{end+1} = st34;
    labels_{end+1} = sprintf('idev=%d, md3vsmd4 (%d subs)',idev,nSub34);
end

% ======================================================
% 输出簇统计结果
% ======================================================
alpha_cluster = 0.01;
alpha_cluster = 0.01;

for i = 1:numel(stats)
    st = stats{i};

    % --- 取正簇的簇级p ---
    if isfield(st,'posclusters') && ~isempty(st.posclusters)
        pos_probs = arrayfun(@(c) c.prob, st.posclusters);
    else
        pos_probs = [];
    end
    pos_sig = ~isempty(pos_probs) && any(pos_probs < alpha_cluster);

    % --- 取负簇的簇级p ---
    if isfield(st,'negclusters') && ~isempty(st.negclusters)
        neg_probs = arrayfun(@(c) c.prob, st.negclusters);
    else
        neg_probs = [];
    end
    neg_sig = ~isempty(neg_probs) && any(neg_probs < alpha_cluster);

    % --- 点位最小p ---
    min_pointwise = min(st.prob(:));

    % --- 合并一个“簇级最小p”便于浏览 ---
    if isempty(pos_probs) && isempty(neg_probs)
        min_cluster_p = NaN;
    elseif isempty(pos_probs)
        min_cluster_p = min(neg_probs);
    elseif isempty(neg_probs)
        min_cluster_p = min(pos_probs);
    else
        min_cluster_p = min([min(pos_probs), min(neg_probs)]);
    end

    fprintf('%s: pos=%d, neg=%d, min_cluster_p=%.4g, min_pointwise_p=%.4g\n', ...
        labels_{i}, pos_sig, neg_sig, min_cluster_p, min_pointwise);
end
%% 画图
%% Cluster plot 可视化（通用版）
cfgp = [];
cfgp.layout      = layout;
cfgp.alpha       = 0.01;
cfgp.parameter   = 'stat';
cfgp.subplotsize = [4 11];   % 这里可以按需要修改
cfgp.zlim        = 'maxabs';
cfgp.colormap    = jet;

fprintf('\n=== Cluster plot: idev=1, md3 vs md4 ===\n');
h = ft_clusterplot(cfgp, stats{3});   % 这里直接用 stats cell，避免写死 stat_idev1_pair34

set(gcf, 'Position', [0 0 1500 600]);   % 控制整个 figure 尺寸

% -------- 调整子图大小和位置 --------
ax = findall(gcf,'Type','axes');
for i = 1:numel(ax)
    pos = get(ax(i),'Position');
    pos(3) = pos(3) * 2.1;   % 宽度放大
    pos(4) = pos(4) * 2.1;   % 高度放大
    pos(1) = pos(1) - 0.15;  % 左移
    pos(2) = pos(2) - 0.15;  % 下移
    set(ax(i),'Position',pos);
end

% -------- 重新调整行间距 --------
pos_all = cell2mat(get(ax,'Position'));
yvals   = unique(pos_all(:,2));
yvals   = sort(yvals,'ascend');
nRows   = numel(yvals);

% 自定义新间距范围（上下边界可调）
new_yvals = linspace(0.1,0.68,nRows);

for i = 1:numel(ax)
    pos = get(ax(i),'Position');
    [~,row_idx] = min(abs(pos(2)-yvals));
    pos(2) = new_yvals(row_idx);
    set(ax(i),'Position',pos);
end

% -------- 修改标题格式（秒 → 毫秒） --------
for i = 1:numel(ax)
    t = get(ax(i), 'Title');
    txt = string(get(t, 'String'));     
    if strlength(txt)==0, continue; end

    nums = regexp(txt, '[-+]?\d*\.?\d+', 'match');
    if isempty(nums), continue; end

    if numel(nums) == 1
        ms1 = round(str2double(nums{1}) * 1000);
        newtxt = sprintf('%d ms', ms1);
    else
        ms1 = round(str2double(nums{1}) * 1000);
        ms2 = round(str2double(nums{2}) * 1000);
        newtxt = sprintf('%d–%d ms', ms1, ms2);
    end

    set(t, 'String', newtxt, 'Interpreter','none');
    set(t, 'Units','normalized');
    pos = get(t,'Position');
    pos(2) = pos(2) - 0.2;   % 标题往下挪
    set(t,'Position',pos, 'VerticalAlignment','top');
end

