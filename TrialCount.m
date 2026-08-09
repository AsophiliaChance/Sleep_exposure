% baseline correction, re-reference, plot, and trial-count summary

clear; clc;

datadir = {'day0','day1','day2','day3'};
basedir = 'G:\study2\002\sleep\2ndanalysis\analysis';
savedir = 'G:\study2\002\sleep\2ndanalysis\results';
filt = '*_preprocessed1a.set';

deviant_types = {'2','3'};
elec = {'C4','C3','FPz'};

art_thresh = 120; % +/- uV
twin = [-0.1 0.7];

eeglab;

baseline = [100 200];

if ~exist(savedir, 'dir')
    mkdir(savedir);
end

%% 用于保存 trial count 的变量

Trial_Night = {};
Trial_Subject = {};
Trial_File = {};
Trial_DeviantType = {};
Trial_DEV_N = [];
Trial_STD_N = [];
Trial_Total_N = [];
Trial_MinDEVSTD_N = [];

%% 主循环

for md = 1:length(datadir)

    STD_avg = [];
    DEV_avg = [];
    Diff_avg = [];
    STD_keeptrials_nsub = [];
    DEV_keeptrials_nsub = [];
    clssi_Diff = [];

    curdir = fullfile(basedir, datadir{md});
    cd(curdir);

    files = dir(filt);
    savenam = datadir{md};

    fprintf('\n==============================\n');
    fprintf('Processing %s\n', savenam);
    fprintf('Found %d files\n', length(files));
    fprintf('==============================\n');

    for curfile = 1:length(files)

        file = files(curfile).name;

        EEG = pop_loadset(file, pwd);
        EEG.nbchan;

        [pth, nam, ext] = fileparts(file);

        % 如果文件名长度少于14，避免报错
        if length(nam) >= 14
            filenam = nam(1:14);
        else
            filenam = nam;
        end

        fprintf('\nWorking on %s\n', [nam ext]);

        %% 基线校正，重新分段

        for idev = 1:length(deviant_types)

            uniqueToDEV = [];
            uniqueToSTD = [];
            indices1 = [];
            indices2 = [];
            indices3 = [];
            indices4 = [];

            curDev = deviant_types{idev};

            fprintf('  Deviant type: %s\n', curDev);

            % 先以 deviant 为中心取较长 epoch，并用 valuelim 做 artifact rejection
            [EEG1, indices0] = pop_epoch(EEG, {curDev}, [-1.5 1], ...
                'valuelim', [-art_thresh art_thresh]);

            EEG1 = pop_rmbase(EEG1, baseline, []);

            EEG.nbchan;

            EEG1 = pop_saveset(EEG1, ...
                'filename', [filenam, '_', curDev, 'epoch3.set'], ...
                'filepath', pwd);

            % 在 EEG1 中重新提取 DEV 和 STD
            [DEV, indices1] = pop_epoch(EEG1, {curDev}, [-0.1 0.9]);
            [STD, indices2] = pop_epoch(EEG1, {'1'}, [-0.1 0.9]);

            DEV = pop_rmbase(DEV, baseline, []);
            STD = pop_rmbase(STD, baseline, []);

            %% ==============================
            %  新增：trial number 计算
            %  这里统计的是经过上述 epoch 和 baseline correction 后保留下来的 trial 数
            %% ==============================

            nDEV = DEV.trials;
            nSTD = STD.trials;
            nTotal = nDEV + nSTD;
            nMinDEVSTD = min(nDEV, nSTD);

            Trial_Night{end+1, 1} = savenam;
            Trial_Subject{end+1, 1} = filenam;
            Trial_File{end+1, 1} = file;
            Trial_DeviantType{end+1, 1} = curDev;
            Trial_DEV_N(end+1, 1) = nDEV;
            Trial_STD_N(end+1, 1) = nSTD;
            Trial_Total_N(end+1, 1) = nTotal;
            Trial_MinDEVSTD_N(end+1, 1) = nMinDEVSTD;

            fprintf('    DEV trials = %d, STD trials = %d\n', nDEV, nSTD);

            %% 转 FieldTrip

            DEV_ft = eeglab2fieldtrip(DEV, 'preprocessing');
            STD_ft = eeglab2fieldtrip(STD, 'preprocessing');

            %% keep trials

            cfg = [];
            cfg.keeptrials = 'yes';

            STD_keeptrials_nsub{curfile, idev} = ft_timelockanalysis(cfg, STD_ft);
            DEV_keeptrials_nsub{curfile, idev} = ft_timelockanalysis(cfg, DEV_ft);

            %% average

            cfg = [];
            cfg.keeptrials = 'no';

            STD_avg{curfile, idev} = ft_timelockanalysis(cfg, STD_ft);
            DEV_avg{curfile, idev} = ft_timelockanalysis(cfg, DEV_ft);

            %% difference wave: DEV - STD

            cfg = [];
            cfg.operation = 'subtract';

            % 如果之后要保留 single-trial difference，可以再打开下面这几行
            % cfg.parameter = 'trial';
            % clssi_Diff{curfile, idev} = ft_math(cfg, ...
            %     DEV_keeptrials_nsub{curfile, idev}, ...
            %     STD_keeptrials_nsub{curfile, idev});

            cfg.parameter = 'avg';
            Diff_avg{curfile, idev} = ft_math(cfg, ...
                DEV_avg{curfile, idev}, ...
                STD_avg{curfile, idev});

        end
    end

    %% 保存每一晚的 ERP 平均结果

    save(fullfile(savedir, [savenam, '_nsubavg', num2str(art_thresh), '.mat']), ...
        'STD_avg', 'DEV_avg', 'Diff_avg');

    % 如需要保存 single-trial 数据，可以打开下面这行
    % save(fullfile(savedir, [savenam, '_nsubDEVnSTDmvpa', num2str(art_thresh), '.mat']), ...
    %     'STD_keeptrials_nsub', 'DEV_keeptrials_nsub', 'clssi_Diff');

end

%% ============================================================
%  生成 subject-level trial count 表格
%% ============================================================

TrialCountTable = table( ...
    Trial_Night, ...
    Trial_Subject, ...
    Trial_File, ...
    Trial_DeviantType, ...
    Trial_DEV_N, ...
    Trial_STD_N, ...
    Trial_Total_N, ...
    Trial_MinDEVSTD_N, ...
    'VariableNames', { ...
        'Night', ...
        'Subject', ...
        'File', ...
        'DeviantType', ...
        'N_DEV_trials', ...
        'N_STD_trials', ...
        'N_Total_DEV_STD_trials', ...
        'N_Min_DEV_STD_trials' ...
    });

%% ============================================================
%  生成每晚 × deviant type 的 summary 表格
%% ============================================================

Summary_Night = {};
Summary_DeviantType = {};
Summary_N_Subjects = [];

Summary_DEV_Mean = [];
Summary_DEV_SD = [];
Summary_DEV_Min = [];
Summary_DEV_Max = [];
Summary_DEV_RangeWidth = [];
Summary_DEV_Range = {};

Summary_STD_Mean = [];
Summary_STD_SD = [];
Summary_STD_Min = [];
Summary_STD_Max = [];
Summary_STD_RangeWidth = [];
Summary_STD_Range = {};

Summary_Total_Mean = [];
Summary_Total_Min = [];
Summary_Total_Max = [];
Summary_Total_Range = {};

for md = 1:length(datadir)

    curNight = datadir{md};

    for idev = 1:length(deviant_types)

        curDev = deviant_types{idev};

        idx = strcmp(TrialCountTable.Night, curNight) & ...
              strcmp(TrialCountTable.DeviantType, curDev);

        devCounts = TrialCountTable.N_DEV_trials(idx);
        stdCounts = TrialCountTable.N_STD_trials(idx);
        totalCounts = TrialCountTable.N_Total_DEV_STD_trials(idx);

        devCounts = devCounts(~isnan(devCounts));
        stdCounts = stdCounts(~isnan(stdCounts));
        totalCounts = totalCounts(~isnan(totalCounts));

        Summary_Night{end+1, 1} = curNight;
        Summary_DeviantType{end+1, 1} = curDev;
        Summary_N_Subjects(end+1, 1) = length(devCounts);

        if isempty(devCounts)

            Summary_DEV_Mean(end+1, 1) = NaN;
            Summary_DEV_SD(end+1, 1) = NaN;
            Summary_DEV_Min(end+1, 1) = NaN;
            Summary_DEV_Max(end+1, 1) = NaN;
            Summary_DEV_RangeWidth(end+1, 1) = NaN;
            Summary_DEV_Range{end+1, 1} = '';

        else

            Summary_DEV_Mean(end+1, 1) = mean(devCounts);
            Summary_DEV_SD(end+1, 1) = std(devCounts);
            Summary_DEV_Min(end+1, 1) = min(devCounts);
            Summary_DEV_Max(end+1, 1) = max(devCounts);
            Summary_DEV_RangeWidth(end+1, 1) = max(devCounts) - min(devCounts);
            Summary_DEV_Range{end+1, 1} = sprintf('%d-%d', min(devCounts), max(devCounts));

        end

        if isempty(stdCounts)

            Summary_STD_Mean(end+1, 1) = NaN;
            Summary_STD_SD(end+1, 1) = NaN;
            Summary_STD_Min(end+1, 1) = NaN;
            Summary_STD_Max(end+1, 1) = NaN;
            Summary_STD_RangeWidth(end+1, 1) = NaN;
            Summary_STD_Range{end+1, 1} = '';

        else

            Summary_STD_Mean(end+1, 1) = mean(stdCounts);
            Summary_STD_SD(end+1, 1) = std(stdCounts);
            Summary_STD_Min(end+1, 1) = min(stdCounts);
            Summary_STD_Max(end+1, 1) = max(stdCounts);
            Summary_STD_RangeWidth(end+1, 1) = max(stdCounts) - min(stdCounts);
            Summary_STD_Range{end+1, 1} = sprintf('%d-%d', min(stdCounts), max(stdCounts));

        end

        if isempty(totalCounts)

            Summary_Total_Mean(end+1, 1) = NaN;
            Summary_Total_Min(end+1, 1) = NaN;
            Summary_Total_Max(end+1, 1) = NaN;
            Summary_Total_Range{end+1, 1} = '';

        else

            Summary_Total_Mean(end+1, 1) = mean(totalCounts);
            Summary_Total_Min(end+1, 1) = min(totalCounts);
            Summary_Total_Max(end+1, 1) = max(totalCounts);
            Summary_Total_Range{end+1, 1} = sprintf('%d-%d', min(totalCounts), max(totalCounts));

        end

    end
end

TrialSummaryTable = table( ...
    Summary_Night, ...
    Summary_DeviantType, ...
    Summary_N_Subjects, ...
    Summary_DEV_Mean, ...
    Summary_DEV_SD, ...
    Summary_DEV_Min, ...
    Summary_DEV_Max, ...
    Summary_DEV_RangeWidth, ...
    Summary_DEV_Range, ...
    Summary_STD_Mean, ...
    Summary_STD_SD, ...
    Summary_STD_Min, ...
    Summary_STD_Max, ...
    Summary_STD_RangeWidth, ...
    Summary_STD_Range, ...
    Summary_Total_Mean, ...
    Summary_Total_Min, ...
    Summary_Total_Max, ...
    Summary_Total_Range, ...
    'VariableNames', { ...
        'Night', ...
        'DeviantType', ...
        'N_Subjects', ...
        'DEV_MeanTrials', ...
        'DEV_SDTrials', ...
        'DEV_MinTrials', ...
        'DEV_MaxTrials', ...
        'DEV_RangeWidth', ...
        'DEV_Range', ...
        'STD_MeanTrials', ...
        'STD_SDTrials', ...
        'STD_MinTrials', ...
        'STD_MaxTrials', ...
        'STD_RangeWidth', ...
        'STD_Range', ...
        'Total_MeanTrials', ...
        'Total_MinTrials', ...
        'Total_MaxTrials', ...
        'Total_Range' ...
    });

%% ============================================================
%  输出表格
%% ============================================================

outExcel = fullfile(savedir, ['trial_count_summary_', num2str(art_thresh), '.xlsx']);
outCSV_subject = fullfile(savedir, ['trial_count_subject_level_', num2str(art_thresh), '.csv']);
outCSV_summary = fullfile(savedir, ['trial_count_summary_', num2str(art_thresh), '.csv']);

writetable(TrialCountTable, outExcel, 'Sheet', 'subject_level');
writetable(TrialSummaryTable, outExcel, 'Sheet', 'summary');

writetable(TrialCountTable, outCSV_subject);
writetable(TrialSummaryTable, outCSV_summary);

fprintf('\n========================================\n');
fprintf('Trial count tables saved:\n');
fprintf('%s\n', outExcel);
fprintf('%s\n', outCSV_subject);
fprintf('%s\n', outCSV_summary);
fprintf('========================================\n');

disp('Subject-level trial count table:');
disp(TrialCountTable);

disp('Summary trial count table:');
disp(TrialSummaryTable);