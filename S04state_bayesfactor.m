%% ======================================================
%  IGNORE condition — Mixed ANOVA + BF10 (BIC) + Waveform Plots (DIFF latency)
%  - No DiD, No cluster-based permutation, No functions
%  - Components & windows for SPEECH sounds (all from DIFFERENCE wave):
%       MMN (frontal):  Amp 190–240 ms (Diff),   Lat 150–260 ms (Diff, min)
%       P3a (frontal):  Amp 250–300 ms (Diff),   Lat 250–350 ms (Diff, max)
%  - Electrodes (merged frontal clusters, average across all):
%       FR_all: [20 23 24 28   4 11 16 19   3 117 118 124]
%  - Model: Value ~ Group*Time + (1|Subject)
%% ======================================================

clc; clear;
cd('G:\study2\results');      % <<< 若路径不同请修改

% -------------------- 数据文件（IGNORE 条件） ----------------
files = { ...
    'S001control_IG_pre_nsubavg.mat', ... % md1 Control-Pre
    'S002_IG_pre_nsubavg.mat', ...        % md2 Experimental-Pre
    'S001control_IG_post_nsubavg.mat', ...% md3 Control-Post
    'S002_IG_post_nsubavg.mat'};          % md4 Experimental-Post

% -------------------- 时间窗（秒） ------------------------
MMN_amp_win  = [0.190 0.240];   % amplitude on Diff (frontal)
P3a_amp_win  = [0.250 0.300];   % amplitude on Diff (frontal; speech)
MMN_lat_win  = [0.150 0.260];   % latency  on Diff (frontal, min)
P3a_lat_win  = [0.250 0.350];   % latency  on Diff (frontal, max)

% -------------------- 额区电极（合并 L/M/R） ---------------
FR_all = unique([20 23 24 28   4 11 16 19   3 117 118 124]); % frontal (F3/Fz/F4 区)

% -------------------- 载入数据 ----------------------------
S = cell(1,4);
for md = 1:4
    S{md} = load(files{md});   % 需包含 Diff_avg（cell: nSub × nDeviants）
end
ndev = size(S{1}.Diff_avg, 2);

% -------------------- 结果容器 ----------------------------
PS = {};        % per-subject wide rows
Summary = {};   % ANOVA interaction summary with BF10/BF01/label

% =========================================================
% 主循环：每个 idev 独立跑
% =========================================================
for idev = 1:ndev

    % 保证同组 pre/post 成对
    nCon = min(size(S{1}.Diff_avg,1), size(S{3}.Diff_avg,1));
    nExp = min(size(S{2}.Diff_avg,1), size(S{4}.Diff_avg,1));

    % 预分配（四个 DV：Amp MMN / Amp P3a / Lat MMN / Lat P3a）
    ampMMN_C_Pre = nan(nCon,1); ampMMN_C_Post = nan(nCon,1);
    ampMMN_E_Pre = nan(nExp,1); ampMMN_E_Post = nan(nExp,1);
    ampP3a_C_Pre = nan(nCon,1); ampP3a_C_Post = nan(nCon,1);
    ampP3a_E_Pre = nan(nExp,1); ampP3a_E_Post = nan(nExp,1);

    latMMN_C_Pre = nan(nCon,1); latMMN_C_Post = nan(nCon,1);
    latMMN_E_Pre = nan(nExp,1); latMMN_E_Post = nan(nExp,1);
    latP3a_C_Pre = nan(nCon,1); latP3a_C_Post = nan(nCon,1);
    latP3a_E_Pre = nan(nExp,1); latP3a_E_Post = nan(nExp,1);

    % 为绘图准备的簇平均 Difference 波形（四组）
    t_ms = [];
    W_CP=[]; W_CPo=[]; W_EP=[]; W_EPo=[];  % Control-Pre/Post, Experimental-Pre/Post

    %% ================== Control-Pre ==================
    for s = 1:nCon
        tl = S{1}.Diff_avg{s,idev};
        if isempty(t_ms), t_ms = tl.time * 1000; end

        % -------- frontal 索引（显式 for 循环） --------
        fidx = zeros(1,numel(FR_all));
        for ii=1:numel(FR_all)
            num = FR_all(ii);
            k = find(strcmp(tl.label, sprintf('E%d', num)), 1);
            if isempty(k), k = find(strcmp(tl.label, sprintf('%d', num)), 1); end
            if isempty(k), k = num; end
            fidx(ii) = k;
        end

        % Difference 波：簇平均
        wave = nanmean(tl.avg(fidx,:),1);

        % Amp: MMN
        tsel = tl.time >= MMN_amp_win(1) & tl.time <= MMN_amp_win(2);
        ampMMN_C_Pre(s) = nanmean(tl.avg(fidx, tsel), 'all');

        % Amp: P3a
        tsel = tl.time >= P3a_amp_win(1) & tl.time <= P3a_amp_win(2);
        ampP3a_C_Pre(s) = nanmean(tl.avg(fidx, tsel), 'all');

        % Lat: MMN（min）
        tsel = tl.time >= MMN_lat_win(1) & tl.time <= MMN_lat_win(2);
        seg  = wave(tsel); segt = tl.time(tsel);
        if isempty(seg), latMMN_C_Pre(s)=NaN; else [~,kmin]=min(seg); latMMN_C_Pre(s)=segt(kmin)*1000; end

        % Lat: P3a（max）
        tsel = tl.time >= P3a_lat_win(1) & tl.time <= P3a_lat_win(2);
        seg  = wave(tsel); segt = tl.time(tsel);
        if isempty(seg), latP3a_C_Pre(s)=NaN; else [~,kmax]=max(seg); latP3a_C_Pre(s)=segt(kmax)*1000; end

        W_CP(s,:) = wave;
    end

    %% ================== Control-Post ==================
    for s = 1:nCon
        tl = S{3}.Diff_avg{s,idev};

        fidx = zeros(1,numel(FR_all));
        for ii=1:numel(FR_all)
            num = FR_all(ii);
            k = find(strcmp(tl.label, sprintf('E%d', num)), 1);
            if isempty(k), k = find(strcmp(tl.label, sprintf('%d', num)), 1); end
            if isempty(k), k = num; end
            fidx(ii) = k;
        end

        wave = nanmean(tl.avg(fidx,:),1);

        tsel = tl.time >= MMN_amp_win(1) & tl.time <= MMN_amp_win(2);
        ampMMN_C_Post(s) = nanmean(tl.avg(fidx, tsel), 'all');

        tsel = tl.time >= P3a_amp_win(1) & tl.time <= P3a_amp_win(2);
        ampP3a_C_Post(s) = nanmean(tl.avg(fidx, tsel), 'all');

        tsel = tl.time >= MMN_lat_win(1) & tl.time <= MMN_lat_win(2);
        seg  = wave(tsel); segt = tl.time(tsel);
        if isempty(seg), latMMN_C_Post(s)=NaN; else [~,kmin]=min(seg); latMMN_C_Post(s)=segt(kmin)*1000; end

        tsel = tl.time >= P3a_lat_win(1) & tl.time <= P3a_lat_win(2);
        seg  = wave(tsel); segt = tl.time(tsel);
        if isempty(seg), latP3a_C_Post(s)=NaN; else [~,kmax]=max(seg); latP3a_C_Post(s)=segt(kmax)*1000; end

        W_CPo(s,:) = wave;
    end

    %% ================== Experimental-Pre ==================
    for s = 1:nExp
        tl = S{2}.Diff_avg{s,idev};

        fidx = zeros(1,numel(FR_all));
        for ii=1:numel(FR_all)
            num = FR_all(ii);
            k = find(strcmp(tl.label, sprintf('E%d', num)), 1);
            if isempty(k), k = find(strcmp(tl.label, sprintf('%d', num)), 1); end
            if isempty(k), k = num; end
            fidx(ii) = k;
        end

        wave = nanmean(tl.avg(fidx,:),1);

        tsel = tl.time >= MMN_amp_win(1) & tl.time <= MMN_amp_win(2);
        ampMMN_E_Pre(s) = nanmean(tl.avg(fidx, tsel), 'all');

        tsel = tl.time >= P3a_amp_win(1) & tl.time <= P3a_amp_win(2);
        ampP3a_E_Pre(s) = nanmean(tl.avg(fidx, tsel), 'all');

        tsel = tl.time >= MMN_lat_win(1) & tl.time <= MMN_lat_win(2);
        seg  = wave(tsel); segt = tl.time(tsel);
        if isempty(seg), latMMN_E_Pre(s)=NaN; else [~,kmin]=min(seg); latMMN_E_Pre(s)=segt(kmin)*1000; end

        tsel = tl.time >= P3a_lat_win(1) & tl.time <= P3a_lat_win(2);
        seg  = wave(tsel); segt = tl.time(tsel);
        if isempty(seg), latP3a_E_Pre(s)=NaN; else [~,kmax]=max(seg); latP3a_E_Pre(s)=segt(kmax)*1000; end

        W_EP(s,:) = wave;
    end

    %% ================== Experimental-Post ==================
    for s = 1:nExp
        tl = S{4}.Diff_avg{s,idev};

        fidx = zeros(1,numel(FR_all));
        for ii=1:numel(FR_all)
            num = FR_all(ii);
            k = find(strcmp(tl.label, sprintf('E%d', num)), 1);
            if isempty(k), k = find(strcmp(tl.label, sprintf('%d', num)), 1); end
            if isempty(k), k = num; end
            fidx(ii) = k;
        end

        wave = nanmean(tl.avg(fidx,:),1);

        tsel = tl.time >= MMN_amp_win(1) & tl.time <= MMN_amp_win(2);
        ampMMN_E_Post(s) = nanmean(tl.avg(fidx, tsel), 'all');

        tsel = tl.time >= P3a_amp_win(1) & tl.time <= P3a_amp_win(2);
        ampP3a_E_Post(s) = nanmean(tl.avg(fidx, tsel), 'all');

        tsel = tl.time >= MMN_lat_win(1) & tl.time <= MMN_lat_win(2);
        seg  = wave(tsel); segt = tl.time(tsel);
        if isempty(seg), latMMN_E_Post(s)=NaN; else [~,kmin]=min(seg); latMMN_E_Post(s)=segt(kmin)*1000; end

        tsel = tl.time >= P3a_lat_win(1) & tl.time <= P3a_lat_win(2);
        seg  = wave(tsel); segt = tl.time(tsel);
        if isempty(seg), latP3a_E_Post(s)=NaN; else [~,kmax]=max(seg); latP3a_E_Post(s)=segt(kmax)*1000; end

        W_EPo(s,:) = wave;
    end

    % ================== 构造 LME 的长表（dataset/nominal） ==================
    % Amp MMN
    Subject={}; Group={}; Time={}; Value=[];
    for s=1:nCon
        Subject{end+1,1}=sprintf('C_%03d',s); Group{end+1,1}='Control';      Time{end+1,1}='Pre';  Value(end+1,1)=ampMMN_C_Pre(s);
        Subject{end+1,1}=sprintf('C_%03d',s); Group{end+1,1}='Control';      Time{end+1,1}='Post'; Value(end+1,1)=ampMMN_C_Post(s);
    end
    for s=1:nExp
        Subject{end+1,1}=sprintf('E_%03d',s); Group{end+1,1}='Experimental'; Time{end+1,1}='Pre';  Value(end+1,1)=ampMMN_E_Pre(s);
        Subject{end+1,1}=sprintf('E_%03d',s); Group{end+1,1}='Experimental'; Time{end+1,1}='Post'; Value(end+1,1)=ampMMN_E_Post(s);
    end
    T_ampMMN = dataset({nominal(Subject),'Subject'}, {nominal(Group),'Group'}, {nominal(Time),'Time'}, {Value,'Value'});

    % Amp P3a
    Subject={}; Group={}; Time={}; Value=[];
    for s=1:nCon
        Subject{end+1,1}=sprintf('C_%03d',s); Group{end+1,1}='Control';      Time{end+1,1}='Pre';  Value(end+1,1)=ampP3a_C_Pre(s);
        Subject{end+1,1}=sprintf('C_%03d',s); Group{end+1,1}='Control';      Time{end+1,1}='Post'; Value(end+1,1)=ampP3a_C_Post(s);
    end
    for s=1:nExp
        Subject{end+1,1}=sprintf('E_%03d',s); Group{end+1,1}='Experimental'; Time{end+1,1}='Pre';  Value(end+1,1)=ampP3a_E_Pre(s);
        Subject{end+1,1}=sprintf('E_%03d',s); Group{end+1,1}='Experimental'; Time{end+1,1}='Post'; Value(end+1,1)=ampP3a_E_Post(s);
    end
    T_ampP3a = dataset({nominal(Subject),'Subject'}, {nominal(Group),'Group'}, {nominal(Time),'Time'}, {Value,'Value'});

    % Lat MMN (ms)
    Subject={}; Group={}; Time={}; Value=[];
    for s=1:nCon
        Subject{end+1,1}=sprintf('C_%03d',s); Group{end+1,1}='Control';      Time{end+1,1}='Pre';  Value(end+1,1)=latMMN_C_Pre(s);
        Subject{end+1,1}=sprintf('C_%03d',s); Group{end+1,1}='Control';      Time{end+1,1}='Post'; Value(end+1,1)=latMMN_C_Post(s);
    end
    for s=1:nExp
        Subject{end+1,1}=sprintf('E_%03d',s); Group{end+1,1}='Experimental'; Time{end+1,1}='Pre';  Value(end+1,1)=latMMN_E_Pre(s);
        Subject{end+1,1}=sprintf('E_%03d',s); Group{end+1,1}='Experimental'; Time{end+1,1}='Post'; Value(end+1,1)=latMMN_E_Post(s);
    end
    T_latMMN = dataset({nominal(Subject),'Subject'}, {nominal(Group),'Group'}, {nominal(Time),'Time'}, {Value,'Value'});

    % Lat P3a (ms)
    Subject={}; Group={}; Time={}; Value=[];
    for s=1:nCon
        Subject{end+1,1}=sprintf('C_%03d',s); Group{end+1,1}='Control';      Time{end+1,1}='Pre';  Value(end+1,1)=latP3a_C_Pre(s);
        Subject{end+1,1}=sprintf('C_%03d',s); Group{end+1,1}='Control';      Time{end+1,1}='Post'; Value(end+1,1)=latP3a_C_Post(s);
    end
    for s=1:nExp
        Subject{end+1,1}=sprintf('E_%03d',s); Group{end+1,1}='Experimental'; Time{end+1,1}='Pre';  Value(end+1,1)=latP3a_E_Pre(s);
        Subject{end+1,1}=sprintf('E_%03d',s); Group{end+1,1}='Experimental'; Time{end+1,1}='Post'; Value(end+1,1)=latP3a_E_Post(s);
    end
    T_latP3a = dataset({nominal(Subject),'Subject'}, {nominal(Group),'Group'}, {nominal(Time),'Time'}, {Value,'Value'});

    % ================== LME + ANOVA ==================
    LME_ampMMN = fitlme(T_ampMMN, 'Value ~ Group*Time + (1|Subject)');
    LME_ampP3a = fitlme(T_ampP3a, 'Value ~ Group*Time + (1|Subject)');
    LME_latMMN = fitlme(T_latMMN, 'Value ~ Group*Time + (1|Subject)');
    LME_latP3a = fitlme(T_latP3a, 'Value ~ Group*Time + (1|Subject)');

    A_ampMMN = anova(LME_ampMMN);
    A_ampP3a = anova(LME_ampP3a);
    A_latMMN = anova(LME_latMMN);
    A_latP3a = anova(LME_latP3a);

    % ================== 提取交互项（兼容 table/dataset） ==================
    % ---- Amp MMN ----
    if isa(A_ampMMN,'dataset'), vnames = get(A_ampMMN,'VarNames'); else, vnames = A_ampMMN.Properties.VariableNames; end
    nameVar = 'Name'; if ~any(strcmp(vnames,'Name')), if any(strcmp(vnames,'Term')), nameVar='Term'; else, nameVar=vnames{1}; end; end
    fVar='FStat'; if ~any(strcmp(vnames,'FStat')), if any(strcmp(vnames,'F')), fVar='F'; else, fVar=vnames{find(~cellfun(@isempty,regexp(vnames,'^F','once')),1)}; end; end
    pVar='pValue'; if ~any(strcmp(vnames,'pValue')), if any(strcmp(vnames,'p')), pVar='p'; else, pVar=vnames{find(~cellfun(@isempty,regexp(vnames,'^p','once')),1)}; end; end
    df1Var='DF1'; if ~any(strcmp(vnames,'DF1')) && any(strcmp(vnames,'DFNum')), df1Var='DFNum'; end
    df2Var='DF2'; if ~any(strcmp(vnames,'DF2')) && any(strcmp(vnames,'DFDen')), df2Var='DFDen'; end
    names = A_ampMMN.(nameVar); if ~iscell(names), try names = cellstr(names); catch, names = cellstr(char(names)); end; end
    ridx = find(strcmp(names,'Group:Time') | strcmp(names,'Time:Group'),1);
    x_ampMMN_F=NaN; x_ampMMN_p=NaN; x_ampMMN_df1=NaN; x_ampMMN_df2=NaN;
    if ~isempty(ridx)
        x_ampMMN_F   = A_ampMMN.(fVar)(ridx);
        x_ampMMN_p   = A_ampMMN.(pVar)(ridx);
        if any(strcmp(vnames,df1Var)), x_ampMMN_df1 = A_ampMMN.(df1Var)(ridx); end
        if any(strcmp(vnames,df2Var)), x_ampMMN_df2 = A_ampMMN.(df2Var)(ridx); end
    end
    % ---- Amp P3a ----
    if isa(A_ampP3a,'dataset'), vnames = get(A_ampP3a,'VarNames'); else, vnames = A_ampP3a.Properties.VariableNames; end
    if ~any(strcmp(vnames,'Name')), if any(strcmp(vnames,'Term')), nameVar='Term'; else, nameVar=vnames{1}; end; end
    if ~any(strcmp(vnames,'FStat')), if any(strcmp(vnames,'F')), fVar='F'; end; end
    if ~any(strcmp(vnames,'pValue')), if any(strcmp(vnames,'p')), pVar='p'; end; end
    names = A_ampP3a.(nameVar); if ~iscell(names), try names = cellstr(names); catch, names = cellstr(char(names)); end; end
    ridx = find(strcmp(names,'Group:Time') | strcmp(names,'Time:Group'),1);
    x_ampP3a_F=NaN; x_ampP3a_p=NaN; x_ampP3a_df1=NaN; x_ampP3a_df2=NaN;
    if ~isempty(ridx)
        x_ampP3a_F   = A_ampP3a.(fVar)(ridx);
        x_ampP3a_p   = A_ampP3a.(pVar)(ridx);
        if any(strcmp(vnames,df1Var)), x_ampP3a_df1 = A_ampP3a.(df1Var)(ridx); end
        if any(strcmp(vnames,df2Var)), x_ampP3a_df2 = A_ampP3a.(df2Var)(ridx); end
    end
    % ---- Lat MMN ----
    if isa(A_latMMN,'dataset'), vnames = get(A_latMMN,'VarNames'); else, vnames = A_latMMN.Properties.VariableNames; end
    nameVar = 'Name'; if ~any(strcmp(vnames,'Name')), if any(strcmp(vnames,'Term')), nameVar='Term'; else, nameVar=vnames{1}; end; end
    fVar='FStat'; if ~any(strcmp(vnames,'FStat')), if any(strcmp(vnames,'F')), fVar='F'; else, fVar=vnames{find(~cellfun(@isempty,regexp(vnames,'^F','once')),1)}; end; end
    pVar='pValue'; if ~any(strcmp(vnames,'pValue')), if any(strcmp(vnames,'p')), pVar='p'; else, pVar=vnames{find(~cellfun(@isempty,regexp(vnames,'^p','once')),1)}; end; end
    df1Var='DF1'; if ~any(strcmp(vnames,'DF1')) && any(strcmp(vnames,'DFNum')), df1Var='DFNum'; end
    df2Var='DF2'; if ~any(strcmp(vnames,'DF2')) && any(strcmp(vnames,'DFDen')), df2Var='DFDen'; end
    names = A_latMMN.(nameVar); if ~iscell(names), try names = cellstr(names); catch, names = cellstr(char(names)); end; end
    ridx = find(strcmp(names,'Group:Time') | strcmp(names,'Time:Group'),1);
    x_latMMN_F=NaN; x_latMMN_p=NaN; x_latMMN_df1=NaN; x_latMMN_df2=NaN;
    if ~isempty(ridx)
        x_latMMN_F   = A_latMMN.(fVar)(ridx);
        x_latMMN_p   = A_latMMN.(pVar)(ridx);
        if any(strcmp(vnames,df1Var)), x_latMMN_df1 = A_latMMN.(df1Var)(ridx); end
        if any(strcmp(vnames,df2Var)), x_latMMN_df2 = A_latMMN.(df2Var)(ridx); end
    end
    % ---- Lat P3a ----
    if isa(A_latP3a,'dataset'), vnames = get(A_latP3a,'VarNames'); else, vnames = A_latP3a.Properties.VariableNames; end
    if ~any(strcmp(vnames,'Name')), if any(strcmp(vnames,'Term')), nameVar='Term'; else, nameVar=vnames{1}; end; end
    if ~any(strcmp(vnames,'FStat')), if any(strcmp(vnames,'F')), fVar='F'; end; end
    if ~any(strcmp(vnames,'pValue')), if any(strcmp(vnames,'p')), pVar='p'; end; end
    names = A_latP3a.(nameVar); if ~iscell(names), try names = cellstr(names); catch, names = cellstr(char(names)); end; end
    ridx = find(strcmp(names,'Group:Time') | strcmp(names,'Time:Group'),1);
    x_latP3a_F=NaN; x_latP3a_p=NaN; x_latP3a_df1=NaN; x_latP3a_df2=NaN;
    if ~isempty(ridx)
        x_latP3a_F   = A_latP3a.(fVar)(ridx);
        x_latP3a_p   = A_latP3a.(pVar)(ridx);
        if any(strcmp(vnames,df1Var)), x_latP3a_df1 = A_latP3a.(df1Var)(ridx); end
        if any(strcmp(vnames,df2Var)), x_latP3a_df2 = A_latP3a.(df2Var)(ridx); end
    end

    % ================== BF10（BIC 近似：full vs reduced） ==================
    LME_ampMMN_red = fitlme(T_ampMMN, 'Value ~ Group + Time + (1|Subject)');
    LME_ampP3a_red = fitlme(T_ampP3a, 'Value ~ Group + Time + (1|Subject)');
    LME_latMMN_red = fitlme(T_latMMN, 'Value ~ Group + Time + (1|Subject)');
    LME_latP3a_red = fitlme(T_latP3a, 'Value ~ Group + Time + (1|Subject)');

    BF10_ampMMN = exp((LME_ampMMN_red.ModelCriterion.BIC - LME_ampMMN.ModelCriterion.BIC)/2);
    BF10_ampP3a = exp((LME_ampP3a_red.ModelCriterion.BIC - LME_ampP3a.ModelCriterion.BIC)/2);
    BF10_latMMN = exp((LME_latMMN_red.ModelCriterion.BIC - LME_latMMN.ModelCriterion.BIC)/2);
    BF10_latP3a = exp((LME_latP3a_red.ModelCriterion.BIC - LME_latP3a.ModelCriterion.BIC)/2);

    % ================== 生成 BF01 与文字标签（if-elseif，无 string 类型） ==================
    % ---- Amp MMN ----
    if isnan(BF10_ampMMN)
        BF01_ampMMN = NaN; lab_ampMMN = 'N/A';
    else
        if BF10_ampMMN >= 1
            BF01_ampMMN = 1/BF10_ampMMN;
            if      BF10_ampMMN >= 100, lab_ampMMN = 'Extreme evidence for interaction';
            elseif  BF10_ampMMN >= 30,  lab_ampMMN = 'Very strong evidence for interaction';
            elseif  BF10_ampMMN >= 10,  lab_ampMMN = 'Strong evidence for interaction';
            elseif  BF10_ampMMN >= 3,   lab_ampMMN = 'Moderate evidence for interaction';
            else                        lab_ampMMN = 'Anecdotal evidence for interaction';
            end
        else
            BF01_ampMMN = 1/BF10_ampMMN;
            if      BF01_ampMMN >= 100, lab_ampMMN = 'Extreme evidence for no interaction';
            elseif  BF01_ampMMN >= 30,  lab_ampMMN = 'Very strong evidence for no interaction';
            elseif  BF01_ampMMN >= 10,  lab_ampMMN = 'Strong evidence for no interaction';
            elseif  BF01_ampMMN >= 3,   lab_ampMMN = 'Moderate evidence for no interaction';
            else                        lab_ampMMN = 'Anecdotal evidence for no interaction';
            end
        end
    end

    % ---- Amp P3a ----
    if isnan(BF10_ampP3a)
        BF01_ampP3a = NaN; lab_ampP3a = 'N/A';
    else
        if BF10_ampP3a >= 1
            BF01_ampP3a = 1/BF10_ampP3a;
            if      BF10_ampP3a >= 100, lab_ampP3a = 'Extreme evidence for interaction';
            elseif  BF10_ampP3a >= 30,  lab_ampP3a = 'Very strong evidence for interaction';
            elseif  BF10_ampP3a >= 10,  lab_ampP3a = 'Strong evidence for interaction';
            elseif  BF10_ampP3a >= 3,   lab_ampP3a = 'Moderate evidence for interaction';
            else                        lab_ampP3a = 'Anecdotal evidence for interaction';
            end
        else
            BF01_ampP3a = 1/BF10_ampP3a;
            if      BF01_ampP3a >= 100, lab_ampP3a = 'Extreme evidence for no interaction';
            elseif  BF01_ampP3a >= 30,  lab_ampP3a = 'Very strong evidence for no interaction';
            elseif  BF01_ampP3a >= 10,  lab_ampP3a = 'Strong evidence for no interaction';
            elseif  BF01_ampP3a >= 3,   lab_ampP3a = 'Moderate evidence for no interaction';
            else                        lab_ampP3a = 'Anecdotal evidence for no interaction';
            end
        end
    end

    % ---- Lat MMN ----
    if isnan(BF10_latMMN)
        BF01_latMMN = NaN; lab_latMMN = 'N/A';
    else
        if BF10_latMMN >= 1
            BF01_latMMN = 1/BF10_latMMN;
            if      BF10_latMMN >= 100, lab_latMMN = 'Extreme evidence for interaction';
            elseif  BF10_latMMN >= 30,  lab_latMMN = 'Very strong evidence for interaction';
            elseif  BF10_latMMN >= 10,  lab_latMMN = 'Strong evidence for interaction';
            elseif  BF10_latMMN >= 3,   lab_latMMN = 'Moderate evidence for interaction';
            else                        lab_latMMN = 'Anecdotal evidence for interaction';
            end
        else
            BF01_latMMN = 1/BF10_latMMN;
            if      BF01_latMMN >= 100, lab_latMMN = 'Extreme evidence for no interaction';
            elseif  BF01_latMMN >= 30,  lab_latMMN = 'Very strong evidence for no interaction';
            elseif  BF01_latMMN >= 10,  lab_latMMN = 'Strong evidence for no interaction';
            elseif  BF01_latMMN >= 3,   lab_latMMN = 'Moderate evidence for no interaction';
            else                        lab_latMMN = 'Anecdotal evidence for no interaction';
            end
        end
    end

    % ---- Lat P3a ----
    if isnan(BF10_latP3a)
        BF01_latP3a = NaN; lab_latP3a = 'N/A';
    else
        if BF10_latP3a >= 1
            BF01_latP3a = 1/BF10_latP3a;
            if      BF10_latP3a >= 100, lab_latP3a = 'Extreme evidence for interaction';
            elseif  BF10_latP3a >= 30,  lab_latP3a = 'Very strong evidence for interaction';
            elseif  BF10_latP3a >= 10,  lab_latP3a = 'Strong evidence for interaction';
            elseif  BF10_latP3a >= 3,   lab_latP3a = 'Moderate evidence for interaction';
            else                        lab_latP3a = 'Anecdotal evidence for interaction';
            end
        else
            BF01_latP3a = 1/BF10_latP3a;
            if      BF01_latP3a >= 100, lab_latP3a = 'Extreme evidence for no interaction';
            elseif  BF01_latP3a >= 30,  lab_latP3a = 'Very strong evidence for no interaction';
            elseif  BF01_latP3a >= 10,  lab_latP3a = 'Strong evidence for no interaction';
            elseif  BF01_latP3a >= 3,   lab_latP3a = 'Moderate evidence for no interaction';
            else                        lab_latP3a = 'Anecdotal evidence for no interaction';
            end
        end
    end

    % ================== 控制台输出 & 汇总 ==================
    fprintf('\n[Ignore idev=%d] Group×Time (F,df1,df2,p) + BF10/BF01 + label\n', idev);
    fprintf('  Amp MMN : F=%.3f, df1=%g, df2=%g, p=%.4g | BF10=%.3f, BF01=%.3f | %s\n', x_ampMMN_F, x_ampMMN_df1, x_ampMMN_df2, x_ampMMN_p, BF10_ampMMN, BF01_ampMMN, lab_ampMMN);
    fprintf('  Amp P3a : F=%.3f, df1=%g, df2=%g, p=%.4g | BF10=%.3f, BF01=%.3f | %s\n', x_ampP3a_F, x_ampP3a_df1, x_ampP3a_df2, x_ampP3a_p, BF10_ampP3a, BF01_ampP3a, lab_ampP3a);
    fprintf('  Lat MMN : F=%.3f, df1=%g, df2=%g, p=%.4g | BF10=%.3f, BF01=%.3f | %s\n', x_latMMN_F, x_latMMN_df1, x_latMMN_df2, x_latMMN_p, BF10_latMMN, BF01_latMMN, lab_latMMN);
    fprintf('  Lat P3a : F=%.3f, df1=%g, df2=%g, p=%.4g | BF10=%.3f, BF01=%.3f | %s\n', x_latP3a_F, x_latP3a_df1, x_latP3a_df2, x_latP3a_p, BF10_latP3a, BF01_latP3a, lab_latP3a);

    Summary(end+1,:) = {idev,'Amplitude_MMN', x_ampMMN_F,x_ampMMN_df1,x_ampMMN_df2,x_ampMMN_p, BF10_ampMMN, BF01_ampMMN, lab_ampMMN};
    Summary(end+1,:) = {idev,'Amplitude_P3a', x_ampP3a_F,x_ampP3a_df1,x_ampP3a_df2,x_ampP3a_p, BF10_ampP3a, BF01_ampP3a, lab_ampP3a};
    Summary(end+1,:) = {idev,'Latency_MMN_ms',x_latMMN_F,x_latMMN_df1,x_latMMN_df2,x_latMMN_p, BF10_latMMN, BF01_latMMN, lab_latMMN};
    Summary(end+1,:) = {idev,'Latency_P3a_ms',x_latP3a_F,x_latP3a_df1,x_latP3a_df2,x_latP3a_p, BF10_latP3a, BF01_latP3a, lab_latP3a};

    % ================== 波形图（Difference，居中显示） ==================
    CP_mean = nanmean(W_CP,1);   CP_sem = nanstd(W_CP,0,1)./sqrt(size(W_CP,1));
    CPo_mean= nanmean(W_CPo,1);  CPo_sem= nanstd(W_CPo,0,1)./sqrt(size(W_CPo,1));
    EP_mean = nanmean(W_EP,1);   EP_sem = nanstd(W_EP,0,1)./sqrt(size(W_EP,1));
    EPo_mean= nanmean(W_EPo,1);  EPo_sem= nanstd(W_EPo,0,1)./sqrt(size(W_EPo,1));
    x = t_ms(:)'; co = lines(4);

    % ---- 幅度窗图：同时标出 MMN 与 P3a 幅度窗 ----
    fh = figure('Name', sprintf('IGNORE Frontal Diff (Amp) idev=%d', idev), 'Color','w', 'Position',[100 100 900 420]);
    movegui(fh,'center'); hold on;
    fill([x fliplr(x)],[CP_mean+CP_sem fliplr(CP_mean-CP_sem)],co(1,:),'FaceAlpha',0.15,'EdgeColor','none');
    fill([x fliplr(x)],[CPo_mean+CPo_sem fliplr(CPo_mean-CPo_sem)],co(2,:),'FaceAlpha',0.15,'EdgeColor','none');
    fill([x fliplr(x)],[EP_mean+EP_sem fliplr(EP_mean-EP_sem)],co(3,:),'FaceAlpha',0.15,'EdgeColor','none');
    fill([x fliplr(x)],[EPo_mean+EP_sem fliplr(EPo_mean-EPo_sem)],co(4,:),'FaceAlpha',0.15,'EdgeColor','none');
    p1=plot(x,CP_mean,'Color',co(1,:),'LineWidth',1.5);
    p2=plot(x,CPo_mean,'Color',co(2,:),'LineWidth',1.5);
    p3=plot(x,EP_mean,'Color',co(3,:),'LineWidth',1.5);
    p4=plot(x,EPo_mean,'Color',co(4,:),'LineWidth',1.5);
    yl=ylim; plot([0 0],yl,':','Color',[0 0 0 0.6]); plot(xlim,[0 0],':','Color',[0 0 0 0.6]);
    % 标出两个幅度窗
    patch([MMN_amp_win(1)*1000 MMN_amp_win(2)*1000 MMN_amp_win(2)*1000 MMN_amp_win(1)*1000],[yl(1) yl(1) yl(2) yl(2)],[0 0 0],'FaceAlpha',0.06,'EdgeColor','none');
    patch([P3a_amp_win(1)*1000 P3a_amp_win(2)*1000 P3a_amp_win(2)*1000 P3a_amp_win(1)*1000],[yl(1) yl(1) yl(2) yl(2)],[0 0 0],'FaceAlpha',0.06,'EdgeColor','none');
    text(mean(MMN_amp_win)*1000, yl(2)*0.9, 'MMN amp', 'HorizontalAlignment','center');
    text(mean(P3a_amp_win)*1000, yl(2)*0.9, 'P3a amp', 'HorizontalAlignment','center');
    xlabel('Time (ms)'); ylabel('Amplitude (\muV)'); title(sprintf('IGNORE Frontal (Amp windows) idev=%d',idev));
    legend([p1 p2 p3 p4],{'Control-Pre','Control-Post','Experimental-Pre','Experimental-Post'},'Location','best'); box on; grid on;
    print(fh, sprintf('IGNORE_Frontal_Diff_Amp_idev%d.png', idev), '-dpng','-r300');

    % ---- 潜伏期窗图：同时标出 MMN 与 P3a 潜伏期窗 ----
    fh2 = figure('Name', sprintf('IGNORE Frontal Diff (Lat) idev=%d', idev), 'Color','w', 'Position',[100 540 900 420]);
    movegui(fh2,'center'); hold on;
    p1=plot(x,CP_mean,'Color',co(1,:),'LineWidth',1.5);
    p2=plot(x,CPo_mean,'Color',co(2,:),'LineWidth',1.5);
    p3=plot(x,EP_mean,'Color',co(3,:),'LineWidth',1.5);
    p4=plot(x,EPo_mean,'Color',co(4,:),'LineWidth',1.5);
    yl=ylim; plot([0 0],yl,':','Color',[0 0 0 0.6]); plot(xlim,[0 0],':','Color',[0 0 0 0.6]);
    % 标出两个潜伏期窗
    patch([MMN_lat_win(1)*1000 MMN_lat_win(2)*1000 MMN_lat_win(2)*1000 MMN_lat_win(1)*1000],[yl(1) yl(1) yl(2) yl(2)],[0 0 0],'FaceAlpha',0.06,'EdgeColor','none');
    patch([P3a_lat_win(1)*1000 P3a_lat_win(2)*1000 P3a_lat_win(2)*1000 P3a_lat_win(1)*1000],[yl(1) yl(1) yl(2) yl(2)],[0 0 0],'FaceAlpha',0.06,'EdgeColor','none');
    text(mean(MMN_lat_win)*1000, yl(2)*0.9, 'MMN lat', 'HorizontalAlignment','center');
    text(mean(P3a_lat_win)*1000, yl(2)*0.9, 'P3a lat', 'HorizontalAlignment','center');
    xlabel('Time (ms)'); ylabel('Amplitude (\muV)'); title(sprintf('IGNORE Frontal (Latency windows) idev=%d',idev));
    legend([p1 p2 p3 p4],{'Control-Pre','Control-Post','Experimental-Pre','Experimental-Post'},'Location','best'); box on; grid on;
    print(fh2, sprintf('IGNORE_Frontal_Diff_Lat_idev%d.png', idev), '-dpng','-r300');

    % ================== per-subject 宽表行 ==================
    for s=1:nCon
        PS(end+1,:) = {idev, sprintf('C_%03d',s), 'Control', ...
            ampMMN_C_Pre(s), ampMMN_C_Post(s), ampP3a_C_Pre(s), ampP3a_C_Post(s), ...
            latMMN_C_Pre(s), latMMN_C_Post(s), latP3a_C_Pre(s), latP3a_C_Post(s)};
    end
    for s=1:nExp
        PS(end+1,:) = {idev, sprintf('E_%03d',s), 'Experimental', ...
            ampMMN_E_Pre(s), ampMMN_E_Post(s), ampP3a_E_Pre(s), ampP3a_E_Post(s), ...
            latMMN_E_Pre(s), latMMN_E_Post(s), latP3a_E_Pre(s), latP3a_E_Post(s)};
    end
end

% ================== 写 CSV：perSubject_metrics_wide_ignore.csv ==================
fn = 'perSubject_metrics_wide_ignore.csv';
fid = fopen(fn,'w');
fprintf(fid, 'DeviantIdx,Subject,Group,Amp_MMN_Pre,Amp_MMN_Post,Amp_P3a_Pre,Amp_P3a_Post,Lat_MMN_Pre_ms,Lat_MMN_Post_ms,Lat_P3a_Pre_ms,Lat_P3a_Post_ms\n');
for i=1:size(PS,1)
    fprintf(fid, '%d,%s,%s,%.10g,%.10g,%.10g,%.10g,%.10g,%.10g,%.10g,%.10g\n', ...
        PS{i,1}, PS{i,2}, PS{i,3}, PS{i,4}, PS{i,5}, PS{i,6}, PS{i,7}, PS{i,8}, PS{i,9}, PS{i,10}, PS{i,11});
end
fclose(fid);

% ================== 写 CSV：ANOVA_GroupXTime_ignore_summary.csv ==================
fn = 'ANOVA_GroupXTime_ignore_summary.csv';
fid = fopen(fn,'w');
fprintf(fid, 'DeviantIdx,DV,F,df1,df2,p,BF10,BF01,Evidence\n');
for i=1:size(Summary,1)
    dv   = Summary{i,2};
    Fval = Summary{i,3};
    df1  = Summary{i,4};
    df2  = Summary{i,5};
    p    = Summary{i,6};
    BF10 = Summary{i,7};
    BF01 = Summary{i,8};
    lab  = Summary{i,9};
    if isnan(df1), df1out=''; else, df1out=num2str(df1); end
    if isnan(df2), df2out=''; else, df2out=num2str(df2); end
    fprintf(fid, '%d,%s,%.6g,%s,%s,%.6g,%.6g,%.6g,%s\n', Summary{i,1}, dv, Fval, df1out, df2out, p, BF10, BF01, lab);
end
fclose(fid);

fprintf('\n[IGNORE | DIFF latency] 导出完成：\n  - perSubject_metrics_wide_ignore.csv\n  - ANOVA_GroupXTime_ignore_summary.csv\n  - 每个 idev 的 PNG 图（全部窗口已居中显示）：\n    * IGNORE_Frontal_Diff_Amp_idev#.png\n    * IGNORE_Frontal_Diff_Lat_idev#.png\n');

%% ===== 依赖说明 =====
% * 需要 Statistics and Machine Learning Toolbox（fitlme、dataset/nominal）。
% * 若透明度或 lines 颜色在老版本不可用，可将 fill 的 'FaceAlpha' 去掉或调整。
