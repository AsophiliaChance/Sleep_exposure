%% ====================================================== 
%  IGNORE (Ignore) condition — Mixed ANOVA + BF10 (BIC) + Waveform Plots
%  - 绘图部分：同一张图上标 amplitude (虚线框) & latency (实线框)，无填充
%  - 两个 deviants (Small / Large change) 各一张图，包含 Frontal (MMN & P3a)
%  - legend: Experimental → Sleep
% ======================================================

clc; clear;
cd('G:\study2\results');      % <<< 路径请自行修改

% -------------------- 数据文件 ----------------
files = { ...
    'S001control_IG_pre_nsubavg.mat', ... % md1 Control-Pre
    'S002_IG_pre_nsubavg.mat', ...        % md2 Sleep-Pre
    'S001control_IG_post_nsubavg.mat', ...% md3 Control-Post
    'S002_IG_post_nsubavg.mat'};          % md4 Sleep-Post

% -------------------- 时间窗（毫秒） ----------------
MMN_amp_win  = [190 240];   % amplitude (frontal, MMN)
P3a_amp_win  = [250 300];   % amplitude (frontal, P3a)
MMN_lat_win  = [150 260];   % latency (frontal, MMN)
P3a_lat_win  = [250 350];   % latency (frontal, P3a)

% -------------------- 电极簇 -----------------
FR_all = unique([20 23 24 28   4 11 16 19   3 117 118 124]); % frontal

% -------------------- 载入数据 ----------------
S = cell(1,4);
for md = 1:4
    S{md} = load(files{md});   % 需包含 Diff_avg（cell: nSub × nDeviants）
end
ndev = size(S{1}.Diff_avg, 2);

% -------------------- 主循环：每个 Deviant ----------------
for idev = 1:ndev
    % ============= 波形收集容器 ============= 
    W_all{idev}.CP  = []; % Control-Pre
    W_all{idev}.CPo = []; % Control-Post
    W_all{idev}.EP  = []; % Sleep-Pre
    W_all{idev}.EPo = []; % Sleep-Post

    % ============= Control Pre/Post ============= 
    for s=1:size(S{1}.Diff_avg,1)
        tl = S{1}.Diff_avg{s,idev};
        if s==1, t_ms = tl.time*1000; end
        fidx = label2idx(tl.label,FR_all);
        W_all{idev}.CP(end+1,:)  = mean(tl.avg(fidx,:),1);
    end
    for s=1:size(S{3}.Diff_avg,1)
        tl = S{3}.Diff_avg{s,idev};
        fidx = label2idx(tl.label,FR_all);
        W_all{idev}.CPo(end+1,:) = mean(tl.avg(fidx,:),1);
    end

    % ============= Sleep Pre/Post ============= 
    for s=1:size(S{2}.Diff_avg,1)
        tl = S{2}.Diff_avg{s,idev};
        fidx = label2idx(tl.label,FR_all);
        W_all{idev}.EP(end+1,:)  = mean(tl.avg(fidx,:),1);
    end
    for s=1:size(S{4}.Diff_avg,1)
        tl = S{4}.Diff_avg{s,idev};
        fidx = label2idx(tl.label,FR_all);
        W_all{idev}.EPo(end+1,:) = mean(tl.avg(fidx,:),1);
    end
end

%% -------------------- 绘图 ----------------
for idev=1:ndev 
    devNames = {'Small change','Large change'};
    colors = lines(4);

    fh = figure('Color','w','Position',[100 100 450 250]);
    sgtitle(devNames{idev},'fontweight', 'bold');   % 新版替代 suptitle

    % ---- FRONTAL (MMN) ----
    subplot(1,2,1); hold on;
    plot(t_ms, nanmean(W_all{idev}.CP,1),  'Color', colors(1,:), 'LineWidth', 1.5);
    plot(t_ms, nanmean(W_all{idev}.CPo,1), 'Color', colors(2,:), 'LineWidth', 1.5);
    plot(t_ms, nanmean(W_all{idev}.EP,1),  'Color', colors(3,:), 'LineWidth', 1.5);
    plot(t_ms, nanmean(W_all{idev}.EPo,1), 'Color', colors(4,:), 'LineWidth', 1.5);
    ylim([-2 2]); yl = ylim;
    % Amplitude (虚线框)
    rectangle('Position',[MMN_amp_win(1) yl(1) diff(MMN_amp_win) yl(2)-yl(1)], ...
        'EdgeColor','k','LineStyle','--','LineWidth',1.2);
    % Latency (实线框)
    rectangle('Position',[MMN_lat_win(1) yl(1) diff(MMN_lat_win) yl(2)-yl(1)], ...
        'EdgeColor','k','LineStyle','-','LineWidth',1.2);
    xlabel('Time (ms)'); ylabel('Amplitude (\muV)');
    title('MMN','fontweight', 'bold');
    if idev==1
        lgd = legend({'Control-Pre','Control-Post','Sleep-Pre','Sleep-Post'}, ...
                     'Box','off','Location','northeast');
        lgd.ItemTokenSize = [5,5];
        lgd.Position(1) = lgd.Position(1) + 0.05;   % 往右挪
        lgd.Position(2) = lgd.Position(2) - 0.05;   % 往下挪
    end
    axis square;
    xlim([-100 600]);
    set(gca, 'FontSize', 9, 'fontweight', 'bold');

    % ---- FRONTAL (P3a) ----
    subplot(1,2,2); hold on;
    plot(t_ms, nanmean(W_all{idev}.CP,1),  'Color', colors(1,:), 'LineWidth', 1.5);
    plot(t_ms, nanmean(W_all{idev}.CPo,1), 'Color', colors(2,:), 'LineWidth', 1.5);
    plot(t_ms, nanmean(W_all{idev}.EP,1),  'Color', colors(3,:), 'LineWidth', 1.5);
    plot(t_ms, nanmean(W_all{idev}.EPo,1), 'Color', colors(4,:), 'LineWidth', 1.5);
    ylim([-2 2]); yl = ylim;
    % Amplitude (虚线框)
    rectangle('Position',[P3a_amp_win(1) yl(1) diff(P3a_amp_win) yl(2)-yl(1)], ...
        'EdgeColor','k','LineStyle','--','LineWidth',1.5);
    % Latency (实线框)
    rectangle('Position',[P3a_lat_win(1) yl(1) diff(P3a_lat_win) yl(2)-yl(1)], ...
        'EdgeColor','k','LineStyle','-','LineWidth',0.5);
    xlabel('Time (ms)'); ylabel('Amplitude (\muV)');
    title('P3a','fontweight', 'bold');
    axis square;
    xlim([-100 600]);
    set(gca, 'FontSize', 9, 'fontweight', 'bold');

    % 保存
    saveas(fh, sprintf('Ignore_Deviant%d.png',idev));
end

fprintf('绘图完成: 每个 deviant 已输出 PNG 图。\n');

%% =================== 辅助函数 ===================
function idx = label2idx(labels,numList)
    idx = zeros(1,numel(numList));
    for ii=1:numel(numList)
        num = numList(ii);
        k = find(strcmp(labels, sprintf('E%d', num)), 1);
        if isempty(k), k = find(strcmp(labels, sprintf('%d', num)), 1); end
        if isempty(k), k = num; end
        idx(ii) = k;
    end
end
