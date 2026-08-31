%% ============================================================
% SL06_ModelComparisonOnly.m
%
% Purpose:
%   Compare candidate linear mixed-effects models for four ERP outcomes:
%   P2 amplitude, P450 amplitude, P2 latency, and P450 latency.
%
% Step 1: Compare random-effects structures using REML while keeping
%         the fixed-effects structure identical.
%
%   Random-intercept model:
%       Y ~ Days * DeviantType + Exposure + (1 | Subjects)
%
%   Random-slope model:
%       Y ~ Days * DeviantType + Exposure + (1 + Days | Subjects)
%
% Step 2: Using the selected random-effects structure, compare models
%         with versus without Exposure using ML.
%
%   Without Exposure:
%       Y ~ Days * DeviantType + selected random-effects structure
%
%   With Exposure:
%       Y ~ Days * DeviantType + Exposure + selected random-effects structure
%
% Model-selection rule:
%   A likelihood-ratio-test p value < .05 favors the more complex model.
%   AIC and BIC differences are also reported for transparency.
%
% Output:
%   ERP_ModelComparisonOnly.xlsx
%       Sheet 1: RandomEffectsComparison
%       Sheet 2: ExposureComparison
% ============================================================

clc; clear; close all;

%% -------------------- Basic settings --------------------
nDaysExpected = 4;
nSubExpected  = 20;

dayLevels = arrayfun(@num2str, 1:nDaysExpected, 'UniformOutput', false);
devLevels = {'Small','Large'};
measureNames = {'Amplitude','Latency'};
dummyCoding = 'effects';

%% -------------------- File paths --------------------
resultDir = 'G:\study2\002\sleep\2ndanalysis\results';
cd(resultDir);

matFile = fullfile(resultDir, 'erp_statisticsdata_simple.mat');
exposureFile = 'G:\study2\002\sleep\2ndanalysis\exposure_dur.xlsx';
outFile = fullfile(resultDir, 'ERP_ModelComparisonOnly.xlsx');

%% -------------------- Load ERP data --------------------
load(matFile, 'amplitude_mmn', 'amplitude_p3', 'latency_mmn', 'latency_p3');

%% -------------------- Load exposure duration --------------------
expTbl = readtable(exposureFile);
subj_exp = expTbl{:,1};
expMat   = expTbl{:,2:end};

if size(expMat,2) ~= nDaysExpected
    error('The exposure file must contain %d day/night columns; %d were found.', ...
        nDaysExpected, size(expMat,2));
end

nSub_exp = size(expMat,1);
if nSub_exp ~= nSubExpected
    warning('The exposure file contains %d participants rather than the expected %d.', ...
        nSub_exp, nSubExpected);
end

%% -------------------- Check ERP dimensions --------------------
[nNight1, nSub1, nDev1] = size(amplitude_mmn);
[nNight2, nSub2, nDev2] = size(amplitude_p3);
[nNight3, nSub3, nDev3] = size(latency_mmn);
[nNight4, nSub4, nDev4] = size(latency_p3);

if ~(nNight1 == nDaysExpected && nNight2 == nDaysExpected && ...
     nNight3 == nDaysExpected && nNight4 == nDaysExpected)
    error('All ERP arrays must contain %d nights.', nDaysExpected);
end

if ~(nSub1 == nSub_exp && nSub2 == nSub_exp && ...
     nSub3 == nSub_exp && nSub4 == nSub_exp)
    error('The number of participants differs between the ERP and exposure data.');
end

if ~(nDev1 == 2 && nDev2 == 2 && nDev3 == 2 && nDev4 == 2)
    error('The third ERP dimension must contain two deviant types: Small and Large.');
end

%% -------------------- Correct latency origin --------------------
% Convert latency values from epoch-relative timing to stimulus-relative
% timing when the epoch begins 0.2 s before stimulus onset.
latency_mmn = latency_mmn - 0.2;
latency_p3  = latency_p3  - 0.2;

%% -------------------- Build long-format tables --------------------
T_amp = build_long_table_with_deviant( ...
    amplitude_mmn, amplitude_p3, subj_exp, expMat, ...
    'Amplitude', nDaysExpected, dayLevels, devLevels);

T_lat = build_long_table_with_deviant( ...
    latency_mmn, latency_p3, subj_exp, expMat, ...
    'Latency', nDaysExpected, dayLevels, devLevels);

T_all = {T_amp, T_lat};

%% -------------------- Model comparisons --------------------
randomRows   = {};
exposureRows = {};
rRandom = 1;
rExposure = 1;

for m = 1:numel(T_all)

    Tm = T_all{m};
    comps = categories(Tm.Component);

    for ic = 1:numel(comps)

        thisComp = comps{ic};
        Tc = Tm(Tm.Component == thisComp, :);

        Tc.Subjects    = categorical(Tc.Subjects);
        Tc.Days        = categorical(Tc.Days, dayLevels);
        Tc.DeviantType = categorical(Tc.DeviantType, devLevels);

        % Both candidate models must be fitted to exactly the same rows.
        Tc = Tc(~isnan(Tc.Y) & ~isnan(Tc.Exposure), :);

        if height(Tc) < 10
            warning('%s | %s: too few complete observations; comparison skipped.', ...
                measureNames{m}, thisComp);
            continue;
        end

        fprintf('\n====================================================\n');
        fprintf('%s | %s\n', measureNames{m}, thisComp);

        %% Step 1: Random-effects structure comparison using REML
        formula_RI = 'Y ~ Days * DeviantType + Exposure + (1 | Subjects)';
        formula_RS = 'Y ~ Days * DeviantType + Exposure + (1 + Days | Subjects)';

        selectedRandom = 'RandomInterceptOnly';
        randomTerm = '(1 | Subjects)';
        randomStatus = 'OK';

        pRandom = NaN;
        logLik_RI = NaN;
        logLik_RS = NaN;
        AIC_RI = NaN;
        AIC_RS = NaN;
        BIC_RI = NaN;
        BIC_RS = NaN;

        try
            lme_RI = fitlme(Tc, formula_RI, ...
                'FitMethod', 'REML', 'DummyVarCoding', dummyCoding);

            logLik_RI = lme_RI.LogLikelihood;
            AIC_RI = lme_RI.ModelCriterion.AIC;
            BIC_RI = lme_RI.ModelCriterion.BIC;

            lme_RS = fitlme(Tc, formula_RS, ...
                'FitMethod', 'REML', 'DummyVarCoding', dummyCoding);

            logLik_RS = lme_RS.LogLikelihood;
            AIC_RS = lme_RS.ModelCriterion.AIC;
            BIC_RS = lme_RS.ModelCriterion.BIC;

            cmpRandom = compare(lme_RI, lme_RS);
            pRandom = get_compare_pvalue(cmpRandom);

            if ~isnan(pRandom) && pRandom < 0.05
                selectedRandom = 'RandomInterceptPlusDaysSlope';
                randomTerm = '(1 + Days | Subjects)';
            end

        catch ME
            randomStatus = ['ComparisonFailed: ' ME.message];
            selectedRandom = 'RandomInterceptOnly';
            randomTerm = '(1 | Subjects)';
        end

        deltaAIC_RSminusRI = AIC_RS - AIC_RI;
        deltaBIC_RSminusRI = BIC_RS - BIC_RI;

        randomRows(rRandom,:) = { ...
            measureNames{m}, thisComp, height(Tc), ...
            formula_RI, formula_RS, ...
            logLik_RI, logLik_RS, ...
            AIC_RI, AIC_RS, deltaAIC_RSminusRI, ...
            BIC_RI, BIC_RS, deltaBIC_RSminusRI, ...
            pRandom, selectedRandom, randomStatus};
        rRandom = rRandom + 1;

        fprintf('Random-effects comparison: p = %.4f; selected = %s\n', ...
            pRandom, selectedRandom);

        %% Step 2: Exposure comparison using ML
        formula_noExp = sprintf('Y ~ Days * DeviantType + %s', randomTerm);
        formula_Exp   = sprintf('Y ~ Days * DeviantType + Exposure + %s', randomTerm);

        exposureStatus = 'OK';
        selectedExposure = 'NoExposure';

        pExposure = NaN;
        logLik_noExp = NaN;
        logLik_Exp = NaN;
        AIC_noExp = NaN;
        AIC_Exp = NaN;
        BIC_noExp = NaN;
        BIC_Exp = NaN;

        try
            lme_noExp = fitlme(Tc, formula_noExp, ...
                'FitMethod', 'ML', 'DummyVarCoding', dummyCoding);

            lme_Exp = fitlme(Tc, formula_Exp, ...
                'FitMethod', 'ML', 'DummyVarCoding', dummyCoding);

            logLik_noExp = lme_noExp.LogLikelihood;
            logLik_Exp   = lme_Exp.LogLikelihood;
            AIC_noExp = lme_noExp.ModelCriterion.AIC;
            AIC_Exp   = lme_Exp.ModelCriterion.AIC;
            BIC_noExp = lme_noExp.ModelCriterion.BIC;
            BIC_Exp   = lme_Exp.ModelCriterion.BIC;

            cmpExposure = compare(lme_noExp, lme_Exp);
            pExposure = get_compare_pvalue(cmpExposure);

            if ~isnan(pExposure) && pExposure < 0.05
                selectedExposure = 'WithExposure';
            end

        catch ME
            exposureStatus = ['ComparisonFailed: ' ME.message];
        end

        deltaAIC_ExpMinusNoExp = AIC_Exp - AIC_noExp;
        deltaBIC_ExpMinusNoExp = BIC_Exp - BIC_noExp;

        exposureRows(rExposure,:) = { ...
            measureNames{m}, thisComp, height(Tc), selectedRandom, ...
            formula_noExp, formula_Exp, ...
            logLik_noExp, logLik_Exp, ...
            AIC_noExp, AIC_Exp, deltaAIC_ExpMinusNoExp, ...
            BIC_noExp, BIC_Exp, deltaBIC_ExpMinusNoExp, ...
            pExposure, selectedExposure, exposureStatus};
        rExposure = rExposure + 1;

        fprintf('Exposure comparison: p = %.4f; selected = %s\n', ...
            pExposure, selectedExposure);
    end
end

%% -------------------- Convert results to tables --------------------
T_random = cell2table(randomRows, 'VariableNames', { ...
    'Measure','Component','NRows', ...
    'RandomInterceptFormula','RandomSlopeFormula', ...
    'LogLik_RI','LogLik_RS', ...
    'AIC_RI','AIC_RS','DeltaAIC_RSminusRI', ...
    'BIC_RI','BIC_RS','DeltaBIC_RSminusRI', ...
    'LRT_p','SelectedRandomEffects','Status'});

T_exposure = cell2table(exposureRows, 'VariableNames', { ...
    'Measure','Component','NRows','SelectedRandomEffects', ...
    'NoExposureFormula','ExposureFormula', ...
    'LogLik_NoExposure','LogLik_Exposure', ...
    'AIC_NoExposure','AIC_Exposure','DeltaAIC_ExpMinusNoExp', ...
    'BIC_NoExposure','BIC_Exposure','DeltaBIC_ExpMinusNoExp', ...
    'LRT_p','SelectedExposureModel','Status'});

%% -------------------- Export results --------------------
writetable(T_random, outFile, 'Sheet', 'RandomEffectsComparison');
writetable(T_exposure, outFile, 'Sheet', 'ExposureComparison');

fprintf('\nModel-comparison results saved to:\n%s\n', outFile);

%% ============================================================
% Local functions
% ============================================================

function T = build_long_table_with_deviant(A_p2, A_p450, subj_exp, expMat, ...
    measureName, nDays, dayLevels, devLevels)

rows = {};
r = 1;

nSub = size(A_p2,2);
nDev = size(A_p2,3);

for isub = 1:nSub
    for iday = 1:nDays

        dayStr = num2str(iday);
        expVal = expMat(isub, iday);

        for idev = 1:nDev

            devName = devLevels{idev};

            rows(r,:) = { ...
                subj_exp(isub), dayStr, expVal, ...
                A_p2(iday,isub,idev), measureName, 'P2', devName};
            r = r + 1;

            rows(r,:) = { ...
                subj_exp(isub), dayStr, expVal, ...
                A_p450(iday,isub,idev), measureName, 'P450', devName};
            r = r + 1;
        end
    end
end

T = cell2table(rows, 'VariableNames', ...
    {'Subjects','Days','Exposure','Y','Measure','Component','DeviantType'});

T.Subjects    = categorical(T.Subjects);
T.Days        = categorical(T.Days, dayLevels);
T.Component   = categorical(T.Component);
T.Measure     = categorical(T.Measure);
T.DeviantType = categorical(T.DeviantType, devLevels);

% Remove rows with missing outcome values. Exposure missingness is handled
% before model fitting so that both candidate models use identical rows.
T = T(~isnan(T.Y), :);

end


function p = get_compare_pvalue(cmpTbl)

p = NaN;
varNames = cmpTbl.Properties.VariableNames;

if any(strcmp(varNames, 'pValue'))
    vals = cmpTbl.pValue;
    p = vals(end);
elseif any(strcmp(varNames, 'pValue_LRT'))
    vals = cmpTbl.pValue_LRT;
    p = vals(end);
else
    idx = find(contains(lower(string(varNames)), 'pvalue'), 1);
    if ~isempty(idx)
        vals = cmpTbl.(varNames{idx});
        p = vals(end);
    end
end

end
