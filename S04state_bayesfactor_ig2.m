%% ======================================================
%  IGNORE condition — Mixed ANOVA + BF10 (BIC)
%  - No plotting, No DiD
%  - Components for SPEECH sounds:
%       MMN (Amp: 190–240 ms Diff; Lat: 150–260 ms DEV, min)
%       P3a (Amp: 250–300 ms Diff; Lat: 250–350 ms DEV, max)
%  - Amplitude analyses: difference waves (deviant ? standard)
%  - Latency analyses: deviant responses (field name = DEV_avg)
%  - Outputs: F, df1, df2, p, Estimate, SE, CI, BF10, Evidence
%  - Model: Value ~ Group*Time + (1|Subject)
%% ======================================================

clc; clear;
output_dir = 'G:\study2\results';  % <<< 修改为你的结果目录
if ~exist(output_dir, 'dir'); mkdir(output_dir); end
cd(output_dir);
fprintf('当前工作目录: %s\n', pwd);

% ======================================================
% 输入数据文件
% ======================================================
files = { ...
    'S001control_IG_pre_nsubavg.mat', ...
    'S002_IG_pre_nsubavg.mat', ...
    'S001control_IG_post_nsubavg.mat', ...
    'S002_IG_post_nsubavg.mat'};

MMN_amp_win  = [0.182 0.242];
P3a_amp_win  = [0.257 0.327];
MMN_lat_win  = [0.150 0.260];
P3a_lat_win  =  [0.250 0.350];
FR_all = unique([20 23 24 28 4 11 16 19 3 117 118 124]);

S = cell(1,4);
for md = 1:4
    S{md} = load(files{md});
end
ndev = size(S{1}.Diff_avg, 2);

PS = {}; Summary = {};

%% ======================================================
% 主循环
% ======================================================
for idev = 1:ndev
    nCon = min(size(S{1}.Diff_avg,1), size(S{3}.Diff_avg,1));
    nExp = min(size(S{2}.Diff_avg,1), size(S{4}.Diff_avg,1));

    % 初始化变量
    ampMMN_C_Pre = nan(nCon,1); ampMMN_C_Post = nan(nCon,1);
    ampP3a_C_Pre = nan(nCon,1); ampP3a_C_Post = nan(nCon,1);
    ampMMN_E_Pre = nan(nExp,1); ampMMN_E_Post = nan(nExp,1);
    ampP3a_E_Pre = nan(nExp,1); ampP3a_E_Post = nan(nExp,1);
    latMMN_C_Pre = nan(nCon,1); latMMN_C_Post = nan(nCon,1);
    latP3a_C_Pre = nan(nCon,1); latP3a_C_Post = nan(nCon,1);
    latMMN_E_Pre = nan(nExp,1); latMMN_E_Post = nan(nExp,1);
    latP3a_E_Pre = nan(nExp,1); latP3a_E_Post = nan(nExp,1);

    % ======================================================
    % 计算 amplitude (Diff) & latency (DEV)
    % ======================================================
    for s = 1:nCon
        tlD = S{1}.Diff_avg{s,idev};
        tlV = S{1}.DEV_avg{s,idev};
        fidx = findElectrodeIdx(tlD.label, FR_all);
        ampMMN_C_Pre(s) = meanInWin(tlD,fidx,MMN_amp_win);
        ampP3a_C_Pre(s) = meanInWin(tlD,fidx,P3a_amp_win);
        [latMMN_C_Pre(s),latP3a_C_Pre(s)] = latencyFromDEV(tlV,fidx,MMN_lat_win,P3a_lat_win);
    end
    for s = 1:nCon
        tlD = S{3}.Diff_avg{s,idev};
        tlV = S{3}.DEV_avg{s,idev};
        fidx = findElectrodeIdx(tlD.label, FR_all);
        ampMMN_C_Post(s) = meanInWin(tlD,fidx,MMN_amp_win);
        ampP3a_C_Post(s) = meanInWin(tlD,fidx,P3a_amp_win);
        [latMMN_C_Post(s),latP3a_C_Post(s)] = latencyFromDEV(tlV,fidx,MMN_lat_win,P3a_lat_win);
    end
    for s = 1:nExp
        tlD = S{2}.Diff_avg{s,idev};
        tlV = S{2}.DEV_avg{s,idev};
        fidx = findElectrodeIdx(tlD.label, FR_all);
        ampMMN_E_Pre(s) = meanInWin(tlD,fidx,MMN_amp_win);
        ampP3a_E_Pre(s) = meanInWin(tlD,fidx,P3a_amp_win);
        [latMMN_E_Pre(s),latP3a_E_Pre(s)] = latencyFromDEV(tlV,fidx,MMN_lat_win,P3a_lat_win);
    end
    for s = 1:nExp
        tlD = S{4}.Diff_avg{s,idev};
        tlV = S{4}.DEV_avg{s,idev};
        fidx = findElectrodeIdx(tlD.label, FR_all);
        ampMMN_E_Post(s) = meanInWin(tlD,fidx,MMN_amp_win);
        ampP3a_E_Post(s) = meanInWin(tlD,fidx,P3a_amp_win);
        [latMMN_E_Post(s),latP3a_E_Post(s)] = latencyFromDEV(tlV,fidx,MMN_lat_win,P3a_lat_win);
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

    T_ampMMN = buildTable(ampMMN_C_Pre,ampMMN_C_Post,ampMMN_E_Pre,ampMMN_E_Post,nCon,nExp);
    T_ampP3a = buildTable(ampP3a_C_Pre,ampP3a_C_Post,ampP3a_E_Pre,ampP3a_E_Post,nCon,nExp);
    T_latMMN = buildTable(latMMN_C_Pre,latMMN_C_Post,latMMN_E_Pre,latMMN_E_Post,nCon,nExp);
    T_latP3a = buildTable(latP3a_C_Pre,latP3a_C_Post,latP3a_E_Pre,latP3a_E_Post,nCon,nExp);

    % ======================================================
    % Mixed LME + ANOVA + BF10 + CI
    % ======================================================
    Summary = [Summary;
        extractStats(T_ampMMN,idev,'Amplitude_MMN');
        extractStats(T_ampP3a,idev,'Amplitude_P3a');
        extractStats(T_latMMN,idev,'Latency_MMN');
        extractStats(T_latP3a,idev,'Latency_P3a')];

    % ======================================================
    % 每被试宽表
    % ======================================================
    for s=1:nCon
        PS(end+1,:) = {idev,sprintf('C_%03d',s),'Control', ...
            ampMMN_C_Pre(s),ampMMN_C_Post(s),ampP3a_C_Pre(s),ampP3a_C_Post(s), ...
            latMMN_C_Pre(s),latMMN_C_Post(s),latP3a_C_Pre(s),latP3a_C_Post(s)};
    end
    for s=1:nExp
        PS(end+1,:) = {idev,sprintf('E_%03d',s),'Sleep', ...
            ampMMN_E_Pre(s),ampMMN_E_Post(s),ampP3a_E_Pre(s),ampP3a_E_Post(s), ...
            latMMN_E_Pre(s),latMMN_E_Post(s),latP3a_E_Pre(s),latP3a_E_Post(s)};
    end
end

% ======================================================
% 导出 CSV
% ======================================================
fid = fopen(fullfile(output_dir,'perSubject_metrics_wide_ignore.csv'),'w');
fprintf(fid,'DeviantIdx,Subject,Group,Amp_MMN_Pre,Amp_MMN_Post,Amp_P3a_Pre,Amp_P3a_Post,Lat_MMN_Pre_ms,Lat_MMN_Post_ms,Lat_P3a_Pre_ms,Lat_P3a_Post_ms\n');
for i=1:size(PS,1)
    fprintf(fid,'%d,%s,%s,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n',PS{i,1},PS{i,2},PS{i,3},PS{i,4},PS{i,5},PS{i,6},PS{i,7},PS{i,8},PS{i,9},PS{i,10},PS{i,11});
end
fclose(fid);

fid = fopen(fullfile(output_dir,'ANOVA_GroupXTime_ignore_summary.csv'),'w');
fprintf(fid,'DeviantIdx,DV,F,df1,df2,p,Estimate,SE,CI_Lower,CI_Upper,BF10,Evidence\n');
for i=1:size(Summary,1)
    fprintf(fid,'%d,%s,%.4f,%.2f,%.2f,%.5f,%.5f,%.5f,%.5f,%.5f,%.4f,%s\n',Summary{i,1},Summary{i,2},Summary{i,3},Summary{i,4},Summary{i,5},Summary{i,6},Summary{i,7},Summary{i,8},Summary{i,9},Summary{i,10},Summary{i,11},Summary{i,12});
end
fclose(fid);

fprintf('\n? Exported:\n  perSubject_metrics_wide_ignore.csv\n  ANOVA_GroupXTime_ignore_summary.csv\n');

%% ======================================================
% 辅助函数
% ======================================================
function fidx = findElectrodeIdx(labels, FR_all)
fidx = zeros(1,numel(FR_all));
for ii=1:numel(FR_all)
    num = FR_all(ii);
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

function [latMMN,latP3a] = latencyFromDEV(tl,fidx,winMMN,winP3a)
wave = nanmean(tl.avg(fidx,:),1);
tsel = tl.time >= winMMN(1) & tl.time <= winMMN(2);
seg = wave(tsel); segt = tl.time(tsel);
if isempty(seg), latMMN = NaN; else [~,kmin]=min(seg); latMMN = segt(kmin)*1000; end
tsel = tl.time >= winP3a(1) & tl.time <= winP3a(2);
seg = wave(tsel); segt = tl.time(tsel);
if isempty(seg), latP3a = NaN; else [~,kmax]=max(seg); latP3a = segt(kmax)*1000; end
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

% ? 自动识别交互项
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
