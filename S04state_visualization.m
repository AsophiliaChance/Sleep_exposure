clc;clear
cd('G:\study2\results');

filename={'S001control_IG_pre_nsubavg.mat','S001control_IG_post_nsubavg.mat','S002_IG_pre_nsubavg.mat','S002_IG_post_nsubavg.mat'};
%%
for md=1:4
    load(filename{md});
    %reshape ????±???
    for isub=1:19
        for idev=1:2
            Diff{md,isub,idev}=Diff_avg{isub,idev};
            STD{md,isub,idev}=STD_avg{isub,idev};
            DEV{md,isub,idev}=DEV_avg{isub,idev};
        end
    end
end
eeglab;
%%
% ================= FieldTrip Cluster Permutation (Diff 已是 timelock) =================
% 数据: Diff{md,isub,idev}, md=1..4, idev=1..2
% 每个单元已是 ft_timelockanalysis 的输出结构（含 avg/time/label 等）
% 依赖: 已 addpath FieldTrip 且运行 ft_defaults
% 需要: 正确的 layout 文件（如 'easycapM10.lay'）

% ------- 基本检查 -------
[nMd, nSub, nIdev] = size(Diff);
assert(nMd==4 && nIdev==2, '期望 Diff 为 4 x nSub x 2 的 cell（timelock 结构）。');
% 取一个样本做通道/时间一致性检查
ref = Diff{1,1,1};
assert(isfield(ref,'avg') && isfield(ref,'time') && isfield(ref,'label'), 'Diff 内容需为 timelock 结构。');

% 可选：粗略一致性核验（标签、时间长度）
for idev = 1:nIdev
  for md = 1:nMd
    for s = 1:nSub
      cur = Diff{md,s,idev};
      assert(numel(cur.time)==numel(ref.time), 'time 长度不一致');
      assert(numel(cur.label)==numel(ref.label), '通道数不一致');
      % 如需严格一致，可比较字符串集合是否一致
    end
  end
end

% ------- 邻接关系（基于布局）-------
layout = 'GSN-HydroCel-128.mat';   % ← 按你的实际文件名修改
cfg_neigh = [];
cfg_neigh.method = 'distance';
cfg_neigh.layout = layout;
neighbours = ft_prepare_neighbours(cfg_neigh);

% ------- 统计配置模板（被试内依赖样本；双侧；簇校正）-------
cfg_template = [];
cfg_template.channel           = 'all';
cfg_template.latency           = 'all';
cfg_template.parameter         = 'avg';      % timelock 的参数字段
cfg_template.method            = 'montecarlo';
cfg_template.statistic         = 'depsamplesT';
cfg_template.correctm          = 'cluster';
cfg_template.clusteralpha      = 0.01;
cfg_template.clusterstatistic  = 'maxsum';
cfg_template.mcorrect          = 'no';
cfg_template.tail              = 0;          % 双侧
cfg_template.clustertail       = 0;
cfg_template.alpha             = 0.005;      % 双侧控制
cfg_template.numrandomization  = 5000;
cfg_template.neighbours        = neighbours;
cfg_template.layout            = layout;
cfg_template.minnbchan         = 2;

% ------- 设计矩阵（依赖样本：同一被试的两条件）-------
design = zeros(2, 2*nSub);
design(1,1:nSub)       = 1:nSub;      % 被试
design(1,nSub+1:end)   = 1:nSub;      % 被试
design(2,1:nSub)       = 1;           % 条件1
design(2,nSub+1:end)   = 2;           % 条件2

% ------- idev = 1：md1 vs md2 -------
cfg12_i1 = cfg_template;
cfg12_i1.design = design; cfg12_i1.uvar = 1; cfg12_i1.ivar = 2;
inputs = cell(1, 2*nSub);
for s = 1:nSub
  inputs{s}       = Diff{1,s,1};  % 条件1：md1
  inputs{nSub+s}  = Diff{2,s,1};  % 条件2：md2
end
stat_idev1_pair12 = ft_timelockstatistics(cfg12_i1, inputs{:});

% ------- idev = 1：md3 vs md4 -------
cfg34_i1 = cfg_template;
cfg34_i1.design = design; cfg34_i1.uvar = 1; cfg34_i1.ivar = 2;
inputs = cell(1, 2*nSub);
for s = 1:nSub
  inputs{s}       = Diff{3,s,1};  % 条件1：md3
  inputs{nSub+s}  = Diff{4,s,1};  % 条件2：md4
end
stat_idev1_pair34 = ft_timelockstatistics(cfg34_i1, inputs{:});

disp('idev=1 完成：stat_idev1_pair12, stat_idev1_pair34');

% ------- idev = 2：md1 vs md2 -------
cfg12_i2 = cfg_template;
cfg12_i2.design = design; cfg12_i2.uvar = 1; cfg12_i2.ivar = 2;
inputs = cell(1, 2*nSub);
for s = 1:nSub
  inputs{s}       = Diff{1,s,2};  % 条件1：md1
  inputs{nSub+s}  = Diff{2,s,2};  % 条件2：md2
end
stat_idev2_pair12 = ft_timelockstatistics(cfg12_i2, inputs{:});

% ------- idev = 2：md3 vs md4 -------
cfg34_i2 = cfg_template;
cfg34_i2.design = design; cfg34_i2.uvar = 1; cfg34_i2.ivar = 2;
inputs = cell(1, 2*nSub);
for s = 1:nSub
  inputs{s}       = Diff{3,s,2};  % 条件1：md3
  inputs{nSub+s}  = Diff{4,s,2};  % 条件2：md4
end
stat_idev2_pair34 = ft_timelockstatistics(cfg34_i2, inputs{:});

disp('idev=2 完成：stat_idev2_pair12, stat_idev2_pair34');

%%%
alpha_cluster = 0.01;  % 你要的阈值

stats   = {stat_idev1_pair12, stat_idev1_pair34, stat_idev2_pair12, stat_idev2_pair34};
labels_ = {'idev=1, md1vsmd2', 'idev=1, md3vsmd4', 'idev=2, md1vsmd2', 'idev=2, md3vsmd4'};

for i = 1:numel(stats)
    st = stats{i};

 % --- 取正簇的簇级p ---
if isfield(st,'posclustersprob')
    pos_probs = st.posclustersprob(:);
elseif isfield(st,'posclusters') && ~isempty(st.posclusters)
    pos_probs = arrayfun(@(c) c.prob, st.posclusters(:));
else
    pos_probs = [];
end
pos_sig = ~isempty(pos_probs) && any(pos_probs < alpha_cluster);
if ~isempty(pos_probs)
    min_pos = min(pos_probs);
else
    min_pos = NaN;
end

% --- 取负簇的簇级p ---
if isfield(st,'negclustersprob')
    neg_probs = st.negclustersprob(:);
elseif isfield(st,'negclusters') && ~isempty(st.negclusters)
    neg_probs = arrayfun(@(c) c.prob, st.negclusters(:));
else
    neg_probs = [];
end
neg_sig = ~isempty(neg_probs) && any(neg_probs < alpha_cluster);
if ~isempty(neg_probs)
    min_neg = min(neg_probs);
else
    min_neg = NaN;
end


    % --- 点位最小p（不是簇级p，含义不同）---
    min_pointwise = min(st.prob(:));

    % --- 合并一个“簇级最小p”便于浏览 ---
    if isempty(pos_probs) && isempty(neg_probs)
        min_cluster_p = NaN;
    elseif isempty(pos_probs)
        min_cluster_p = min(neg_probs);
    elseif isempty(neg_probs)
        min_cluster_p = min(pos_probs);
    else
        min_cluster_p = min(min(pos_probs), min(neg_probs));
    end

    fprintf('%s: pos=%d, neg=%d, min_cluster_p=%.4g, min_pointwise_p=%.4g\n', ...
        labels_{i}, pos_sig, neg_sig, min_cluster_p, min_pointwise);
end

%%

cfgp = [];
cfgp.layout     = layout;
cfgp.alpha      = 0.01;
cfgp.parameter  = 'stat';
cfgp.subplotsize = [4 11];   % 指定子图布局为 4 行 11 列
cfgp.zlim       = 'maxabs';  % 色标对称化（可选，使得正负可比）
cfgp.colormap   = jet;       % 配色方案（可选）

fprintf('\n=== Cluster plot: idev=1, md3 vs md4 ===\n');
ft_clusterplot(cfgp, stat_idev1_pair34);

set(gcf, 'Position', [0 0 1500 600]);   % 控制整个 figure 尺寸

% 在 ft_clusterplot 运行后：
ax = findall(gcf,'Type','axes');
for i = 1:numel(ax)
    pos = get(ax(i),'Position');
    % 把子图拉宽、拉高
     pos(3) = pos(3) * 2.1;   % 宽度增大 15%
    pos(4) = pos(4) * 2.1;   % 高度增大 15%
    % 轻微左移/下移，减少间距
    pos(1) = pos(1) - 0.15;
    pos(2) = pos(2) - 0.15;
    set(ax(i),'Position',pos);
end
%
ax = findall(gcf,'Type','axes');
pos_all = cell2mat(get(ax,'Position'));   % N×4 矩阵，每行 [x y w h]

% 获取所有行的 y 值（bottom），按大小排序
yvals = unique(pos_all(:,2));
yvals = sort(yvals,'ascend');  % 从下到上

nRows = numel(yvals);
% 重新分配 y 值，使得间距缩短（例如总高度从 0.1 到 0.9）
new_yvals = linspace(0.1,0.68,nRows);   % 可调：0.1、0.9 控制上下边界

for i = 1:numel(ax)
    pos = pos_all(i,:);
    % 找出该子图属于哪一行（最近的 y）
    [~,row_idx] = min(abs(pos(2)-yvals));
    % 替换 y，不改高度
    pos(2) = new_yvals(row_idx);
    set(ax(i),'Position',pos);
end
%

% —— 在 ft_clusterplot(cfgp, stat_idev1_pair34); 之后加 —— 
ax = findall(gcf,'Type','axes');
%%
for i = 1:numel(ax)
    t = get(ax(i), 'Title');
    txt = string(get(t, 'String'));     % 原标题，如 "time:0.364 s"
    if strlength(txt)==0, continue; end

    % 抓取标题中的数字（支持1个或2个数字）
    nums = regexp(txt, '[-+]?\d*\.?\d+', 'match');
    if isempty(nums), continue; end

    if numel(nums) == 1
        ms1 = round(str2double(nums{1}) * 1000);       % 秒→毫秒
        newtxt = sprintf('%d ms', ms1);
    else
        ms1 = round(str2double(nums{1}) * 1000);
        ms2 = round(str2double(nums{2}) * 1000);
        newtxt = sprintf('%d–%d ms', ms1, ms2);
    end

    set(t, 'String', newtxt, 'Interpreter','none');    % 仅保留数值与 ms

    % 可选：把标题往下挪一点，让它更靠近子图
    set(t, 'Units','normalized');
    pos = get(t,'Position');
    pos(2) = pos(2) - 0.2;                             % 0.02–0.08 之间自行微调
    set(t,'Position',pos, 'VerticalAlignment','top');
end


