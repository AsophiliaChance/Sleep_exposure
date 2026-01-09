%% ======================================================  
%  ATTENTIVE (Attend) condition — Waveform Plots with SE shading
%  - 添加 SE shading（±1 SE）
%  - 仅保留 amplitude 虚线框（顶部比 y 轴上限低 0.2）
%  - 去掉 latency 框 & legend
%  - 标题加上 "-Attend"
% ======================================================

clc; clear;
cd('G:\study2\results');      % <<< 路径请自行修改

% -------------------- 数据文件 ----------------
files = { ...
    'S001control_ATT_pre_ATTnsubavg.mat', ...
    'S002_ATT_pre_ATTnsubavg.mat', ...
    'S001control_ATT_post_ATTnsubavg.mat', ...
    'S002_ATT_post_ATTnsubavg.mat'};

% -------------------- 时间窗（毫秒） ----------------
N2b_amp_win  = [230 280];   % amplitude (central)
P3b_amp_win  = [360 410];   % amplitude (parietal)

% -------------------- 电极簇 -----------------
CN_all = unique([29 30 36 37   5 6 12 11   87 104 105 111]); % central
PR_all = unique([47 52 59 60   61 62 72 78  85 91 92 98]);   % parietal

% -------------------- 载入数据 ----------------
S = cell(1,4);
for md = 1:4
    S{md} = load(files{md});   % 需包含 Diff_avg（cell: nSub × nDeviants）
end
ndev = size(S{1}.Diff_avg, 2);

% -------------------- 主循环 ----------------
for idev = 1:ndev
    Wc_all{idev}.CP  = []; Wc_all{idev}.CPo = [];
    Wc_all{idev}.EP  = []; Wc_all{idev}.EPo = [];
    Wp_all{idev} = Wc_all{idev};

    for s = 1:size(S{1}.Diff_avg,1)
        tl = S{1}.DEV_avg{s,idev};%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if s==1, t_ms = tl.time*1000; end
        cidx = label2idx(tl.label,CN_all);
        pidx = label2idx(tl.label,PR_all);
        Wc_all{idev}.CP(end+1,:)  = mean(tl.avg(cidx,:),1);
        Wp_all{idev}.CP(end+1,:)  = mean(tl.avg(pidx,:),1);
    end
    for s = 1:size(S{3}.Diff_avg,1)
        tl = S{3}.DEV_avg{s,idev};
        cidx = label2idx(tl.label,CN_all);
        pidx = label2idx(tl.label,PR_all);
        Wc_all{idev}.CPo(end+1,:) = mean(tl.avg(cidx,:),1);
        Wp_all{idev}.CPo(end+1,:) = mean(tl.avg(pidx,:),1);
    end
    for s = 1:size(S{2}.Diff_avg,1)
        tl = S{2}.DEV_avg{s,idev};
        cidx = label2idx(tl.label,CN_all);
        pidx = label2idx(tl.label,PR_all);
        Wc_all{idev}.EP(end+1,:)  = mean(tl.avg(cidx,:),1);
        Wp_all{idev}.EP(end+1,:)  = mean(tl.avg(pidx,:),1);
    end
    for s = 1:size(S{4}.Diff_avg,1)
        tl = S{4}.DEV_avg{s,idev};
        cidx = label2idx(tl.label,CN_all);
        pidx = label2idx(tl.label,PR_all);
        Wc_all{idev}.EPo(end+1,:) = mean(tl.avg(cidx,:),1);
        Wp_all{idev}.EPo(end+1,:) = mean(tl.avg(pidx,:),1);
    end
end

%% -------------------- 绘图 ----------------
for idev = 1:ndev
    devNames = {'Small change - Attend-DEV','Large change - Attend-DEV'};
    colors = lines(4);
    condFields = {'CP','CPo','EP','EPo'};

    fh = figure('Color','w','Position',[100 100 460 240]);
    sgtitle(devNames{idev},'fontweight','bold');

    %% -------- CENTRAL (N2b) --------
    subplot(1,2,1); hold on;
    for ic = 1:4
        plot_meansem(t_ms, Wc_all{idev}.(condFields{ic}), colors(ic,:)); % 含 shading
    end
    ylim([-2 2]);
    yl = ylim;
    topY = yl(2) - 0.2; % 框顶部比上限低0.2
    rectangle('Position',[N2b_amp_win(1) yl(1) diff(N2b_amp_win) topY-yl(1)], ...
        'EdgeColor','k','LineStyle','--','LineWidth',1.2);
    xlabel('Time (ms)'); ylabel('Amplitude (\muV)');
    title('N2b','fontweight','bold');
    xlim([-100 600]);
    axis square;
    set(gca,'FontSize',9,'fontweight','bold');

    %% -------- PARIETAL (P3b) --------
    subplot(1,2,2); hold on;
    for ic = 1:4
        plot_meansem(t_ms, Wp_all{idev}.(condFields{ic}), colors(ic,:)); % 含 shading
    end
    ylim([-2 4]);
    yl = ylim;
    topY = yl(2) - 0.2;
    rectangle('Position',[P3b_amp_win(1) yl(1) diff(P3b_amp_win) topY-yl(1)], ...
        'EdgeColor','k','LineStyle','--','LineWidth',1.2);
    xlabel('Time (ms)'); ylabel('Amplitude (\muV)');
    title('P3b','fontweight','bold');
    xlim([-100 600]);
    axis square;
    set(gca,'FontSize',9,'fontweight','bold');

    % 保存
    saveas(fh, sprintf('Attend_Deviant%d_SEshading_NoLegend_NoLatency.png',idev));
end

fprintf('绘图完成: 每个 deviant 已输出 PNG 图（无 legend，无 latency 框，带 shading）。\n');

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
    s = nanstd(Mat,0,1)/sqrt(size(Mat,1));
    fill([t fliplr(t)], [m+s fliplr(m-s)], color, ...
         'FaceAlpha',0.25, 'EdgeColor','none'); % SE shading
    plot(t, m, 'Color', color, 'LineWidth', 1.5);
end
