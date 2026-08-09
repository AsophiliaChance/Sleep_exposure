clc; clear; close all
eeglab

cd('G:\study2\002\sleep\2ndanalysis\results');

filename = {'day0_nsubavg120.mat', ...
            'day1_nsubavg120.mat', ...
            'day2_nsubavg120.mat', ...
            'day3_nsubavg120.mat'};

channelsToAvg = {'FPz', 'C3', 'C4'};

nDay = numel(filename);
nDev = 2;

Diff  = cell(nDay, 0, nDev);
Diff1 = cell(nDay, 0, nDev);
STD   = cell(nDay, 0, nDev);
DEV   = cell(nDay, 0, nDev);

nSub = nan(nDay,1);

%% ================== Load data + channel average ==================
for md = 1:nDay

    S = load(filename{md});

    Diff_avg = S.Diff_avg;
    STD_avg  = S.STD_avg;
    DEV_avg  = S.DEV_avg;

    nSub(md) = size(Diff_avg,1);

    channel_idx = find(ismember(Diff_avg{1,1}.label, channelsToAvg));

    fprintf('Day %d: %s, nSub = %d\n', md, filename{md}, nSub(md));

    for isub = 1:nSub(md)
        for idev = 1:nDev

            %% ---------- Diff: keep selected channels ----------
            avg_diff = Diff_avg{isub,idev};
            avg_diff.avg = Diff_avg{isub,idev}.avg(channel_idx,:);
            Diff{md,isub,idev} = avg_diff;

            %% ---------- Diff1: average selected channels ----------
            avg_diff1 = Diff_avg{isub,idev};
            avg_diff1.avg = mean(Diff_avg{isub,idev}.avg(channel_idx,:), 1, 'omitnan');
            avg_diff1.label = {'FPz_C3_C4_avg'};
            Diff1{md,isub,idev} = avg_diff1;

            %% ---------- STD: average selected channels ----------
            avg_std = STD_avg{isub,idev};
            avg_std.avg = mean(STD_avg{isub,idev}.avg(channel_idx,:), 1, 'omitnan');
            avg_std.label = {'FPz_C3_C4_avg'};
            STD{md,isub,idev} = avg_std;

            %% ---------- DEV: average selected channels ----------
            avg_dev = DEV_avg{isub,idev};
            avg_dev.avg = mean(DEV_avg{isub,idev}.avg(channel_idx,:), 1, 'omitnan');
            avg_dev.label = {'FPz_C3_C4_avg'};
            DEV{md,isub,idev} = avg_dev;

        end
    end
end


%% ================== Grand average ==================
cfg = [];
cfg.channel   = 'all';
cfg.latency   = 'all';
cfg.parameter = 'avg';

Diff_gavg = cell(nDay,nDev);
STD_gavg  = cell(nDay,nDev);
DEV_gavg  = cell(nDay,nDev);

for md = 1:nDay
    for idev = 1:nDev

        tmpDiff = squeeze(Diff1(md,1:nSub(md),idev));
        tmpSTD  = squeeze(STD(md,1:nSub(md),idev));
        tmpDEV  = squeeze(DEV(md,1:nSub(md),idev));

        tmpDiff = tmpDiff(~cellfun(@isempty,tmpDiff));
        tmpSTD  = tmpSTD(~cellfun(@isempty,tmpSTD));
        tmpDEV  = tmpDEV(~cellfun(@isempty,tmpDEV));

        Diff_gavg{md,idev} = ft_timelockgrandaverage(cfg, tmpDiff{:});
        STD_gavg{md,idev}  = ft_timelockgrandaverage(cfg, tmpSTD{:});
        DEV_gavg{md,idev}  = ft_timelockgrandaverage(cfg, tmpDEV{:});

    end
end


%% ================== Find component windows ==================
Diff_ga = [];
DEV_ga  = [];

for idev = 1:nDev
    for md = 1:nDay
        DEV_ga(idev,md,:)  = DEV_gavg{md,idev}.avg;
        Diff_ga(idev,md,:) = Diff_gavg{md,idev}.avg;
    end
end

% deviant 和 day 维度平均，得到总体波形
Diff_ga = squeeze(mean(mean(Diff_ga,2,'omitnan'),1,'omitnan'));
DEV_ga  = squeeze(mean(mean(DEV_ga,2,'omitnan'),1,'omitnan'));

time = Diff_gavg{1,1}.time;

figure;
plot(time(1:201), Diff_ga(50:250), 'LineWidth', 2);
xlabel('Time (s)');
ylabel('Amplitude (\muV)');
title('Grand-average difference wave');
set(gca, 'Box', 'off', 'FontSize', 12);

winlenght = 0.035;

%% ---------- P2 window: positive component ----------
idx_p2 = find(time >= 0.35 & time <= 0.47);

if isempty(idx_p2)
    error('P2 搜索窗口内没有时间点，请检查 time 范围。');
end

[~, p2Idx] = max(Diff_ga(idx_p2));
p2Time = time(idx_p2(p2Idx));

%% ---------- P450 window: positive component ----------
idx_p450 = find(time >= 0.5 & time <= 0.7);

if isempty(idx_p450)
    error('P450 搜索窗口内没有时间点，请检查 time 范围。');
end

[~, p450Idx] = max(Diff_ga(idx_p450));
p450Time = time(idx_p450(p450Idx));

win.p21   = p2Time - winlenght;
win.p22   = p2Time + winlenght;
win.p4501 = p450Time - 0.05;
win.p4502 = p450Time + 0.05;

fprintf('\nDetected windows:\n');
fprintf('P2   window: %.3f - %.3f s\n', win.p21,   win.p22);
fprintf('P450 window: %.3f - %.3f s\n', win.p4501, win.p4502);


%% ================== Waveform plot: mean line + SE ==================
% 使用 subject-level waveform 计算 mean ± SE：
%   STD  -> Standard
%   DEV  -> Deviant
%   Diff1 -> Differential
% Grand average 仍保留用于前面自动寻找 P2 / P450 时间窗。

dataplot{1} = STD;
dataplot{2} = DEV;
dataplot{3} = Diff1;

graphname = {'Standard'; 'Deviant'; 'Differential'};

mycolor = [0 114 178;
           230 159 0;
           0 158 115;
           204 121 167] / 255;

plotTimeWin = [-0.1 0.7];

for idev = 1:nDev

    ax = [];
    figure('Position', [100, 100, 900, 320]);

    for idata = 1:3

        data = dataplot{idata};

        ax{idata} = subplot(1,3,idata);
        hold on;

        h_all = gobjects(nDay,1);

        for iday = 1:nDay

            %% ---------- collect subject-level waveforms ----------
            yMat = [];
            t = [];

            for isub = 1:nSub(iday)

                data_sub = data{iday, isub, idev};

                if isempty(data_sub) || ~isstruct(data_sub) || ...
                        ~isfield(data_sub, 'time') || ~isfield(data_sub, 'avg')
                    continue
                end

                t_full = data_sub.time;
                y_full = data_sub.avg(50:250);

                tidx = find(t_full >= plotTimeWin(1) & t_full <= plotTimeWin(2));

                if isempty(tidx)
                    continue
                end

                if isempty(t)
                    t = t_full(tidx);
                    t = t(:)';
                end

                y = y_full(:)';
                y = y(tidx);

                % 只保留长度一致的 subject waveform
                if numel(y) == numel(t)
                    yMat = [yMat; y];
                end
            end

            if isempty(yMat)
                warning('No valid subject-level data: idev=%d, idata=%d, iday=%d', ...
                    idev, idata, iday);
                continue
            end

            %% ---------- mean ± SE ----------
            mu = mean(yMat, 1, 'omitnan');
            nPerTime = sum(~isnan(yMat), 1);
            se = std(yMat, 0, 1, 'omitnan') ./ sqrt(nPerTime);
            se(nPerTime <= 1) = NaN;

            % SE shaded area
            xPatch = [t, fliplr(t)];
            yPatch = [mu + se, fliplr(mu - se)];

            fill(xPatch, yPatch, mycolor(iday,:), ...
                'FaceAlpha', 0.15, ...
                'EdgeColor', 'none', ...
                'HandleVisibility', 'off');

            % Mean line
            h_all(iday) = plot(t, mu, ...
                'LineWidth', 2, ...
                'Color', mycolor(iday,:));

        end

        %% ---------- component windows ----------
        rectangle('Position', [win.p21-0.2, -4, win.p22-win.p21, 8], ...
            'EdgeColor', mycolor(1,:), ...
            'LineStyle', '--', ...
            'LineWidth', 1);

        rectangle('Position', [win.p4501-0.2, -4, win.p4502-win.p4501, 8], ...
            'EdgeColor', mycolor(2,:), ...
            'LineStyle', '--', ...
            'LineWidth', 1);

        title(graphname{idata}, 'FontWeight', 'bold');

        %% ---------- labels: only show P2 / P450 text in Differential ----------
        if idata == 3
            text(win.p21-0.17,- 1.45, 'P2', ...
                'FontSize', 10, ...
                'Color', mycolor(1,:), ...
                'Rotation', 90);

            text(win.p4501-0.15,- 1.45, 'P450', ...
                'FontSize', 10, ...
                'Color', mycolor(2,:), ...
                'Rotation', 90);
        end

        %% ---------- axis ----------
        set(gca, ...
            'FontSize', 12, ...
            'FontWeight', 'bold', ...
            'Box', 'off', ...
            'TickLength', [0.02, 0.025]);

        axis([plotTimeWin(1) 0.7 -1.5 3.5]);
        xticks([0, 0.2, 0.4, 0.6, 0.8]);
        yticks([-3,-2,-1,0,1,2,3]);
        axis square;

        if idata == 1
            ylabel('Amplitude (\muV)');
            xlabel('Time (s)');
        end

        %% ---------- legend: only in Differential, upper-right, moved outward 0.05 ----------
        if idata == 3

            validH = h_all(isgraphics(h_all));

            if ~isempty(validH)
                leg = legend(validH, {'Night 1'; 'Night 2'; 'Night 3'; 'Night 4'}, ...
                    'Location', 'northeast', ...
                    'Orientation', 'vertical', ...
                    'FontSize', 10, ...
                    'FontWeight', 'bold', ...
                    'Box', 'off');

                leg.ItemTokenSize = [9,9];

                set(leg, 'Units', 'normalized');
                pos = get(leg, 'Position');
                pos(1) = pos(1) + 0.01;   % move outward to the right
                set(leg, 'Position', pos);
            end
        end

        hold off;
    end

    %% ---------- adjust subplot positions ----------
    for i = 1:length(ax)
        pos = get(ax{i}, 'Position');
        pos(1) = pos(1) - 0.03*(i-1);
        pos(2) = pos(2) - 0.02;
        pos(3) = pos(3) - 0.025;
        pos(4) = pos(4) - 0.02;
        set(ax{i}, 'Position', pos);
    end

    %% ---------- make Differential 0.05 wider and 0.05 taller than Deviant ----------
    posDev  = get(ax{2}, 'Position');
    posDiff = get(ax{3}, 'Position');

    posDiff(3) = posDev(3) + 0.05;   % width
    posDiff(4) = posDev(4) + 0.05;   % height

    set(ax{3}, 'Position', posDiff);

    %% ---------- title ----------
    change = {'Small change','Large change'};
    annotation('textbox', [0.3, 0.94, 0.4, 0.05], ...
        'String', change{idev}, ...
        'EdgeColor','none', ...
        'HorizontalAlignment','center', ...
        'FontWeight','bold', ...
        'FontSize', 20);

    set(findall(gcf, '-property', 'FontName'), 'FontName', 'Times New Roman');

    outname = sprintf('ERP%d_gavg.tiff', idev);
    print(outname, '-dtiff', '-r600');

end


%% ================== 50% Area Latency Detection ==================

maxSub = max(nSub);

amplitude_diff.mmn = nan(nDay, maxSub, nDev);   % 实际对应 P2 amplitude
amplitude_diff.p3  = nan(nDay, maxSub, nDev);   % 实际对应 P450 amplitude

latency_diff.mmn   = nan(nDay, maxSub, nDev);   % 实际对应 P2 50% area latency
latency_diff.p3    = nan(nDay, maxSub, nDev);   % 实际对应 P450 50% area latency

for md = 1:nDay
    for idev = 1:nDev
        for isub = 1:nSub(md)

            data = Diff1{md,isub,idev};

            if isempty(data) || ~isstruct(data)
                continue
            end

            %% ---------- P2: mean amplitude + 50% positive area latency ----------
            idx = find(data.time >= win.p21 & data.time <= win.p22);

            if ~isempty(idx)

                t = data.time(idx);
                y = data.avg(idx);

                % Amplitude: mean voltage within predefined window
                amplitude_diff.mmn(md,isub,idev) = mean(y, 'omitnan');

                % P2 是正向成分：positive area latency
                latency_diff.mmn(md,isub,idev) = fractional_area_latency_50(t, y, 'positive');

            end

            %% ---------- P450: mean amplitude + 50% positive area latency ----------
            idx = find(data.time >= win.p4501 & data.time <= win.p4502);

            if ~isempty(idx)

                t = data.time(idx);
                y = data.avg(idx);

                % Amplitude: mean voltage within predefined window
                amplitude_diff.p3(md,isub,idev) = mean(y, 'omitnan');

                % P450 是正向成分：positive area latency
                latency_diff.p3(md,isub,idev) = fractional_area_latency_50(t, y, 'positive');

            end

        end
    end
end


%% ================== Save ERP summary ==================

% 注意：
% 这里变量名为了兼容后续统计脚本，仍然使用 mmn / p3。
% 但实际含义是：
%   amplitude_mmn = P2 amplitude
%   latency_mmn   = P2 50% area latency
%   amplitude_p3  = P450 amplitude
%   latency_p3    = P450 50% area latency

amplitude_mmn = amplitude_diff.mmn;
amplitude_p3  = amplitude_diff.p3;

latency_mmn   = latency_diff.mmn;
latency_p3    = latency_diff.p3;


%% ================== Insert missing subject positions ==================
% 目标：把不同 md 中缺失的 subject 位置补成 NaN，
%      并将后面的数据整体往后移动到正确 subject 位置。

nSubTotal = 20;

missingSub = cell(4,1);
missingSub{1} = [5 6 7 12 17];   % md = 1 缺失位置
missingSub{2} = [];              % md = 2 无缺失
missingSub{3} = [16];            % md = 3 缺失位置
missingSub{4} = [];              % md = 4 无缺失

varList = {'amplitude_mmn', 'amplitude_p3', 'latency_mmn', 'latency_p3'};

for ivar = 1:numel(varList)

    X = eval(varList{ivar});

    nDayX = size(X,1);
    nDevX = size(X,3);

    X_new = nan(nDayX, nSubTotal, nDevX);

    for md = 1:nDayX

        validSubIdx = setdiff(1:nSubTotal, missingSub{md});
        nValid = numel(validSubIdx);

        if nValid > size(X,2)
            warning('%s Day %d: nValid > 原始 subject 数，自动截断。', varList{ivar}, md);
            nValid = size(X,2);
            validSubIdx = validSubIdx(1:nValid);
        end

        X_new(md, validSubIdx, :) = X(md, 1:nValid, :);

    end

    eval([varList{ivar} ' = X_new;']);

end


%% ================== Save ==================
save('erp_statisticsdata_simple.mat', ...
    'amplitude_mmn', ...
    'amplitude_p3', ...
    'latency_mmn', ...
    'latency_p3', ...
    'missingSub', ...
    '-v7');

save('erp_statisticsdata.mat', ...
    'amplitude_diff', ...
    'latency_diff', ...
    'missingSub', ...
    '-v7');

fprintf('\nERP statistics data saved successfully.\n');


%% ============================================================
% Local function: 50% fractional area latency
% ============================================================
function lat50 = fractional_area_latency_50(t, y, polarity)

    lat50 = NaN;

    t = t(:);
    y = y(:);

    valid = ~isnan(t) & ~isnan(y);
    t = t(valid);
    y = y(valid);

    if numel(t) < 2
        return
    end

    switch lower(polarity)

        case 'positive'
            % 只计算正向面积
            yy = y;
            yy(yy < 0) = 0;

        case 'negative'
            % 负向成分：把负波取反，只计算负向面积
            yy = -y;
            yy(yy < 0) = 0;

        otherwise
            error('polarity must be either positive or negative');
    end

    totalArea = trapz(t, yy);

    if totalArea <= 0 || isnan(totalArea)
        return
    end

    cumArea = cumtrapz(t, yy);
    targetArea = 0.5 * totalArea;

    % 找累计面积第一次达到 50% 的位置
    idxCross = find(cumArea >= targetArea, 1, 'first');

    if isempty(idxCross)
        return
    end

    if idxCross == 1
        lat50 = t(1);
        return
    end

    % 线性插值，提高时间点精度
    t1 = t(idxCross - 1);
    t2 = t(idxCross);
    a1 = cumArea(idxCross - 1);
    a2 = cumArea(idxCross);

    if a2 == a1
        lat50 = t2;
    else
        lat50 = t1 + (targetArea - a1) * (t2 - t1) / (a2 - a1);
    end

end