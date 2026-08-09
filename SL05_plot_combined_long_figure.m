% UPDATED VERSION ¡ª 2026-08-05
% Figure headings and D/E spacing revised as requested.
clc; clear; close all

% Combined long figure based on:
% 1) SL05_plot_diffavg_waveform_and_P450avg_violin.m
% 2) SL05_plot_devavg_waveform_P450_amp_latency_violin.m
%
% Layout:
% A-B: Small/Large-averaged results across four nights
% C-E: Four-night-averaged results for Small versus Large deviants

%% ================== Toolbox and working directory ==================
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

% Colors for four nights
nightColor = [0 114 178; ...
              230 159 0; ...
              0 158 115; ...
              204 121 167] / 255;

% Colors for deviant types
smallColor = [145 191 219] / 255;
largeColor = [252 141 89] / 255;

% Component-window colors
compColorP450 = [230 159 0] / 255;
colMean       = [0.05 0.05 0.05];

plotTimeWin = [-0.1 0.7];
plotYLim    = [-1.5 3.5];
violinPaddingRatio = 0.40;

componentBoxBottom = -4;
componentBoxTop    = plotYLim(2) - 0.10;
componentBoxHeight = componentBoxTop - componentBoxBottom;

%% ================== Load data and average channels ==================
Diff1 = cell(nDay, 0, nDev);
nSub  = nan(nDay, 1);

for md = 1:nDay
    S = load(filename{md});

    if ~isfield(S, 'Diff_avg')
        error('%s does not contain the variable Diff_avg.', filename{md});
    end

    Diff_avg = S.Diff_avg;
    nSub(md) = size(Diff_avg, 1);

    if isempty(Diff_avg) || isempty(Diff_avg{1,1})
        error('%s contains no usable Diff_avg data.', filename{md});
    end

    channel_idx = find(ismember(Diff_avg{1,1}.label, channelsToAvg));
    if isempty(channel_idx)
        error('None of the requested channels were found in %s.', filename{md});
    end

    fprintf('Day %d: %s, nSub = %d\n', md, filename{md}, nSub(md));

    for isub = 1:nSub(md)
        for idev = 1:nDev
            if isempty(Diff_avg{isub,idev})
                continue
            end

            avg_diff1 = Diff_avg{isub,idev};
            avg_diff1.avg = mean(Diff_avg{isub,idev}.avg(channel_idx,:), 1, 'omitnan');
            avg_diff1.label = {'FPz_C3_C4_avg'};
            Diff1{md,isub,idev} = avg_diff1;
        end
    end
end

%% ================== Grand average and automatic windows ==================
cfg = [];
cfg.channel   = 'all';
cfg.latency   = 'all';
cfg.parameter = 'avg';

Diff_gavg = cell(nDay, nDev);

for md = 1:nDay
    for idev = 1:nDev
        tmpDiff = squeeze(Diff1(md,1:nSub(md),idev));
        tmpDiff = tmpDiff(~cellfun(@isempty, tmpDiff));

        if isempty(tmpDiff)
            error('No usable waveform data for day %d, deviant %d.', md, idev);
        end

        Diff_gavg{md,idev} = ft_timelockgrandaverage(cfg, tmpDiff{:});
    end
end

Diff_ga = [];
for idev = 1:nDev
    for md = 1:nDay
        Diff_ga(idev,md,:) = Diff_gavg{md,idev}.avg;
    end
end

% Average across Small/Large and all four nights for window detection
Diff_ga = squeeze(mean(mean(Diff_ga, 2, 'omitnan'), 1, 'omitnan'));
time = Diff_gavg{1,1}.time;

idx_p450 = find(time >= 0.5 & time <= 0.7);
if isempty(idx_p450)
    error('No time points were found in the P450 search interval.');
end
[~, p450Idx] = max(Diff_ga(idx_p450));
p450Time = time(idx_p450(p450Idx));

win.p4501 = p450Time - 0.05;
win.p4502 = p450Time + 0.05;

fprintf('\nDetected window:\n');
fprintf('P450 window: %.3f - %.3f s\n', win.p4501, win.p4502);

%% ================== A: waveform by night, averaged across deviants ==================
nightWaveMean = cell(nDay, 1);
nightWaveSE   = cell(nDay, 1);
nightWaveTime = cell(nDay, 1);

for iday = 1:nDay
    yMat = [];
    tRef = [];

    for isub = 1:nSub(iday)
        subjWaveAllDev = [];
        tThis = [];

        for idev = 1:nDev
            data_sub = Diff1{iday,isub,idev};

            if isempty(data_sub) || ~isstruct(data_sub) || ...
                    ~isfield(data_sub, 'time') || ~isfield(data_sub, 'avg')
                continue
            end

            % Keep the original waveform indexing exactly as in the source scripts.
            t_full = data_sub.time;
            y_full = data_sub.avg(50:250);

            tidx = find(t_full >= plotTimeWin(1) & t_full <= plotTimeWin(2));
            if isempty(tidx)
                continue
            end

            tTmp = t_full(tidx);
            yTmp = y_full(:)';
            yTmp = yTmp(tidx);

            if isempty(tThis)
                tThis = tTmp;
            end

            if numel(yTmp) == numel(tThis) && max(abs(tTmp - tThis)) < 1e-10
                subjWaveAllDev = [subjWaveAllDev; yTmp]; %#ok<AGROW>
            end
        end

        if isempty(subjWaveAllDev)
            continue
        end

        ySubAvg = mean(subjWaveAllDev, 1, 'omitnan');

        if isempty(tRef)
            tRef = tThis;
        end

        if numel(ySubAvg) == numel(tRef)
            yMat = [yMat; ySubAvg]; %#ok<AGROW>
        end
    end

    if isempty(yMat)
        warning('Night %d has no usable waveform data.', iday);
        continue
    end

    nightWaveMean{iday} = mean(yMat, 1, 'omitnan');
    nPerTime = sum(~isnan(yMat), 1);
    nightWaveSE{iday} = std(yMat, 0, 1, 'omitnan') ./ sqrt(nPerTime);
    nightWaveSE{iday}(nPerTime <= 1) = NaN;
    nightWaveTime{iday} = tRef;
end

%% ================== B: P450 amplitude by night ==================
% For each subject and night, average P450 amplitude across Small and Large.
p450NightAvg = nan(nDay, max(nSub));

for iday = 1:nDay
    for isub = 1:nSub(iday)
        ampDev = nan(1, nDev);

        for idev = 1:nDev
            data_sub = Diff1{iday,isub,idev};

            if isempty(data_sub) || ~isstruct(data_sub) || ...
                    ~isfield(data_sub, 'time') || ~isfield(data_sub, 'avg')
                continue
            end

            idx = find(data_sub.time >= win.p4501 & data_sub.time <= win.p4502);
            if isempty(idx) || max(idx) > numel(data_sub.avg)
                continue
            end

            ampDev(idev) = mean(data_sub.avg(idx), 'omitnan');
        end

        p450NightAvg(iday,isub) = mean(ampDev, 'omitnan');
    end
end

%% ================== C: waveform by deviant, averaged across nights ==================
devWaveMean = cell(nDev, 1);
devWaveSE   = cell(nDev, 1);
devWaveTime = cell(nDev, 1);

for idev = 1:nDev
    yMat = [];
    tRef = [];

    for iday = 1:nDay
        for isub = 1:nSub(iday)
            data_sub = Diff1{iday,isub,idev};

            if isempty(data_sub) || ~isstruct(data_sub) || ...
                    ~isfield(data_sub, 'time') || ~isfield(data_sub, 'avg')
                continue
            end

            % Keep the original waveform indexing exactly as in the source scripts.
            t_full = data_sub.time;
            y_full = data_sub.avg(50:250);

            tidx = find(t_full >= plotTimeWin(1) & t_full <= plotTimeWin(2));
            if isempty(tidx)
                continue
            end

            tTmp = t_full(tidx);
            yTmp = y_full(:)';
            yTmp = yTmp(tidx);

            if isempty(tRef)
                tRef = tTmp;
            end

            if numel(yTmp) == numel(tRef) && max(abs(tTmp - tRef)) < 1e-10
                yMat = [yMat; yTmp]; %#ok<AGROW>
            end
        end
    end

    if isempty(yMat)
        warning('Deviant %d has no usable waveform data.', idev);
        continue
    end

    devWaveMean{idev} = mean(yMat, 1, 'omitnan');
    nPerTime = sum(~isnan(yMat), 1);
    devWaveSE{idev} = std(yMat, 0, 1, 'omitnan') ./ sqrt(nPerTime);
    devWaveSE{idev}(nPerTime <= 1) = NaN;
    devWaveTime{idev} = tRef;
end

%% ================== D-E: P450 amplitude and latency by deviant ==================
load('erp_statisticsdata_simple.mat', 'amplitude_p3', 'latency_p3');

% Convert latency to time relative to stimulus onset, as in the original script.
latency_p3 = latency_p3 - 0.2;

% Average each subject across the four nights.
ampSmall = squeeze(mean(amplitude_p3(:,:,1), 1, 'omitnan'))';
ampLarge = squeeze(mean(amplitude_p3(:,:,2), 1, 'omitnan'))';
latSmall = squeeze(mean(latency_p3(:,:,1),   1, 'omitnan'))';
latLarge = squeeze(mean(latency_p3(:,:,2),   1, 'omitnan'))';

%% ================== Plot five-panel long figure ==================
fig = figure('Position', [40 100 1600 400], ...
             'Color', 'w', ...
             'PaperPositionMode', 'auto', ...
             'InvertHardcopy', 'off');

% Explicit positions are used instead of tiledlayout for compatibility with
% older MATLAB versions.
nightWavePos   = [0.0350 0.13 0.145 0.60];
nightViolinPos = [0.2255 0.13 0.145 0.60];
devWavePos     = [0.4405 0.13 0.145 0.60];
ampViolinPos   = [0.6310 0.13 0.075 0.60];
latViolinPos   = [0.7515 0.13 0.070 0.60];

%% ----- Panel A: night-wise waveform -----
axA = axes('Parent', fig, 'Position', nightWavePos);
hold(axA, 'on');
hNight = gobjects(nDay,1);

for iday = 1:nDay
    if isempty(nightWaveMean{iday})
        continue
    end

    t  = nightWaveTime{iday};
    mu = nightWaveMean{iday};
    se = nightWaveSE{iday};

    fill(axA, [t fliplr(t)], [mu+se fliplr(mu-se)], nightColor(iday,:), ...
        'FaceAlpha', 0.15, 'EdgeColor', 'none', 'HandleVisibility', 'off');

    hNight(iday) = plot(axA, t, mu, 'LineWidth', 2, 'Color', nightColor(iday,:));
end

add_p450_window(axA, win, componentBoxBottom, componentBoxHeight, ...
    compColorP450);
format_wave_axis(axA, plotTimeWin, plotYLim);

validIdx = find(isgraphics(hNight));
if ~isempty(validIdx)
    nightLabels = {'Night 1','Night 2','Night 3','Night 4'};
    legA = legend(axA, hNight(validIdx), nightLabels(validIdx), ...
        'Location', 'northeast', 'Orientation', 'vertical', ...
        'FontSize', 9, 'FontWeight', 'bold', 'Box', 'off');
    legA.ItemTokenSize = [9 9];
    set(legA, 'Units', 'normalized');
    legPos = get(legA, 'Position');
    legPos(1) = legPos(1) + 0.012;
    set(legA, 'Position', legPos);
end
hold(axA, 'off');

%% ----- Panel B: P450 amplitude across nights -----
axB = axes('Parent', fig, 'Position', nightViolinPos);
hold(axB, 'on');
plot_four_night_violin(axB, p450NightAvg, nightColor, colMean, violinPaddingRatio, '*');
hold(axB, 'off');

%% ----- Panel C: Small versus Large waveform -----
axC = axes('Parent', fig, 'Position', devWavePos);
hold(axC, 'on');

% Plot Large first so that the legend order matches the original figure.
if ~isempty(devWaveMean{2})
    t = devWaveTime{2};
    fill(axC, [t fliplr(t)], ...
        [devWaveMean{2}+devWaveSE{2}, fliplr(devWaveMean{2}-devWaveSE{2})], ...
        largeColor, 'FaceAlpha', 0.18, 'EdgeColor', 'none', ...
        'HandleVisibility', 'off');
    hLarge = plot(axC, t, devWaveMean{2}, 'LineWidth', 2, 'Color', largeColor);
else
    hLarge = gobjects(1);
end

if ~isempty(devWaveMean{1})
    t = devWaveTime{1};
    fill(axC, [t fliplr(t)], ...
        [devWaveMean{1}+devWaveSE{1}, fliplr(devWaveMean{1}-devWaveSE{1})], ...
        smallColor, 'FaceAlpha', 0.18, 'EdgeColor', 'none', ...
        'HandleVisibility', 'off');
    hSmall = plot(axC, t, devWaveMean{1}, 'LineWidth', 2, 'Color', smallColor);
else
    hSmall = gobjects(1);
end

add_p450_window(axC, win, componentBoxBottom, componentBoxHeight, ...
    compColorP450);
format_wave_axis(axC, plotTimeWin, plotYLim);

if isgraphics(hLarge) && isgraphics(hSmall)
    legC = legend(axC, [hLarge hSmall], {'Large','Small'}, ...
        'Location', 'northeast', 'Orientation', 'vertical', ...
        'FontSize', 9, 'FontWeight', 'bold', 'Box', 'off');
    legC.ItemTokenSize = [9 9];
end
hold(axC, 'off');

%% ----- Panel D: P450 amplitude by deviant -----
axD = axes('Parent', fig, 'Position', ampViolinPos);
hold(axD, 'on');
plot_two_group_violin(axD, ampSmall, ampLarge, smallColor, largeColor, ...
    colMean, 'Amplitude (\muV)', '*', violinPaddingRatio);
xlabel(axD, '');
hold(axD, 'off');

%% ----- Panel E: P450 latency by deviant -----
axE = axes('Parent', fig, 'Position', latViolinPos);
hold(axE, 'on');
plot_two_group_violin(axE, latSmall, latLarge, smallColor, largeColor, ...
    colMean, 'Latency (s)', '***', violinPaddingRatio);
xlabel(axE, '');
hold(axE, 'off');

annotation(fig, 'textbox', [0.006 0.795 0.025 0.055], ...
    'String', 'A', ...
    'EdgeColor', 'none', 'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'middle', 'FontWeight', 'bold', 'FontSize', 16);

annotation(fig, 'textbox', [0.414 0.795 0.025 0.055], ...
    'String', 'B', ...
    'EdgeColor', 'none', 'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'middle', 'FontWeight', 'bold', 'FontSize', 16);

%% ----- Group headings and separator -----
annotation(fig, 'textbox', [0.178 0.935 0.500 0.065], ...
    'String', 'P450 differential response', ...
    'EdgeColor', 'none', 'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', 'FontWeight', 'bold', 'FontSize', 17);

annotation(fig, 'textbox', [0.0350 0.795 0.3355 0.055], ...
    'String', 'Main effect of Night', ...
    'EdgeColor', 'none', 'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', 'FontWeight', 'bold', 'FontSize', 15);

annotation(fig, 'textbox', [0.4405 0.795 0.3810 0.055], ...
    'String', 'Main effect of Deviant type', ...
    'EdgeColor', 'none', 'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', 'FontWeight', 'bold', 'FontSize', 15);


% Re-lock axes positions after titles, labels, and legends are created.
set(axA, 'Units', 'normalized', 'Position', nightWavePos, ...
    'PlotBoxAspectRatioMode', 'auto', 'DataAspectRatioMode', 'auto');
set(axB, 'Units', 'normalized', 'Position', nightViolinPos, ...
    'PlotBoxAspectRatioMode', 'auto', 'DataAspectRatioMode', 'auto');
set(axC, 'Units', 'normalized', 'Position', devWavePos, ...
    'PlotBoxAspectRatioMode', 'auto', 'DataAspectRatioMode', 'auto');
set(axD, 'Units', 'normalized', 'Position', ampViolinPos, ...
    'PlotBoxAspectRatioMode', 'auto', 'DataAspectRatioMode', 'auto');
set(axE, 'Units', 'normalized', 'Position', latViolinPos, ...
    'PlotBoxAspectRatioMode', 'auto', 'DataAspectRatioMode', 'auto');

set(findall(fig, '-property', 'FontName'), 'FontName', 'Times New Roman');

outputName = 'ERP_combined_long_figure_P450_only_spacing1p3_labels_shifted_down_P450up_final2.tiff';
print(fig, outputName, '-dtiff', '-r600');
fprintf('\nCombined long figure exported: %s\n', outputName);

%% ================== Local functions ==================
function add_p450_window(ax, win, boxBottom, boxHeight, p450Color)
rectangle(ax, 'Position', ...
    [win.p4501-0.2, boxBottom, win.p4502-win.p4501, boxHeight], ...
    'EdgeColor', p450Color, 'LineStyle', '--', 'LineWidth', 1);

text(ax, win.p4501-0.15, -1.35, 'P450', ...
    'FontSize', 10, 'Color', p450Color, 'Rotation', 90);
end

function format_wave_axis(ax, plotTimeWin, plotYLim)
set(ax, 'FontSize', 12, 'FontWeight', 'bold', 'Box', 'off', ...
    'TickLength', [0.02 0.025], 'LineWidth', 1);
axis(ax, [plotTimeWin(1) plotTimeWin(2) plotYLim]);
xticks(ax, [0 0.2 0.4 0.6]);
yticks(ax, [-3 -2 -1 0 1 2 3]);
xlabel(ax, 'Time (s)');
ylabel(ax, 'Amplitude (\muV)');
end

function add_panel_label(ax, labelText)
text(ax, -0.16, 1.10, labelText, 'Units', 'normalized', ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'top', ...
    'FontSize', 15, 'FontWeight', 'bold', 'Clipping', 'off');
end

function plot_four_night_violin(ax, p450Data, colors, colMean, paddingRatio, sigText)
nDay = size(p450Data, 1);
allY = [];
violinWidth = 0.20;
jitterWidth = 0.05;

for d = 1:nDay
    yy = p450Data(d,:);
    yy = yy(~isnan(yy));
    yy = yy(:);
    allY = [allY; yy]; %#ok<AGROW>

    if isempty(yy)
        continue
    end

    thisColor = colors(d,:);
    xBase = d;

    if numel(unique(yy)) > 1
        try
            [f, yi] = ksdensity(yy, 'Function', 'pdf');
            if max(f) > 0
                f = f ./ max(f) * violinWidth;
                fill(ax, [xBase-f, xBase+fliplr(f)], [yi, fliplr(yi)], ...
                    thisColor, 'FaceAlpha', 0.35, 'EdgeColor', 'none');
            end
        catch
            % Continue without the violin envelope if ksdensity is unavailable.
        end
    end

    rng(200+d);
    xx = xBase + (rand(size(yy))-0.5) * 2 * jitterWidth;
    scatter(ax, xx, yy, 18, 'MarkerFaceColor', thisColor, ...
        'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', 0.45);

    mu = mean(yy, 'omitnan');
    sem = std(yy, 'omitnan') / sqrt(numel(yy));
    errorbar(ax, xBase, mu, sem, 'Color', colMean, ...
        'LineStyle', 'none', 'LineWidth', 1.3, 'CapSize', 6);
    plot(ax, [xBase-0.06 xBase+0.06], [mu mu], '-', ...
        'Color', colMean, 'LineWidth', 2.2);
end

% Preserve the wider vertical padding used in the original night-wise violin.
yl = calculate_y_limits(allY, paddingRatio, 1);
ylim(ax, yl);
xlim(ax, [0.55 nDay+0.60]);
xticks(ax, 1:nDay);
xticklabels(ax, {'1','2','3','4'});
xlabel(ax, 'Nights');
ylabel(ax, 'Amplitude (\muV)');
set(ax, 'FontSize', 12, 'FontWeight', 'bold', 'Box', 'off', 'LineWidth', 1);

if ~isempty(allY)
    ySpan = yl(2)-yl(1);
    yLine = yl(2)-0.10*ySpan;
    tickH = 0.04*ySpan;
    plot(ax, [1 1 4 4], [yLine-tickH yLine yLine yLine-tickH], '-', ...
        'Color', [0.18 0.18 0.18], 'LineWidth', 1.0);
    text(ax, 2.5, yLine+0.015*ySpan, sigText, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
        'FontSize', 12, 'FontWeight', 'bold', 'Color', [0.18 0.18 0.18]);
end
end

function plot_two_group_violin(ax, y1, y2, color1, color2, colMean, ...
    yLabelText, sigText, paddingRatio)
y1 = y1(~isnan(y1));
y2 = y2(~isnan(y2));

violinWidth = 0.22;
jitterWidth = 0.05;
allY = [y1(:); y2(:)];
colors = [color1; color2];
dataCell = {y1(:), y2(:)};
labels = {'Small','Large'};

for i = 1:2
    yy = dataCell{i};
    xBase = i;
    thisColor = colors(i,:);

    if isempty(yy)
        continue
    end

    if numel(unique(yy)) > 1
        try
            [f, yi] = ksdensity(yy, 'Function', 'pdf');
            if max(f) > 0
                f = f ./ max(f) * violinWidth;
                fill(ax, [xBase-f, xBase+fliplr(f)], [yi, fliplr(yi)], ...
                    thisColor, 'FaceAlpha', 0.40, 'EdgeColor', 'none');
            end
        catch
            % Continue without the violin envelope if ksdensity is unavailable.
        end
    end

    rng(300+i);
    xx = xBase + (rand(size(yy))-0.5) * 2 * jitterWidth;
    scatter(ax, xx, yy, 18, 'MarkerFaceColor', thisColor, ...
        'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', 0.45);

    mu = mean(yy, 'omitnan');
    sem = std(yy, 'omitnan') / sqrt(numel(yy));
    errorbar(ax, xBase, mu, sem, 'Color', colMean, ...
        'LineStyle', 'none', 'LineWidth', 1.3, 'CapSize', 6);
    plot(ax, [xBase-0.08 xBase+0.08], [mu mu], '-', ...
        'Color', colMean, 'LineWidth', 2.2);
end

yl = calculate_y_limits(allY, paddingRatio, 0);
ylim(ax, yl);
xlim(ax, [0.5 2.5]);
xticks(ax, 1:2);
xticklabels(ax, labels);
xlabel(ax, 'Deviant type');
ylabel(ax, yLabelText);
set(ax, 'FontSize', 12, 'FontWeight', 'bold', 'Box', 'off', 'LineWidth', 1);

if ~isempty(allY)
    ySpan = yl(2)-yl(1);
    yLine = yl(2)-0.10*ySpan;
    tickH = 0.04*ySpan;
    plot(ax, [1 1 2 2], [yLine-tickH yLine yLine yLine-tickH], '-', ...
        'Color', [0.18 0.18 0.18], 'LineWidth', 1.0);
    text(ax, 1.5, yLine+0.015*ySpan, sigText, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
        'FontSize', 12, 'FontWeight', 'bold', 'Color', [0.18 0.18 0.18]);
end
end

function yl = calculate_y_limits(y, paddingRatio, extraMargin)
if isempty(y)
    yl = [0 1];
    return
end

yMin = min(y)-extraMargin;
yMax = max(y)+extraMargin;
yRange = yMax-yMin;

if yRange == 0
    yRange = max(abs(yMax), 1);
end

padding = paddingRatio*yRange;
yl = [yMin-padding, yMax+padding];
end
