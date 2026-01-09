clc; clear
cd('G:\study2\002\sleep\2ndanalysis\results');

filename = {'day1_nsubavg120.mat','day2_nsubavg120.mat','day3_nsubavg120.mat'};
channelsToAvg = {'FPz', 'C3', 'C4'};

%% ================== Load data + channel average ==================
for md = 1:3
    load(filename{md});
    channel_idx = find(ismember(Diff_avg{1,1}.label, channelsToAvg));

    for isub = 1:size(Diff_avg,1)
        for idev = 1:2
            
            % Diff
            avg_diff = Diff_avg{isub,idev};
            avg_diff.avg = Diff_avg{isub,idev}.avg(channel_idx,:);
            Diff{md,isub,idev} = avg_diff;

            avg_diff.avg = mean(Diff_avg{isub,idev}.avg(channel_idx,:));
            Diff1{md,isub,idev} = avg_diff;

            % STD
            avg_std = STD_avg{isub,idev};
            avg_std.avg = mean(STD_avg{isub,idev}.avg(channel_idx,:));
            STD{md,isub,idev} = avg_std;

            % DEV
            avg_dev = DEV_avg{isub,idev};
            avg_dev.avg = mean(DEV_avg{isub,idev}.avg(channel_idx,:));
            DEV{md,isub,idev} = avg_dev;
        end
    end
end


%% ================== Grand average ==================
cfg = [];
cfg.channel   = 'all';
cfg.latency   = 'all';
cfg.parameter = 'avg';

for md = 1:3
    for idev = 1:2

        if md == 2
            Diff_gavg{md,idev} = ft_timelockgrandaverage(cfg, Diff1{md,1:19,idev});
            Diff1{md,20,idev} = Diff_gavg{md,idev};
            STD_gavg{md,idev} = ft_timelockgrandaverage(cfg, STD{md,1:19,idev});
            DEV_gavg{md,idev} = ft_timelockgrandaverage(cfg, DEV{md,1:19,idev});
        else
            Diff_gavg{md,idev} = ft_timelockgrandaverage(cfg, Diff1{md,:,idev});
            STD_gavg{md,idev}  = ft_timelockgrandaverage(cfg, STD{md,:,idev});
            DEV_gavg{md,idev}  = ft_timelockgrandaverage(cfg, DEV{md,:,idev});
        end

    end
end


%% ================== Find peak windows ==================
Diff_ga = []; DEV_ga = [];
for idev = 1:2
    for md = 1:3
        DEV_ga(idev,md,:) = DEV_gavg{md,idev}.avg;
        Diff_ga(idev,md,:) = Diff_gavg{md,idev}.avg;
    end
end

Diff_ga = squeeze(mean(mean(Diff_ga,2),1));
DEV_ga  = squeeze(mean(mean(DEV_ga,2),1));

time = Diff_gavg{1,1}.time;
winlenght = 0.035;

% MMN window
idx_min = find(time >= 0.35 & time <= 0.47);
[~, minIdx] = max(DEV_ga(idx_min));
minTime = time(idx_min(minIdx));

% P3 window
idx_max = find(time >= 0.5 & time <= 0.7);
[~, maxIdx] = max(Diff_ga(idx_max));
maxTime = time(idx_max(maxIdx));

win.mmn1 = minTime - winlenght;
win.mmn2 = minTime + winlenght;
win.p31  = maxTime - 0.05;
win.p32  = maxTime + 0.05;


%% ================== Peak Detection ==================
for md = 1:3
    for idev = 1:2
        for isub = 1:size(Diff1,2)
            data = Diff1{md,isub,idev};

            % MMN (negative)
            idx = find(data.time >= win.mmn1 & data.time <= win.mmn2);
            [~,peakIdx] = min(data.avg(idx));
            latency_diff.mmn(md,isub,idev)   = data.time(idx(peakIdx));
            amplitude_diff.mmn(md,isub,idev) = mean(data.avg(idx));

            % P3 (positive)
            idx = find(data.time >= win.p31 & data.time <= win.p32);
            [~,peakIdx] = max(data.avg(idx));
            latency_diff.p3(md,isub,idev)   = data.time(idx(peakIdx));
            amplitude_diff.p3(md,isub,idev) = mean(data.avg(idx));
        end
    end
end


%% ================== Save ERP peak summary ==================
amplitude_mmn = amplitude_diff.mmn;
amplitude_p3  = amplitude_diff.p3;
latency_mmn   = latency_diff.mmn;
latency_p3    = latency_diff.p3;

save('erp_statisticsdata_simple.mat', ...
    'amplitude_mmn','amplitude_p3','latency_mmn','latency_p3','-v7');

save('erp_statisticsdata.mat','amplitude_diff','latency_diff');


%% ================== LMM + Semi-partial R? (兼容所有 MATLAB 版本) ==================

components = {'MMN_amp','P3_amp','MMN_lat','P3_lat'};
data_all = {amplitude_diff.mmn, amplitude_diff.p3, latency_diff.mmn, latency_diff.p3};

results_LMM = {};
row = 1;

for c = 1:numel(components)

    data_c = data_all{c};           % [day × subj × condition]
    [nDay,nSubj,nCond] = size(data_c);

    for idev = 1:nCond

        % ---- 构造 long T ----
        Y = reshape(data_c(:,:,idev),[],1);
        Days = repmat((1:nDay)', nSubj, 1);
        Subjects = repelem((1:nSubj)', nDay);

        T = table(Subjects, Days, Y);
        T.Subjects = categorical(T.Subjects);
        T.Days = categorical(T.Days);

        % ========= Full model =========
        fullModel = fitlme(T,'Y ~ Days + (1|Subjects)','FitMethod','REML');

        % ========= Null model =========
        nullModel = fitlme(T,'Y ~ 1 + (1|Subjects)','FitMethod','REML');

        %% ================= 固定效应拟合值 ==================
        % Full model
        Xf = fullModel.designMatrix('Fixed');
        betaf = fixedEffects(fullModel);
        yhat_fixed_full = Xf * betaf;

        % Null model
        Xn = nullModel.designMatrix('Fixed');
        betan = fixedEffects(nullModel);
        yhat_fixed_null = Xn * betan;

        %% ================= 方差计算 ==================
        % Random-effect variance (old MATLAB version safe)
        sigma2_full = fullModel.MSE;
        D_full = fullModel.covarianceParameters;   % random-effect parameters
        Var_rand_full = sum(cellfun(@(x) sum(x(:).^2), D_full)) * sigma2_full;

        sigma2_null = nullModel.MSE;
        D_null = nullModel.covarianceParameters;
        Var_rand_null = sum(cellfun(@(x) sum(x(:).^2), D_null)) * sigma2_null;

        % Fixed-effect variance
        Var_fixed_full = var(yhat_fixed_full);
        Var_fixed_null = var(yhat_fixed_null);

        % Residual variance
        Var_res_full = sigma2_full;
        Var_res_null = sigma2_null;

        %% ================= R? ==================
        R2_full = Var_fixed_full / (Var_fixed_full + Var_rand_full + Var_res_full);
        R2_null = Var_fixed_null / (Var_fixed_null + Var_rand_null + Var_res_null);

        %% ================= Semi-partial R? ==================
        semi_partial_R2 = R2_full - R2_null;

        %% Save
        results_LMM(row,:) = {components{c}, idev, R2_full, R2_null, semi_partial_R2};
        row = row + 1;

    end
end

T_LMM = cell2table(results_LMM, ...
    'VariableNames',{'Component','Condition','R2_full','R2_null','SemiPartialR2'});

writetable(T_LMM,'ERP_LMM_SemiPartialR2.xlsx');

disp('? Semi-partial R? 已完成 (兼容所有 MATLAB 版本)');
