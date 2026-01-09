%% ======================================================
%  每个被试 — Ignore Condition — 个体 ERP 图
%  - 每个被试一张图（含 MMN & P3a）
%  - FR_all 平均
%  - y 轴 [-2, 1.5]
%  - amplitude 虚线框画到 y = 1.4
% ======================================================

clc; clear;
cd('G:\study2\results');      % <<< 路径请自行修改

%% -------------------- 数据文件 ----------------
files = { ...
    'S001control_IG_pre_nsubavg.mat', ... % md1 Control-Pre
    'S002_IG_pre_nsubavg.mat', ...        % md2 Sleep-Pre
    'S001control_IG_post_nsubavg.mat', ...% md3 Control-Post
    'S002_IG_post_nsubavg.mat'};          % md4 Sleep-Post

condNames  = {'Control-Pre','Sleep-Pre','Control-Post','Sleep-Post'};

%% -------------------- 时间窗（毫秒） ----------------
MMN_win = [190 240];
P3a_win = [250 300];

%% -------------------- 电极 -----------------
FR_all = unique([20 23 24 28   4 11 16 19   3 117 118 124]);

%% -------------------- 载入 ----------------
S = cell(1,4);
for md = 1:4
    S{md} = load(files{md});   
end

ndev = size(S{1}.DEV_avg,2);
nsub = size(S{1}.DEV_avg,1);   % 所有文件结构一致，取 md1 作为基准

%% -------------------- 主循环： 每个被试 × 每个 deviant ----------------
for s = 1:nsub          % 每个被试
    for idev = 1:ndev   % 每个 deviant

        W = zeros(4, length(S{1}.DEV_avg{s,idev}.time));   % 4 条曲线
        t_ms = S{1}.DEV_avg{s,idev}.time * 1000;

        %% ---- 提取该被试的数据 ----
        for md = 1:4
            tl = S{md}.Diff_avg{s,idev};%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            fidx = label2idx(tl.label, FR_all);
            W(md,:) = mean(tl.avg(fidx,:),1);
        end

        %% ========== 绘图（每个被试一张） ==========
        fh = figure('Color','w','Position',[200 200 480 240]);
        sgtitle(sprintf('Subject %02d — Deviant %d', s, idev), 'FontWeight','bold');

        colors = lines(4);

        %% ---------- MMN ----------
        subplot(1,2,1); hold on;
        for md = 1:4
            plot(t_ms, W(md,:), 'Color', colors(md,:), 'LineWidth', 1.4);
        end

        ylim([-4 4]);
        xlim([-100 600]);
        axis square;
        set(gca,'FontSize',9,'FontWeight','bold');
        title('MMN','FontWeight','bold');
        xlabel('Time (ms)'); ylabel('Amplitude (\muV)');

        yl = ylim;
        rectangle('Position',[MMN_win(1) yl(1) diff(MMN_win) 1.4-yl(1)], ...
            'EdgeColor','k','LineStyle','--','LineWidth',1);

       
            % 全局第一个图加 legend
            lgd = legend(condNames,'Box','off','Location','southwest');
            lgd.ItemTokenSize=[6 6];
            lgd.Position(1)=lgd.Position(1)-0.02;
            lgd.Position(2)=lgd.Position(2)-0.085;
        

        %% ---------- P3a ----------
        subplot(1,2,2); hold on;
        for md = 1:4
            plot(t_ms, W(md,:), 'Color', colors(md,:), 'LineWidth', 1.4);
        end

        ylim([-4 4]);
        xlim([-100 600]);
        axis square;
        set(gca,'FontSize',9,'FontWeight','bold');
        title('P3a','FontWeight','bold');
        xlabel('Time (ms)'); ylabel('Amplitude (\muV)');

        yl = ylim;
        rectangle('Position',[P3a_win(1) yl(1) diff(P3a_win) 1.4-yl(1)], ...
            'EdgeColor','k','LineStyle','--','LineWidth',1);

        %% ---------- 保存 ----------
        fname = sprintf('Subject_%02d_Dev%d.png', s, idev);
        saveas(fh, fname);
        close(fh);
    end
end

fprintf('完成：已为每个被试、每个 deviant 输出 PNG 图。\n');

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
