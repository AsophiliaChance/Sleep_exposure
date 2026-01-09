clc; clear
cd('G:\study2\results');

% ======================================================
% 文件说明：
% md1 = 控制组 前测
% md2 = 实验组 前测
% md3 = 控制组 后测
% md4 = 实验组 后测
% ======================================================
filename = { ...
    'S001control_IG_pre_nsubavg.mat', ... % md1
    'S002_IG_pre_nsubavg.mat', ...        % md2
    'S001control_IG_post_nsubavg.mat', ...% md3
    'S002_IG_post_nsubavg.mat'};          % md4

% -------- 导入数据 --------
for md = 1:4
    load(filename{md});   % 载入 Diff_avg, STD_avg, DEV_avg
    nsub = size(Diff_avg,1);
    ndev = size(Diff_avg,2);

    for isub = 1:nsub
        for idev = 1:ndev
            Diff{md,isub,idev} = Diff_avg{isub,idev};
        end
    end
    fprintf('已导入 %s: %d subjects, %d conditions\n', filename{md}, nsub, ndev);
end

eeglab;

% ======================================================
% ============ 差异中的差异 (DiD) 数据构造 ============
% ======================================================
for idev = 1:ndev
    nCon_pre  = sum(~cellfun(@isempty,Diff(1,:,idev)));
    nExp_pre  = sum(~cellfun(@isempty,Diff(2,:,idev)));
    nCon_post = sum(~cellfun(@isempty,Diff(3,:,idev)));
    nExp_post = sum(~cellfun(@isempty,Diff(4,:,idev)));
    nSub = min([nCon_pre, nCon_post, nExp_pre, nExp_post]);

    for s = 1:nSub
        % 取出 timelock 结构
        Con_pre  = Diff{1,s,idev};
        Exp_pre  = Diff{2,s,idev};
        Con_post = Diff{3,s,idev};
        Exp_post = Diff{4,s,idev};

        % 构造差异中的差异
        DiD{s,idev} = Exp_post;  
        DiD{s,idev}.avg = (Exp_post.avg - Exp_pre.avg) - (Con_post.avg - Con_pre.avg);

        % 构造一个零条件（完全 0，用于单样本 vs 0）
        Zero{s,idev} = Exp_post; 
        Zero{s,idev}.avg = zeros(size(Exp_post.avg));
    end
end

% ======================================================
% ============ FieldTrip Cluster Permutation ===========
% ======================================================
layout = 'GSN-HydroCel-128.mat';   % ← 按你的实际文件名修改
cfg_neigh = [];
cfg_neigh.method = 'distance';
cfg_neigh.layout = layout;
neighbours = ft_prepare_neighbours(cfg_neigh);

cfg = [];
cfg.channel           = 'all';
cfg.latency           = 'all';
cfg.parameter         = 'avg';
cfg.method            = 'montecarlo';
cfg.statistic         = 'depsamplesT';  % 配对 t 检验 (DiD vs Zero)
cfg.correctm          = 'cluster';
cfg.clusteralpha      = 0.05;
cfg.clusterstatistic  = 'maxsum';
cfg.tail              = 0;
cfg.clustertail       = 0;
cfg.alpha             = 0.025;
cfg.numrandomization  = 5000;
cfg.neighbours        = neighbours;
cfg.layout            = layout;
cfg.minnbchan         = 2;

stats = {};
%%
for idev = 2:ndev
    nSub = numel(DiD(:,idev));

    % 设计矩阵：配对 t (条件1=DiD, 条件2=Zero)
    design = zeros(2,2*nSub);
    design(1,:) = repmat(1:nSub,1,2);        % 被试
    design(2,1:nSub) = 1;                    % 条件1
    design(2,nSub+1:end) = 2;                % 条件2
    cfg.design = design;
    cfg.uvar   = 1;  % 被试因子
    cfg.ivar   = 2;  % 条件因子

    % 收集输入 (DiD 和 Zero)
    inputs = cell(1,2*nSub);
    for s = 1:nSub
        inputs{s}       = DiD{s,idev};
        inputs{nSub+s}  = Zero{s,idev};
    end

    % 运行统计
    stat = ft_timelockstatistics(cfg, inputs{:});
    stats{idev} = stat;

    fprintf('\n=== DiD 单样本检验 (用 depsamplesT): idev=%d ===\n', idev);
    if isfield(stat,'posclusters') || isfield(stat,'negclusters')
        ft_clusterplot(struct('alpha',0.01,'layout',layout,'parameter','stat'), stat);
    end
end

