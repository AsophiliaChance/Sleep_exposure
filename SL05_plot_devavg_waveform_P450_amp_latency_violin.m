clc; clear; close all

eeglab
cd('G:\study2\002\sleep\2ndanalysis\results');

%% ================== Basic settings ==================
filename = {'day0_nsubavg120.mat', ...
            'day1_nsubavg120.mat', ...
            'day2_nsubavg120.mat', ...
            'day3_nsubavg120.mat'};

channelsToAvg = {'FPz', 'C3', 'C4'};

nDay = numel(filename);
nDev = 2;   % 1 = Small, 2 = Large

smallColor = [145 191 219] / 255;
largeColor = [252 141 89] / 255;
compColor1 = [0 114 178] / 255;   % P2 label/box
compColor2 = [230 159 0] / 255;   % P450 label/box
colMean    = [0.05 0.05 0.05];

plotTimeWin = [-0.1 0.7];
plotYLim    = [-1.5 3.5];
violinPaddingRatio = 0.40;   % 与 "Averaged across Small and Large change" 图一致

componentBoxBottom = -4;
componentBoxTop    = plotYLim(2) - 0.10;
componentBoxHeight = componentBoxTop - componentBoxBottom;

%% ================== Load waveform data ==================
Diff1 = cell(nDay, 0, nDev);
nSub  = nan(nDay,1);

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

%% ================== Grand average for window detection ==================
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

% Across small/large and 4 nights
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

%% ================== Average waveform across 4 nights ==================
waveMean = cell(nDev,1);
waveSE   = cell(nDev,1);
waveTime = cell(nDev,1);

for idev = 1:nDev

    yMat = [];
    tRef = [];

    for iday = 1:nDay
        for isub = 1:nSub(iday)

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

            if isempty(tRef)
                tRef = t_full(tidx);
                tRef = tRef(:)';
            end

            y = y_full(:)';
            y = y(tidx);

            if numel(y) == numel(tRef)
                yMat = [yMat; y]; %#ok<AGROW>
            end
        end
    end

    mu = mean(yMat, 1, 'omitnan');
    nPerTime = sum(~isnan(yMat), 1);
    se = std(yMat, 0, 1, 'omitnan') ./ sqrt(nPerTime);
    se(nPerTime <= 1) = NaN;

    waveMean{idev} = mu;
    waveSE{idev}   = se;
    waveTime{idev} = tRef;
end

%% ================== Load P450 amplitude and latency ==================
load('erp_statisticsdata_simple.mat', 'amplitude_p3', 'latency_p3');

% latency 校正：转换为相对刺激起点的 latency
latency_p3 = latency_p3 - 0.2;

% 每个被试分别对 4 天取平均
ampSmall = squeeze(mean(amplitude_p3(:,:,1), 1, 'omitnan'))';
ampLarge = squeeze(mean(amplitude_p3(:,:,2), 1, 'omitnan'))';
latSmall = squeeze(mean(latency_p3(:,:,1),   1, 'omitnan'))';
latLarge = squeeze(mean(latency_p3(:,:,2),   1, 'omitnan'))';

%% ================== Plot ==================
% 整体画布与 "Averaged across Small and Large change" 图一致
fig = figure('Position', [100 100 600 360]);

% 三个坐标轴的长短与 "Averaged across Small and Large change" 图风格一致
waveAxesPos = [0.07 0.15 0.34 0.60];
ampAxesPos  = [0.50 0.15 0.17 0.60];   % waveform width 的一半
latAxesPos  = [0.76 0.15 0.17 0.60];   % waveform width 的一半

%% ----- Left: waveform -----
ax1 = axes('Position', waveAxesPos);
hold(ax1, 'on');

% Large first in legend
xPatch = [waveTime{2}, fliplr(waveTime{2})];
yPatch = [waveMean{2} + waveSE{2}, fliplr(waveMean{2} - waveSE{2})];
fill(ax1, xPatch, yPatch, largeColor, ...
    'FaceAlpha', 0.18, ...
    'EdgeColor', 'none', ...
    'HandleVisibility', 'off');
hLarge = plot(ax1, waveTime{2}, waveMean{2}, ...
    'LineWidth', 2, 'Color', largeColor);

xPatch = [waveTime{1}, fliplr(waveTime{1})];
yPatch = [waveMean{1} + waveSE{1}, fliplr(waveMean{1} - waveSE{1})];
fill(ax1, xPatch, yPatch, smallColor, ...
    'FaceAlpha', 0.18, ...
    'EdgeColor', 'none', ...
    'HandleVisibility', 'off');
hSmall = plot(ax1, waveTime{1}, waveMean{1}, ...
    'LineWidth', 2, 'Color', smallColor);

rectangle(ax1, 'Position', ...
    [win.p21-0.2, componentBoxBottom, win.p22-win.p21, componentBoxHeight], ...
    'EdgeColor', compColor1, 'LineStyle', '--', 'LineWidth', 1);
rectangle(ax1, 'Position', ...
    [win.p4501-0.2, componentBoxBottom, win.p4502-win.p4501, componentBoxHeight], ...
    'EdgeColor', compColor2, 'LineStyle', '--', 'LineWidth', 1);

text(ax1, win.p21-0.17, -1.45, 'P2', ...
    'FontSize', 10, 'Color', compColor1, 'Rotation', 90);
text(ax1, win.p4501-0.15, -1.45, 'P450', ...
    'FontSize', 10, 'Color', compColor2, 'Rotation', 90);

hTitle1 = title(ax1, 'Differential', 'FontWeight', 'bold');
set(hTitle1, 'Units', 'normalized', 'Position', [0.5, 1.03, 0]);

set(ax1, 'FontSize', 12, 'FontWeight', 'bold', 'Box', 'off', ...
    'TickLength', [0.02, 0.025], 'LineWidth', 1);
axis(ax1, [plotTimeWin(1) plotTimeWin(2) plotYLim]);
xticks(ax1, [0, 0.2, 0.4, 0.6]);
yticks(ax1, [-3,-2,-1,0,1,2,3]);
ylabel(ax1, 'Amplitude (\muV)');
xlabel(ax1, 'Time (s)');

leg = legend(ax1, [hLarge, hSmall], {'Large', 'Small'}, ...
    'Location', 'northeast', 'Orientation', 'vertical', ...
    'FontSize', 10, 'FontWeight', 'bold', 'Box', 'off');
leg.ItemTokenSize = [9,9];
set(leg, 'Units', 'normalized');
pos = get(leg, 'Position');
pos(1) = pos(1) + 0.04;
set(leg, 'Position', pos);

hold(ax1, 'off');

%% ----- Middle: P450 amplitude violin -----
ax2 = axes('Position', ampAxesPos);
hold(ax2, 'on');
plot_two_group_violin(ax2, ampSmall, ampLarge, smallColor, largeColor, colMean, 'Amplitude (\muV)', '*', violinPaddingRatio);
hTitle2 = title(ax2, {'P450'}, 'FontWeight', 'bold');
set(hTitle2, 'Units', 'normalized', 'Position', [0.5, 1.03, 0]);
hold(ax2, 'off');

%% ----- Right: P450 latency violin -----
ax3 = axes('Position', latAxesPos);
hold(ax3, 'on');
plot_two_group_violin(ax3, latSmall, latLarge, smallColor, largeColor, colMean, 'Latency (s)', '*', violinPaddingRatio);
hTitle3 = title(ax3, {'P450'}, 'FontWeight', 'bold');
set(hTitle3, 'Units', 'normalized', 'Position', [0.5, 1.03, 0]);
hold(ax3, 'off');

annotation(fig, 'textbox', [0.22, 0.92, 0.56, 0.06], ...
    'String', 'Averaged across four nights', ...
    'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', ...
    'FontWeight', 'bold', ...
    'FontSize', 16);

% 重新锁定三个坐标轴位置，避免 MATLAB 自动改变实际绘图区大小。
set(ax1, 'Units', 'normalized', 'Position', waveAxesPos, ...
    'PlotBoxAspectRatioMode', 'auto', 'DataAspectRatioMode', 'auto');
set(ax2, 'Units', 'normalized', 'Position', ampAxesPos, ...
    'PlotBoxAspectRatioMode', 'auto', 'DataAspectRatioMode', 'auto');
set(ax3, 'Units', 'normalized', 'Position', latAxesPos, ...
    'PlotBoxAspectRatioMode', 'auto', 'DataAspectRatioMode', 'auto');

set(findall(fig, '-property', 'FontName'), 'FontName', 'Times New Roman');
print(fig, 'ERP_devavg_waveform_P450_amp_latency_violin.tiff', '-dtiff', '-r600');

fprintf('\n图已导出：ERP_devavg_waveform_P450_amp_latency_violin.tiff\n');

%% ================== Local functions ==================
function plot_two_group_violin(ax, y1, y2, color1, color2, colMean, yLabelText, sigText, paddingRatio)

y1 = y1(~isnan(y1));
y2 = y2(~isnan(y2));

violinWidth = 0.22;
jitterWidth = 0.05;
allY = [y1(:); y2(:)];
colors = [color1; color2];
dataCell = {y1(:), y2(:)};
labels = {'Small', 'Large'};

for i = 1:2
    yy = dataCell{i};
    xBase = i;
    thisColor = colors(i,:);

    if numel(unique(yy)) > 1
        try
            [f, yi] = ksdensity(yy, 'Function', 'pdf');
            f = f ./ max(f) * violinWidth;
            xv = [xBase - f, xBase + fliplr(f)];
            yv = [yi, fliplr(yi)];
            fill(ax, xv, yv, thisColor, ...
                'FaceAlpha', 0.40, ...
                'EdgeColor', 'none');
        catch
        end
    end

    rng(300 + i);
    xx = xBase + (rand(size(yy)) - 0.5) * 2 * jitterWidth;
    scatter(ax, xx, yy, 18, ...
        'MarkerFaceColor', thisColor, ...
        'MarkerEdgeColor', 'none', ...
        'MarkerFaceAlpha', 0.45);

    mu  = mean(yy, 'omitnan');
    sem = std(yy, 'omitnan') / sqrt(numel(yy));
    errorbar(ax, xBase, mu, sem, ...
        'Color', colMean, ...
        'LineStyle', 'none', ...
        'LineWidth', 1.3, ...
        'CapSize', 6);
    plot(ax, [xBase-0.08 xBase+0.08], [mu mu], '-', ...
        'Color', colMean, 'LineWidth', 2.2);
end

yl = calculate_y_limits(allY, paddingRatio);
ylim(ax, yl);
xlim(ax, [0.5, 2.5]);
xticks(ax, 1:2);
xticklabels(ax, labels);
xlabel(ax, 'Deviant type');
ylabel(ax, yLabelText);
set(ax, 'FontSize', 12, 'FontWeight', 'bold', 'Box', 'off', 'LineWidth', 1);

% 显著性星号
if ~isempty(allY)
    ySpan = yl(2) - yl(1);
    yLine = yl(2) - 0.10 * ySpan;
    tickH = 0.04 * ySpan;
    plot(ax, [1 1 2 2], [yLine-tickH yLine yLine yLine-tickH], '-', ...
        'Color', [0.18 0.18 0.18], 'LineWidth', 1.0);
    text(ax, 1.5, yLine + 0.015 * ySpan, sigText, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', ...
        'FontSize', 12, ...
        'FontWeight', 'bold', ...
        'Color', [0.18 0.18 0.18]);
end

end

function yl = calculate_y_limits(y, paddingRatio)
if isempty(y)
    yl = [0 1];
    return;
end

yMin = min(y);
yMax = max(y);
yRange = yMax - yMin;
if yRange == 0
    yRange = max(abs(yMax), 1);
end
padding = paddingRatio * yRange;
yl = [yMin - padding, yMax + padding];
end
