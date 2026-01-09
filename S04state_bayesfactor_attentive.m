%% ======================================================
%  ATTEND (Attend) condition — Mixed ANOVA + BF10 (BIC)
%  - No plotting
%  - Components:
%       N2b (central):  Amp 230–280 ms (Diff),   Lat 200–310 ms (DEV, min)
%       P3b (parietal): Amp 360–410 ms (Diff),   Lat 340–460 ms (DEV, max)
%  - Amplitude analyses: difference waves (deviant ? standard)
%  - Latency analyses: deviant responses (field = DEV_avg)
%  - Electrodes:
%       CN_all (central):  [29 30 36 37 5 6 12 11 87 104 105 111]
%       PR_all (parietal): [47 52 59 60 61 62 72 78 85 91 92 98]
%  - Output: F, df1, df2, p, Estimate, SE, CI, BF10, Evidence
%  - Model: Value ~ Group*Time + (1|Subject)
%% ======================================================

clc; clear;
output_dir = 'G:\study2\results';   % <<< 修改路径
if ~exist(output_dir,'dir'), mkdir(output_dir); end
cd(output_dir);

% ======================================================
% 输入数据文件
% ======================================================
files = { ...
    'S001control_ATT_pre_ATTnsubavg.mat', ...
    'S002_ATT_pre_ATTnsubavg.mat', ...
    'S001control_ATT_post_ATTnsubavg.mat', ...
    'S002_ATT_post_ATTnsubavg.mat'};

N2b_amp_win = [0.230 0.280];
P3b_amp_win = [0.360 0.410];
N2b_lat_win = [0.200 0.310];
P3b_lat_win = [0.340 0.460];
CN_all = unique([29 30 36 37 5 6 12 11 87 104 105 111]);
PR_all = unique([47 52 59 60 61 62 72 78 85 91 92 98]);

S = cell(1,4);
for md = 1:4
    S{md} = load(files{md});
end
ndev = size(S{1}.Diff_avg, 2);

PS = {}; Summary = {};

% ======================================================
% 主循环
% ======================================================
for idev = 1:ndev
    nCon = min(size(S{1}.Diff_avg,1), size(S{3}.Diff_avg,1));
    nExp = min(size(S{2}.Diff_avg,1), size(S{4}.Diff_avg,1));

    ampN2b_C_Pre = nan(nCon,1); ampN2b_C_Post = nan(nCon,1);
    ampN2b_E_Pre = nan(nExp,1); ampN2b_E_Post = nan(nExp,1);
    ampP3b_C_Pre = nan(nCon,1); ampP3b_C_Post = nan(nCon,1);
    ampP3b_E_Pre = nan(nExp,1); ampP3b_E_Post = nan(nExp,1);
    latN2b_C_Pre = nan(nCon,1); latN2b_C_Post = nan(nCon,1);
    latP3b_C_Pre = nan(nCon,1); latP3b_C_Post = nan(nCon,1);
    latN2b_E_Pre = nan(nExp,1); latN2b_E_Post = nan(nExp,1);
    latP3b_E_Pre = nan(nExp,1); latP3b_E_Post = nan(nExp,1);

    % ------------------------------------------------------
    % Control-Pre
    % ------------------------------------------------------
    for s=1:nCon
        tDiff = S{1}.Diff_avg{s,idev};
        tDev  = S{1}.DEV_avg{s,idev};
        cidx = findElectrodeIdx(tDiff.label,CN_all);
        pidx = findElectrodeIdx(tDiff.label,PR_all);
        ampN2b_C_Pre(s) = meanInWin(tDiff,cidx,N2b_amp_win);
        ampP3b_C_Pre(s) = meanInWin(tDiff,pidx,P3b_amp_win);
        [latN2b_C_Pre(s),latP3b_C_Pre(s)] = latencyFromDEV(tDev,cidx,pidx,N2b_lat_win,P3b_lat_win);
    end

    % Control-Post
    for s=1:nCon
        tDiff = S{3}.Diff_avg{s,idev};
        tDev  = S{3}.DEV_avg{s,idev};
        cidx = findElectrodeIdx(tDiff.label,CN_all);
        pidx = findElectrodeIdx(tDiff.label,PR_all);
        ampN2b_C_Post(s) = meanInWin(tDiff,cidx,N2b_amp_win);
        ampP3b_C_Post(s) = meanInWin(tDiff,pidx,P3b_amp_win);
        [latN2b_C_Post(s),latP3b_C_Post(s)] = latencyFromDEV(tDev,cidx,pidx,N2b_lat_win,P3b_lat_win);
    end

    % Experimental-Pre
    for s=1:nExp
        tDiff = S{2}.Diff_avg{s,idev};
        tDev  = S{2}.DEV_avg{s,idev};
        cidx = findElectrodeIdx(tDiff.label,CN_all);
        pidx = findElectrodeIdx(tDiff.label,PR_all);
        ampN2b_E_Pre(s) = meanInWin(tDiff,cidx,N2b_amp_win);
        ampP3b_E_Pre(s) = meanInWin(tDiff,pidx,P3b_amp_win);
        [latN2b_E_Pre(s),latP3b_E_Pre(s)] = latencyFromDEV(tDev,cidx,pidx,N2b_lat_win,P3b_lat_win);
    end

    % Experimental-Post
    for s=1:nExp
        tDiff = S{4}.Diff_avg{s,idev};
        tDev  = S{4}.DEV_avg{s,idev};
        cidx = findElectrodeIdx(tDiff.label,CN_all);
        pidx = findElectrodeIdx(tDiff.label,PR_all);
        ampN2b_E_Post(s) = meanInWin(tDiff,cidx,N2b_amp_win);
        ampP3b_E_Post(s) = meanInWin(tDiff,pidx,P3b_amp_win);
        [latN2b_E_Post(s),latP3b_E_Post(s)] = latencyFromDEV(tDev,cidx,pidx,N2b_lat_win,P3b_lat_win);
    end

    % ======================================================
    % 构建 LME 数据表
    % ======================================================
    buildTable = @(C_Pre,C_Post,E_Pre,E_Post,nCon,nExp) dataset( ...
        {nominal([arrayfun(@(x)sprintf('C_%03d',x),(1:nCon),'UniformOutput',false), ...
                  arrayfun(@(x)sprintf('C_%03d',x),(1:nCon),'UniformOutput',false), ...
                  arrayfun(@(x)sprintf('E_%03d',x),(1:nExp),'UniformOutput',false), ...
                  arrayfun(@(x)sprintf('E_%03d',x),(1:nExp),'UniformOutput',false)])','Subject'}, ...
        {nominal([repmat({'Control'},2*nCon,1); repmat({'Sleep'},2*nExp,1)]),'Group'}, ...
        {nominal([repmat({'Pre'},nCon,1); repmat({'Post'},nCon,1); ...
                  repmat({'Pre'},nExp,1); repmat({'Post'},nExp,1)]),'Time'}, ...
        {double([C_Pre;C_Post;E_Pre;E_Post]),'Value'});

    T_ampN2b = buildTable(ampN2b_C_Pre,ampN2b_C_Post,ampN2b_E_Pre,ampN2b_E_Post,nCon,nExp);
    T_ampP3b = buildTable(ampP3b_C_Pre,ampP3b_C_Post,ampP3b_E_Pre,ampP3b_E_Post,nCon,nExp);
    T_latN2b = buildTable(latN2b_C_Pre,latN2b_C_Post,latN2b_E_Pre,latN2b_E_Post,nCon,nExp);
    T_latP3b = buildTable(latP3b_C_Pre,latP3b_C_Post,latP3b_E_Pre,latP3b_E_Post,nCon,nExp);

    % ======================================================
    % Mixed LME + ANOVA + BF10 + CI
    % ======================================================
    Summary = [Summary;
        extractStats(T_ampN2b,idev,'Amplitude_N2b');
        extractStats(T_ampP3b,idev,'Amplitude_P3b');
        extractStats(T_latN2b,idev,'Latency_N2b');
        extractStats(T_latP3b,idev,'Latency_P3b')];

    % ======================================================
    % 每被试宽表
    % ======================================================
    for s=1:nCon
        PS(end+1,:) = {idev,sprintf('C_%03d',s),'Control', ...
            ampN2b_C_Pre(s),ampN2b_C_Post(s),ampP3b_C_Pre(s),ampP3b_C_Post(s), ...
            latN2b_C_Pre(s),latN2b_C_Post(s),latP3b_C_Pre(s),latP3b_C_Post(s)};
    end
    for s=1:nExp
        PS(end+1,:) = {idev,sprintf('E_%03d',s),'Sleep', ...
            ampN2b_E_Pre(s),ampN2b_E_Post(s),ampP3b_E_Pre(s),ampP3b_E_Post(s), ...
            latN2b_E_Pre(s),latN2b_E_Post(s),latP3b_E_Pre(s),latP3b_E_Post(s)};
    end
end

% ======================================================
% 导出 CSV
% ======================================================
fid = fopen(fullfile(output_dir,'perSubject_metrics_wide_attend.csv'),'w');
fprintf(fid,'DeviantIdx,Subject,Group,Amp_N2b_Pre,Amp_N2b_Post,Amp_P3b_Pre,Amp_P3b_Post,Lat_N2b_Pre_ms,Lat_N2b_Post_ms,Lat_P3b_Pre_ms,Lat_P3b_Post_ms\n');
for i=1:size(PS,1)
    fprintf(fid,'%d,%s,%s,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n',PS{i,1},PS{i,2},PS{i,3},PS{i,4},PS{i,5},PS{i,6},PS{i,7},PS{i,8},PS{i,9},PS{i,10},PS{i,11});
end
fclose(fid);

fid = fopen(fullfile(output_dir,'ANOVA_GroupXTime_attend_summary.csv'),'w');
fprintf(fid,'DeviantIdx,DV,F,df1,df2,p,Estimate,SE,CI_Lower,CI_Upper,BF10,Evidence\n');
for i=1:size(Summary,1)
    fprintf(fid,'%d,%s,%.4f,%.2f,%.2f,%.5f,%.5f,%.5f,%.5f,%.5f,%.4f,%s\n',Summary{i,1},Summary{i,2},Summary{i,3},Summary{i,4},Summary{i,5},Summary{i,6},Summary{i,7},Summary{i,8},Summary{i,9},Summary{i,10},Summary{i,11},Summary{i,12});
end
fclose(fid);

fprintf('\n? Exported:\n  perSubject_metrics_wide_attend.csv\n  ANOVA_GroupXTime_attend_summary.csv\n');

%% ======================================================
% 辅助函数
% ======================================================
function fidx = findElectrodeIdx(labels, list)
fidx = zeros(1,numel(list));
for ii=1:numel(list)
    num = list(ii);
    k = find(strcmp(labels, sprintf('E%d', num)), 1);
    if isempty(k), k = find(strcmp(labels, sprintf('%d', num)), 1); end
    if isempty(k), k = num; end
    fidx(ii) = k;
end
end

function val = meanInWin(tl,fidx,win)
tsel = tl.time >= win(1) & tl.time <= win(2);
val = nanmean(tl.avg(fidx,tsel),'all');
end

function [latN2b,latP3b] = latencyFromDEV(tl,cidx,pidx,winN2b,winP3b)
waveC = nanmean(tl.avg(cidx,:),1);
tsel = tl.time >= winN2b(1) & tl.time <= winN2b(2);
seg = waveC(tsel); segt = tl.time(tsel);
if isempty(seg), latN2b=NaN; else [~,kmin]=min(seg); latN2b=segt(kmin)*1000; end

waveP = nanmean(tl.avg(pidx,:),1);
tsel = tl.time >= winP3b(1) & tl.time <= winP3b(2);
seg = waveP(tsel); segt = tl.time(tsel);
if isempty(seg), latP3b=NaN; else [~,kmax]=max(seg); latP3b=segt(kmax)*1000; end
end

function out = extractStats(T,idev,label)
LME = fitlme(T,'Value ~ Group*Time + (1|Subject)');
A = anova(LME);
ridx = find(strcmp(A.Term,'Group:Time') | strcmp(A.Term,'Time:Group'),1);
if isempty(ridx)
    Fval=NaN; pval=NaN; df1=NaN; df2=NaN;
else
    Fval=A.FStat(ridx); pval=A.pValue(ridx); df1=A.DF1(ridx); df2=A.DF2(ridx);
end

coef = dataset2table(LME.Coefficients);
idx = find(contains(coef.Name,'Group') & contains(coef.Name,'Time'));
if ~isempty(idx)
    est = coef.Estimate(idx);
    se  = coef.SE(idx);
    ciL = coef.Lower(idx);
    ciU = coef.Upper(idx);
else
    est = NaN; se = NaN; ciL = NaN; ciU = NaN;
end

LME_red = fitlme(T,'Value ~ Group + Time + (1|Subject)');
BF10 = exp((LME_red.ModelCriterion.BIC - LME.ModelCriterion.BIC)/2);
labelBF = interpretBF(BF10);
out = {idev,label,Fval,df1,df2,pval,est,se,ciL,ciU,BF10,labelBF};
end

function txt = interpretBF(BF10)
if isnan(BF10)
    txt='N/A';
elseif BF10>=100
    txt='Extreme evidence for interaction';
elseif BF10>=30
    txt='Very strong evidence for interaction';
elseif BF10>=10
    txt='Strong evidence for interaction';
elseif BF10>=3
    txt='Moderate evidence for interaction';
elseif BF10>=1
    txt='Anecdotal evidence for interaction';
else
    txt='Evidence for no interaction';
end
end
