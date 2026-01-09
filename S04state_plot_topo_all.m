%% ======================================================
%   IGNORE + ATTEND Topomap 合并（4×8）
%   - 第一行前 4 列顶部居中：Small change
%   - 第一行后 4 列顶部居中：Large change
%   - 每一行最左侧：纵向 MMN / P3a / N2b / P3b
%   - 每个小图标题（只第一行）：Control-Pre / Control-Post / Sleep-Pre / Sleep-Post
% ======================================================

clc; clear;
addpath('G:\matlab_toolboxes\fieldtrip');
eeglab;
cd('G:\study2\results');

%% ------------------- 文件 -------------------
files_ignore = { ...
    'S001control_IG_pre_nsubavg.mat', ...
    'S002_IG_pre_nsubavg.mat', ...
    'S001control_IG_post_nsubavg.mat', ...
    'S002_IG_post_nsubavg.mat'};

files_attend = { ...
    'S001control_ATT_pre_ATTnsubavg.mat', ...
    'S002_ATT_pre_ATTnsubavg.mat', ...
    'S001control_ATT_post_ATTnsubavg.mat', ...
    'S002_ATT_post_ATTnsubavg.mat'};

conds = {'Control-Pre','Control-Post','Sleep-Pre','Sleep-Post'};
order = [1 3 2 4];    % CP, CPo, EP, EPo

%% ------------------- 时间窗 -------------------
MMN_xlim = [0.182 0.242];
P3a_xlim = [0.257 0.327];
N2b_xlim = [0.210 0.270];
P3b_xlim = [0.369 0.439];

%% ------------------- cluster -------------------
FR_cluster_Ignore = {'E20','E23','E24','E28','E4','E11','E16','E19','E3','E117','E118','E124'};
FR_cluster_N2b    = {'E29','E30','E36','E37','E5','E6','E12','E11','E87','E104','E105','E111'};
FR_cluster_P3b    = {'E47','E52','E59','E60','E61','E62','E72','E78','E85','E91','E92','E98'};

ZLIM_ignore = [-4 4];
ZLIM_attend = [-4 4];

%% ------------------- 载入并 GA -------------------
S_IG = cell(1,4);
S_AT = cell(1,4);
for k = 1:4
    S_IG{k} = load(files_ignore{k});
    S_AT{k} = load(files_attend{k});
end
ndev = size(S_IG{1}.Diff_avg, 2);

DiffGA_IG = cell(4, ndev);
DiffGA_AT = cell(4, ndev);

for idev = 1:ndev
    for md = 1:4
        % IGNORE
        nSub_ig = size(S_IG{md}.Diff_avg, 1);
        tmp_ig  = cell(1, nSub_ig);
        for s = 1:nSub_ig
            tmp_ig{s} = S_IG{md}.Diff_avg{s, idev};
        end
        DiffGA_IG{md, idev} = ft_timelockgrandaverage([], tmp_ig{:});

        % ATTEND
        nSub_at = size(S_AT{md}.Diff_avg, 1);
        tmp_at  = cell(1, nSub_at);
        for s = 1:nSub_at
            tmp_at{s} = S_AT{md}.Diff_avg{s, idev};
        end
        DiffGA_AT{md, idev} = ft_timelockgrandaverage([], tmp_at{:});
    end
end

layout = 'GSN-HydroCel-128.mat';

%% ------------------- 建图 -------------------
fh = figure('Color','w','Position',[50 50 1800 800]);

%% 控制 subplot spacing（沿用你之前的列布局）
baseW = 1/8;
halfW = baseW * 0.5;

colX = zeros(1,8);
for c = 1:8
    if c == 4
        colX(c) = (c-1)*baseW;
    elseif c == 5
        colX(c) = (c-1)*baseW - 0.7*halfW;
    elseif c < 4
        colX(c) = baseW + (4-c)*halfW*1.1 - 0.4*halfW;
    elseif c > 5
        colX(c) = (4*baseW) + (c-5)*halfW*1.1 - 0.7*halfW;
    end
end
colX = sort(colX)+0.1; 
h   = 0.20;      % 每行高度
gap = 0.12;      % 相邻行底部之间的间隔

rowY = zeros(1,4);
rowY(1) = 0.78 - 0.1;
for r = 2:4
    rowY(r) = rowY(r-1) -gap;   % 防止重叠：上一行底 - 高度 - 间隔
end

rowLabel = {'MMN','P3a','N2b','P3b'};

%% ======================================================
%                     主循环
%% ======================================================
for row = 1:4

    % ==== 每一行最左侧：纵向 MMN/P3a/N2b/P3b ====
    % 借用第一列第一个 axes 的高度位置，在 figure 左边写竖排
    text(0.16, rowY(row) + 0.7*h-(row-1)*h*0.15, rowLabel{row}, ...
        'Units','normalized', ...
        'FontSize', 15, 'FontWeight', 'bold', ...
        'Rotation', 90, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle');
end
for row = 1:4

    % ==== 每一行最左侧：纵向 MMN/P3a/N2b/P3b ====
    % 借用第一列第一个 axes 的高度位置，在 figure 左边写竖排
%     text(0.01, rowY(row) + h, rowLabel{row}, ...
%         'Units','normalized', ...
%         'FontSize', 12, 'FontWeight', 'bold', ...
%         'Rotation', 90, ...
%         'HorizontalAlignment', 'center', ...
%         'VerticalAlignment', 'middle');

    % ==== 只在第一行加 Small / Large change ====
    if row == 1
        centerSmall = mean(colX(1:4)-0.5* halfW);
        centerLarge = mean(colX(5:8) +0.5* halfW);
        yTitle = rowY(row) + h + 0.08;  % 略微高于第一行子图

        text(centerSmall, yTitle, 'Small change', ...
            'Units', 'normalized', ...
            'FontSize', 18, 'FontWeight', 'bold', ...
            'HorizontalAlignment', 'center');

        text(centerLarge, yTitle, 'Large change', ...
            'Units', 'normalized', ...
            'FontSize', 18, 'FontWeight', 'bold', ...
            'HorizontalAlignment', 'center');
    end

    % ==== 画这一行的 8 个 topo ====
    for idev = 1:ndev       % 1:Small, 2:Large
        for idx = 1:4       % CP / CPo / EP / EPo

            md = order(idx);              % CP→CPo→EP→EPo
            subplot_col = (idev-1)*4 + idx;

            left = colX(subplot_col);
            ax = axes('Position',[left rowY(row) halfW h]);

            % 选择时间窗 / cluster / 数据
            switch row
                case 1
                    data   = DiffGA_IG{md, idev};
                    twin   = MMN_xlim;
                    zlim_  = ZLIM_ignore;
                    clust  = FR_cluster_Ignore;
                case 2
                    data   = DiffGA_IG{md, idev};
                    twin   = P3a_xlim;
                    zlim_  = ZLIM_ignore;
                    clust  = FR_cluster_Ignore;
                case 3
                    data   = DiffGA_AT{md, idev};
                    twin   = N2b_xlim;
                    zlim_  = ZLIM_attend;
                    clust  = FR_cluster_N2b;
                case 4
                    data   = DiffGA_AT{md, idev};
                    twin   = P3b_xlim;
                    zlim_  = ZLIM_attend;
                    clust  = FR_cluster_P3b;
            end

            cfg = [];
            cfg.layout       = layout;
            cfg.comment      = 'no';
            cfg.electrodes   = 'off';
            cfg.xlim         = twin;
            cfg.avgovertime  = 'yes';
            cfg.zlim         = zlim_;
            cfg.colorbar     = 'no';
            cfg.figure       = gcf;
            cfg.axes         = ax;
            cfg.highlight        = 'on';
            cfg.highlightchannel = clust;
            cfg.highlightsymbol  = '.';
            cfg.highlightsize    = 6;
            cfg.highlightcolor   = [0 0 0];

            ft_topoplotER(cfg, data);

            % 小图标题：只在第一行加 Control-Pre 等
            if row == 1
                title(conds{idx}, 'FontSize', 13, 'FontWeight', 'bold');
            end

            axis(ax,'square');
        end
    end
end
set(findall(gcf,'-property','FontName'),'FontName','Times New Roman');
set(findall(gcf,'-property','FontWeight'),'FontWeight','bold');
%% colorbar（右侧）
cb = colorbar('Position',[0.83 0.37 0.01 0.45]);
cb.FontSize = 15;           % 控制刻度数字大小
cb.FontWeight = 'bold';     % 刻度加粗（可选）
ylabel(cb,'Amplitude (\muV)','FontWeight','bold','FontSize',15);

% set(findall(gcf,'-property','FontName'),'FontName','Times New Roman');
% set(findall(gcf,'-property','FontWeight'),'FontWeight','bold');
%% 保存
print(fh,'Topo_Ignore_Attend_4x8_Final','-dtiff','-r600');

fprintf('\n? 已完成 4×8 合并图（Small/Large 标题 + 纵向 MMN/P3a/N2b/P3b + 语法修正）\n');
