%% ======================================================================= 
%  LME (2×2 Mixed Design): Group(Control/Experiment) × Time(Pre/Post)
%  - 输出 Group×Time 交互项的 F 检验 + Estimate + SE + CI + BF10
%  - 同时计算基于BIC近似的Bayes因子
%  - 自动兼容 table / dataset
% ========================================================================

clear; clc;

%% 1) 数据文件路径
files = {'G:\study2\REACTION_TIMES_ALL.xlsx'};   % <<< 修改为实际路径

%% 2) 配置
measures   = {'RT','ACC'};         % 反应时与正确率
conditions = {'DEV_1','DEV_2'};    % Deviant条件
timeTags   = {'PRE','POST'};
mustHave   = 'CHI';                % 仅纳入 "*_CHI" 列

%% 3) 读取Excel并筛选
T = table();
for i = 1:numel(files)
    Ti = readtable(files{i}, 'FileType','spreadsheet');
    T  = [T; Ti]; %#ok<AGROW>
end

% 仅保留 *_CHI、ID、group
vnames     = string(T.Properties.VariableNames);
keepCHI    = contains(upper(vnames), upper(mustHave));
forceKeep  = contains(upper(vnames), "ID") | contains(upper(vnames), "GROUP");
T = T(:, keepCHI | forceKeep);

assert(any(strcmpi(T.Properties.VariableNames, 'ID')), '未找到 ID 列。');
T.Subject = string(T.ID);

assert(any(strcmpi(T.Properties.VariableNames, 'group')), '未找到 group 列。');
[grpCat, grpMapInfo] = map_group_safely(T.group);
T.Group = grpCat;
fprintf('Group 映射:\n'); disp(grpMapInfo);

T = T(~ismissing(T.Group), :);

%% 4) 主循环分析
results = [];

for m = 1:numel(measures)
    measure = measures{m};
    for c = 1:numel(conditions)
        cond = conditions{c};

        % 查找 PRE / POST 列
        [preVar, postVar] = findPrePostVars(T, cond, measure, timeTags, mustHave);
        if isempty(preVar) || isempty(postVar)
            fprintf('[跳过] 未找到 %s - %s 的 PRE/POST CHI 列。\n', cond, measure);
            continue;
        end

        % 构建长表
        L = table();
        L.Subject = [T.Subject;  T.Subject];
        L.Group   = [T.Group;    T.Group];
        L.Time    = categorical([repmat(string(timeTags{1}), height(T), 1); ...
                                 repmat(string(timeTags{2}), height(T), 1)], ...
                                 string(timeTags));
        L.Y       = [T.(preVar); T.(postVar)];

        L = L(~isnan(L.Y) & ~ismissing(L.Group), :);

        n_ctrl = numel(unique(L.Subject(L.Group=="Control")));
        n_exp  = numel(unique(L.Subject(L.Group=="Experiment")));
        if n_ctrl < 2 || n_exp < 2
            fprintf('[跳过] %s - %s：有效样本过少。\n', cond, measure);
            continue;
        end

        % --- LME 模型 ---
        useFormulaRand = '(Time|Subject)';
        try
            lme_full = fitlme(L, sprintf('Y ~ Group*Time + %s', useFormulaRand), 'FitMethod','ML');
            lme_redu = fitlme(L, sprintf('Y ~ Group + Time + %s', useFormulaRand), 'FitMethod','ML');
        catch
            warning('%s - %s: (Time|Subject) 不收敛，回退到 (1|Subject)。', cond, measure);
            useFormulaRand = '(1|Subject)';
            lme_full = fitlme(L, sprintf('Y ~ Group*Time + %s', useFormulaRand), 'FitMethod','ML');
            lme_redu = fitlme(L, sprintf('Y ~ Group + Time + %s', useFormulaRand), 'FitMethod','ML');
        end

        % --- (1) F 检验整体交互效应 ---
        A = anova(lme_full);
        if isa(A,'dataset')
            vnamesA = get(A,'VarNames');
        else
            vnamesA = A.Properties.VariableNames;
        end

        termCol = pick_term_col(A);
        names = string(A.(termCol));
        ridx = find(strcmp(names,'Group:Time') | strcmp(names,'Time:Group'),1);

        if isempty(ridx)
            Fval=NaN; pval=NaN; df1=NaN; df2=NaN;
        else
            Fval = A.FStat(ridx);
            pval = A.pValue(ridx);
            df1  = A.DF1(ridx);
            df2  = A.DF2(ridx);
        end

        % --- (2) 提取交互项的估计值 (Estimate / SE / CI) ---
        coefTbl  = lme_full.Coefficients;
        rowIdx = row_index_by_predicate(coefTbl, 'Name', ...
                @(s) contains(s,'Group_') && contains(s,':Time_') && contains(s,'POST'));

        if isempty(rowIdx)
            est=NaN; SE=NaN; CI_low=NaN; CI_high=NaN;
        else
            est = coefTbl.Estimate(rowIdx);
            SE  = coefTbl.SE(rowIdx);

            % CI兼容
            if istable(coefTbl)
                vnames = coefTbl.Properties.VariableNames;
            elseif isa(coefTbl,'dataset')
                vnames = get(coefTbl,'VarNames');
            else
                vnames = fieldnames(coefTbl);
            end

            if all(ismember({'Lower','Upper'}, vnames))
                if isa(coefTbl,'dataset')
                    CI_low  = coefTbl.('Lower')(rowIdx);
                    CI_high = coefTbl.('Upper')(rowIdx);
                else
                    CI_low  = coefTbl.Lower(rowIdx);
                    CI_high = coefTbl.Upper(rowIdx);
                end
            else
                df = pick_first_field_val(coefTbl, rowIdx, {'DF','DFE','DFResid'});
                if isempty(df) || isnan(df)
                    df = height(L) - 4;
                end
                tcrit = tinv(0.975, df);
                CI_low  = est - tcrit*SE;
                CI_high = est + tcrit*SE;
            end
        end

        % --- (3) 模型比较 + Bayes 因子 ---
        C = compare(lme_redu, lme_full);
        [bic_redu,bic_full] = get_compare_bic(C);
        BF10 = exp((bic_redu - bic_full)/2);

        % --- 汇总 ---
        results = [results; struct( ...
            'Measure', measure, ...
            'Condition', cond, ...
            'N_Control', n_ctrl, ...
            'N_Experiment', n_exp, ...
            'Estimate', est, ...
            'SE', SE, ...
            'CI_low', CI_low, ...
            'CI_high', CI_high, ...
            'F', Fval, ...
            'df1', df1, ...
            'df2', df2, ...
            'p', pval, ...
            'BF10', BF10 ...
        )];

        fprintf('== %s | %s ==  F(%g,%g)=%.3f, p=%.4f | β=%.3f (SE=%.3f) CI=[%.3f,%.3f] | BF10=%.3f\n', ...
            cond, measure, df1, df2, Fval, pval, est, SE, CI_low, CI_high, BF10);
    end
end

%% 5) 保存结果
if ~isempty(results)
    R = struct2table(results);
    disp('-----------------------------------------------------------');
    disp(R);
    [folder, base, ~] = fileparts(files{1});
    outPath = fullfile(folder, sprintf('%s_LME_Bayes_F.csv', base));
    writetable(R, outPath);
    fprintf('\n? 已保存结果文件: %s\n', outPath);
else
    warning('没有可用结果。');
end


%% ========================= 辅助函数 ==============================

function [preVar, postVar] = findPrePostVars(T, cond, measure, timeTags, mustHave)
    v  = string(T.Properties.VariableNames);
    U  = upper(v);
    cond  = upper(string(cond));
    meas  = upper(string(measure));
    must  = upper(string(mustHave));
    tPre  = upper(string(timeTags{1}));
    tPost = upper(string(timeTags{2}));

    isCand = contains(U, cond) & contains(U, meas) & contains(U, must);
    preIdx  = find(isCand & contains(U, tPre), 1);
    postIdx = find(isCand & contains(U, tPost), 1);
    if ~isempty(preIdx) && ~isempty(postIdx)
        preVar  = char(v(preIdx));
        postVar = char(v(postIdx));
    else
        preVar = ''; postVar = '';
    end
end

function idx = row_index_by_predicate(A, name_col, pred)
    idx = [];
    vn = varnames_any(A);
    if any(vn == string(name_col))
        col = A.(char(name_col));
        if iscellstr(col) || isstring(col), col = string(col); end
        if iscategorical(col), col = string(col); end
        for i = 1:numel(col)
            try
                if pred(string(col(i)))
                    idx = i; break;
                end
            end
        end
    end
end

function names = varnames_any(A)
    if istable(A)
        names = A.Properties.VariableNames;
    elseif isa(A,'dataset')
        names = get(A,'VarNames');
    else
        names = fieldnames(A);
    end
    names = string(names);
end

function val = pick_first_field_val(A, rowIdx, candidates)
    val = NaN;
    vn = varnames_any(A);
    for k = 1:numel(candidates)
        cand = string(candidates{k});
        if any(vn == cand)
            tmp = A.(char(cand));
            val = tmp(rowIdx);
            return;
        end
    end
end

function termCol = pick_term_col(A)
    vn = varnames_any(A);
    if any(vn == "Term"), termCol = 'Term';
    elseif any(vn == "Name"), termCol = 'Name';
    else, termCol = vn(1); end
end

function [bic_redu, bic_full] = get_compare_bic(C)
    vn = varnames_any(C);
    if any(vn == "BIC")
        b = C.BIC; bic_redu = b(1); bic_full = b(2); return;
    elseif all(ismember({'BIC1','BIC2'}, vn))
        bic_redu = C.BIC1(1); bic_full = C.BIC2(1); return;
    else
        bic_redu = NaN; bic_full = NaN;
    end
end

function [grpCat, mappingTable] = map_group_safely(rawGroup)
    mappingTable = table([],[], 'VariableNames', {'Original','Mapped'});
    n = numel(rawGroup);
    grpCat = categorical(repmat(missing, n, 1), {'Control','Experiment'});
    s = lower(strtrim(string(rawGroup)));
    isCtrl = s=="control" | s=="ctrl" | s=="1" | contains(s,"control");
    isExp  = s=="experiment" | s=="exp" | s=="2" | contains(s,"exper");
    grpCat(isCtrl) = 'Control';
    grpCat(isExp ) = 'Experiment';
    mappingTable = [mappingTable; table(string(rawGroup), string(grpCat), ...
        'VariableNames',{'Original','Mapped'})];
end
