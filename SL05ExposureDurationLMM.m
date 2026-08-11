%% ERP_duration.m
% Analyze exposure duration across four sleep-exposure nights
%
% Expected Excel format:
%   Subject | day1 | day2 | day3 | day4
%
% This script:
%   1. Reads exposure duration data
%   2. Converts wide format to long format
%   3. Summarizes exposure duration by night
%   4. Separates valid ERP observations using duration >  min
%   5. Tests whether exposure duration differs across nights using LMM
%
% LMM:
%   Duration ~ Night + (1 | Subject)

clear;
clc;

%% ===================== 1. Settings =====================

filePath = 'G:\study2\002\sleep\2ndanalysis\exposure_dur.xlsx';

% According to your description:
% valid ERP observations have exposure duration > 60 min
validERPThreshold = 59;

% Expected valid ERP N by night
expectedValidN = [15; 20; 19; 20];

% Output folder
[outFolder, ~, ~] = fileparts(filePath);
resultFolder = fullfile(outFolder, 'exposureDurationResults');

if ~exist(resultFolder, 'dir')
    mkdir(resultFolder);
end

diaryFile = fullfile(resultFolder, 'ExposureDurationResults.txt');

%% ===================== 2. Read Excel file =====================

if ~isfile(filePath)
    error('File not found. Please check the path: %s', filePath);
end

% Compatible with old and new MATLAB versions
try
    T = readtable(filePath, 'VariableNamingRule', 'preserve');
catch
    T = readtable(filePath);
end

disp('Original data preview:');
disp(T);

%% ===================== 3. Detect columns =====================

varNames = T.Properties.VariableNames;
lowerNames = lower(varNames);

% Detect subject column
subjectIdx = find(contains(lowerNames, 'subject') | ...
                  contains(lowerNames, 'subj') | ...
                  strcmp(lowerNames, 'id'), 1);

if isempty(subjectIdx)
    subjectIdx = 1;
    warning('Subject column was not detected automatically. The first column is used as Subject.');
end

subjectCol = varNames{subjectIdx};

% Detect day/night columns
dayIdx = [];

for i = 1:numel(varNames)
    nameLower = lower(varNames{i});
    if contains(nameLower, 'day') || contains(nameLower, 'night')
        dayIdx(end+1) = i; %#ok<SAGROW>
    end
end

% If not detected, use columns 2-5
if numel(dayIdx) < 4
    warning('Day/night columns were not detected automatically. Columns 2-5 are used as day1-day4.');
    dayIdx = 2:5;
end

dayIdx = dayIdx(1:4);
dayCols = varNames(dayIdx);

fprintf('\nDetected subject column: %s\n', subjectCol);
fprintf('Detected night columns:\n');
disp(dayCols');

%% ===================== 4. Convert wide format to long format =====================

subjectsRaw = T.(subjectCol);
subjects = string(subjectsRaw);

nSub = height(T);
nNight = 4;

SubjectStr = strings(0, 1);
NightStr = strings(0, 1);
Duration = [];

for n = 1:nNight
    durRaw = T.(dayCols{n});
    durNumeric = convertToNumeric(durRaw);

    SubjectStr = [SubjectStr; subjects]; %#ok<AGROW>
    NightStr = [NightStr; repmat("Night" + string(n), nSub, 1)]; %#ok<AGROW>
    Duration = [Duration; durNumeric]; %#ok<AGROW>
end

nightOrder = {'Night1', 'Night2', 'Night3', 'Night4'};

Subject = categorical(cellstr(SubjectStr));
Night = categorical(cellstr(NightStr), nightOrder);

longT = table(Subject, Night, Duration);

% Remove rows with missing duration
longT = longT(~isnan(longT.Duration), :);

disp('Long-format data preview:');
disp(longT(1:min(10, height(longT)), :));

%% ===================== 5. Define valid ERP and short exposure observations =====================

validT = longT(longT.Duration > validERPThreshold, :);
shortT = longT(longT.Duration <= validERPThreshold, :);

%% ===================== 6. Descriptive statistics =====================

summaryAll = summarizeByNight(longT, nightOrder);
summaryValid = summarizeByNight(validT, nightOrder);
summaryShort = summarizeByNight(shortT, nightOrder);

fprintf('\n===== Summary: all exposure nights =====\n');
disp(summaryAll);

fprintf('\n===== Summary: valid ERP observations only, Duration > %.1f min =====\n', validERPThreshold);
disp(summaryValid);

fprintf('\n===== Summary: short exposure nights, Duration <= %.1f min =====\n', validERPThreshold);
disp(summaryShort);

fprintf('\nExpected valid ERP N by night:\n');
expectedTable = table(["Night1"; "Night2"; "Night3"; "Night4"], expectedValidN, ...
    'VariableNames', {'Night', 'ExpectedN'});
disp(expectedTable);

fprintf('\nObserved valid ERP N by night:\n');
disp(summaryValid(:, {'Night', 'N'}));

if height(summaryValid) == 4 && all(summaryValid.N == expectedValidN)
    fprintf('\nValid ERP N matches the expected values: 15, 20, 19, 20.\n');
else
    warning('Observed valid ERP N does not match the expected values 15, 20, 19, 20. Please check threshold or data.');
end

%% ===================== 7. LMM analysis =====================

diary(diaryFile);

fprintf('Exposure duration analysis\n');
fprintf('==========================\n\n');

fprintf('Input file:\n%s\n\n', filePath);
fprintf('Valid ERP threshold: Duration > %.1f min\n\n', validERPThreshold);

fprintf('Detected subject column: %s\n', subjectCol);
fprintf('Detected night columns:\n');
disp(dayCols');

fprintf('\n===== Summary: all exposure nights =====\n');
disp(summaryAll);

fprintf('\n===== Summary: valid ERP observations only =====\n');
disp(summaryValid);

fprintf('\n===== Summary: short exposure nights =====\n');
disp(summaryShort);

fprintf('\nExpected valid ERP N by night:\n');
disp(expectedTable);

fprintf('\nObserved valid ERP N by night:\n');
disp(summaryValid(:, {'Night', 'N'}));

fprintf('\n\n===== LMM 1: all exposure nights =====\n');
resultsAll = runLMM(longT, 'All exposure nights', nightOrder);

fprintf('\n\n===== LMM 2: valid ERP observations only =====\n');
resultsValid = runLMM(validT, 'Valid ERP observations only', nightOrder);

diary off;

%% ===================== 8. Save output tables =====================

writetable(longT, fullfile(resultFolder, 'ExposureDurationLongFormat.xlsx'));
writetable(summaryAll, fullfile(resultFolder, 'SummaryAllExposureNights.xlsx'));
writetable(summaryValid, fullfile(resultFolder, 'SummaryValidERPObservations.xlsx'));
writetable(summaryShort, fullfile(resultFolder, 'SummaryShortExposureNights.xlsx'));

%% ===================== 9. Save figures =====================

plotDurationByNight(longT, ...
    fullfile(resultFolder, 'DurationAllExposureNights.png'), ...
    'Exposure duration across all sleep-exposure nights');

plotDurationByNight(validT, ...
    fullfile(resultFolder, 'DurationValidERPObservations.png'), ...
    'Exposure duration among valid ERP observations');

plotDurationByNight(shortT, ...
    fullfile(resultFolder, 'DurationShortExposureNights.png'), ...
    'Short exposure nights');

fprintf('\nAnalysis finished.\n');
fprintf('Results saved in:\n%s\n', resultFolder);
fprintf('Text output saved as:\n%s\n', diaryFile);

%% ===================== Local functions =====================

function x = convertToNumeric(xRaw)
    if isnumeric(xRaw)
        x = double(xRaw);
    elseif iscell(xRaw)
        x = str2double(string(xRaw));
    elseif isstring(xRaw)
        x = str2double(xRaw);
    elseif iscategorical(xRaw)
        x = str2double(string(xRaw));
    else
        x = str2double(string(xRaw));
    end
end

function summaryT = summarizeByNight(T, nightOrder)

    Night = strings(4, 1);
    N = zeros(4, 1);
    Mean = nan(4, 1);
    SD = nan(4, 1);
    SE = nan(4, 1);
    Median = nan(4, 1);
    Min = nan(4, 1);
    Max = nan(4, 1);

    for i = 1:4
        thisNight = nightOrder{i};
        idx = T.Night == thisNight;
        values = T.Duration(idx);
        values = values(~isnan(values));

        Night(i) = string(thisNight);
        N(i) = numel(values);

        if ~isempty(values)
            Mean(i) = mean(values);
            SD(i) = std(values);
            SE(i) = SD(i) / sqrt(N(i));
            Median(i) = median(values);
            Min(i) = min(values);
            Max(i) = max(values);
        end
    end

    summaryT = table(Night, N, Mean, SD, SE, Median, Min, Max);
end

function results = runLMM(T, labelText, nightOrder)

    results = struct();

    T = T(~isnan(T.Duration), :);
    T.Subject = categorical(T.Subject);
    T.Night = categorical(cellstr(string(T.Night)), nightOrder);

    fprintf('\nModel set: %s\n', labelText);
    fprintf('Number of observations: %d\n', height(T));
    fprintf('Number of subjects: %d\n', numel(categories(T.Subject)));

    if height(T) < 8
        warning('Too few observations for LMM. Skipping this model.');
        return;
    end

    if exist('fitlme', 'file') ~= 2
        warning('fitlme is not available. Statistics and Machine Learning Toolbox may be missing.');
        return;
    end

    % Use ML for fixed-effect model comparison
    lmeNull = fitlme(T, 'Duration ~ 1 + (1|Subject)', 'FitMethod', 'ML');
    lmeFull = fitlme(T, 'Duration ~ Night + (1|Subject)', 'FitMethod', 'ML');

    fprintf('\nNull model: Duration ~ 1 + (1|Subject)\n');
    disp(lmeNull);

    fprintf('\nFull model: Duration ~ Night + (1|Subject)\n');
    disp(lmeFull);

    fprintf('\nLikelihood-ratio model comparison:\n');
    cmp = compare(lmeNull, lmeFull);
    disp(cmp);

    fprintf('\nANOVA table for full model:\n');
    aov = anova(lmeFull);
    disp(aov);

    results.lmeNull = lmeNull;
    results.lmeFull = lmeFull;
    results.compare = cmp;
    results.anova = aov;
end

function plotDurationByNight(T, savePath, titleText)

    if isempty(T)
        warning('No data available for plotting: %s', titleText);
        return;
    end

    fig = figure('Color', 'w');
    hold on;

    try
        boxchart(T.Night, T.Duration);
    catch
        boxplot(T.Duration, T.Night);
    end

    % Add individual points
    x = grp2idx(T.Night);
    jitter = (rand(size(x)) - 0.5) * 0.15;
    scatter(x + jitter, T.Duration, 30, 'filled');

    xlabel('Night');
    ylabel('Exposure duration (min)');
    title(titleText);
    grid on;
    box on;

    try
        exportgraphics(fig, savePath, 'Resolution', 300);
    catch
        saveas(fig, savePath);
    end

    close(fig);
end
