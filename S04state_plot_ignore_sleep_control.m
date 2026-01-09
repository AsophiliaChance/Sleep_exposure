%% ======================================================  
%  IGNORE (Ignore) condition — Mixed ANOVA + BF10 (BIC) + Waveform Plots
%  - 曲线添加 SE shading（±1 SE）
%  - 仅保留 amplitude 虚线框（顶部画到 1.4）
%  - legend 放在左下角，进一步左移+下移
%  - y 轴范围 [-2, 1.5]
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
MMN_amp_win  = [182 242];   % amplitude (frontal, MMN)
P3a_amp_win  = [257 327];   % amplitude (frontal, P3a)

% -------------------- 电极簇 -----------------
FR_all = unique([20 23 24 28   4 11 16 19   3 117 118 124]); % frontal

% -------------------- 载入数据 ----------------
S = cell(1,4);
for md = 1:4
    S{md} = load(files{md});   % 需包含 Diff_avg（cell: nSub × nDeviants）
end
ndev = size(S{1}.DEV_avg, 2);

% -------------------- 主循环：每个 Deviant ----------------
for idev = 1:ndev
    % ============= 波形收集容器 ============= 
    W_all{idev}.CP  = []; % Control-Pre
    W_all{idev}.CPo = []; % Control-Post
    W_all{idev}.EP  = []; % Sleep-Pre
    W_all{idev}.EPo = []; % Sleep-Post

    % ============= Control Pre/Post ============= 
    for s=1:size(S{1}.Diff_avg,1)
        tl = S{1}.Diff_avg{s,idev};%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
    devNames = {'Small change-Ignore-Diff','Large change-Ignore-Diff'};
    colors = lines(4);
    condFields = {'CP','CPo','EP','EPo'};
    condNames  = {'Control-Pre','Control-Post','Sleep-Pre','Sleep-Post'};

    fh = figure('Color','w','Position',[100 100 480 240]);
    sgtitle(devNames{idev},'fontweight','bold');   

    %% ========== MMN ==========
    subplot(1,2,1); hold on;
    hLine = gobjects(1,4);
    for ic = 1:4
        dat = W_all{idev}.(condFields{ic});
        m = nanmean(dat,1);
        se = nanstd(dat,0,1)/sqrt(size(dat,1));
        % SE shading
        fill([t_ms fliplr(t_ms)], [m+se fliplr(m-se)], ...
             colors(ic,:), 'FaceAlpha',0.25, 'EdgeColor','none');
        % 曲线
        hLine(ic) = plot(t_ms, m, 'Color', colors(ic,:), 'LineWidth', 1.5);
    end

    ylim([-2 1.5]);
    yl = ylim;
    % amplitude 虚线框（顶部画到 1.4）
    rectangle('Position',[MMN_amp_win(1) yl(1) diff(MMN_amp_win) 1.4-yl(1)], ...
        'EdgeColor','k','LineStyle','--','LineWidth',1.2);

    xlabel('Time (ms)'); ylabel('Amplitude (\muV)');
    title('MMN','fontweight','bold');
    xlim([-100 600]); axis square;
    set(gca,'FontSize',9,'fontweight','bold');

    if idev==1
        lgd = legend(hLine, condNames, 'Box','off','Location','southwest');
        lgd.ItemTokenSize = [6,6];
        % 显著左移、下移
        lgd.Position(1)=lgd.Position(1)-0.02;
        lgd.Position(2)=lgd.Position(2)-0.085;
    end

    %% ========== P3a ==========
    subplot(1,2,2); hold on;
    hLine = gobjects(1,4);
    for ic = 1:4
        dat = W_all{idev}.(condFields{ic});
        m = nanmean(dat,1);
        se = nanstd(dat,0,1)/sqrt(size(dat,1));
        fill([t_ms fliplr(t_ms)], [m+se fliplr(m-se)], ...
             colors(ic,:), 'FaceAlpha',0.25, 'EdgeColor','none');
        hLine(ic) = plot(t_ms, m, 'Color', colors(ic,:), 'LineWidth', 1.5);
    end
    ylim([-2 1.5]);
    yl = ylim;
    rectangle('Position',[P3a_amp_win(1) yl(1) diff(P3a_amp_win) 1.4-yl(1)], ...
        'EdgeColor','k','LineStyle','--','LineWidth',1.2);

    xlabel('Time (ms)'); ylabel('Amplitude (\muV)');
    title('P3a','fontweight','bold');
    xlim([-100 600]); axis square;
    set(gca,'FontSize',9,'fontweight','bold');

    % 保存
    saveas(fh, sprintf('Ignore_Deviant%d_SEshading_ylim2to1p5_legendSWshifted.png',idev));
end

fprintf('绘图完成: 每个 deviant 已输出 PNG 图（y: -2~1.5，legend 深左下角，虚线框至1.4）。\n');

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
