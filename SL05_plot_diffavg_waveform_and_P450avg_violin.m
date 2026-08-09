clc; clear; close all
%eeglab
% 如需 FieldTrip / EEGLAB 环境，请按原脚本方式先启动对应工具箱

eeglab
cd('G:\study2\002\sleep\2ndanalysis\results');

filename = {'day0_nsubavg120.mat', ...
            'day1_nsubavg120.mat', ...
            'day2_nsubavg120.mat', ...
            'day3_nsubavg120.mat'};

channelsToAvg = {'FPz', 'C3', 'C4'};

nDay = numel(filename);
nDev = 2;

Diff1 = cell(nDay, 0, nDev);
nSub = nan(nDay,1);

%% ================== Load data + channel average ==================
for md = 1:nDay

    S = load(filename{md});
    Diff_avg = S.Diff_avg;

    nSub(md) = size(Diff_avg,1);
    channel_idx = find(ismember(Diff_avg{1,1}.label, channelsToAvg));

    fprintf('Day %d: %s, nSub = %d\n', md, filename{md}, nSub(md));

    for isub = 1:nSub(md)
        for idev = 1:nDev
            avg_diff1 = Diff_avg{isub,idev};
            avg_diff1.avg = mean(Diff_avg{isub,idev}.avg(channel_idx,:), 1, 'omitnan');
            avg_diff1.label = {'FPz_C3_C4_avg'};
            Diff1{md,isub,idev} = avg_diff1;
        end
    end
end


%% ================== Grand average: detect windows ==================
cfg = [];
cfg.channel   = 'all';
cfg.latency   = 'all';
cfg.parameter = 'avg';

Diff_gavg = cell(nDay,nDev);

for md = 1:nDay
    for idev = 1:nDev
        tmpDiff = squeeze(Diff1(md,1:nSub(md),idev));
        tmpDiff = tmpDiff(~cellfun(@isempty,tmpDiff));
        Diff_gavg{md,idev} = ft_timelockgrandaverage(cfg, tmpDiff{:});
    end
end

Diff_ga = [];
for idev = 1:nDev
    for md = 1:nDay
        Diff_ga(idev,md,:) = Diff_gavg{md,idev}.avg;
    end
end

% Small 和 Large、4 天全部平均，用于自动寻找 P2 / P450 时间窗
Diff_ga = squeeze(mean(mean(Diff_ga,2,'omitnan'),1,'omitnan'));
time = Diff_gavg{1,1}.time;

winlenght = 0.035;

idx_p2 = find(time >= 0.35 & time <= 0.47);
if isempty(idx_p2)
    error('P2 搜索窗口内没有时间点，请检查 time 范围。');
end
[~, p2Idx] = max(Diff_ga(idx_p2));
p2Time = time(idx_p2(p2Idx));

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


%% ================== Build averaged differential waveform ==================
plotTimeWin = [-0.1 0.7];
plotYLim    = [-1.5 3.5];

mycolor = [0 114 178;
           230 159 0;
           0 158 115;
           204 121 167] / 255;

% P2 / P450 标注保持与原脚本一致
componentBoxBottom = -4;
componentBoxTop    = plotYLim(2) - 0.10;
componentBoxHeight = componentBoxTop - componentBoxBottom;

waveMean = cell(nDay,1);
waveSE   = cell(nDay,1);
waveTime = cell(nDay,1);

for iday = 1:nDay

    yMat = [];
    tRef = [];

    for isub = 1:nSub(iday)

        subjWaveAllDev = [];
        tThis = [];

        for idev = 1:nDev
            data_sub = Diff1{iday, isub, idev};

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

            t_tmp = t_full(tidx);
            y_tmp = y_full(:)';
            y_tmp = y_tmp(tidx);

            if isempty(tThis)
                tThis = t_tmp(:)';
            end

            if numel(y_tmp) == numel(tThis)
                subjWaveAllDev = [subjWaveAllDev; y_tmp]; %#ok<AGROW>
            end
        end

        % 对同一个被试的 Small / Large differential response 先平均
        if ~isempty(subjWaveAllDev)
            ySubAvg = mean(subjWaveAllDev, 1, 'omitnan');

            if isempty(tRef)
                tRef = tThis;
            end

            if numel(ySubAvg) == numel(tRef)
                yMat = [yMat; ySubAvg]; %#ok<AGROW>
            end
        end
    end

    if isempty(yMat)
        warning('Day %d 没有可用于平均的 differential waveform。', iday);
        waveMean{iday} = [];
        waveSE{iday}   = [];
        waveTime{iday} = [];
        continue
    end

    mu = mean(yMat, 1, 'omitnan');
    nPerTime = sum(~isnan(yMat), 1);
    se = std(yMat, 0, 1, 'omitnan') ./ sqrt(nPerTime);
    se(nPerTime <= 1) = NaN;

    waveMean{iday} = mu;
    waveSE{iday}   = se;
    waveTime{iday} = tRef;
end


%% ================== Build averaged P450 amplitude by subject ==================
% 每个被试先对 Small / Large 的 P450 amplitude 取平均，再按 4 个 night 绘制 violin
p450Avg = nan(nDay, max(nSub));

for iday = 1:nDay
    for isub = 1:nSub(iday)

        ampDev = nan(1, nDev);

        for idev = 1:nDev
            data_sub = Diff1{iday, isub, idev};

            if isempty(data_sub) || ~isstruct(data_sub) || ...
                    ~isfield(data_sub, 'time') || ~isfield(data_sub, 'avg')
                continue
            end

            idx = find(data_sub.time >= win.p4501 & data_sub.time <= win.p4502);
            if isempty(idx)
                continue
            end

            y = data_sub.avg(idx);
            ampDev(idev) = mean(y, 'omitnan');
        end

        p450Avg(iday, isub) = mean(ampDev, 'omitnan');
    end
end


%% ================== Plot combined figure ==================
% figure 大小与原 violin 脚本保持一致
fig = figure('Position', [100 100 600 360]);

% 左图保持原高度；右侧 violin 的纵轴适当缩短并垂直居中
leftAxesPos  = [0.08 0.15 0.34 0.60];
rightAxesPos = [0.58 0.15 0.34 0.60];

ax1 = axes('Position', leftAxesPos);
hold(ax1, 'on');

h_all = gobjects(nDay,1);

for iday = 1:nDay
    if isempty(waveMean{iday})
        continue
    end

    t = waveTime{iday};
    mu = waveMean{iday};
    se = waveSE{iday};

    xPatch = [t, fliplr(t)];
    yPatch = [mu + se, fliplr(mu - se)];

    fill(ax1, xPatch, yPatch, mycolor(iday,:), ...
        'FaceAlpha', 0.15, ...
        'EdgeColor', 'none', ...
        'HandleVisibility', 'off');

    h_all(iday) = plot(ax1, t, mu, ...
        'LineWidth', 2, ...
        'Color', mycolor(iday,:));
end

rectangle(ax1, 'Position', ...
    [win.p21-0.2, componentBoxBottom, win.p22-win.p21, componentBoxHeight], ...
    'EdgeColor', mycolor(1,:), ...
    'LineStyle', '--', ...
    'LineWidth', 1);

rectangle(ax1, 'Position', ...
    [win.p4501-0.2, componentBoxBottom, win.p4502-win.p4501, componentBoxHeight], ...
    'EdgeColor', mycolor(2,:), ...
    'LineStyle', '--', ...
    'LineWidth', 1);

hTitle1 = title(ax1, 'Differential', 'FontWeight', 'bold');
set(hTitle1, 'Units', 'normalized', 'Position', [0.5, 1.03, 0]);

text(ax1, win.p21-0.17, -1.45, 'P2', ...
    'FontSize', 10, ...
    'Color', mycolor(1,:), ...
    'Rotation', 90);

text(ax1, win.p4501-0.15, -1.45, 'P450', ...
    'FontSize', 10, ...
    'Color', mycolor(2,:), ...
    'Rotation', 90);

set(ax1, ...
    'FontSize', 12, ...
    'FontWeight', 'bold', ...
    'Box', 'off', ...
    'TickLength', [0.02, 0.025]);

axis(ax1, [plotTimeWin(1) plotTimeWin(2) plotYLim]);
xticks(ax1, [0, 0.2, 0.4, 0.6, 0.8]);
yticks(ax1, [-3,-2,-1,0,1,2,3]);
ylabel(ax1, 'Amplitude (\muV)');
xlabel(ax1, 'Time (s)');

validH = h_all(isgraphics(h_all));
if ~isempty(validH)
    leg = legend(ax1, validH, {'Night 1'; 'Night 2'; 'Night 3'; 'Night 4'}, ...
        'Location', 'northeast', ...
        'Orientation', 'vertical', ...
        'FontSize', 10, ...
        'FontWeight', 'bold', ...
        'Box', 'off');
    leg.ItemTokenSize = [9,9];
    set(leg, 'Units', 'normalized');
    pos = get(leg, 'Position');

    % 将 legend 向右移：仅约 2/5 位于坐标系内，至少 3/5 位于坐标系外。
    axesRight = leftAxesPos(1) + leftAxesPos(3);
    pos(1) = axesRight - 0.40 * pos(3);

    % 保持 legend 靠近左图右上角。
    pos(2) = leftAxesPos(2) + leftAxesPos(4) - pos(4) - 0.015;
    set(leg, 'Position', pos);
end
hold(ax1, 'off');

% 右侧 violin 保持相同宽度，但纵轴高度缩短；纵轴上下留白仍为数据范围的 40%
ax2 = axes('Position', rightAxesPos);
hold(ax2, 'on');

allY = [];
violinWidth = 0.20;
jitterWidth = 0.05;

for d = 1:nDay
    yy = p450Avg(d, :);
    yy = yy(~isnan(yy));
    yy = yy(:);

    allY = [allY; yy]; %#ok<AGROW>

    if isempty(yy)
        continue
    end

    thisColor = mycolor(d,:);
    xBase = d;

    if numel(unique(yy)) > 1
        try
            [f, yi] = ksdensity(yy, 'Function', 'pdf');
            f = f ./ max(f) * violinWidth;

            xv = [xBase - f, xBase + fliplr(f)];
            yv = [yi, fliplr(yi)];

            fill(ax2, xv, yv, thisColor, ...
                'FaceAlpha', 0.35, ...
                'EdgeColor', 'none');
        catch
        end
    end

    rng(200 + d);
    xx = xBase + (rand(size(yy)) - 0.5) * 2 * jitterWidth;

    scatter(ax2, xx, yy, 18, ...
        'MarkerFaceColor', thisColor, ...
        'MarkerEdgeColor', 'none', ...
        'MarkerFaceAlpha', 0.45);

    mu  = mean(yy, 'omitnan');
    sem = std(yy, 'omitnan') / sqrt(numel(yy));

    errorbar(ax2, xBase, mu, sem, ...
        'Color', [0.05 0.05 0.05], ...
        'LineStyle', 'none', ...
        'LineWidth', 1.3, ...
        'CapSize', 6);

    plot(ax2, [xBase-0.04 xBase+0.08], [mu mu], '-', ...
        'Color', [0.05 0.05 0.05], ...
        'LineWidth', 2.2);
end

yl = calculate_y_limits(allY, 0.40);
ylim(ax2, yl);
xlim(ax2, [0.55, nDay + 0.60]);
xticks(ax2, 1:nDay);
xticklabels(ax2, {'1','2','3','4'});
xlabel(ax2, 'Nights');
ylabel(ax2, 'Amplitude (\muV)');

% Night 1 与 Night 4 之间显著性星号
if ~isempty(allY)
    ySpan = yl(2) - yl(1);
    yLine = yl(2) - 0.10 * ySpan;
    tickH  = 0.04 * ySpan;

    plot(ax2, [1 1 4 4], [yLine-tickH yLine yLine yLine-tickH], '-', ...
        'Color', [0.18 0.18 0.18], ...
        'LineWidth', 1.0);

    text(ax2, 2.5, yLine + 0.015 * ySpan, '*', ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', ...
        'FontSize', 12, ...
        'FontWeight', 'bold', ...
        'Color', [0.18 0.18 0.18]);
end

hTitle2 = title(ax2, 'P450', 'FontWeight', 'bold');
set(hTitle2, 'Units', 'normalized', 'Position', [0.5, 1.03, 0]);

set(ax2, ...
    'FontSize', 12, ...
    'FontWeight', 'bold', ...
    'Box', 'off', ...
    'LineWidth', 1);

hold(ax2, 'off');

% 在 legend、标题和坐标标签创建后，再次锁定两个绘图区的位置。
% 左图保持原高度，右侧 violin 纵轴使用较短高度。
set(ax1, 'Units', 'normalized', 'Position', leftAxesPos);
set(ax2, 'Units', 'normalized', 'Position', rightAxesPos);
set(ax1, 'PlotBoxAspectRatioMode', 'auto', 'DataAspectRatioMode', 'auto');
set(ax2, 'PlotBoxAspectRatioMode', 'auto', 'DataAspectRatioMode', 'auto');

annotation(fig, 'textbox', [0.15, 0.9, 0.70, 0.05], ...
    'String', 'Averaged across Small and Large change', ...
    'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', ...
    'FontWeight', 'bold', ...
    'FontSize', 16);

set(findall(fig, '-property', 'FontName'), 'FontName', 'Times New Roman');

print(fig, 'ERP_diffavg_waveform_P450avg_violin.tiff', '-dtiff', '-r600');

fprintf('\n图已导出：ERP_diffavg_waveform_P450avg_violin.tiff\n');


function yl = calculate_y_limits(y, paddingRatio)

if isempty(y)
    yl = [0 1];
    return;
end

yMin = min(y)-1;
yMax = max(y)+1;
yRange = yMax - yMin;

if yRange == 0
    yRange = max(abs(yMax), 1);
end

padding = paddingRatio * yRange;
yl = [yMin - padding, yMax + padding];

end
