%%
clear;clc;
%%
basedir = {'E:\study2\002\IG\PreIg','E:\study2\002\IG\PostIg'};
filt ='*_keeptrials.mat';
twin = [-0.1 0.6];
matfileNAM={'pre','post'};
%%

for md=1:2
    cd(basedir{md});
    outputdir = basedir{md};
    files = dir(filt);
    

%%

for  subj = 1:length(files)
    load(files(subj).name);
    
    cfg = [];                
    cfg.method     = 'mtmconvol'; 
    cfg.taper      = 'dpss';%有利于频率的平滑，特别适合与分析gamma波（不大适合<30 Hz低频，本数据没有30 Hz以上结果，顾没有分析30 Hz以上）
    cfg.keeptrials =  'no';
    cfg.output     = 'pow';	
    cfg.foi        = 30:1:50;
    cfg.t_ftimwin    = 3./cfg.foi;    % 3 cycles per frequency (should not smaller than 3);窗口大小依据频率调节，与小波类似    
    cfg.tapsmofrq     = 0.4 .*cfg.foi;%频率平滑的宽度（这里是随着频率增加，也可考虑不变？） 
    % 2*cfg.t_ftimwin*cfg.tapsmofrq - 1需大于0，且此差值表示multitaper的数目（因此需要是整数）。此差值越大，平滑程度越大
    cfg.toi        = -0.1:0.004:0.6;
    cfg.pad = 'nextpow2';% more efficient FFT computation than the default 'maxperlen'
    if md==1
        
    TFRpre_std1{1,subj} = ft_freqanalysis(cfg, std1);
    TFRpre_std2{1,subj} = ft_freqanalysis(cfg, std2);
    TFRpre_dev1{1,subj} = ft_freqanalysis(cfg, dev1);
    TFRpre_dev2{1,subj} = ft_freqanalysis(cfg, dev2);
    cfg = [];
    cfg.baseline = [-0.1 0];
    cfg.baselinetype =   'relchange'; % 'absolute', 'relative', 'relchange', 'normchange' or 'db'
    cfg.parameter = 'powspctrm';
    TFRpre_std1{1,subj} = ft_freqbaseline(cfg, TFRpre_std1{1,subj});
    TFRpre_std2{1,subj} = ft_freqbaseline(cfg, TFRpre_std2{1,subj});
    TFRpre_dev1{1,subj} = ft_freqbaseline(cfg, TFRpre_dev1{1,subj});
    TFRpre_dev2{1,subj} = ft_freqbaseline(cfg, TFRpre_dev2{1,subj});

    else
    TFRpost_std1{1,subj} = ft_freqanalysis(cfg, std1);
    TFRpost_std2{1,subj} = ft_freqanalysis(cfg, std2);
    TFRpost_dev1{1,subj} = ft_freqanalysis(cfg, dev1);
    TFRpost_dev2{1,subj} = ft_freqanalysis(cfg, dev2);
        cfg = [];
    cfg.baseline = [-0.1 0];
    cfg.baselinetype =   'relchange'; % 'absolute', 'relative', 'relchange', 'normchange' or 'db'
    cfg.parameter = 'powspctrm';
    TFRpost_std1{1,subj} = ft_freqbaseline(cfg, TFRpost_std1{1,subj});
    TFRpost_std2{1,subj} = ft_freqbaseline(cfg, TFRpost_std2{1,subj});
    TFRpost_dev1{1,subj} = ft_freqbaseline(cfg, TFRpost_dev1{1,subj});
    TFRpost_dev2{1,subj} = ft_freqbaseline(cfg, TFRpost_dev2{1,subj});
    end
end
if md==1
    save('TFRpow.mat','TFRpre_std1','TFRpre_std2','TFRpre_dev1','TFRpre_dev2');
else
     save('TFRpow.mat','TFRpost_std1','TFRpost_std2','TFRpost_dev1','TFRpost_dev2');
end
end

%% statistics
cfg = [];
cfg.channel = 'all';

layout = ft_prepare_layout(cfg,  std1);

 cfg.method = 'triangulation';
% % cfg.neighbourdist = 0.7;
 cfg.layout = layout;
cfg.feedback = 'yes'; %%with this you get the feedback plot
neighbours = ft_prepare_neighbours(cfg, std1);


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
cfg.numrandomization = 1000;
cfg.minnbchan        = 2; 

Nsubj  = 19;
design = zeros(2, Nsubj*2);
design(1,:) = [1:Nsubj 1:Nsubj];
design(2,:) = [ones(1,Nsubj) ones(1,Nsubj)*2];

cfg.design = design;
cfg.uvar   = 1;
cfg.ivar   = 2;
%%
[stat_std1] = ft_freqstatistics(cfg, TFRpre_std1{:}, TFRpost_std1{:});
[stat_std2] = ft_freqstatistics(cfg, TFRpre_std2{:}, TFRpost_std2{:});
[stat_dev1] = ft_freqstatistics(cfg, TFRpre_dev1{:}, TFRpost_dev1{:});
[stat_dev2] = ft_freqstatistics(cfg, TFRpre_dev2{:}, TFRpost_dev2{:});

