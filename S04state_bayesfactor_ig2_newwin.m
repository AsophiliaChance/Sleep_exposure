clc; clear;
output_dir = 'G:\study2\results';  % <<< 修改为你的结果目录
if ~exist(output_dir, 'dir'); mkdir(output_dir); end
cd(output_dir);
fprintf('当前工作目录: %s\n', pwd);
%% ============================================
% 输入数据
%% ============================================
files = { ...
    'S001control_IG_pre_nsubavg.mat', ...
    'S002_IG_pre_nsubavg.mat', ...
    'S001control_IG_post_nsubavg.mat', ...
    'S002_IG_post_nsubavg.mat'};

FR_all = unique([20 23 24 28 4 11 16 19 3 117 118 124]);

% 读取四个数据文件
S = cell(1,4);
for md = 1:4
    S{md} = load(files{md});
end

ndev = size(S{1}.Diff_avg, 2);     % deviant 数量
time  = S{1}.Diff_avg{1,1}.time;   % 时间轴（假设一致）

%% =============================================================
% 层级 1 + 层级 2：FR_all × 被试 平均
%% =============================================================
GA_FR_all = struct();
GA_FR_all.Diff = cell(4, ndev);
GA_FR_all.DEV  = cell(4, ndev);
GA_FR_all.time = time;

for md = 1:4
    nSub = size(S{md}.Diff_avg,1);

    for idev = 1:ndev
        allDiff = nan(nSub, numel(time));
        allDev  = nan(nSub, numel(time));

        for s = 1:nSub
            tlD = S{md}.Diff_avg{s, idev};
            tlV = S{md}.DEV_avg{s, idev};

            fidx = findElectrodeIdx(tlD.label, FR_all);

            % 层级 1：FR_all 平均（不平均时间）
            allDiff(s,:) = nanmean(tlD.avg(fidx,:),1);
            allDev(s,:)  = nanmean(tlV.avg(fidx,:),1);
        end

        % 层级 2：跨被试平均
        GA_FR_all.Diff{md,idev} = nanmean(allDiff,1);
        GA_FR_all.DEV{md,idev}  = nanmean(allDev,1);
    end
end

%% =============================================================
% 层级 3：FR_all × 被试 × md 平均
%% =============================================================
GA_FR_all_allMD = struct();
GA_FR_all_allMD.Diff = cell(1,ndev);
GA_FR_all_allMD.DEV  = cell(1,ndev);
GA_FR_all_allMD.time = time;

for idev = 1:ndev
    tmpDiff = nan(4, numel(time));
    tmpDev  = nan(4, numel(time));

    for md = 1:4
        tmpDiff(md,:) = GA_FR_all.Diff{md,idev};
        tmpDev(md,:)  = GA_FR_all.DEV{md,idev};
    end

    % 层级 3：跨 md 平均
    GA_FR_all_allMD.Diff{idev} = nanmean(tmpDiff,1);
    GA_FR_all_allMD.DEV{idev}  = nanmean(tmpDev,1);
end

%% =============================================================
% 层级 4：FR_all × 被试 × md × idev 最终 grand average
%% =============================================================
GA_final = struct();
GA_final.time = time;

matDiff = nan(ndev, numel(time));
matDev  = nan(ndev, numel(time));

for idev = 1:ndev
    matDiff(idev,:) = GA_FR_all_allMD.Diff{idev};
    matDev(idev,:)  = GA_FR_all_allMD.DEV{idev};
end

% 层级 4：跨 idev 平均
GA_final.Diff = nanmean(matDiff,1);
GA_final.DEV  = nanmean(matDev,1);

%% 输出提示
disp('四层级平均完成！');
disp('结果位于：GA_FR_all、GA_FR_all_allMD、GA_final');
%%
%% =============================================================
% 求 GA_final.Diff / GA_final.DEV 在 250–400 ms 的最大值与潜伏期
%% =============================================================
win = [0.180 0.240];   % 秒

tsel = GA_final.time >= win(1) & GA_final.time <= win(2);

% 250–400ms 的数据片段
segDiff = GA_final.Diff(tsel);
segDev  = GA_final.DEV(tsel);
segTime = GA_final.time(tsel);

% 最大幅度
[maxDiff, idxDiff] = min(segDiff);
[maxDev,  idxDev ] = min(segDev);

% 转换为毫秒
GA_final.peakAmp.Diff = maxDiff;
GA_final.peakLat.Diff = segTime(idxDiff) * 1000;

GA_final.peakAmp.DEV  = maxDev;
GA_final.peakLat.DEV  = segTime(idxDev) * 1000;

%% 打印结果
fprintf('\n=== Final GA Peak (250–400 ms) ===\n');
fprintf('Diff: Max = %.4f ?V   Lat = %.2f ms\n', GA_final.peakAmp.Diff, GA_final.peakLat.Diff);
fprintf('DEV : Max = %.4f ?V   Lat = %.2f ms\n', GA_final.peakAmp.DEV,  GA_final.peakLat.DEV);

%% =============================================================
% 辅助函数
%% =============================================================
function fidx = findElectrodeIdx(labels, FR_all)
fidx = zeros(1,numel(FR_all));
for ii = 1:numel(FR_all)
    num = FR_all(ii);
    k = find(strcmp(labels, sprintf('E%d', num)),1);
    if isempty(k), k = find(strcmp(labels, sprintf('%d', num)),1); end
    if isempty(k), k = num; end
    fidx(ii) = k;
end
end
