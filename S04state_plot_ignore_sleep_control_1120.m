%% ======================================================  
%  IGNORE condition — Control/Sleep 分开 + 4 subplot (1x4)
%  - MMN + P3a 同一坐标
%  - Times New Roman 字体
%  - MMN/P3a 淡色填充，不在顶部标注
%  - 在 subplot(1) 的 patch 内部底部放置纵向标签 MMN/P3a
%  - tick 加倍
%  - figure = [100 200 800 220]
% ======================================================

clc; clear;
cd('G:\study2\results');      % <<< 修改为你的路径

% -------------------- 文件 ----------------
files = { ...
    'S001control_IG_pre_nsubavg.mat', ...
    'S002_IG_pre_nsubavg.mat', ...
    'S001control_IG_post_nsubavg.mat', ...
    'S002_IG_post_nsubavg.mat'};

% -------------------- 时间窗 ----------------
MMN_amp_win  = [182 242];
P3a_amp_win  = [257 327];

% ---- 淡色填充颜色 ----
MMN_fill = [1.0 0.80 0.80];     % 淡红
P3a_fill = [0.80 0.85 1.0];     % 淡蓝

% -------------------- 电极簇 -----------------
FR_all = unique([20 23 24 28   4 11 16 19   3 117 118 124]); 

% -------------------- 载入数据 ----------------
S = cell(1,4);
for md = 1:4
    S{md} = load(files{md});
end
ndev = size(S{1}.DEV_avg, 2);

% -------------------- 收集波形 ----------------
W = struct();
for idev = 1:ndev
    W(idev).CP  = [];
    W(idev).CPo = [];
    W(idev).EP  = [];
    W(idev).EPo = [];

    % ==== Control Pre ====
    for s=1:size(S{1}.Diff_avg,1)
        tl = S{1}.Diff_avg{s,idev};
        if s==1, t_ms = tl.time*1000; end
        idx = label2idx(tl.label, FR_all);
        W(idev).CP(end+1,:) = mean(tl.avg(idx,:),1);
    end

    % ==== Control Post ====
    for s=1:size(S{3}.Diff_avg,1)
        tl = S{3}.Diff_avg{s,idev};
        idx = label2idx(tl.label, FR_all);
        W(idev).CPo(end+1,:) = mean(tl.avg(idx,:),1);
    end

    % ==== Sleep Pre ====
    for s=1:size(S{2}.Diff_avg,1)
        tl = S{2}.Diff_avg{s,idev};
        idx = label2idx(tl.label, FR_all);
        W(idev).EP(end+1,:) = mean(tl.avg(idx,:),1);
    end

    % ==== Sleep Post ====
    for s=1:size(S{4}.Diff_avg,1)
        tl = S{4}.Diff_avg{s,idev};
        idx = label2idx(tl.label, FR_all);
        W(idev).EPo(end+1,:) = mean(tl.avg(idx,:),1);
    end
end

%% =================== 绘图 ======================
devNames = {'Small change','Large change'};
groups   = {'Control','Sleep'};
fields   = {{'CP','CPo'}, {'EP','EPo'}};

colors = lines(2);

fh = figure('Color','w','Position',[100 200 800 230]);
sgtitle('Ignore: MMN and P3a','FontWeight','bold','FontSize',14,'FontName','Times New Roman');

plot_id = 1;
for d = 1:2 
for g = 1:2      % Control/Sleep
     % Small/Large

    subplot(1,4,plot_id); hold on;
    set(gca,'FontName','Times New Roman');

    condFields = fields{g};
    dat_pre  = W(d).(condFields{1});
    dat_post = W(d).(condFields{2});

    m1 = mean(dat_pre,1);  se1 = std(dat_pre)/sqrt(size(dat_pre,1));
    m2 = mean(dat_post,1); se2 = std(dat_post)/sqrt(size(dat_post,1));

    yl = [-2 1.5];

    % ============================================================
    % 1) MMN + P3a 淡色填充区域
    % ============================================================
    hMMN = patch([MMN_amp_win(1) MMN_amp_win(2) MMN_amp_win(2) MMN_amp_win(1)], ...
                 [yl(1) yl(1) 1.4 1.4], MMN_fill, ...
                 'FaceAlpha',0.35, 'EdgeColor','none');

    hP3a = patch([P3a_amp_win(1) P3a_amp_win(2) P3a_amp_win(2) P3a_amp_win(1)], ...
                 [yl(1) yl(1) 1.4 1.4], P3a_fill, ...
                 'FaceAlpha',0.35, 'EdgeColor','none');

    % ============================================================
    % 2) 在第一个 subplot 的 patch 内部底端 放置竖排文字
    % ============================================================
    if plot_id == 1
        text(mean(MMN_amp_win)+30, yl(1)+0.4, 'MMN', ...
            'Rotation',90, 'HorizontalAlignment','center', ...
            'VerticalAlignment','bottom', 'FontWeight','bold', ...
            'FontName','Times New Roman', 'FontSize',7.5);

        text(mean(P3a_amp_win)+20, yl(1)+0.3, 'P3a', ...
            'Rotation',90, 'HorizontalAlignment','center', ...
            'VerticalAlignment','bottom', 'FontWeight','bold', ...
            'FontName','Times New Roman', 'FontSize',8);
    end

    % ============================================================
    % 3) 波形 + SE shading
    % ============================================================
    fill([t_ms fliplr(t_ms)], [m1+se1 fliplr(m1-se1)], colors(1,:), ...
        'FaceAlpha',0.25,'EdgeColor','none');
    fill([t_ms fliplr(t_ms)], [m2+se2 fliplr(m2-se2)], colors(2,:), ...
        'FaceAlpha',0.25,'EdgeColor','none');

    h1 = plot(t_ms, m1, 'Color', colors(1,:), 'LineWidth', 1.6);
    h2 = plot(t_ms, m2, 'Color', colors(2,:), 'LineWidth', 1.6);

    ylim(yl); xlim([-100 600]);
    set(gca,'TickLength',[0.02 0.02]);    % tick 加倍

    t=title(sprintf('%s-%s', devNames{d}, groups{g}), ...
        'FontWeight','bold','FontName','Times New Roman','FontSize',10);
    t.Position
t.Position(2) = t.Position(2) + 0.65; 
t.Position
    xlabel('Time (ms)','FontName','Times New Roman','FontSize',9,'FontWeight','bold');
    if plot_id == 1
        ylabel('Amplitude (\muV)','FontName','Times New Roman','FontSize',9,'FontWeight','bold');
    end

    % ---- legend only in first subplot ----
    if plot_id == 1
        lgd = legend([h1 h2], {'Pre','Post'}, 'Box','off', ...
                     'Location','northwest','FontName','Times New Roman','FontSize',9);
        lgd.ItemTokenSize = [8 8];
    end

    plot_id = plot_id + 1;
axis equal square
end
end
set(findall(gcf,'Type','axes'),'FontSize',10,'FontName','Times New Roman','FontWeight','bold');

set(findall(gcf,'-property','FontWeight'),'FontWeight','bold');
print(fh, 'Ignore_4subplot_FillBands_BottomVerticalLabels_TimesNewRoman.tif', '-dtiff', '-r600');


fprintf('绘图完成：MMN/P3a 标签移至第一个subplot底部（竖排）。\n');


%% 辅助函数
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
