%% ======================================================
%  250–500 ms，每 50 ms 均值窗口 — Mixed ANOVA + BF10
%  - 窗口: [250–300], [300–350], [350–400], [400–450], [450–500] ms
%  - 使用 Diff_avg（Difference wave）
%  - Value ~ Group*Time + (1|Subject)
% ======================================================

clc; clear;
output_dir = 'G:\study2\results';  % <<< 修改为你的路径
if ~exist(output_dir,'dir'); mkdir(output_dir); end
cd(output_dir);

%% 输入文件
files = {
    'S001control_IG_pre_nsubavg.mat', ...
    'S002_IG_pre_nsubavg.mat', ...
    'S001control_IG_post_nsubavg.mat', ...
    'S002_IG_post_nsubavg.mat'};

FR_all = unique([20 23 24 28 4 11 16 19 3 117 118 124]);

%% 载入
S = cell(1,4);
for md = 1:4
    S{md} = load(files{md});
end
ndev = size(S{1}.Diff_avg, 2);

%% 时间窗（秒）
winList = [0.250 0.300;
           0.300 0.350;
           0.350 0.400;
           0.400 0.450;
           0.450 0.500];
nWin = size(winList,1);

%% 输出容器
PS = {};  
Summary = {};

%% =================== 主循环 ===================
for idev = 1:ndev

    nCon = size(S{1}.Diff_avg,1);
    nExp = size(S{2}.Diff_avg,1);

    % 每个窗口初始化
    C_Pre = nan(nCon, nWin);
    C_Post = nan(nCon, nWin);
    E_Pre = nan(nExp, nWin);
    E_Post = nan(nExp, nWin);

    %% === 计算每个被试 × 每窗 的均值 ===
    for w = 1:nWin
        win = winList(w,:);

        for s = 1:nCon
            tl = S{1}.Diff_avg{s,idev}; fidx = findElectrode(tl.label,FR_all);
            C_Pre(s,w)  = meanWin(tl,fidx,win);

            tl = S{3}.Diff_avg{s,idev};
            C_Post(s,w) = meanWin(tl,fidx,win);
        end
        for s = 1:nExp
            tl = S{2}.Diff_avg{s,idev}; fidx = findElectrode(tl.label,FR_all);
            E_Pre(s,w)  = meanWin(tl,fidx,win);

            tl = S{4}.Diff_avg{s,idev};
            E_Post(s,w) = meanWin(tl,fidx,win);
        end
    end

    %% ========== Mixed ANOVA + BF10 ==========
    for w = 1:nWin
        winName = sprintf('Mean_%d_%dms', round(winList(w,1)*1000), round(winList(w,2)*1000));

        T = buildTable(C_Pre(:,w),C_Post(:,w),E_Pre(:,w),E_Post(:,w),nCon,nExp);

        Stats = extractStats(T, idev, winName);
        Summary = [Summary; Stats];

        % === 每被试宽表 ===
        for s=1:nCon
            PS(end+1,:) = {idev, winName, sprintf('C_%03d',s),'Control', C_Pre(s,w),C_Post(s,w)};
        end
        for s=1:nExp
            PS(end+1,:) = {idev, winName, sprintf('E_%03d',s),'Sleep', E_Pre(s,w),E_Post(s,w)};
        end
    end
end

%% ==================== 导出 CSV =====================
fid = fopen('perSubject_250_500ms_wide.csv','w');
fprintf(fid,'Deviant,Window,Subject,Group,Pre,Post\n');
for i=1:size(PS,1)
    fprintf(fid,'%d,%s,%s,%s,%.6f,%.6f\n',PS{i,1},PS{i,2},PS{i,3},PS{i,4},PS{i,5},PS{i,6});
end
fclose(fid);

fid = fopen('ANOVA_250_500ms_summary.csv','w');
fprintf(fid,'Deviant,Window,F,df1,df2,p,Estimate,SE,CI_L,CI_U,BF10,Evidence\n');
for i=1:size(Summary,1)
    fprintf(fid,'%d,%s,%.4f,%.2f,%.2f,%.5f,%.5f,%.5f,%.5f,%.5f,%.4f,%s\n',...
        Summary{i,1},Summary{i,2},Summary{i,3},Summary{i,4},Summary{i,5},Summary{i,6},...
        Summary{i,7},Summary{i,8},Summary{i,9},Summary{i,10},Summary{i,11},Summary{i,12});
end
fclose(fid);

fprintf('\n已完成：每 50ms 窗口 (250–500ms) 的统计分析。\n');

%% =================== 辅助函数 ===================
function fidx = findElectrode(labels, FR_all)
fidx = zeros(1,numel(FR_all));
for ii=1:numel(FR_all)
    k = find(strcmp(labels, sprintf('E%d', FR_all(ii))),1);
    if isempty(k), k = find(strcmp(labels, sprintf('%d',FR_all(ii))),1); end
    if isempty(k), k = FR_all(ii); end
    fidx(ii) = k;
end
end

function val = meanWin(tl,fidx,win)
tsel = tl.time >= win(1) & tl.time <= win(2);
val = nanmean(tl.avg(fidx,tsel),'all');
end

function T = buildTable(C_Pre,C_Post,E_Pre,E_Post,nCon,nExp)
T = dataset( ...
    {nominal([arrayfun(@(x)sprintf('C_%03d',x),(1:nCon),'UniformOutput',false), ...
              arrayfun(@(x)sprintf('C_%03d',x),(1:nCon),'UniformOutput',false), ...
              arrayfun(@(x)sprintf('E_%03d',x),(1:nExp),'UniformOutput',false), ...
              arrayfun(@(x)sprintf('E_%03d',x),(1:nExp),'UniformOutput',false)])','Subject'}, ...
    {nominal([repmat({'Control'},2*nCon,1); repmat({'Sleep'},2*nExp,1)]),'Group'}, ...
    {nominal([repmat({'Pre'},nCon,1); repmat({'Post'},nCon,1); ...
              repmat({'Pre'},nExp,1); repmat({'Post'},nExp,1)]),'Time'}, ...
    {double([C_Pre;C_Post;E_Pre;E_Post]),'Value'});
end

function out = extractStats(T,idev,label)
LME = fitlme(T,'Value ~ Group*Time + (1|Subject)');
A = anova(LME);

ridx = find(strcmp(A.Term,'Group:Time') | strcmp(A.Term,'Time:Group'),1);
if isempty(ridx)
    F = NaN; p = NaN; df1 = NaN; df2 = NaN;
else
    F = A.FStat(ridx); p = A.pValue(ridx); df1 = A.DF1(ridx); df2 = A.DF2(ridx);
end

coef = dataset2table(LME.Coefficients);
idx = find(contains(coef.Name,'Group') & contains(coef.Name,'Time'));

if ~isempty(idx)
    est = coef.Estimate(idx); se = coef.SE(idx);
    ciL = coef.Lower(idx); ciU = coef.Upper(idx);
else
    est = NaN; se = NaN; ciL = NaN; ciU = NaN;
end

LME_red = fitlme(T,'Value ~ Group + Time + (1|Subject)');
BF10 = exp((LME_red.ModelCriterion.BIC - LME.ModelCriterion.BIC)/2);
Evidence = bfLabel(BF10);

out = {idev,label,F,df1,df2,p,est,se,ciL,ciU,BF10,Evidence};
end

function txt = bfLabel(BF10)
if isnan(BF10), txt='N/A';
elseif BF10>=100, txt='Extreme evidence for interaction';
elseif BF10>=30, txt='Very strong evidence';
elseif BF10>=10, txt='Strong evidence';
elseif BF10>=3, txt='Moderate evidence';
elseif BF10>=1, txt='Anecdotal evidence';
else txt='Evidence for no interaction';
end
end
