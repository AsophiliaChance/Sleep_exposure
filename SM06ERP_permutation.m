%% statistics
%% load files
clc;clear
%% compute difference wave
load('E:\study2\002\IG\PreIg\subject_avgallbad.mat')

cfg           = [];
cfg.operation = 'subtract';
cfg.parameter = 'avg';
for i=1:length(DEV1)
    prediff1{i} = ft_math(cfg, DEV1{i}, STD1{i});
    prediff2{i} = ft_math(cfg, DEV2{i}, STD2{i});
end
clear STD1 DEV1 STD2 DEV2
%%
load('G:\study2\002\IG\postIg\subject_avgallbad.mat')
cfg           = [];
cfg.operation = 'subtract';
cfg.parameter = 'avg';
for i=1:length(DEV1)
    postdiff1{i} = ft_math(cfg, DEV1{i}, STD1{i});
    postdiff2{i} = ft_math(cfg, DEV2{i}, STD2{i});
end

%% statistics
cfg = [];
cfg.channel = 'all';

layout = ft_prepare_layout(cfg,  STD2{1});

 cfg.method = 'triangulation';
% % cfg.neighbourdist = 0.7;
 cfg.layout = layout;
cfg.feedback = 'yes'; %%with this you get the feedback plot
neighbours = ft_prepare_neighbours(cfg, STD1{1});
%%

cfg=[];
cfg.channel          = 'all';
cfg.latency          = [-0.1 0.5960];
cfg.method           = 'montecarlo';
cfg.statistic        = 'depsamplesT';
cfg.correctm         = 'cluster';
cfg.clusteralpha     = 0.05;
cfg.clusterstatistic = 'maxsum';
cfg.neighbours       = neighbours;  % same as defined for the between-trials experiment
cfg.tail             = 0;
cfg.clustertail      = 0;
cfg.alpha            = 0.1;
cfg.numrandomization = 5000;
cfg.minnbchan        = 2; 

Nsubj  = 19;
design = zeros(2, Nsubj*2);
design(1,:) = [1:Nsubj 1:Nsubj];
design(2,:) = [ones(1,Nsubj) ones(1,Nsubj)*2];

cfg.design = design;
cfg.uvar   = 1;
cfg.ivar   = 2;
%[stat1] = ft_timelockstatistics(cfg, prediff1{:}, postdiff1{:});
[stat2] = ft_timelockstatistics(cfg, prediff2{:}, postdiff2{:});

cd('G:\study2\002\IG\result')
save('ERPstatistics','stat2')

[rows,cols,~] =find(stat2.mask==1);
rows=unique(rows);
cols=unique(cols);
%% plot grand average