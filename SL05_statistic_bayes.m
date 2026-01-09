%% =====================================================
% SL05_full_stat_plot.m
% ERP: One-sample t-tests + LMM + Bayes Factor + 原版画图 + 窗口输出 + Excel
% =====================================================
clc; clear;
eeglab;
%% -------------------- 路径与输入 --------------------
cd('G:\study2\002\sleep\2ndanalysis\results');

filename={'day1_nsubavg120.mat','day2_nsubavg120.mat','day3_nsubavg120.mat'};
channelsToAvg = {'FPz', 'C3', 'C4'};

%% -------------------- 读数据 + 预处理（与原脚本一致） --------------------
%平均目标electrol,
for md = 1:3
    load(filename{md}); channel_idx = find(ismember(Diff_avg{1,1}.label, channelsToAvg));
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

%% -------------------- grand average（与原脚本一致） --------------------
cfg = []; cfg.channel='all'; cfg.latency='all'; cfg.parameter='avg';
for md=1:3
    for idev=1:2
        if md==2
            Diff_gavg{md,idev} = ft_timelockgrandaverage(cfg, Diff1{md,1:19,idev});
            Diff1{md,20,idev}  = Diff_gavg{md,idev};
            STD_gavg{md,idev}  = ft_timelockgrandaverage(cfg, STD{md,1:19,idev});
            STD{md,20,idev}  = STD_gavg{md,idev};
            DEV_gavg{md,idev}  = ft_timelockgrandaverage(cfg, DEV{md,1:19,idev});
            DEV{md,20,idev}  = DEV_gavg{md,idev};
        else
            Diff_gavg{md,idev} = ft_timelockgrandaverage(cfg, Diff1{md,:,idev});
            STD_gavg{md,idev}  = ft_timelockgrandaverage(cfg, STD{md,:,idev});
            DEV_gavg{md,idev}  = ft_timelockgrandaverage(cfg, DEV{md,:,idev});
        end
    end
end

%% -------------------- 定义时间窗（与原脚本一致） --------------------
Diff_ga=[]; DEV_ga=[];
for idev=1:2
    for md=1:3
        DEV_ga(idev,md,:)  = DEV_gavg{md,idev}.avg;
        Diff_ga(idev,md,:) = Diff_gavg{md,idev}.avg;
    end
end
Diff_ga = squeeze(mean(mean(Diff_ga,2),1));
DEV_ga  = squeeze(mean(mean(DEV_ga,2),1));
winlenght = 0.035;
time = Diff_gavg{md, idev}.time;

idx_min = find(Diff_gavg{md, idev}.time >= 0.35 & Diff_gavg{md, idev}.time <= 0.47);
[~, minIdx] = max(DEV_ga(idx_min));  minTime = time(idx_min(minIdx));
idx_max = find(time >= 0.5 & time <= 0.7);
[~, maxIdx] = max(Diff_ga(idx_max)); maxTime = time(idx_max(maxIdx));

win=[]; % 名称沿用
win.mmn1=minTime-winlenght; win.mmn2=minTime+winlenght;
win.p31=maxTime-0.05;       win.p32=maxTime+0.05;

%% -------------------- Peak detection（与原脚本一致） --------------------
isub=0;
for md =1:3
    for idev = 1:2
        for isub = 1:size(Diff1,2)
            data = Diff1{md, isub, idev};
            
            idx = find(data.time >= win.mmn1 & data.time <= win.mmn2);
            [~, peakIdx] = min(data.avg(idx));
            latency_diff.mmn(md, isub, idev)    = data.time(idx(peakIdx));
            amplitude_diff.mmn(md, isub, idev)  = mean(data.avg(idx));
            
            idx = find(data.time >= win.p31 & data.time <= win.p32);
            [~, peakIdx] = max(data.avg(idx));
            latency_diff.p3(md, isub, idev)     = data.time(idx(peakIdx));
            amplitude_diff.p3(md, isub, idev)   = mean(data.avg(idx));
        end
    end
end

% 另存简化数据
amplitude_mmn = amplitude_diff.mmn;
amplitude_p3  = amplitude_diff.p3;
latency_mmn   = latency_diff.mmn;
latency_p3    = latency_diff.p3;
save('erp_statisticsdata_simple.mat','amplitude_mmn','amplitude_p3','latency_mmn','latency_p3','-v7');
save('erp_statisticsdata.mat','amplitude_diff','latency_diff');

%% =====================================================
% 画图（严格沿用你的代码）+ 保存 LMM 数据表 T 以便后续BF
% =====================================================
set(groot,'defaultAxesTickLength',[0.03 0.06])

% ---------- Amplitude ----------
clc
data = cat(3, amplitude_diff.mmn, amplitude_diff.p3);
figure('Position', [100 100 800 230])
componentTitles = {'Small P2','Large P2','Small P450','Large P450'};

T_all_ampl = cell(1,4);
amplitudeFE = cell(1,4);

for i = 1:4
    subplot(1,4,i); hold on
    
    Days = repmat((1:3)',20,1);
    Subjects = repelem((1:20)',3);
    Y = reshape(data(:,:,i),[],1);
    n = 20;
    
    T = table(Subjects,Days,Y);
    T.Subjects = categorical(T.Subjects);
    T.Days = categorical(T.Days);
    T_all_ampl{i} = T;                         % 保存
    
    lme = fitlme(T, 'Y ~ Days + (1|Subjects)','FitMethod','REML');
    
    if iscategorical(T.Days), T.DayNum = double(T.Days); else, T.DayNum = T.Days; end
    days_list = [2,3,4];
    mean_Y = groupsummary(T,"DayNum","mean","Y");
    sem_Y  = groupsummary(T,"DayNum","std","Y");
    sem_Y.std_Y  = sem_Y.std_Y / sqrt(n);
    
    bar(days_list, mean_Y.mean_Y, 0.5, 'FaceAlpha',0.5, 'EdgeColor','none');
    errorbar(days_list, mean_Y.mean_Y, sem_Y.std_Y, 'k.', 'LineWidth',1, 'CapSize',5);
    
    ax = gca;
    if i <= 2
        ylim(ax,[0 1.5]); ax.YTick=[0 0.5 1 1.5];
    else
        ax.YDir='normal'; ylim(ax,[0 4]); ax.YTick=0:1:4;
    end
    
    xticks(days_list)
    set(gca, 'FontSize', 10);
    if i==1
        xlabel('Night', 'FontSize', 15,'FontWeight', 'bold');
        ylabel('Amplitude (μV)', 'FontSize', 15,'FontWeight', 'bold');
    end
    title(componentTitles{i}, 'FontSize', 15)
    set(findall(gcf,'-property','FontWeight'), 'FontWeight', 'bold')
    
    [~,~,FE] = fixedEffects(lme,'DFMethod','Satterthwaite');
    amplitudeFE{i}= FE; disp(FE)
    
    pvals = FE.pValue;  % (Intercept, Days_2, Days_3)
    p2star = @(p) repmat('*',1,(p<0.05)+(p<0.01)+(p<0.001));
    ySpan = range(ylim(ax));
    starOffset=0.02*ySpan;
    nStar = 0;
    for d = 2:3
        if pvals(d) < 0.05
            nStar = nStar + 2;
            barTops = mean_Y.mean_Y([1 d-1]);     % 与你的代码一致的取法
            yBase   = max(barTops);
            baseAdd = 0.45; if i==1, baseAdd = 0.15; end
            yLine = yBase + baseAdd + (nStar-1)*0.15;
            line([1.7 d+1.3],[yLine yLine], 'Parent',ax, 'Color','k','LineWidth',1.2);
            xMid = mean([2 d+1]); yStar = yLine + starOffset;
            text(xMid, yStar, p2star(pvals(d)), 'HorizontalAlignment','center','VerticalAlignment','middle','FontSize',12);
        end
    end
    hold off
end
sgtitle('Amplitude', 'FontWeight','bold', 'FontSize',20);
print(gcf,'-dtiff','-r400','bar_amplitude.tif');

%% ---------- Latency ----------

set(groot,'defaultAxesTickLength',[0.03 0.06])
data = cat(3, latency_diff.mmn, latency_diff.p3);
figure('Position', [100 100 800 230])

T_all_lat = cell(1,4);
latencyFE  = cell(1,4);

for i = 1:4
    subplot(1,4,i); hold on
    
    Days = repmat((1:3)',20,1);
    Subjects = repelem((1:20)',3);
    Y = reshape(data(:,:,i),[],1);
    n = 20;
    
    T = table(Subjects,Days,Y);
    T.Subjects = categorical(T.Subjects);
    T.Days = categorical(T.Days);
    T_all_lat{i} = T;                         % 保存
    
    lme = fitlme(T, 'Y ~ Days + (1|Subjects)');
    
    if iscategorical(T.Days), T.DayNum = double(T.Days); else, T.DayNum = T.Days; end
    days_list = [2,3,4];
    mean_Y = groupsummary(T,"DayNum","mean","Y") ;
    sem_Y  = groupsummary(T,"DayNum","std","Y");
    sem_Y.std_Y  = sem_Y.std_Y / sqrt(n);
    
    bar(days_list, 1000*(mean_Y.mean_Y-0.2), 0.5, 'FaceAlpha',0.5, 'EdgeColor','none');
    errorbar(days_list, 1000*(mean_Y.mean_Y-0.2), 1000*(sem_Y.std_Y), 'k.', 'LineWidth',1, 'CapSize',5);
    
    ax = gca;
    if i <= 2
        ylim(ax,[150 250]); ax.YTick=150:20:250;
    else
        ax.YDir='normal'; ylim(ax,[330 430]); ax.YTick=330:20:430;
    end
    
    xticks(days_list)
    set(gca, 'FontSize', 10);
    if i==1
        xlabel('Night', 'FontSize', 15,'FontWeight', 'bold');
        ylabel('Latency (ms)', 'FontSize', 15,'FontWeight', 'bold');
    end
    title(componentTitles{i}, 'FontSize', 15)
    set(findall(gcf,'-property','FontWeight'), 'FontWeight', 'bold')
    
    [~,~,FE] = fixedEffects(lme,'DFMethod','Satterthwaite');
    latencyFE{i}= FE; disp(FE)
    
    pvals = FE.pValue;
    p2star = @(p) repmat('*',1,(p<0.05)+(p<0.01)+(p<0.001));
    ySpan = range(ylim(ax)); starOffset=0.02*ySpan;
    nStar = 0;
    for d = 2:3
        if i==1 && d==2 %if pvals(d) < 0.05
            nStar = nStar + 1;
            barTops = mean_Y.mean_Y([1 d-1]);
            yBase = max(barTops);
            yLine = (yBase + (nStar-1)*0.1 + 0.01)*1000-200+10;
            line([1.7 d+1.3],[yLine yLine], 'Parent',ax, 'Color','k','LineWidth',1.2);
            xMid = mean([2 d+1]); yStar = yLine + starOffset;
            %             line([1 d],[yLine yLine], 'Parent',ax, 'Color','k','LineWidth',1.2);
            %             xMid = mean([1 d]); yStar = yLine + starOffset;
            text(xMid, yStar, p2star(pvals(d)), 'HorizontalAlignment','center','VerticalAlignment','middle','FontSize',12);
        end
    end
    
    
    hold off
end
sgtitle('Latency', 'FontWeight','bold', 'FontSize',20);
print(gcf,'-dtiff','-r400','bar_latency.tif');

%% ---------- waveform（与你的代码一致） ----------
clc
deviant_type={'Small deviant','Large deviant'};
ax=[]; dataplot{3}=Diff_gavg; dataplot{1}=STD_gavg; dataplot{2}=DEV_gavg;
 dataplot1{3}=Diff1; dataplot1{1}=STD; dataplot1{2}=DEV;
mycolor = [31 120 180;   % 蓝色 (blue)
    227 26 28;    % 红色 (red)
    150 150 150] / 255;   % 灰色 (gray)

for idev=1:2
    ax=[]; figure('Position', [100, 100, 800, 300]);
    for idata=1:3
        data=dataplot{idata};
        data1=dataplot1{idata};
        ax{idata}= subplot(1,3,idata);
        for iday = 1:3
            nSub = size(Diff1, 2);   % 例如 20
            tmp = [];
            for isub = 1:nSub
                data_sub = STD{iday, isub, idev};  % 取出对应的三维 cell 数组 (Diff1 / STD / DEV)
                tmp(isub, :) = data_sub.avg(50:250);
            end
            wave_all = tmp;
            sem = std(wave_all, 0, 1) / sqrt(nSub);
            avg =data{iday, idev}.avg(50:250);
            t = STD_gavg{1,1}.time(1:201);
            
%             % 绘制阴影和主线
%             fill([t fliplr(t)], [avg - sem, fliplr(avg + sem)], ...
%                 mycolor(iday,:), 'FaceAlpha', 0.25, 'EdgeColor', 'none'); hold on;
            
           h_all(iday) = plot(t, avg, 'LineWidth', 2, 'Color', mycolor(iday,:)); hold on;
            
            
            x1 = win.mmn1 - 0.2; y1=-4; width1 = 0.07; height1 = 8;
            rectangle('Position', [x1, y1, width1, height1], 'EdgeColor', mycolor(1,:), 'LineStyle', '--','LineWidth', 1);
            x2 = win.p31-0.2; y2 = -4; width2 = 0.1; height2 = 8;
            rectangle('Position', [x2, y2, width2, height2], 'EdgeColor', mycolor(2,:), 'LineStyle', '--', 'LineWidth', 1);
            graphname = { 'Standard'; 'Deviant';'Differential'};
            title( graphname{idata}, 'fontweight', 'bold');
            

                fill([t fliplr(t)], [avg - sem, fliplr(avg + sem)], ...
         mycolor(iday,:), 'FaceAlpha', 0.25, 'EdgeColor', 'none'); hold on;
     if idata==1
            text(0.23, 2.3, 'P2', 'FontSize', 10, 'Color',mycolor(1,:), 'Rotation', 90);
            text(0.38, 2.3, 'P450', 'FontSize', 10, 'Color',mycolor(2,:), 'Rotation', 90);
     end
            
            set(gca, 'FontSize', 12, 'fontweight', 'bold');
            axis([-0.100 0.7 -1.5 3.5]); xticks([0,0.2, 0.4, 0.6 ]);
            yticks([-3, -2,-1 0,1 2, 3]); set(gca, 'box', 'off'); axis square; set(gca, 'TickLength', [0.02, 0.025]);
        end
                if idata==1
                ylabel('Amplitude (\muV)'); xlabel('Time (s)');
                %legend({'Night 2','Night 4','Night 6'},'Location','Northeast','FontSize',10,'Box','off');
                leg = legend( h_all,{ 'Night 2'; 'Night 3'; 'Night 4'}, 'Location', 'Northeast', 'Orientation', 'vertical', 'FontSize', 10, 'fontweight', 'bold', 'box', 'off');
                leg.ItemTokenSize = [9,9]; set(leg, 'Units', 'normalized');
                pos = get(leg, 'Position'); pos(2)=pos(2)-0.03; pos(1)=pos(1)+0.01; set(leg, 'Position', pos);
            end

    end

    
    for i = 1:length(ax)
        pos = get(ax{i}, 'Position'); pos(1)=pos(1)-0.03*(i-1); pos(2)=pos(2)-0.02; pos(3)=pos(3)-0.025; pos(4)=pos(4)-0.02;
        set(ax{i}, 'Position', pos);
    end
    change={'Small change','Large change'};
    annotation('textbox', [0.3, 0.94, 0.4, 0.05], 'String',change{idev}, 'EdgeColor','none', 'HorizontalAlignment','center', 'FontWeight','bold', 'FontSize', 20);
    set(findall(gcf, '-property', 'FontName'), 'FontName', 'Times New Roman');
    filename = sprintf('ERP%d.tiff', idev);
    print(filename, '-dtiff', '-r600');
end

%% =====================================================  
% 统计分析脚本
% LMM + Bayes Factor (BIC近似, 传统定义: BF10)
% 输出: 仅传统意义 BF10 (即 p(data|H1)/p(data|H0))
% =====================================================

clc;

three = @(x) round(double(x),3);   % 保留三位小数

% ---------- 初始化 ----------
rows = {}; 
r = 1;
labels = {'Small P2','Large P2','Small P450','Large P450'};

% =====================================================
%  measureType = 1 → Amplitude (REML)
%  measureType = 2 → Latency   (REML)
% =====================================================
for measureType = 1:2   
    if measureType==1
        T_all = T_all_ampl;       % 含振幅数据
        fitMethod = 'REML';
        measureName = 'Amplitude';
    else
        T_all = T_all_lat;        % 含潜伏期数据
        fitMethod = 'REML';
        measureName = 'Latency';
    end

    for i = 1:4
        T = T_all{i};
        % ----------------- 拟合完整模型 -----------------
        lme_full = fitlme(T,'Y ~ Days + (1|Subjects)','FitMethod','ML');
        BIC_full = lme_full.ModelCriterion.BIC;

        % ----------------- Night3 vs Night2 -----------------
        D3 = T.Days;
        D3(D3=='2') = '1'; 
        D3 = removecats(D3);
        T3 = T; T3.Days = D3;

        lme_reduced3 = fitlme(T3,'Y ~ Days + (1|Subjects)','FitMethod','ML');
        BIC_reduced3 = lme_reduced3.ModelCriterion.BIC;

        % 传统定义: BF10 = exp((BIC_H0 - BIC_H1)/2)
        BF10_3 = exp((BIC_reduced3 - BIC_full)/2);

        % ----------------- Night4 vs Night2 -----------------
        D4 = T.Days;
        D4(D4=='3') = '1'; 
        D4 = removecats(D4);
        T4 = T; T4.Days = D4;

        lme_reduced4 = fitlme(T4,'Y ~ Days + (1|Subjects)','FitMethod','ML');
        BIC_reduced4 = lme_reduced4.ModelCriterion.BIC;

        BF10_4 = exp((BIC_reduced4 - BIC_full)/2);

        % ----------------- 固定效应估计与置信区间 -----------------
        [beta, namesTblOrCell, st] = fixedEffects(lme_full,'DFMethod','Satterthwaite');
        CI = coefCI(lme_full,'Alpha',0.05,'DFMethod','Satterthwaite');

        % ----------------- 打印到命令行 -----------------
        fprintf('\n[%s] %s\n', measureName, labels{i});
        fprintf('  BF10 (Night3 vs Night2) = %.3f\n', three(BF10_3));
        fprintf('  BF10 (Night4 vs Night2) = %.3f\n', three(BF10_4));

        % ----------------- 写入结果表 -----------------
        for k = 1:numel(beta)
            eff = char(st.Name{k});
            BFval = NaN;
            if contains(eff,'Days_2'), BFval = three(BF10_3); end
            if contains(eff,'Days_3'), BFval = three(BF10_4); end
            condLBL = 'Small'; if mod(i,2)==0, condLBL='Large'; end

            rows(r,:) = {measureName, labels{i}, condLBL, eff, ...
                three(beta(k)), three(st.SE(k)), three(st.DF(k)), ...
                three(st.tStat(k)), three(st.pValue(k)), ...
                three(CI(k,1)), three(CI(k,2)), BFval};
            r = r + 1;
        end
    end
end

% ---------- 汇总输出表 ----------
T_LMM_BF = cell2table(rows,'VariableNames', ...
   {'Measure','Component','Condition','Effect','Estimate','SE','DF','t','p', ...
    'CI_Lower','CI_Upper','BF10'});

disp('===== LMM + 传统定义 BF10 (BIC近似) 结果 =====');
format shortG;
disp(T_LMM_BF);

% ---------- 导出 Excel ----------
out_file = 'ERP_LMM_BF10.xlsx';
writetable(T_LMM_BF, out_file, 'Sheet','LMM_BF10');
fprintf('\n=== 结果已保存至 %s ===\n', fullfile(pwd,out_file));


%% tttttttttttttttttttttttttttttttttttttttttttttttttttttttttt
%% =====================================================  
% One-sample t test + Bonferroni correction + Bayes Factor (BIC近似)
% 输出: p值、校正p、BF10、log10BF10 (三位小数)
% 输入要求:
%   amplitude_diff.mmn, amplitude_diff.p3, latency_diff.mmn, latency_diff.p3
%   每个维度: [night x subj x cond]
% =====================================================

clc;

% -------------------- 定义函数 --------------------
three = @(x) round(double(x),3);   % 保留三位小数

% -------------------- One-sample t-tests --------------------
components = {'MMN_amp','P3_amp','MMN_lat','P3_lat'};
data_all   = {amplitude_diff.mmn, amplitude_diff.p3, latency_diff.mmn, latency_diff.p3};

os_rows = {}; 
r = 1;
p_all = [];   % 用于 Bonferroni

for c = 1:numel(components)
    A = data_all{c}; % [night x subj x cond]
    for md = 1:size(A,1)   % 每个 night
        for idev = 1:size(A,3)   % 每种 deviant (Small / Large)
            v = squeeze(A(md,:,idev));
            v = v(:);
            v = v(~isnan(v));     % 去除 NaN
            n = numel(v);

            % ---------- 频率学 One-sample t 检验 ----------
            [~,p,~,st] = ttest(v,0);
            p_all = [p_all; p];

            % ---------- Bayes 因子 (BIC近似) ----------
            RSS1 = sum( (v - mean(v)).^2 );
            RSS0 = sum( v.^2 );
            k1 = 2; k0 = 1;
            epsRSS = 1e-12;
            RSS1 = max(RSS1, epsRSS);
            RSS0 = max(RSS0, epsRSS);
            BIC1 = n*log(RSS1/n) + k1*log(n);
            BIC0 = n*log(RSS0/n) + k0*log(n);
            BF10 = exp( (BIC0 - BIC1)/2 );   % 偏好 μ≠0 的证据
            log10BF10 = log10(BF10);

            % --- 保留三位小数 ---
            BF10 = round(BF10,3);
            log10BF10 = round(log10BF10,3);

            condLBL = 'Small'; 
            if idev==2, condLBL='Large'; end

            os_rows(r,:) = {components{c}, md, condLBL, ...
                three(mean(v)), three(std(v)), ...
                three(st.tstat), three(st.df), ...
                three(p), NaN, '', BF10, log10BF10};
            r = r + 1;
        end
    end
end

% -------------------- Bonferroni 校正 --------------------
p_corr_all = min(p_all * numel(p_all), 1);

for i = 1:length(p_corr_all)
    p_corr = p_corr_all(i);
    if p_corr<0.001
        pstars='***';
    elseif p_corr<0.01
        pstars='**';
    elseif p_corr<0.05
        pstars='*';
    else
        pstars='';
    end

    if p_corr < 0.0005
        p_corr_str = sprintf('%.3f%s', 0, pstars);
    else
        p_corr_str = sprintf('%.3f%s', p_corr, pstars);
    end

    os_rows{i,9}  = three(p_corr);     % 数值型 p_corr
    os_rows{i,10} = p_corr_str;        % 字符串型 p_corr (带星号)
end

% -------------------- 结果输出 --------------------
T_onesamp = cell2table(os_rows,'VariableNames', ...
    {'Component','Night','Condition','Mean','SD','t','df','p_raw', ...
     'p_corr_num','p_corr_str','BF10','log10BF10'});

disp('===== One-sample t test + Bayes Factor (BIC近似) 结果 =====');
format shortG; % 控制台显示短格式
disp(T_onesamp);

% -------------------- 保存到 Excel --------------------
outFile = 'OneSample_with_BF.xlsx';
writetable(T_onesamp, outFile, 'Sheet', 'OneSample');
fprintf('\n结果已保存至: %s\n', outFile);


%% =====================================================
% 统计： LMM + Bayes Factor + CI + Excel（无 function）
% =====================================================

three = @(x) round(double(x),3);   % 保留三位小数

% ---------- LMM + BF + CI ----------
rows = {}; r = 1;
labels = {'Small P2','Large P2','Small P450','Large P450'};

for measureType = 1:2   % 1=Amplitude, 2=Latency
    if measureType==1
        T_all = T_all_ampl;
        fitMethod = 'REML';
        measureName = 'Amplitude';
    else
        T_all = T_all_lat;
        fitMethod = 'ML';
        measureName = 'Latency';
    end

    for i = 1:4
        T = T_all{i};
        lmeML = fitlme(T,'Y ~ Days + (1|Subjects)','FitMethod',fitMethod);

        % 固定效应估计 + 置信区间
        [beta, namesTblOrCell, st] = fixedEffects(lmeML,'DFMethod','Satterthwaite');
        CI = coefCI(lmeML,'Alpha',0.05,'DFMethod','Satterthwaite');

        % --- Bayes 因子 ---
        lme_full = fitlme(T,'Y ~ Days + (1|Subjects)','FitMethod','ML');
        BICf = lme_full.ModelCriterion.BIC;

        D = T.Days;
        % Night3 vs Night2
        D3 = D; D3(D=='2')='1'; D3 = removecats(D3);
        T3 = T; T3.Days = D3;
        lme3 = fitlme(T3,'Y ~ Days + (1|Subjects)','FitMethod','ML');
        BIC3 = lme3.ModelCriterion.BIC;
        BF3 = exp((BIC3 - BICf)/2);

        % Night4 vs Night2
        D4 = D; D4(D=='3')='1'; D4 = removecats(D4);
        T4 = T; T4.Days = D4;
        lme4 = fitlme(T4,'Y ~ Days + (1|Subjects)','FitMethod','ML');
        BIC4 = lme4.ModelCriterion.BIC;
        BF4 = exp((BIC4 - BICf)/2);

        logBF3 = log10(BF3); logBF4 = log10(BF4);

        % 命令行输出
        fprintf('\n[%s] %s\n', measureName, labels{i});
        for k=1:numel(beta)
            p = st.pValue(k);
            if p<0.001, pstars='***';
            elseif p<0.01, pstars='**';
            elseif p<0.05, pstars='*';
            else, pstars='';
            end
            if p < 0.0005
                pdisp = sprintf('%.3f%s', 0, pstars);
            else
                pdisp = sprintf('%.3f%s', p, pstars);
            end

            fprintf('  %-10s  b=% .3f, SE=%.3f, DF=%.3f, t=% .3f, p=%s, 95%% CI=[%.3f, %.3f]\n', ...
                st.Name{k}, three(beta(k)), three(st.SE(k)), three(st.DF(k)), ...
                three(st.tStat(k)), pdisp, three(CI(k,1)), three(CI(k,2)));
        end
        fprintf('  BF(Night3 vs Night2) = %.3f | log10(BF10)=%.3f\n', three(BF3), three(logBF3));
        fprintf('  BF(Night4 vs Night2) = %.3f | log10(BF10)=%.3f\n', three(BF4), three(logBF4));

        % 汇总入表
        for k=1:numel(beta)
            eff = char(st.Name{k});
            BF=''; BF10='';
            if contains(eff,'Days_2'), BF = three(BF3); BF10 = three(logBF3); end
            if contains(eff,'Days_3'), BF = three(BF4); BF10 = three(logBF4); end
            condLBL = 'Small'; if mod(i,2)==0, condLBL='Large'; end

            p = st.pValue(k);
            if p<0.001, pstars='***';
            elseif p<0.01, pstars='**';
            elseif p<0.05, pstars='*';
            else, pstars='';
            end
            if p < 0.0005
                pdisp = sprintf('%.3f%s', 0, pstars);
            else
                pdisp = sprintf('%.3f%s', p, pstars);
            end

            rows(r,:) = {measureName, labels{i}, condLBL, eff, ...
                three(beta(k)), three(st.SE(k)), three(st.DF(k)), ...
                three(st.tStat(k)), pdisp, ...
                three(CI(k,1)), three(CI(k,2)), three(BF), three(BF10)};
            r = r + 1;
        end
    end
end

%% ---------- 汇总输出表 ----------
T_LMM_BF = cell2table(rows,'VariableNames', ...
   {'Measure','Component','Condition','Effect','Estimate','SE','DF','t','p','CI_Lower','CI_Upper','BF','BF10'});

% ---------- 导出 Excel ----------
out_file = 'ERP_statistics_full.xlsx';
writetable(T_onesamp, out_file, 'Sheet','OneSampleT_Bonferroni');
writetable(T_LMM_BF, out_file, 'Sheet','LMM_BayesFactor_CI');
fprintf('\n=== 结果已保存至 %s ===\n', fullfile(pwd,out_file));


%% ================== 局部函数：必须放在脚本末尾 ==================
function s = p_with_stars(p)
% 返回三位小数+星号的字符串
if p < 0.0005
    s = sprintf('%.3f%s', 0, stars(p));  % 显示为 0.000***
else
    s = sprintf('%.3f%s', p, stars(p));
end
end

function s = stars(p)
if p<0.001, s='***';
elseif p<0.01, s='**';
elseif p<0.05, s='*';
else, s='';
end
end

% 用“同一数据 + ML 拟合 + 合并类别”计算 Night3/Night4 vs Night2 的 BF
function [BF3, BF4] = bf_from_T(T)
lme_full = fitlme(T,'Y ~ Days + (1|Subjects)','FitMethod','ML');
BICf = lme_full.ModelCriterion.BIC;

D = T.Days;

% Night3 合并到 Night2
D3 = D; D3(D=='2')='1'; D3 = removecats(D3);
T3 = T; T3.Days = D3;
lme3 = fitlme(T3,'Y ~ Days + (1|Subjects)','FitMethod','ML');
BIC3 = lme3.ModelCriterion.BIC;
BF3 = exp((BIC3 - BICf)/2);

% Night4 合并到 Night2
D4 = D; D4(D=='3')='1'; D4 = removecats(D4);
T4 = T; T4.Days = D4;
lme4 = fitlme(T4,'Y ~ Days + (1|Subjects)','FitMethod','ML');
BIC4 = lme4.ModelCriterion.BIC;
BF4 = exp((BIC4 - BICf)/2);
end
