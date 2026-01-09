clc; clear;
% -------------------- 读取 EEG --------------------
EEG = pop_loadset('filename','SM201pre_deIC4.set','filepath','G:\\study2\\002\\IG\\pre\\');

% -------------------- 电极簇定义 --------------------
clusters.Ignore_MMN = {'E20','E23','E24','E28','E4','E11','E16','E19','E3','E117','E118','E124'};
clusters.Ignore_P3a = {'E20','E23','E24','E28','E4','E11','E16','E19','E3','E117','E118','E124'};
clusters.Attend_N2b = {'E29','E30','E36','E37','E5','E6','E12','E11','E87','E104','E105','E111'};
clusters.Attend_P3b = {'E47','E52','E59','E60','E61','E62','E72','E78','E85','E91','E92','E98'};

% -------------------- 每个成分的时间窗（毫秒） --------------------
win.Ignore_MMN = [190 240];
win.Ignore_P3a = [250 300];
win.Attend_N2b = [230 280];
win.Attend_P3b = [360 410];

% -------------------- 颜色映射 --------------------
colors = [ ...
    31 120 180;    % 蓝 - MMN
    51 160 44;     % 绿 - P3a
    255 127 0;     % 橙 - N2b
    227 26 28] / 255;  % 红 - P3b

% -------------------- 时间索引 --------------------
t_ms = EEG.times;  % ms 单位
fields = fieldnames(clusters);

figure('Color','w');
set(gcf,'Position',[100 100 600 250]);

% 子图布局
pos = { [0.08 0.2 0.20 0.6], ...
        [0.30 0.2 0.20 0.6], ...
        [0.52 0.2 0.20 0.6], ...
        [0.74 0.2 0.20 0.6] };

for i = 1:4
    comp = fields{i};
    ax = subplot('Position',pos{i});

    % ---- 取时间窗内平均振幅 ----
    tidx = t_ms >= win.(comp)(1) & t_ms <= win.(comp)(2);
    amp = mean(EEG.data(:,tidx,:),[2 3]);  % 平均时间和trial
    amp = squeeze(amp);                    % [nChan, 1]

    % ---- 绘制整体振幅分布 ----
    topoplot(amp, EEG.chanlocs, ...
        'maplimits','maxmin', ...
        'electrodes','off', ...
        'style','both', ...
        'emarker',{'.','k',6,1});
    hold on;

    % ---- 高亮 cluster 电极 ----
    clusterLabels = clusters.(comp);
    clusterIdx = find(ismember({EEG.chanlocs.labels}, clusterLabels));
    scatter([EEG.chanlocs(clusterIdx).X], ...
            [EEG.chanlocs(clusterIdx).Y], ...
            80, colors(i,:), 'filled', 'MarkerEdgeColor','k', 'LineWidth',0.5);

    axis square;
    set(gca,'XLim',[-0.6 0.6],'YLim',[-0.6 0.6]);

    % ---- 标题 ----
    tlabel = strrep(comp,'_',' ');
    text(0.5, 1.12, tlabel, ...
        'Units','normalized', ...
        'HorizontalAlignment','center', ...
        'FontSize',9,'FontWeight','bold');
end

% -------------------- 统一色标 --------------------
colormap jet;
c = colorbar('Position',[0.92 0.25 0.02 0.5]);
ylabel(c,'Amplitude (\muV)','FontSize',9,'FontWeight','bold');

sgtitle('Electrode Clusters with Amplitude (Ignore / Attend)', ...
    'FontSize',11,'FontWeight','bold');

% -------------------- 保存图像 --------------------
cd('G:\study2\results');
print(gcf,'-dpng','-r600','Electrode_Clusters_Amplitude.png');

fprintf('? 已输出: Electrode_Clusters_Amplitude.png（包含真实振幅，600 dpi）\n');
