%% ======================================================   
%  IGNORE (Ignore) condition — Topomap (Amplitude windows)
%  - 去掉 waveform 曲线，改为真实 amplitude topo
%  - 仅标出表格中对应 electrode（黑点），不显示其他电极
%  - 每个 deviant 输出两张图：MMN(190–240 ms)、P3a(250–300 ms)
% ======================================================

clc; clear;
addpath('G:\matlab_toolboxes\fieldtrip');  % <<< FieldTrip 路径
eeglab
cd('G:\study2\results');                   % <<< 数据路径

% -------------------- 数据文件 ----------------
files = { ...
    'S001control_IG_pre_nsubavg.mat', ...
    'S002_IG_pre_nsubavg.mat', ...
    'S001control_IG_post_nsubavg.mat', ...
    'S002_IG_post_nsubavg.mat'};
conds = {'Control-Pre','Sleep-Pre','Control-Post','Sleep-Post'};

% -------------------- 时间窗（秒） ----------------
MMN_xlim = [0.190 0.240];    % frontal MMN
P3a_xlim = [0.400 0.450];    % frontal P3a
ZLIM = [-4 4];               % 统一色标范围，可改为 'maxabs'

% -------------------- cluster 电极（黑点显示） ----------------
FR_cluster = {'E20','E23','E24','E28','E4','E11','E16','E19','E3','E117','E118','E124'};

% -------------------- 载入数据 ----------------
S = cell(1,4);
for md = 1:4
    S{md} = load(files{md});   % 含 Diff_avg（cell: nSub × nDeviants）
end
ndev = size(S{1}.Diff_avg, 2);
devNames = {'Small change - Ignore','Large change - Ignore'};

% -------------------- 生成 Grand Average ----------------
Diff_gavg = cell(4, ndev);
for idev = 1:ndev
    for md = 1:4
        nSub = size(S{md}.Diff_avg,1);
        allSub = cell(1,nSub);
        for s = 1:nSub
            allSub{s} = S{md}.Diff_avg{s,idev};
        end
        cfgGA = [];
        cfgGA.keepindividual = 'no';
        Diff_gavg{md,idev} = ft_timelockgrandaverage(cfgGA, allSub{:});
    end
end

% -------------------- 自动生成 EGI128 layout ----------------
example_tl = Diff_gavg{1,1};
cfg_layout = [];
cfg_layout.elec = example_tl.elec;
cfg_layout.projection = 'polar';
cfg_layout.rotate = 0;        % 若朝向不对，可改 90/180/270
%layout = ft_prepare_layout(cfg_layout);
layout = 'GSN-HydroCel-128.mat'; 
%% ======================================================
% 绘图：每个 deviant 输出两张图 (MMN + P3a)
% ======================================================
for idev = 1:ndev
    %% -------------------- MMN --------------------
    fh1 = figure('Color','w','Position',[100 100 500 200]);
    sgtitle(sprintf('%s — MMN (%.0f–%.0f ms)', devNames{idev}, MMN_xlim(1)*1000, MMN_xlim(2)*1000), ...
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
        cfg.xlim         = MMN_xlim;     % 秒
        cfg.avgovertime  = 'yes';        % 时间窗内平均
        cfg.zlim         = ZLIM;
        cfg.colorbar     = 'no';
        cfg.figure       = 'gcf';
        cfg.axes         = axDraw;

        % 只高亮 cluster 电极
        cfg.highlight        = 'on';
        cfg.highlightchannel = FR_cluster;
        cfg.highlightsymbol  = '.';
        cfg.highlightsize    = 5;
        cfg.highlightcolor   = [0 0 0];

        ft_topoplotER(cfg, Diff_gavg{md, idev});
        title(sprintf('%s', conds{md}), 'FontWeight','bold','FontSize',11);
        axis(axDraw,'square');
    end
    colormap(fh1, 'jet');
    cb1 = colorbar('Position',[0.93 0.30 0.01 0.50]);
    ylabel(cb1, 'Amplitude (\muV)', 'FontWeight','bold');
    saveas(fh1, sprintf('Ignore_MMN_Topo_OnlyCluster_Deviant%d.png', idev));

    %% -------------------- P3a --------------------
    fh2 = figure('Color','w','Position',[100 450 500 200]);
    sgtitle(sprintf('%s — P3a (%.0f–%.0f ms)', devNames{idev}, P3a_xlim(1)*1000, P3a_xlim(2)*1000), ...
        'FontWeight','bold','FontSize',12);

    for md = 1:4
        ax = subplot(1,4,md);
        pos = get(ax, 'Position');
        newPos = [pos(1) pos(2) pos(3)+0.01 pos(4)+0.01];
        axDraw = subplot('Position', newPos);

        cfg = [];
        cfg.layout       = layout;
        cfg.comment      = 'no';
        cfg.electrodes   = 'off';
        cfg.xlim         = P3a_xlim;
        cfg.avgovertime  = 'yes';
        cfg.zlim         = ZLIM;
        cfg.colorbar     = 'no';
        cfg.figure       = 'gcf';
        cfg.axes         = axDraw;

        cfg.highlight        = 'on';
        cfg.highlightchannel = FR_cluster;
        cfg.highlightsymbol  = '.';
        cfg.highlightsize    = 5;
        cfg.highlightcolor   = [0 0 0];

        ft_topoplotER(cfg, Diff_gavg{md, idev});
        title(sprintf('%s', conds{md}), 'FontWeight','bold','FontSize',11);
        axis(axDraw,'square');
    end
    colormap(fh2, 'jet');
    cb2 = colorbar('Position',[0.93 0.3 0.01 0.5]);
    ylabel(cb2, 'Amplitude (\muV)', 'FontWeight','bold');
    saveas(fh2, sprintf('Ignore_P3a_Topo_OnlyCluster_Deviant%d.png', idev));
end

fprintf('? 已生成 Ignore 条件的 MMN/P3a topomap（仅 cluster 电极为黑点显示）。\n');
