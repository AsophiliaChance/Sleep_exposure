%% ====================================================== 
%  ATTENTIVE (Attend) condition — Mixed ANOVA + BF10 (BIC) + Waveform Plots
%  - 绘图部分：同一张图上标 amplitude (虚线框) & latency (实线框)，无填充
%  - 两个 deviants (Small / Large change) 各一张图，包含 Central (N2b) & Parietal (P3b)
%  - legend: Experimental → Sleep
% ======================================================

clc; clear;
cd('G:\study2\results');      % <<< 路径请自行修改

% -------------------- 数据文件 ----------------
files = { ...
    'S001control_ATT_pre_ATTnsubavg.mat', ... % md1 Control-Pre
    'S002_ATT_pre_ATTnsubavg.mat', ...        % md2 Sleep-Pre
    'S001control_ATT_post_ATTnsubavg.mat', ...% md3 Control-Post
    'S002_ATT_post_ATTnsubavg.mat'};          % md4 Sleep-Post

% -------------------- 时间窗（毫秒） ----------------
N2b_amp_win  = [230 280];   % amplitude (central)
P3b_amp_win  = [360 410];   % amplitude (parietal)
N2b_lat_win  = [200 310];   % latency (central)
P3b_lat_win  = [340 460];   % latency (parietal)

% -------------------- 电极簇 -----------------
CN_all = unique([29 30 36 37   5 6 12 11   87 104 105 111]); % central
PR_all = unique([47 52 59 60   61 62 72 78  85 91 92 98]);   % parietal

% -------------------- 载入数据 ----------------
S = cell(1,4);
for md = 1:4
    S{md} = load(files{md});   % 需包含 Diff_avg（cell: nSub × nDeviants）
end
ndev = size(S{1}.Diff_avg, 2);

% -------------------- 主循环：每个 Deviant ----------------
for idev = 1:ndev
    % ============= 波形收集容器 =============
    Wc_all{idev}.CP  = []; % Control-Pre
    Wc_all{idev}.CPo = []; % Control-Post
    Wc_all{idev}.EP  = []; % Sleep-Pre
    Wc_all{idev}.EPo = []; % Sleep-Post
    Wp_all{idev} = Wc_all{idev};

    % ============= Control Pre/Post =============
    for s=1:size(S{1}.Diff_avg,1)
        tl = S{1}.Diff_avg{s,idev};
        if s==1, t_ms = tl.time*1000; end
        cidx = label2idx(tl.label,CN_all);
        pidx = label2idx(tl.label,PR_all);
        Wc_all{idev}.CP(end+1,:)  = mean(tl.avg(cidx,:),1);
        Wp_all{idev}.CP(end+1,:)  = mean(tl.avg(pidx,:),1);
    end
    for s=1:size(S{3}.Diff_avg,1)
        tl = S{3}.Diff_avg{s,idev};
        cidx = label2idx(tl.label,CN_all);
        pidx = label2idx(tl.label,PR_all);
        Wc_all{idev}.CPo(end+1,:) = mean(tl.avg(cidx,:),1);
        Wp_all{idev}.CPo(end+1,:) = mean(tl.avg(pidx,:),1);
    end

    % ============= Sleep Pre/Post =============
    for s=1:size(S{2}.Diff_avg,1)
        tl = S{2}.Diff_avg{s,idev};
        cidx = label2idx(tl.label,CN_all);
        pidx = label2idx(tl.label,PR_all);
        Wc_all{idev}.EP(end+1,:)  = mean(tl.avg(cidx,:),1);
        Wp_all{idev}.EP(end+1,:)  = mean(tl.avg(pidx,:),1);
    end
    for s=1:size(S{4}.Diff_avg,1)
        tl = S{4}.Diff_avg{s,idev};
        cidx = label2idx(tl.label,CN_all);
        pidx = label2idx(tl.label,PR_all);
        Wc_all{idev}.EPo(end+1,:) = mean(tl.avg(cidx,:),1);
        Wp_all{idev}.EPo(end+1,:) = mean(tl.avg(pidx,:),1);
    end
end

%% -------------------- 绘图 ----------------
for idev=1:ndev 
    devNames = {'Small change','Large change'};
    colors = lines(4);

    fh = figure('Color','w','Position',[100 100 450 240]);
    sgtitle(devNames{idev},'fontweight', 'bold');   % 新版替代 suptitle

    % ---- CENTRAL (N2b) ----
    subplot(1,2,1); hold on;
    plot(t_ms, nanmean(Wc_all{idev}.CP,1), 'Color', colors(1,:), 'LineWidth', 1.5);
    plot(t_ms, nanmean(Wc_all{idev}.CPo,1), 'Color', colors(2,:), 'LineWidth', 1.5);
    plot(t_ms, nanmean(Wc_all{idev}.EP,1), 'Color', colors(3,:), 'LineWidth', 1.5);
    plot(t_ms, nanmean(Wc_all{idev}.EPo,1), 'Color', colors(4,:), 'LineWidth', 1.5);
    ylim([-2 2]); yl = ylim;
    rectangle('Position',[N2b_amp_win(1) yl(1) diff(N2b_amp_win) yl(2)-yl(1)], ...
        'EdgeColor','k','LineStyle','--','LineWidth',1.2);
    rectangle('Position',[N2b_lat_win(1) yl(1) diff(N2b_lat_win) yl(2)-yl(1)], ...
        'EdgeColor','k','LineStyle','-','LineWidth',1.2);
    xlabel('Time (ms)'); ylabel('Amplitude (\muV)');
    title('N2b','fontweight', 'bold');
    if idev==1
lgd = legend({'Control-Pre','Control-Post','Sleep-Pre','Sleep-Post'}, ...
             'Box','off','Location','northeast');
lgd.ItemTokenSize = [5,5];   % 缩短 legend 线段
lgd.Position(1) = lgd.Position(1) + 0.05;   % ? 向右挪一点
lgd.Position(2) = lgd.Position(2) - 0.05;   % ? 向右挪一点
    end
    axis square;
    xlim([-100 600]);  %ylim([-2 4]);      
      set(gca, 'FontSize', 9, 'fontweight', 'bold');

    % ---- PARIETAL (P3b) ----
    subplot(1,2,2); hold on;
    plot(t_ms, nanmean(Wp_all{idev}.CP,1), 'Color', colors(1,:), 'LineWidth', 1.5);
    plot(t_ms, nanmean(Wp_all{idev}.CPo,1), 'Color', colors(2,:), 'LineWidth', 1.5);
    plot(t_ms, nanmean(Wp_all{idev}.EP,1), 'Color', colors(3,:), 'LineWidth', 1.5);
    plot(t_ms, nanmean(Wp_all{idev}.EPo,1), 'Color', colors(4,:), 'LineWidth', 1.5);
     ylim([-2 4]); yl = ylim;
    rectangle('Position',[P3b_amp_win(1) yl(1) diff(P3b_amp_win) yl(2)-yl(1)], ...
        'EdgeColor','k','LineStyle','--','LineWidth',1.2);
    rectangle('Position',[P3b_lat_win(1) yl(1) diff(P3b_lat_win) yl(2)-yl(1)], ...
        'EdgeColor','k','LineStyle','-','LineWidth',1.2);
    xlabel('Time (ms)'); ylabel('Amplitude (\muV)');
    title('P3b','fontweight', 'bold');

    axis square;
    xlim([-100 600]);
    ylim([-2 4]); 
     set(gca, 'FontSize', 9, 'fontweight', 'bold');

    % 保存
    saveas(fh, sprintf('Attend_Deviant%d.png',idev));
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

function plot_meansem(t,Mat,color)
    m = nanmean(Mat,1);
    s = nanstd(Mat,0,1)./sqrt(size(Mat,1));
    fill([t fliplr(t)],[m+s fliplr(m-s)],color,'FaceAlpha',0.15,'EdgeColor','none');
    plot(t,m,'Color',color,'LineWidth',1.5);
end
