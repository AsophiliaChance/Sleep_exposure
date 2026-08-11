%% ============================================================
% Export_ERP_Nightly_Mean_SE_TableFormat.m
%
% Purpose:
%   Generate a manuscript-ready Excel table containing the nightly
%   mean and standard error for each ERP component, measure, and deviant type.
%
% Output columns:
%   1) Component
%   2) Measure
%   3) Deviant type
%   4) Night
%   5) Mean
%   6) SE
%
% Formatting:
%   - Mean and SE are rounded to two decimal places.
%   - The Excel sheet is formatted as Times New Roman when Microsoft Excel
%     ActiveX is available, usually on Windows.
%
% Input variables from erp_statisticsdata_simple.mat:
%   amplitude_mmn: P2 amplitude,    Night ¡Á Subject ¡Á DeviantType
%   amplitude_p3 : P450 amplitude,  Night ¡Á Subject ¡Á DeviantType
%   latency_mmn  : P2 latency,      Night ¡Á Subject ¡Á DeviantType
%   latency_p3   : P450 latency,    Night ¡Á Subject ¡Á DeviantType
% ============================================================

clc; clear; close all;

%% -------------------- Basic settings --------------------
nDaysExpected = 4;

componentLabels = {'P2', 'P450'};
measureLabels   = {'Amplitude', 'Latency'};
devLabels       = {'Small deviant', 'Large deviant'};

% If latency_mmn / latency_p3 are stored relative to the epoch start
% with epoch onset at -0.2 s, subtract 0.2 s to express latency relative
% to stimulus onset.
correctLatencyByEpochStart = true;
epochStartCorrection = 0.2;   % seconds

% Export latency in milliseconds for manuscript tables.
exportLatencyInMilliseconds = true;

%% -------------------- Paths --------------------
resultDir = 'G:\study2\002\sleep\2ndanalysis\results';
cd(resultDir);

matFile = fullfile(resultDir, 'erp_statisticsdata_simple.mat');

outFile = fullfile(resultDir, 'ERP_Nightly_Mean_SE_TableFormat.xlsx');

%% -------------------- Load ERP data --------------------
load(matFile, 'amplitude_mmn', 'amplitude_p3', 'latency_mmn', 'latency_p3');

%% -------------------- Check dimensions --------------------
[nNight1, nSub1, nDev1] = size(amplitude_mmn);
[nNight2, nSub2, nDev2] = size(amplitude_p3);
[nNight3, nSub3, nDev3] = size(latency_mmn);
[nNight4, nSub4, nDev4] = size(latency_p3);

if ~(nNight1 == nDaysExpected && nNight2 == nDaysExpected && ...
     nNight3 == nDaysExpected && nNight4 == nDaysExpected)
    error(['Night dimension should be %d. Current dimensions are: ', ...
           'amplitude_mmn=%d, amplitude_p3=%d, latency_mmn=%d, latency_p3=%d'], ...
           nDaysExpected, nNight1, nNight2, nNight3, nNight4);
end

if ~(nSub1 == nSub2 && nSub1 == nSub3 && nSub1 == nSub4)
    error('The number of participants is inconsistent across ERP matrices.');
end

if ~(nDev1 == 2 && nDev2 == 2 && nDev3 == 2 && nDev4 == 2)
    error('The third dimension should be 2, corresponding to Small and Large deviant types.');
end

%% -------------------- Latency correction --------------------
if correctLatencyByEpochStart
    latency_mmn = latency_mmn - epochStartCorrection;
    latency_p3  = latency_p3  - epochStartCorrection;
end

if exportLatencyInMilliseconds
    latency_mmn = latency_mmn * 1000;
    latency_p3  = latency_p3  * 1000;
end

%% -------------------- Prepare data arrays --------------------
% Data{component, measure}
% component: 1 = P2, 2 = P450
% measure:   1 = Amplitude, 2 = Latency
Data = cell(2, 2);
Data{1, 1} = amplitude_mmn;  % P2 amplitude
Data{2, 1} = amplitude_p3;   % P450 amplitude
Data{1, 2} = latency_mmn;    % P2 latency
Data{2, 2} = latency_p3;     % P450 latency

%% -------------------- Calculate nightly mean and SE --------------------
rows = {};
r = 1;

for icomp = 1:numel(componentLabels)

    for imeasure = 1:numel(measureLabels)

        A = Data{icomp, imeasure};  % Night ¡Á Subject ¡Á DeviantType

        for idev = 1:numel(devLabels)

            for iday = 1:nDaysExpected

                yy = squeeze(A(iday, :, idev));
                yy = yy(:);
                yy = yy(~isnan(yy));

                nVal = numel(yy);

                if nVal > 0
                    meanVal = mean(yy, 'omitnan');
                    sdVal   = std(yy, 'omitnan');
                    seVal   = sdVal / sqrt(nVal);
                else
                    meanVal = NaN;
                    seVal   = NaN;
                end

                rows(r, :) = { ...
                    componentLabels{icomp}, ...
                    measureLabels{imeasure}, ...
                    devLabels{idev}, ...
                    sprintf('Night %d', iday), ...
                    round(meanVal, 2), ...
                    round(seVal, 2)};

                r = r + 1;
            end
        end
    end
end

%% -------------------- Export Excel with exact column names --------------------
header = {'Component', 'Measure', 'Deviant type', 'Night', 'Mean', 'SE'};
outCell = [header; rows];

if exist(outFile, 'file')
    delete(outFile);
end

writecell(outCell, outFile, 'Sheet', 'Nightly_Mean_SE');

%% -------------------- Format Excel --------------------
% This step requires Microsoft Excel ActiveX, which is normally available
% only on Windows with Excel installed. If unavailable, the data are still
% exported correctly, but font formatting may not be applied automatically.
try
    excel = actxserver('Excel.Application');
    excel.DisplayAlerts = false;

    workbook = excel.Workbooks.Open(outFile);
    sheet = workbook.Worksheets.Item('Nightly_Mean_SE');

    usedRange = sheet.UsedRange;
    usedRange.Font.Name = 'Times New Roman';
    usedRange.Font.Size = 12;

    % Header formatting
    headerRange = sheet.Range('A1:F1');
    headerRange.Font.Bold = true;

    % Keep two decimal places visually in Excel for Mean and SE
    sheet.Range('E:F').NumberFormat = '0.00';

    % Autofit columns
    usedRange.Columns.AutoFit;

    workbook.Save;
    workbook.Close(false);
    excel.Quit;
    delete(excel);

catch ME
    warning(['Excel formatting via ActiveX was not completed. ', ...
             'The table has still been exported. Details: %s'], ME.message);
end

fprintf('\nExcel table saved to:\n%s\n', outFile);
fprintf('Columns: Component | Measure | Deviant type | Night | Mean | SE\n');
fprintf('Mean and SE are rounded to two decimal places.\n');
