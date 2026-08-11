%% ============================================================
% SL06_day_main_effect_withExposure_DeviantType_4days_NoFDR_BonfPairwise.m
%
% 适用于：
%   - Day/Night = 4
%   - 被试约 20 人
%   - DeviantType 作为 fixed effect
%   - 不再对 Small/Large deviant 分别建模
%
% 模型比较：
%   Model 0:
%       Y ~ Days + DeviantType + (1|Subjects)
%
%   Model 1:
%       Y ~ Days + DeviantType + Exposure + (1|Subjects)
%
%   使用 ML 比较两个模型；
%   若 Exposure 模型显著改善拟合，则选择带 Exposure 的模型；
%   否则选择不带 Exposure 的模型。
%
% 后续分析：
%   使用选定模型，并用 REML 重拟合：
%       Y ~ Days + DeviantType (+ Exposure) + (1|Subjects)
%
% 多重比较校正：
%   - 不对 omnibus model effects 做 FDR 校正
%   - 不对 Night 1 one-sample tests 做 FDR 校正
%   - 只对 planned night pairwise comparisons 做 Bonferroni correction
%
% 输出：
%   ERP_stats_DayMainEffect_DeviantType_ModelCompare_4days_NoFDR_BonfPairwise.xlsx
% ============================================================

clc; clear; close all;

%% -------------------- 基本设置 --------------------
nDaysExpected = 4;
nSubExpected  = 20;

dayLevels = arrayfun(@num2str, 1:nDaysExpected, 'UniformOutput', false);
devLevels = {'Small','Large'};

measureNames = {'Amplitude','Latency'};
componentLabels = {'P2','P450'};

%% -------------------- 路径设置 --------------------
resultDir = 'G:\study2\002\sleep\2ndanalysis\results';
cd(resultDir);

matFile = fullfile(resultDir, 'erp_statisticsdata_simple.mat');
exposureFile = 'G:\study2\002\sleep\2ndanalysis\exposure_dur.xlsx';

%% -------------------- 读取 ERP 数据 --------------------
load(matFile, 'amplitude_mmn', 'amplitude_p3', 'latency_mmn', 'latency_p3');

%% -------------------- 读取 exposure duration --------------------
expTbl = readtable(exposureFile);

subj_exp = expTbl{:,1};
expMat   = expTbl{:,2:end};

if size(expMat,2) ~= nDaysExpected
    error('Exposure 文件应包含 %d 个 day/night 列。当前检测到 %d 列。', ...
        nDaysExpected, size(expMat,2));
end

nSub_exp = size(expMat,1);

if nSub_exp ~= nSubExpected
    warning('Exposure 文件中的被试数不是 %d，而是 %d。请确认是否符合预期。', ...
        nSubExpected, nSub_exp);
end

%% -------------------- 检查 ERP 数据维度 --------------------
[nNight1, nSub1, nDev1] = size(amplitude_mmn);
[nNight2, nSub2, nDev2] = size(amplitude_p3);
[nNight3, nSub3, nDev3] = size(latency_mmn);
[nNight4, nSub4, nDev4] = size(latency_p3);

if ~(nNight1 == nDaysExpected && nNight2 == nDaysExpected && ...
     nNight3 == nDaysExpected && nNight4 == nDaysExpected)

    error(['ERP 数据 night 维度不是 %d，请检查。当前维度分别为：', ...
           'amplitude_mmn=%d, amplitude_p3=%d, latency_mmn=%d, latency_p3=%d'], ...
           nDaysExpected, nNight1, nNight2, nNight3, nNight4);
end

if ~(nSub1==nSub_exp && nSub2==nSub_exp && nSub3==nSub_exp && nSub4==nSub_exp)
    error('ERP 数据被试数与 exposure 文件中的被试数不一致。');
end

if ~(nDev1==2 && nDev2==2 && nDev3==2 && nDev4==2)
    error('ERP 数据第 3 维应为 2，对应 Small/Large deviant。');
end

%% -------------------- latency 时间校正 --------------------
% 如果 latency_mmn / latency_p3 是基于 epoch 起点，例如 epoch = -0.2 到 0.8，
% 则减去 0.2 后变成相对刺激起点的 latency。
latency_mmn = latency_mmn - 0.2;
latency_p3  = latency_p3  - 0.2;

%% -------------------- 整理成长表 --------------------
T_amp = build_long_table_with_deviant( ...
    amplitude_mmn, amplitude_p3, subj_exp, expMat, ...
    'Amplitude', nDaysExpected, dayLevels, devLevels);

T_lat = build_long_table_with_deviant( ...
    latency_mmn, latency_p3, subj_exp, expMat, ...
    'Latency', nDaysExpected, dayLevels, devLevels);

T_all = {T_amp, T_lat};

%% -------------------- 统计分析 --------------------
allFixedRows   = {};
allDayRows     = {};
allModelRows   = {};
allPosthocRows = {};
allNight1Rows  = {};

rFixed   = 1;
rDay     = 1;
rModel   = 1;
rPosthoc = 1;
rNight1  = 1;

AOV_ALL = table();

for m = 1:2

    Tm = T_all{m};
    comps = categories(Tm.Component);

    for ic = 1:numel(comps)

        thisComp = comps{ic};

        Tc0 = Tm(Tm.Component == thisComp, :);

        Tc0.Subjects    = categorical(Tc0.Subjects);
        Tc0.Days        = categorical(Tc0.Days, dayLevels);
        Tc0.DeviantType = categorical(Tc0.DeviantType, devLevels);
        Tc0.Component   = categorical(Tc0.Component);

        fprintf('\n====================================================\n');
        fprintf('%s | %s\n', measureNames{m}, thisComp);

        %% ---------- Night 1 amplitude > 0: one-sample t-test ----------
        % 这里把 Small 和 Large 放在一起，检验 Night 1 的平均 amplitude 是否 > 0。
        % 不做 FDR 校正，只输出原始 p_raw。
        if strcmp(measureNames{m}, 'Amplitude')

            Tn1 = Tc0(Tc0.Days == '1', :);
            y_n1 = Tn1.Y;
            y_n1 = y_n1(~isnan(y_n1));

            if ~isempty(y_n1)

                [~, p_one, ci_one, stats_one] = ttest(y_n1, 0, ...
                    'Tail', 'right', 'Alpha', 0.05);

                n_n1    = numel(y_n1);
                mean_n1 = mean(y_n1, 'omitnan');
                sd_n1   = std(y_n1, 'omitnan');

                if sd_n1 > 0
                    d_n1 = mean_n1 / sd_n1;
                else
                    d_n1 = NaN;
                end

                allNight1Rows(rNight1,:) = { ...
                    measureNames{m}, ...
                    thisComp, ...
                    n_n1, ...
                    mean_n1, ...
                    sd_n1, ...
                    stats_one.df, ...
                    stats_one.tstat, ...
                    p_one, ...
                    ci_one(1), ...
                    ci_one(2), ...
                    d_n1};

                rNight1 = rNight1 + 1;
            end
        end

        %% ---------- 模型比较：有无 Exposure ----------
        % 模型比较必须使用同一批数据，所以这里去掉 Y 或 Exposure 缺失的行。
        Tc_compare = Tc0(~isnan(Tc0.Y) & ~isnan(Tc0.Exposure), :);

        if height(Tc_compare) < 10
            warning('%s | %s 可用于模型比较的数据太少，跳过。', measureNames{m}, thisComp);
            continue;
        end

        formula_noExp = 'Y ~ Days + DeviantType + (1|Subjects)';
        formula_Exp   = 'Y ~ Days + DeviantType + Exposure + (1|Subjects)';

        lme_noExp_ML = fitlme(Tc_compare, formula_noExp, 'FitMethod', 'ML');
        lme_Exp_ML   = fitlme(Tc_compare, formula_Exp,   'FitMethod', 'ML');

        cmpTbl = compare(lme_noExp_ML, lme_Exp_ML);

        [p_model, deltaAIC, deltaBIC] = extract_model_compare_info(cmpTbl);

        if cmpTbl(2,8).pValue < 0.05
            selectedModel = 'WithExposure';
            selectedFormula = formula_Exp;
        else
            selectedModel = 'NoExposure';
            selectedFormula = formula_noExp;
        end

        fprintf('Model comparison: p = %.4f, selected model = %s\n', ...
            cmpTbl(2,8).pValue, selectedModel);

        allModelRows(rModel,:) = { ...
            measureNames{m}, ...
            thisComp, ...
            p_model, ...
            deltaAIC, ...
            deltaBIC, ...
            selectedModel};

        rModel = rModel + 1;

        %% ---------- 用选定模型重新整理数据 ----------
        % 如果最终模型不含 Exposure，可以保留 Exposure 缺失但 Y 有效的数据。
        % 如果最终模型含 Exposure，则必须去掉 Exposure 缺失。
        if strcmp(selectedModel, 'WithExposure')
            Tc = Tc0(~isnan(Tc0.Y) & ~isnan(Tc0.Exposure), :);
        else
            Tc = Tc0(~isnan(Tc0.Y), :);
        end

        Tc.Subjects    = categorical(Tc.Subjects);
        Tc.Days        = categorical(Tc.Days, dayLevels);
        Tc.DeviantType = categorical(Tc.DeviantType, devLevels);

        %% ---------- 主模型：REML ----------
        lme = fitlme(Tc, selectedFormula, 'FitMethod', 'REML');

        %% ---------- ANOVA ----------
        aovTbl = anova(lme, 'DFMethod', 'Satterthwaite');
        aovOut = convert_anova_to_table(aovTbl);

        aovOut = add_effect_size_to_anova(aovOut);

        nRow = size(aovOut, 1);
        aovOut.Measure       = repmat({measureNames{m}}, nRow, 1);
        aovOut.Component     = repmat({thisComp}, nRow, 1);
        aovOut.SelectedModel = repmat({selectedModel}, nRow, 1);

        if isempty(AOV_ALL)
            AOV_ALL = aovOut;
        else
            AOV_ALL = [AOV_ALL; aovOut];
        end

        %% ---------- fixed effects ----------
        [beta,~,st] = fixedEffects(lme, 'DFMethod', 'Satterthwaite');
        CI = coefCI(lme, 'Alpha', 0.05, 'DFMethod', 'Satterthwaite');

        for k = 1:numel(beta)

            allFixedRows(rFixed,:) = { ...
                measureNames{m}, ...
                thisComp, ...
                selectedModel, ...
                char(st.Name{k}), ...
                round(double(beta(k)),3), ...
                round(double(st.SE(k)),3), ...
                round(double(st.DF(k)),3), ...
                round(double(st.tStat(k)),3), ...
                round(double(st.pValue(k)),3), ...
                round(double(CI(k,1)),3), ...
                round(double(CI(k,2)),3)};

            rFixed = rFixed + 1;
        end

        %% ---------- Day 主效应 ----------
        dayRow = find_effect_row(aovOut, 'Days');

        if isempty(dayRow)
            warning('未在 ANOVA 表中找到 Days 行: %s | %s', measureNames{m}, thisComp);
        else
            [Fval, df1, df2, pval] = extract_effect_values(aovOut, dayRow);
            eta_day = calc_partial_eta2(Fval, df1, df2);

            allDayRows(rDay,:) = { ...
                measureNames{m}, ...
                thisComp, ...
                selectedModel, ...
                df1, ...
                df2, ...
                Fval, ...
                pval, ...
                eta_day};

            rDay = rDay + 1;

            fprintf('Day main effect: F(%s, %s) = %.3f, p = %.4f, eta_p^2 = %.3f\n', ...
                num2str(df1), num2str(df2), Fval, pval, eta_day);
        end

        %% ---------- planned comparisons: Day2/3/4 vs Day1 ----------
        posthocTbl = run_day_planned_comparisons_selected_model(Tc, selectedFormula, nDaysExpected);

        for rr = 1:size(posthocTbl,1)

            allPosthocRows(rPosthoc,:) = { ...
                measureNames{m}, ...
                thisComp, ...
                selectedModel, ...
                char(posthocTbl.Comparison(rr)), ...
                double(posthocTbl.Estimate(rr)), ...
                double(posthocTbl.SE(rr)), ...
                double(posthocTbl.DF(rr)), ...
                double(posthocTbl.t(rr)), ...
                double(posthocTbl.p_raw(rr)), ...
                double(posthocTbl.r_effect(rr))};

            rPosthoc = rPosthoc + 1;
        end
    end
end

%% -------------------- 结果表整理 --------------------
T_model = cell2table(allModelRows, 'VariableNames', ...
    {'Measure','Component','ModelCompare_p','DeltaAIC_ExpMinusNoExp','DeltaBIC_ExpMinusNoExp','SelectedModel'});

T_fixed = cell2table(allFixedRows, 'VariableNames', ...
    {'Measure','Component','SelectedModel','Effect','Estimate','SE','DF','t','p','CI_Lower','CI_Upper'});

T_day = cell2table(allDayRows, 'VariableNames', ...
    {'Measure','Component','SelectedModel','DF1','DF2','F','p','PartialEta2'});

if isempty(allPosthocRows)
    T_posthoc = table();
else
    T_posthoc = cell2table(allPosthocRows, 'VariableNames', ...
        {'Measure','Component','SelectedModel','Comparison','Estimate','SE','DF','t','p_raw','r_effect'});
end

%% -------------------- Bonferroni 校正：仅 planned night pairwise comparisons --------------------
if ~isempty(T_posthoc)

    % 只对每个 Measure × Component 内的 3 个 planned comparisons 做 Bonferroni:
    % Day2 vs Day1, Day3 vs Day1, Day4 vs Day1
    T_posthoc.p_bonf = nan(height(T_posthoc),1);

    for i = 1:height(T_posthoc)

        idxGroup = strcmp(T_posthoc.Measure, T_posthoc.Measure{i}) & ...
                   strcmp(T_posthoc.Component, T_posthoc.Component{i});

        nCmp = sum(idxGroup);  % 通常为 3

        T_posthoc.p_bonf(i) = min(T_posthoc.p_raw(i) * nCmp, 1);

    end

    % planned comparisons 仍然只在对应 Days 主效应原始 p < .05 时保留
    keepMask = false(height(T_posthoc),1);

    for i = 1:height(T_posthoc)

        idxDay = strcmp(T_day.Measure, T_posthoc.Measure{i}) & ...
                 strcmp(T_day.Component, T_posthoc.Component{i});

        if any(idxDay) && T_day.p(find(idxDay,1)) < 0.05
            keepMask(i) = true;
        end
    end

    T_posthoc = T_posthoc(keepMask,:);
end

%% -------------------- Night 1 amplitude > 0 单样本 t 检验结果 --------------------
if isempty(allNight1Rows)

    T_night1 = table();

else

    T_night1 = cell2table(allNight1Rows, 'VariableNames', ...
        {'Measure','Component','N','Mean','SD','DF','t','p_raw','CI_Lower','CI_Upper','Cohens_d'});

end

%% -------------------- 导出 Excel --------------------
outFile = fullfile(resultDir, ...
    'ERP_stats_DayMainEffect_DeviantType_ModelCompare_4days_NoFDR_BonfPairwise.xlsx');

writetable(T_model, outFile, 'Sheet', 'ModelComparison');
writetable(T_fixed, outFile, 'Sheet', 'FixedEffects');
writetable(AOV_ALL, outFile, 'Sheet', 'ANOVA');
writetable(T_day, outFile, 'Sheet', 'DayMainEffect');

if ~isempty(T_posthoc)
    writetable(T_posthoc, outFile, 'Sheet', 'PostHoc_DayVsDay1_Bonf');
end

if ~isempty(T_night1)
    writetable(T_night1, outFile, 'Sheet', 'Night1_Amplitude_gt0');
end

fprintf('\n统计结果已保存到：%s\n', outFile);

%% -------------------- 绘图 --------------------
plot_day_change_raincloud_deviant(T_amp, 'Amplitude', T_posthoc, ...
    fullfile(resultDir, 'ERP_Amplitude_dayChange_DeviantType_4days_NoFDR_BonfPairwise.tif'), ...
    nDaysExpected, dayLevels);

plot_day_change_raincloud_deviant(T_lat, 'Latency', T_posthoc, ...
    fullfile(resultDir, 'ERP_Latency_dayChange_DeviantType_4days_NoFDR_BonfPairwise.tif'), ...
    nDaysExpected, dayLevels);

fprintf('\n所有图已导出完成。\n');


%% ============================================================
% 局部函数
% ============================================================

function T = build_long_table_with_deviant(A_mmn, A_p3, subj_exp, expMat, ...
    measureName, nDays, dayLevels, devLevels)

rows = {};
r = 1;

nSub = size(A_mmn,2);
nDev = size(A_mmn,3);

for isub = 1:nSub

    for iday = 1:nDays

        dayStr = num2str(iday);
        expVal = expMat(isub, iday);

        for idev = 1:nDev

            devName = devLevels{idev};

            % P2
            rows(r,:) = { ...
                subj_exp(isub), ...
                dayStr, ...
                expVal, ...
                A_mmn(iday,isub,idev), ...
                measureName, ...
                'P2', ...
                devName};
            r = r + 1;

            % P450
            rows(r,:) = { ...
                subj_exp(isub), ...
                dayStr, ...
                expVal, ...
                A_p3(iday,isub,idev), ...
                measureName, ...
                'P450', ...
                devName};
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

% 这里只删除 Y 缺失。
% Exposure 缺失是否删除，放到模型比较和最终模型阶段处理。
T = T(~isnan(T.Y), :);

end


function [p_model, deltaAIC, deltaBIC] = extract_model_compare_info(cmpTbl)

p_model  = NaN;
deltaAIC = NaN;
deltaBIC = NaN;

try
    if any(strcmp(cmpTbl.Properties.VariableNames, 'pValue'))
        pvals = cmpTbl.pValue;
        p_model = pvals(end);
    elseif any(strcmp(cmpTbl.Properties.VariableNames, 'pValue_LRT'))
        pvals = cmpTbl.pValue_LRT;
        p_model = pvals(end);
    end
catch
    p_model = NaN;
end

try
    if any(strcmp(cmpTbl.Properties.VariableNames, 'AIC'))
        deltaAIC = cmpTbl.AIC(end) - cmpTbl.AIC(1);
    end
catch
    deltaAIC = NaN;
end

try
    if any(strcmp(cmpTbl.Properties.VariableNames, 'BIC'))
        deltaBIC = cmpTbl.BIC(end) - cmpTbl.BIC(1);
    end
catch
    deltaBIC = NaN;
end

end


function posthocTbl = run_day_planned_comparisons_selected_model(Tc, selectedFormula, nDays)

lme = fitlme(Tc, selectedFormula, 'FitMethod', 'REML');

[beta,~,st] = fixedEffects(lme, 'DFMethod', 'Satterthwaite');

nCmp = nDays - 1;

cmpNames    = cell(nCmp,1);
effectNames = cell(nCmp,1);

for i = 1:nCmp
    targetDay = i + 1;
    cmpNames{i}    = sprintf('Day%d vs Day1', targetDay);
    effectNames{i} = sprintf('Days_%d', targetDay);
end

Estimate = nan(nCmp,1);
SE       = nan(nCmp,1);
DF       = nan(nCmp,1);
tval     = nan(nCmp,1);
p_raw    = nan(nCmp,1);
r_effect = nan(nCmp,1);

for i = 1:nCmp

    idx = strcmp(st.Name, effectNames{i});

    if any(idx)
        Estimate(i) = beta(idx);
        SE(i)       = st.SE(idx);
        DF(i)       = st.DF(idx);
        tval(i)     = st.tStat(idx);
        p_raw(i)    = st.pValue(idx);
        r_effect(i) = calc_r_from_t(tval(i), DF(i));
    else
        warning('未找到固定效应项：%s。请检查 Days 的 reference level 是否为 Day1。', effectNames{i});
    end
end

posthocTbl = table(categorical(cmpNames(:)), Estimate, SE, DF, tval, p_raw, r_effect, ...
    'VariableNames', {'Comparison','Estimate','SE','DF','t','p_raw','r_effect'});

end


function plot_day_change_raincloud_deviant(T, measureName, T_posthoc, outName, nDays, dayLevels)

componentLabels = {'P2','P450'};
devLevels = {'Small','Large'};

col_violin = [170 210 235]/255;
col_points = [0.23 0.35 0.47];
col_mean   = [0.05 0.05 0.05];
col_line   = [0.18 0.18 0.18];

figure('Position',[100 100 600 300]);

ax = cell(1,2);

for i = 1:2

    ax{i} = subplot(1,2,i);
    hold on;

    compName = componentLabels{i};
    Tc = T(T.Component == compName, :);

    Tc.Subjects    = categorical(Tc.Subjects);
    Tc.Days        = categorical(Tc.Days, dayLevels);
    Tc.DeviantType = categorical(Tc.DeviantType, devLevels);

    violinWidth = 0.20;
    jitterWidth = 0.05;

    allY = [];

    for d = 1:nDays

        dayStr = num2str(d);

        for idev = 1:2

            devName = devLevels{idev};

            if idev == 1
                xBase = d - 0.13;
            else
                xBase = d + 0.2;
            end

            yy = Tc.Y(Tc.Days == dayStr & Tc.DeviantType == devName);
            yy = yy(~isnan(yy));

            allY = [allY; yy(:)];

            if isempty(yy)
                continue;
            end

            %% half violin
            if numel(unique(yy)) > 1
                try
                    [f, yi] = ksdensity(yy, 'Function', 'pdf');
                    f = f ./ max(f) * violinWidth;

                    xv = [xBase - f, repmat(xBase, 1, numel(f))];
                    yv = [yi, fliplr(yi)];

                    fill(xv, yv, col_violin, ...
                        'FaceAlpha', 0.65, ...
                        'EdgeColor', 'none');
                catch
                end
            end

            %% jittered points
            rng(100 + d*10 + idev);
            xx = xBase + (rand(size(yy)) - 0.5) * 2 * jitterWidth + 0.05;

            scatter(xx, yy, 18, ...
                'MarkerFaceColor', col_points, ...
                'MarkerEdgeColor', 'none', ...
                'MarkerFaceAlpha', 0.35);

            %% mean ± SEM
            mu  = mean(yy, 'omitnan');
            sem = std(yy, 'omitnan') / sqrt(sum(~isnan(yy)));

            errorbar(xBase + 0.02, mu, sem, ...
                'Color', col_mean, ...
                'LineStyle', 'none', ...
                'LineWidth', 1.3, ...
                'CapSize', 6);

            plot([xBase-0.04 xBase+0.08], [mu mu], '-', ...
                'Color', col_mean, ...
                'LineWidth', 2.2);
        end
    end

    %% 自动 y 轴范围
    if isempty(allY)

        yl = [0 1];

    else

        yMin = min(allY);
        yMax = max(allY);
        yRange = yMax - yMin;

        if yRange == 0
            yRange = max(abs(yMax), 1) * 0.2;
        end

        padLow  = 0.08 * yRange;
        padHigh = 0.22 * yRange;

        yl = [yMin - padLow, yMax + padHigh];
    end

    ylim(yl);

    %% 显著性标记：使用 Bonferroni-corrected p
    if ~isempty(T_posthoc)

        Tsub = T_posthoc(strcmp(T_posthoc.Measure, measureName) & ...
                         strcmp(T_posthoc.Component, compName), :);

        if ~isempty(Tsub)

            yTop  = yl(2);
            ySpan = yl(2) - yl(1);

            baseY = yTop - 0.10 * ySpan;
            stepY = 0.08 * ySpan;

            compOrder = cell(nDays-1,1);
            for dd = 2:nDays
                compOrder{dd-1} = sprintf('Day%d vs Day1', dd);
            end

            nSig = 0;

            for k = 1:numel(compOrder)

                idx = strcmp(cellstr(Tsub.Comparison), compOrder{k});

                if any(idx)

                    pCorr = Tsub.p_bonf(find(idx,1));
                    starTxt = p_to_stars(pCorr);

                    if ~isempty(starTxt)

                        nSig = nSig + 1;

                        x2 = k + 1;
                        yLine = baseY + (nSig-1) * stepY;

                        plot([1 x2], [yLine yLine], '-', ...
                            'Color', col_line, ...
                            'LineWidth', 1.0);

                        text(mean([1 x2]), yLine- 0.1, starTxt, ...
                            'HorizontalAlignment', 'center', ...
                            'VerticalAlignment', 'bottom', ...
                            'FontSize', 15, ...
                            'FontWeight', 'bold', ...
                            'Color', col_line);
                    end
                end
            end
        end
    end

    xlim([0.55 nDays + 0.60]);
    xticks(1:nDays);
    xticklabels(dayLevels);
    xlabel('Nights');

    if i == 1
        if strcmp(measureName, 'Amplitude')
            ylabel('Amplitude (\muV)');
       text(3.80, yl(2)-0.8, 'Small'  , 'FontSize', 12, 'Color', [0.25 0.25 0.25],'Rotation', 90);
    text(4.2, yl(2)-0.8, 'Large'  , 'FontSize', 12, 'Color', [0.25 0.25 0.25],'Rotation', 90);
        else
            ylabel('Latency (s)');
        end
    end

    title(compName, 'FontWeight', 'bold');


    set(gca, ...
        'FontSize', 15, ...
        'FontWeight', 'bold', ...
        'Box', 'off', ...
        'LineWidth', 1);

    hold off;
end

sgtitle(measureName, 'FontWeight', 'bold', 'FontSize', 20);

set(findall(gcf,'-property','FontName'), 'FontName', 'Times New Roman');

print(gcf, outName, '-dtiff', '-r600');
close(gcf);

end


function s = p_to_stars(p)

if isnan(p)
    s = '';
elseif p < 0.001
    s = '***';
elseif p < 0.01
    s = '**';
elseif p < 0.05
    s = '*';
else
    s = '';
end

end


function aovOut = convert_anova_to_table(aovTbl)

if istable(aovTbl)
    aovOut = aovTbl;
    return;
end

try
    aovOut = dataset2table(aovTbl);
    return;
catch
end

try
    aovOut = struct2table(aovTbl);
    return;
catch
end

error('无法将 anova 输出转换为 table，请检查 MATLAB 版本。');

end


function aovOut = add_effect_size_to_anova(aovOut)

nRow = size(aovOut, 1);
etaVals = nan(nRow, 1);

varNames = aovOut.Properties.VariableNames;

%% 找 F 列
Fcol = '';

for i = 1:numel(varNames)

    vn = lower(varNames{i});

    if strcmp(vn,'fstat') || strcmp(vn,'f') || contains(vn,'fstat')
        Fcol = varNames{i};
        break;
    end
end

%% 找 p 列
pcol = '';

for i = 1:numel(varNames)

    vn = lower(varNames{i});

    if strcmp(vn,'pvalue') || strcmp(vn,'p') || contains(vn,'pvalue')
        pcol = varNames{i};
        break;
    end
end

%% 找 df 列
dfCandidates = {};

for i = 1:numel(varNames)

    vn = lower(varNames{i});

    if contains(vn,'df')
        dfCandidates{end+1} = varNames{i};
    end
end

if numel(dfCandidates) < 2 || isempty(Fcol)
    aovOut.PartialEta2 = etaVals;
    return;
end

df1col = dfCandidates{1};
df2col = dfCandidates{2};

for r = 1:nRow

    Fval = safe_get_numeric(aovOut.(Fcol), r);
    df1  = safe_get_numeric(aovOut.(df1col), r);
    df2  = safe_get_numeric(aovOut.(df2col), r);

    if ~isempty(pcol)

        pval = safe_get_numeric(aovOut.(pcol), r);

        if isnan(Fval) || isnan(df1) || isnan(df2) || isnan(pval)
            etaVals(r) = NaN;
            continue;
        end
    end

    etaVals(r) = calc_partial_eta2(Fval, df1, df2);
end

aovOut.PartialEta2 = etaVals;

end


function idx = find_effect_row(aovOut, effectName)

idx = [];
varNames = aovOut.Properties.VariableNames;

candidateCols = {};

for i = 1:numel(varNames)

    vn = lower(varNames{i});

    if contains(vn, 'term') || contains(vn, 'name') || contains(vn, 'source')
        candidateCols{end+1} = varNames{i};
    end
end

if isempty(candidateCols)
    candidateCols = {varNames{1}};
end

for c = 1:numel(candidateCols)

    col = candidateCols{c};
    vals = aovOut.(col);

    try
        if iscell(vals)
            valsStr = string(vals);
        elseif iscategorical(vals)
            valsStr = string(vals);
        elseif isstring(vals)
            valsStr = vals;
        else
            valsStr = string(vals);
        end

        hit = find(strcmpi(strtrim(valsStr), effectName));

        if ~isempty(hit)
            idx = hit(1);
            return;
        end
    catch
    end
end

end


function [Fval, df1, df2, pval] = extract_effect_values(aovOut, rowIdx)

varNames = aovOut.Properties.VariableNames;

Fval = NaN;
df1  = NaN;
df2  = NaN;
pval = NaN;

%% F
for i = 1:numel(varNames)

    vn = lower(varNames{i});

    if strcmp(vn,'fstat') || strcmp(vn,'f') || contains(vn,'fstat')
        Fval = safe_get_numeric(aovOut.(varNames{i}), rowIdx);
        break;
    end
end

%% p
for i = 1:numel(varNames)

    vn = lower(varNames{i});

    if strcmp(vn,'pvalue') || strcmp(vn,'p') || contains(vn,'pvalue')
        pval = safe_get_numeric(aovOut.(varNames{i}), rowIdx);
        break;
    end
end

%% df
dfCandidates = {};

for i = 1:numel(varNames)

    vn = lower(varNames{i});

    if contains(vn,'df')
        dfCandidates{end+1} = varNames{i};
    end
end

if numel(dfCandidates) >= 1
    df1 = safe_get_numeric(aovOut.(dfCandidates{1}), rowIdx);
end

if numel(dfCandidates) >= 2
    df2 = safe_get_numeric(aovOut.(dfCandidates{2}), rowIdx);
end

end


function x = safe_get_numeric(col, idx)

try

    if isnumeric(col)
        x = double(col(idx));

    elseif iscell(col)
        x = str2double(col{idx});

    elseif isstring(col)
        x = str2double(col(idx));

    elseif iscategorical(col)
        x = str2double(string(col(idx)));

    else
        x = NaN;
    end

catch
    x = NaN;
end

end


function eta_p2 = calc_partial_eta2(Fval, df1, df2)

try

    if isnan(Fval) || isnan(df1) || isnan(df2) || df1 <= 0 || df2 <= 0
        eta_p2 = NaN;
    else
        eta_p2 = (Fval * df1) / (Fval * df1 + df2);
    end

catch
    eta_p2 = NaN;
end

end


function r = calc_r_from_t(tval, df)

try

    if isnan(tval) || isnan(df) || df <= 0
        r = NaN;
    else
        r = sign(tval) * sqrt((tval.^2) / (tval.^2 + df));
    end

catch
    r = NaN;
end

end