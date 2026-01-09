clc; clear  
% 读取 EEG
EEG = pop_loadset('filename','SM201pre_deIC4.set','filepath','G:\\study2\\002\\IG\\pre\\');

clusters.Ignore_MMN = {'E20','E23','E24','E28','E4','E11','E16','E19','E3','E117','E118','E124'};
clusters.Ignore_P3a = {'E20','E23','E24','E28','E4','E11','E16','E19','E3','E117','E118','E124'};
clusters.Attend_N2b = {'E29','E30','E36','E37','E5','E6','E12','E11','E87','E104','E105','E111'};
clusters.Attend_P3b = {'E47','E52','E59','E60','E61','E62','E72','E78','E85','E91','E92','E98'};

%%
figure;
set(gcf,'Position',[100 100 500 200]);   % 整体画布

fields = fieldnames(clusters);

% 手动设置子图位置 (left, bottom, width, height)
pos = { [0.13 0.2 0.18 0.6], ...
        [0.32 0.2 0.18 0.6], ...
        [0.51 0.2 0.18 0.6], ...
        [0.69 0.2 0.205 0.6] };   % 最后一幅更宽

for i = 1:4
    ax = subplot('Position',pos{i});
    EEG_cluster = pop_select(EEG, 'channel', clusters.(fields{i}));
    data = zeros(1, EEG_cluster.nbchan);
    topoplot(data, EEG_cluster.chanlocs, ...
        'style','blank', ...
        'emarker',{'.','k',14,2});
    axis square;
    set(gca,'XLim',[-0.6 0.6],'YLim',[-0.6 0.6]); 
    tlabel = strrep(fields{i}, '_', ' ');
    
    % === 自动计算文字位置 ===
    % 中心 x = 0.5，往右移 10% 子图宽度
    xPos = 0.5 + 0.1;
    % 标题 y 统一在 1.15，最后一幅往下移 0.1
    yPos = 1.15 - (i==4)*0.09;
    
    text(xPos, yPos, tlabel, ...
        'Units','normalized', ...
        'HorizontalAlignment','center', ...
        'FontSize',8,'FontWeight', 'bold');
end

sgtitle('Electrode Clusters', 'FontSize', 10, 'FontWeight', 'bold');

% 保存为高分辨率 PNG
cd('G:\study2\results')
print(gcf,'-dpng','-r600','Electrode_Clusters.png');
