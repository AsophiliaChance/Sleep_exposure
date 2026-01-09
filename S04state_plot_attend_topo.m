%% ======================================================   
%  ATTENTIVE (Attend) — Amplitude Topomap (only cluster electrodes shown)
%  - 真实 amplitude topo：在时间窗内平均 (avgovertime)
%  - 不显示所有电极，只高亮表中电极为黑点
%  - EGI128 帽子：layout 从 data.elec 自动生成
%  - 每个组件一张图：1×4 子图（四个条件）
% ======================================================

clc; clear;
eeglab
cd('G:\study2\results');                   % <<< 数据路径

% -------------------- 数据文件 ----------------
files = { ...
    'S001control_ATT_pre_ATTnsubavg.mat', ...
    'S002_ATT_pre_ATTnsubavg.mat', ...
    'S001control_ATT_post_ATTnsubavg.mat', ...
    'S002_ATT_post_ATTnsubavg.mat'};
conds = {'Control-Pre','Sleep-Pre','Control-Post','Sleep-Post'};

% -------------------- cluster 电极（表格中的通道标签） ----------------
clusters.Attend_N2b = {'E29','E30','E36','E37','E5','E6','E12','E11','E87','E104','E105','E111'};
clusters.Attend_P3b = {'E47','E52','E59','E60','E61','E62','E72','E78','E85','E91','E92','E98'};

% -------------------- 时间窗（秒） ----------------
N2b_xlim = [0.230 0.280];
P3b_xlim = [0.360 0.410];

% 统一颜色范围（如需自动范围，置为 [] 或 'maxabs'）
ZLIM_N2b = [-4  4];
ZLIM_P3b = [-4  4];

% -------------------- 载入数据 ----------------
S = cell(1,4);
for md = 1:4
    S{md} = load(files{md});   % 含 Diff_avg（cell: nSub × nDeviants），元素为 FieldTrip timelock
end
ndev = size(S{1}.Diff_avg, 2);
devNames = {'Small change - Attend','Large change - Attend'};

% -------------------- GA（对每条件、每deviant汇总到一个 timelock） ----------------
Diff_gavg = cell(4, ndev);
for idev = 1:ndev
    for md = 1:4
        nSub = size(S{md}.Diff_avg, 1);
        allSub = cell(1, nSub);
        for s = 1:nSub
            allSub{s} = S{md}.Diff_avg{s, idev};  % FieldTrip timelock
        end
        cfgGA = [];
        cfgGA.keepindividual = 'no';
        Diff_gavg{md, idev} = ft_timelockgrandaverage(cfgGA, allSub{:});
    end
end

% -------------------- 从数据自动生成 EGI128 layout ----------------
example_tl = Diff_gavg{1,1};
cfg_layout = [];
cfg_layout.elec = example_tl.elec;
cfg_layout.projection = 'polar';
cfg_layout.rotate = 0;          % 若朝向不对，可改 90/180/270
%layout = ft_prepare_layout(cfg_layout);
layout = 'GSN-HydroCel-128.mat'; 

% ==================== 绘图 ====================
for idev = 1:ndev
    %% ---------- N2b：1×4 ----------
    fh1 = figure('Color','w','Position',[100 100 500 250]);
    sgtitle(sprintf('%s — N2b (%.0f–%.0f ms)', devNames{idev}, N2b_xlim(1)*1000, N2b_xlim(2)*1000), ...
        'FontWeight','bold','FontSize',12);

    for md = 1:4
        % 先用 subplot 拿位置，再微调（保留你的写法风格）
        ax = subplot(1,4,md);
        pos = get(ax, 'Position');
        newPos = [pos(1) pos(2) pos(3)+0.01 pos(4)+0.01];
        axDraw = subplot('Position', newPos);

        cfg = [];
        cfg.layout       = layout;
        cfg.comment      = 'no';
        cfg.electrodes   = 'off';        % 关键1：不显示所有电极
        cfg.xlim         = N2b_xlim;     % 秒
        cfg.avgovertime  = 'yes';        % 时间窗内平均
        cfg.zlim         = ZLIM_N2b;     % 统一颜色范围；自动可用 'maxabs' 或 []
        cfg.colorbar     = 'no';
        cfg.figure       = 'gcf';
        cfg.axes         = axDraw;

        % 关键2：只高亮表格中的电极为黑点
        cfg.highlight        = 'on';
        cfg.highlightchannel = clusters.Attend_N2b;  % 你的表格
        cfg.highlightsymbol  = '.';
        cfg.highlightsize    = 5;                   % 点大小
        cfg.highlightcolor   = [0 0 0];              % 黑色

        ft_topoplotER(cfg, Diff_gavg{md, idev});
        title(sprintf('%s', conds{md}), 'FontWeight','bold','FontSize',11);
        axis(axDraw, 'square');
    end
colormap(fh1, 'jet');
cb1 = colorbar('Position', [0.93 0.30 0.01 0.50]);
cb1.FontSize = 8;                      % ← 设置colorbar刻度字体大小
ylabel(cb1, 'Amplitude (\muV)', ...
       'FontWeight','bold', ...
       'FontSize',8);                  % ← 设置标签字体大小

    saveas(fh1, sprintf('Attend_N2b_Topo_onlyCluster_Deviant%d.png', idev));

    %% ---------- P3b：1×4 ----------
    fh2 = figure('Color','w','Position',[100 450 500 200]);
    sgtitle(sprintf('%s — P3b (%.0f–%.0f ms)', devNames{idev}, P3b_xlim(1)*1000, P3b_xlim(2)*1000), ...
        'FontWeight','bold','FontSize',12);

    for md = 1:4
        ax = subplot(1,4,md);
        pos = get(ax, 'Position');
        newPos = [pos(1) pos(2) pos(3)+0.01 pos(4)+0.01];
        axDraw = subplot('Position', newPos);

        cfg = [];
        cfg.layout       = layout;
        cfg.comment      = 'no';
        cfg.electrodes   = 'off';        % 不显示所有电极
        cfg.xlim         = P3b_xlim;
        cfg.avgovertime  = 'yes';
        cfg.zlim         = ZLIM_P3b;
        cfg.colorbar     = 'no';
        cfg.figure       = 'gcf';
        cfg.axes         = axDraw;

        cfg.highlight        = 'on';
        cfg.highlightchannel = clusters.Attend_P3b;
        cfg.highlightsymbol  = '.';
        cfg.highlightsize    = 5;
        cfg.highlightcolor   = [0 0 0];

        ft_topoplotER(cfg, Diff_gavg{md, idev});
        title(sprintf('%s', conds{md}), 'FontWeight','bold','FontSize',11);
        axis(axDraw, 'square');
    end
    colormap(fh2, 'jet');
    cb2 = colorbar('Position', [0.93 0.3 0.01 0.50]);
    ylabel(cb2, 'Amplitude (\muV)', 'FontWeight','bold');
    saveas(fh2, sprintf('Attend_P3b_Topo_onlyCluster_Deviant%d.png', idev));
end

fprintf('? 已输出：真实 amplitude topo（仅黑点显示表格电极，其他电极不显示）。\n');
