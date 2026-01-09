clc;clear
cd('G:\study2\002\sleep\2ndanalysis\results');

filename={'day1_nsubavg120.mat','day2_nsubavg120.mat','day3_nsubavg120.mat'};
%%
channelsToAvg = {'FPz', 'C3', 'C4'};

for md = 1:3
    load(filename{md});channel_idx = find(ismember( Diff_avg{1,1} .label, channelsToAvg));
    % 对每个受试者和设备进行数据重排及平均
    for isub = 1:size(Diff_avg,1)
        for idev = 1:2
            % 对 Diff_avg 中 F3, F4, Fz 通道数据求平均
            avg_diff=Diff_avg{isub,idev};
            avg_diff.avg= Diff_avg{isub,idev}.avg(channel_idx,:);                     
            Diff{md,isub,idev} = avg_diff;
            avg_diff.avg = mean(Diff_avg{isub,idev}.avg(channel_idx,:));
            Diff1{md,isub,idev} = avg_diff;
            
            % 同理，对 STD_avg 与 DEV_avg 也可以计算平均值
            avg_std=STD_avg{isub,idev};
            avg_std.avg  = mean(STD_avg{isub,idev}.avg (channel_idx,:));
            STD{md,isub,idev} = avg_std;
            
            avg_dev=DEV_avg{isub,idev};
            avg_dev.avg  = mean(DEV_avg{isub,idev}.avg (channel_idx,:));
            DEV{md,isub,idev}  = avg_dev;
        end
    end
end


%% grand average for plotting
cfg = [];
cfg.channel   = 'all';
cfg.latency   = 'all';
cfg.parameter = 'avg';
for md=1:3
    for idev=1:2

if md==2
     Diff_gavg {md,idev}      = ft_timelockgrandaverage(cfg, Diff1{md,1:19,idev});
     Diff1{md,20,idev}    = Diff_gavg {md,idev};
     STD_gavg {md,idev}      = ft_timelockgrandaverage(cfg, STD{md,1:19,idev});
     DEV_gavg {md,idev}      = ft_timelockgrandaverage(cfg, DEV{md,1:19,idev});
else
        Diff_gavg {md,idev}      = ft_timelockgrandaverage(cfg, Diff1{md,:,idev});
        STD_gavg {md,idev}      = ft_timelockgrandaverage(cfg, STD{md,:,idev});
         DEV_gavg {md,idev}      = ft_timelockgrandaverage(cfg, DEV{md,:,idev});
end
    end
    
end

%% define window combine deviant


Diff_ga=[];DEV_ga=[];
for idev=1:2   
    for md=1:3
    DEV_ga (idev,md,:)      =  DEV_gavg{md,idev}.avg;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Diff_ga (idev,md,:)      =  Diff_gavg{md,idev}.avg;
    end
end

 Diff_ga =squeeze(mean(mean(Diff_ga,2),1)); 
 DEV_ga =squeeze(mean(mean(DEV_ga,2),1)); 
winlenght=0.035;
time=Diff_gavg{md, idev}.time;
idx_min = find(Diff_gavg{md, idev}.time >= 0.35 & Diff_gavg{md, idev}.time <= 0.47);
        [minVal, minIdx] = max(DEV_ga(idx_min));
        minTime = time(idx_min(minIdx));
        idx_max = find(time >= 0.5 & time <= 0.7);
        [maxVal, maxIdx] = max(Diff_ga(idx_max));
        maxTime= time(idx_max(maxIdx));
        win=[];
win.mmn1=minTime-winlenght; win.mmn2=minTime+winlenght;
win.p31=maxTime-0.05; win.p32=maxTime+0.05;
%% Peak detection
latency=[]; amplitude=[];
for md = 1:3
    for idev = 1:2
        
        for isub = 1:size(Diff1,2)
           % if md~=2 && isub~=20
            data = Diff1{md, isub, idev};
            idx = find(data.time >= win.mmn1 & data.time <= win.mmn2);
%             amplitude_diff.mmn(md, isub, idev) = mean(data.avg(idx));
            [~, peakIdx] = min(data.avg(idx));
            latency_diff.mmn(md, isub, idev) = data.time(idx(peakIdx));
            % idx = find(data.time >= data.time(idx(peakIdx))-0.025 & data.time <= data.time(idx(peakIdx))+0.025 );
            amplitude_diff.mmn(md, isub, idev) = mean(data.avg(idx));
            
            
            idx = find(data.time >= win.p31 & data.time <= win.p32);
           % amplitude_diff.p3(md, isub, idev) = mean(data.avg(idx));
            [~, peakIdx] = max(data.avg(idx));
            latency_diff.p3(md, isub, idev) = data.time(idx(peakIdx));
             %idx = find(data.time >= data.time(idx(peakIdx))-0.025 & data.time <= data.time(idx(peakIdx))+0.025 );
            amplitude_diff.p3(md, isub, idev) = mean(data.avg(idx));
            %end
        end
    end
end
%%
% 假设你已有这两个变量：amplitude_diff 和 latency_diff
% 其中每个字段是 4×14×2 数组（day × subject × condition）

% 单独提取字段
amplitude_mmn = amplitude_diff.mmn;   % 4×14×2
amplitude_p3  = amplitude_diff.p3;

latency_mmn = latency_diff.mmn;
latency_p3  = latency_diff.p3;

% 保存成独立变量，R中易读取（避免嵌套结构体）
save('erp_statisticsdata_simple.mat', ...
     'amplitude_mmn', 'amplitude_p3', ...
     'latency_mmn', 'latency_p3', '-v7');

save('erp_statisticsdata.mat','amplitude_diff','latency_diff');
%%
%% 1. 准备数据（模拟）
% 对应的Day
set(groot,'defaultAxesTickLength',[0.03 0.06])   % 放在脚本最开头

clc
data = cat(3, amplitude_diff.mmn, amplitude_diff.p3);
figure('Position', [100 100 800 230])    % 改宽一点，合理布局
componentTitles = {'Small P2','Large P2','Small P450','Large P450'};

for i = 1:4
    subplot(1,4,i)
    hold on

    Days = repmat((1:3)',20,1);     
    Subjects = repelem((1:20)',3);
    Y = reshape(data(:,:,i),[],1); 
    n = 20;    % 每组14个受试者，注意加！

    T = table(Subjects,Days,Y);
    T.Subjects = categorical(T.Subjects);
    T.Days = categorical(T.Days);

   % lme = fitlme(T, 'Y ~ Days + (Days|Subjects)');
    lme = fitlme(T, 'Y ~ Days + (1|Subjects)','FitMethod','REML');
   


% % 4. 比较随机结构，选择更合适的模型
% disp('随机结构对比 (lme1 vs lme)：');
% compare(lme1, lme)
    %gee = fitgee(T, 'Y ~ Days', 'Subjects', 'Correlation','AR(1)');

    %disp(lme)

    if iscategorical(T.Days)
        T.DayNum = double(T.Days);
    else
        T.DayNum = T.Days;
    end

    days_list = [2,3,4];
    mean_Y = groupsummary(T,"DayNum","mean","Y");
    sem_Y  = groupsummary(T,"DayNum","std","Y");
    sem_Y.std_Y  = sem_Y.std_Y / sqrt(n);

    % ---- 只画柱形图 + errorbar ----
    bar(days_list, mean_Y.mean_Y, 0.5, 'FaceAlpha',0.5, 'EdgeColor','none');
    errorbar(days_list, mean_Y.mean_Y, sem_Y.std_Y, 'k.', 'LineWidth',1, 'CapSize',5);

ax = gca;                        % 当前 subplot 句柄

if i <= 2                       % -------- 前两幅（MMN）--------
       % 负值朝上
    ylim(ax,[0 1.5])             % 0 到 –2 ?V
    ax.YTick    = [0 0.5 1 1.5]; 
   
else                            % -------- 后两幅（P3a）--------
    ax.YDir     = 'normal';     % 正值朝上（默认）
    ylim(ax,[0 4])              % 0 到 3 ?V
    ax.YTick    = 0:1:4;        % 可选：刻度
end

    

    xticks(days_list)
   % xlim([0.5 4.5])
   % grid on   % 打开网格更专业
set(gca, 'FontSize', 10);
if i==1
xlabel('Night', 'FontSize', 15,'FontWeight', 'bold');
ylabel('Amplitude (μV)', 'FontSize', 15,'FontWeight', 'bold');
end
title(componentTitles{i}, 'FontSize', 15)
set(findall(gcf,'-property','FontWeight'), 'FontWeight', 'bold')
% --- SIGNIFICANCE: Day 2–4 vs Day 1 -----------------------------
 % --- SIGNIFICANCE: Day 2–4 vs Day 1 -----------------------------
    [~,~,FE] = fixedEffects(lme,'DFMethod','Satterthwaite');
   amplitudeFE{i}= FE;
   disp(FE)
    pvals = FE.pValue;                    % (Intercept, Days_2, Days_3, Days_4)

    p2star = @(p) repmat('*',1,(p<0.05)+(p<0.01)+(p<0.001));

    % Determine offsets -------------------------------------------------------
    ySpan        = range(ylim(ax));           % full axis span
    lineOffset   = 0.15 * ySpan;             % distance from bar top to line (was 0.08)
    starOffset   = 0.02 * ySpan;             % distance star above line for clarity
    if strcmp(ax.YDir,'reverse')             % reverse axis => invert offsets
        lineOffset = -lineOffset;
        starOffset = -starOffset;
    end

    nStar = 0;   % counter to stack multiple lines vertically if needed

    for d = 2:3
        if pvals(d) < 0.05
            nStar = nStar + 2;
            % Height of this significance line (stack if multiple) ---
            barTops = mean_Y.mean_Y([1 d]);
            yBase   = max(barTops);
            if strcmp(ax.YDir,'reverse'), yBase = min(barTops)-1; end
            yLine   = yBase + (nStar-1)*0.15+0.45;    % higher line level
            if i==1
            yLine   = yBase + (nStar-1)*0.15+0.15;  
            end

            % Draw horizontal line connecting Day1 and Day d ----------
            line([1.7 d+1.3],[yLine yLine], 'Parent',ax, ...
                 'Color','k','LineWidth',1.2');

            % Place star(s) slightly above line ----------------------
            xMid = mean([2 d+1]);
            yStar = yLine + starOffset;            % closer to the line
            text(xMid, yStar, p2star(pvals(d)), ...
                 'HorizontalAlignment','center', ...
                 'VerticalAlignment','middle', ...
                 'FontSize',12);
        end
    end


    hold off
end
sgtitle('Amplitude', 'FontWeight','bold', 'FontSize',20);
print(gcf,'-dtiff','-r400','bar_amplitude.tif');  % saves 400?dpi TIFF in current folder

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %%
%1. 准备数据（模拟）
% 对应的Day
set(groot,'defaultAxesTickLength',[0.03 0.06])   % 放在脚本最开头
1

data = cat(3, latency_diff.mmn, latency_diff.p3);
figure('Position', [100 100 800 230])    % 改宽一点，合理布局
componentTitles = {'Small P2','Large P2','Small P450','Large P450'};

for i = 1:4
    subplot(1,4,i)
    hold on

    Days = repmat((1:3)',20,1);     
    Subjects = repelem((1:20)',3);
    Y = reshape(data(:,:,i),[],1); 
    n = 20;   

    T = table(Subjects,Days,Y);
    T.Subjects = categorical(T.Subjects);
    T.Days = categorical(T.Days);

    lme = fitlme(T, 'Y ~ Days + (1|Subjects)');
    %disp(lme)

    if iscategorical(T.Days)
        T.DayNum = double(T.Days);
    else
        T.DayNum = T.Days;
    end

    days_list = [2,3,4];
    mean_Y = groupsummary(T,"DayNum","mean","Y") ;
    sem_Y  = groupsummary(T,"DayNum","std","Y");
    sem_Y.std_Y  = sem_Y.std_Y / sqrt(n);

    % ---- 只画柱形图 + errorbar ----
    bar(days_list, 1000*(mean_Y.mean_Y-0.2), 0.5, 'FaceAlpha',0.5, 'EdgeColor','none');
    errorbar(days_list, 1000*(mean_Y.mean_Y-0.2), 1000*(sem_Y.std_Y), 'k.', 'LineWidth',1, 'CapSize',5);

ax = gca;                        % 当前 subplot 句柄

if i <= 2                       % -------- 前两幅（MMN）--------
       % 负值朝上
    ylim(ax,[150 250])  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%           % 0 到 –2 ?V
    ax.YTick    = 150:20:250; 
    %ax.YDir     = 'reverse'; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else                            % -------- 后两幅（P3a）--------
    ax.YDir     = 'normal';     % 正值朝上（默认）
    ylim(ax,[330 430])              % 0 到 3 ?V
    ax.YTick    = 330:20:430;        % 可选：刻度
end
%     title(componentTitles{i})

    xticks(days_list)
   % xlim([0.5 4.5])
   % grid on   % 打开网格更专业
set(gca, 'FontSize', 10);
if i==1
    xlabel('Night', 'FontSize', 15,'FontWeight', 'bold');
    ylabel('Latency (ms)', 'FontSize', 15,'FontWeight', 'bold');
end
title(componentTitles{i}, 'FontSize', 15)
set(findall(gcf,'-property','FontWeight'), 'FontWeight', 'bold')
% --- SIGNIFICANCE: Day 2–4 vs Day 1 -----------------------------
 % --- SIGNIFICANCE: Day 2–4 vs Day 1 -----------------------------
    [~,~,FE] = fixedEffects(lme,'DFMethod','Satterthwaite');
   latencyFE{i}= FE;
   disp(FE)
    pvals = FE.pValue;                    % (Intercept, Days_2, Days_3, Days_4)

    p2star = @(p) repmat('*',1,(p<0.05)+(p<0.01)+(p<0.001));

    % Determine offsets -------------------------------------------------------
    ySpan        = range(ylim(ax));           % full axis span
    lineOffset   = 0.015 * ySpan;             % distance from bar top to line (was 0.08)
    starOffset   = 0.02 * ySpan;             % distance star above line for clarity
    if strcmp(ax.YDir,'reverse')             % reverse axis => invert offsets
        lineOffset = -lineOffset;
        starOffset = -starOffset;
    end

    nStar = 0;   % counter to stack multiple lines vertically if needed

    for d = 2:3
        if pvals(d) < 0.05
            nStar = nStar + 1;
            % Height of this significance line (stack if multiple) ---
            barTops = mean_Y.mean_Y([1 d]);
            yBase   = max(barTops);
            if strcmp(ax.YDir,'reverse'), yBase = min(barTops)-1; end
            yLine   = (yBase+ (nStar-1)*0.1+0.01)*1000;    % higher line level

            % Draw horizontal line connecting Day1 and Day d ----------
            line([1 d],[yLine yLine], 'Parent',ax, ...
                 'Color','k','LineWidth',1.2');

            % Place star(s) slightly above line ----------------------
            xMid = mean([1 d]);
            yStar = yLine + starOffset;            % closer to the line
            text(xMid, yStar, p2star(pvals(d)), ...
                 'HorizontalAlignment','center', ...
                 'VerticalAlignment','middle', ...
                 'FontSize',12);
        end
    end


    hold off
end
sgtitle('Latency', 'FontWeight','bold', 'FontSize',20);
print(gcf,'-dtiff','-r400','bar_latency.tif');  % saves 400?dpi TIFF in current folder
%}
%% waveform
% waveform
clc
deviant_type={'Small deviant','Large deviant'};% i=[1,2,3,4];
ax=[];
dataplot{3}=Diff_gavg;dataplot{1}=STD_gavg;dataplot{2}=DEV_gavg;
mycolor = [103 169 207; 2 129 138;4,90,141] / 255;


for idev=1:2
    ax=[];
    figure('Position', [100, 100, 800, 300]);
    
    for idata=1:3
        data=dataplot{idata};
        
        ax{idata}= subplot(1,3,idata);
        
        for iday=1:3
            plot(STD_gavg{1, 1}.time(1:201), data{iday, idev}.avg(50:250), 'LineWidth',2, 'color',mycolor(iday,:)); hold on;
            %             plot(Diff_gavg{1, 1}.time, STD_gavg{iday, idev}.avg, 'LineWidth',2); hold on;
            %             plot(Diff_gavg{1, 1}.time, DEV_gavg{iday, idev}.avg, 'LineWidth',2); hold on;
            %
            
            x1 = win.mmn1 - 0.2;
            y1=-4;
            width1 = 0.07;
            height1 = 8;
            rectangle('Position', [x1, y1, width1, height1], 'EdgeColor', mycolor(1,:), 'LineStyle', '--','LineWidth', 1);
            
            % 第二个矩形
            % x 范围：270 到 380，宽度 = 380 - 270 = 110
            % y 范围：0.5 到 2.5，底部为 0.5，高度 = 2.5 - 0.5 = 2.0
            x2 = win.p31-0.2;
            y2 = -4;
            width2 = 0.1;
            height2 = 8;
            rectangle('Position', [x2, y2, width2, height2], 'EdgeColor', mycolor(2,:), 'LineStyle', '--', 'LineWidth', 1);
            
            graphname = { 'Standard'; 'Deviant';'Differential'};
            title( graphname{idata}, 'fontweight', 'bold');
            
            
            if idata==1
                ylabel('Amplitude (\muV)');
                xlabel('Time (s)');
                leg = legend({'Night 2'; 'Night 3'; 'Night 4'; 'Day4'}, 'Location', 'Northeast', 'Orientation', 'vertical', 'FontSize', 10, 'fontweight', 'bold', 'box', 'off');
                leg.ItemTokenSize = [9,9];
                set(leg, 'Units', 'normalized');  % 使用归一化单位方便定位
                pos = get(leg, 'Position');  % pos = [left, bottom, width, height]
                
                % 将图例的左侧向右平移半个图例宽度
               pos(2)=pos(2)-0.03;
                pos(1) = pos(1)+0.01;
                set(leg, 'Position', pos);
                
            end
            % 在坐标 (0, -2) 处添加文本 "190-260ms"
            
            
            text(0.24, -2.9, 'P2', 'FontSize', 10, 'Color',mycolor(1,:), 'Rotation', 90);
            text(0.38, -2.9, 'P450', 'FontSize', 10, 'Color',mycolor(2,:), 'Rotation', 90);
            
            
            
            set(gca, 'FontSize', 12, 'fontweight', 'bold');
            axis([-0.100 0.7 -3 3.5]);
            xticks([0,0.2, 0.4, 0.6 ]);
            
            % 设置 y 轴刻度位置
            yticks([-3, -2,-1 0,1 2, 3]);
            set(gca, 'box', 'off');
            axis square;
            set(gca, 'TickLength', [0.02, 0.025]);
            
            
            
            % 设置 x 轴刻度，每隔 50ms (0.05秒)一条
            % set(gca, 'XTick', -0.1:0.05:0.6);
            % grid on;
        end
        % 调整每个子图的位置和大小，减少间距
        
        
        % hAx = axes('Position', [0 0 1 1], 'Visible', 'off');
        %text(0.06, 0.5, deviant_type{idev}, 'Units', 'normalized', 'Rotation', 90, ...
        %      'FontSize', 20,'fontweight', 'bold', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
    end
    for i = 1:length(ax)
        ax1=ax;
        pos = get(ax{i}, 'Position');
        pos(1) = pos(1) - 0.03*(i-1);  % 向右移动一点
        pos(2) = pos(2) - 0.02;  % 向上移动一点
         pos(3) = pos(3) - 0.025;
        pos(4) = pos(4) - 0.02 ;
        set(ax{i}, 'Position', pos);
    end
    
    change={'Small change','Large change'};
    annotation('textbox', [0.3, 0.94, 0.4, 0.05], ... % 你可以根据需要调整这些数值
        'String',change{idev}, ...
        'EdgeColor', 'none', ...  % 取消边框
        'HorizontalAlignment', 'center', ...
        'FontWeight', 'bold', 'FontSize', 20);
    filename = sprintf('ERP%d.tiff', idev);
    print(filename, '-dtiff', '-r600');
    
end
%%
%% ================== One-sample t test for each Night × Component ==================
results = {};
row = 1;

components = {'MMN_amp','P3_amp','MMN_lat','P3_lat'};
data_all = {amplitude_diff.mmn, amplitude_diff.p3, latency_diff.mmn, latency_diff.p3};

for c = 1:numel(components)
    data_c = data_all{c}; % [day × subj × condition]
    for md = 1:size(data_c,1)   % 每一晚
        for idev = 1:size(data_c,3)  % 每个条件
            vec = squeeze(data_c(md,:,idev));  % Nsub × 1
            [~,p,~,stats] = ttest(vec,0);
            mu = mean(vec); sd = std(vec);

            results(row,:) = {components{c}, md, idev, mu, sd, ...
                              stats.tstat, stats.df, p};
            row = row+1;
        end
    end
end

T_results = cell2table(results, ...
    'VariableNames',{'Component','Night','Condition','Mean','SD','t','df','p'});

writetable(T_results,'ERP_OneSampleT.xlsx');

%% ================== Bayes Factor for LMM ==================
% 用 BIC 近似 BF
BF_results = {};
row = 1;
for i = 1:length(amplitudeFE)
    % 构造空模型（只有截距）
    lme_full = fitlme(T,'Y ~ Days + (1|Subjects)','FitMethod','REML');
    lme_null = fitlme(T,'Y ~ 1 + (1|Subjects)','FitMethod','REML');

    BIC_full = lme_full.ModelCriterion.BIC;
    BIC_null = lme_null.ModelCriterion.BIC;

    BF10 = exp((BIC_null - BIC_full)/2);

    BF_results(row,:) = {componentTitles{i}, BIC_full, BIC_null, BF10};
    row = row+1;
end

T_BF = cell2table(BF_results, ...
    'VariableNames',{'Component','BIC_full','BIC_null','BF10'});

writetable(T_BF,'ERP_LMM_BayesFactor.xlsx');
%%
%% ================== Bayes Factor (Night 3/4 vs Night 2) ==================
BF_results = {};
row = 1;

for i = 1:length(amplitudeFE)   % 对每个成分循环
    % 取当前成分对应的数据
    % 注意：这里你在画图时构造的 T (table) 需要在循环外保存，否则会丢失
    % 建议你在 fitlme 前把每个成分的数据存到 T_all{i}
    T = T_all{i};  
    
    % -------- Night 3 vs Night 2 --------
    lme_full = fitlme(T, 'Y ~ Days + (1|Subjects)','FitMethod','REML');   % 完整模型
    % 去掉 Night 3，只保留 Intercept + Night4
    T2 = T;
    T2.Days = removecats(T2.Days, '3');   % 删除 Night 3 类别
    lme_null = fitlme(T2, 'Y ~ Days + (1|Subjects)','FitMethod','REML');  
    
    BIC_full = lme_full.ModelCriterion.BIC;
    BIC_null = lme_null.ModelCriterion.BIC;
    BF_3vs2 = exp((BIC_null - BIC_full)/2);

    % -------- Night 4 vs Night 2 --------
    T2 = T;
    T2.Days = removecats(T2.Days, '4');   % 删除 Night 4 类别
    lme_null = fitlme(T2, 'Y ~ Days + (1|Subjects)','FitMethod','REML');
    
    BIC_null = lme_null.ModelCriterion.BIC;
    BF_4vs2 = exp((BIC_null - BIC_full)/2);

    % 存结果
    BF_results(row,:) = {componentTitles{i}, BF_3vs2, BF_4vs2};
    row = row+1;
end

T_BF = cell2table(BF_results, ...
    'VariableNames',{'Component','BF_N3vsN2','BF_N4vsN2'});

writetable(T_BF,'ERP_LMM_BayesFactor_NightComparisons.xlsx');


