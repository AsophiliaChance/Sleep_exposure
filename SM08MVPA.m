%% MVPA
%%
clear;clc;
%% 导入的数据应为单个被试keep trial的数据
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
        if md==1
            predata{subj,1}=dev1;
            predata{subj,2}=dev2;
            predata{subj,3}=std1;
            predata{subj,4}=std2;
        else
            postdata{subj,1}=dev1;
            postdata{subj,2}=dev2;
            postdata{subj,3}=std1;
            postdata{subj,4}=std2;
        end
    end
end
%%
for nsub=1:19
    for i=1:4
        npre(i)=size(predata{nsub,i}.trial,1);
        npost(i)=size(postdata{nsub,i}.trial,1);
    end
    
    
    
    cfg = [] ;
    cfg.method           = 'mvpa';
    cfg.features         = [];
    cfg.mvpa.classifier  = 'svm';
    cfg.mvpa.metric      = 'auc';
    cfg.mvpa.k           = 10;
    cfg.mvpa.repeat      = 1;
    
    
    for i=1:4
        cfg.design           =[];
        cfg.design           = [ones(npre(i),1); 2*ones(npost(i),1)];
        
        stat{nsub,i} = ft_timelockstatistics(cfg, predata{nsub,i}, postdata{nsub,i});      
    end
    
end
cd('E:\study2\002\IG\result')
save('Ig_MVPA_result','stat');
load('E:\study2\002\IG\PreIg\subject_avgallbad.mat')
%%
cfg = [];
cfg.channel     = [1];  
for n=1:19
    for i=1:4
mvpa_result{n,i}        = ft_preprocessing(cfg, DEV1{1});
mvpa_result{n,i}.avg=stat{n,i}.auc;
null_data{n,i}=mvpa_result{n,i};
null_data{n,i}.avg=zeros(1,175)+0.5;
    end
end
%%
gavg=[];
cfg=[];
cfg.parameter      = 'avg';
for i=1:4
    gavg{i}=ft_timelockgrandaverage(cfg,mvpa_result{:,i});
end
%% group level statistics
cfg=[];
cfg.method           = 'montecarlo';
cfg.statistic        = 'depsamplesT';
cfg.correctm         = 'cluster';
cfg.clusteralpha     = 0.01;
cfg.clusterstatistic = 'maxsum';
%cfg.neighbours       = neighbours;  % same as defined for the between-trials experiment
cfg.tail             = 1;
cfg.clustertail      = 1;
cfg.alpha            = 0.01;
cfg.numrandomization = 10000;


Nsubj  = 19;
design = zeros(2, Nsubj*2);
design(1,:) = [1:Nsubj 1:Nsubj];
design(2,:) = [ones(1,Nsubj) ones(1,Nsubj)*2];

cfg.design = design;
cfg.uvar   = 1;
cfg.ivar   = 2;
%[stat1] = ft_timelockstatistics(cfg, prediff1{:}, postdiff1{:});
for i=1:4
mvpa_1ttest{i} = ft_timelockstatistics(cfg, mvpa_result{:,i}, null_data{:,i});
any(mvpa_1ttest{i}.mask)
end
save('IG_mvpa_statistics','mvpa_1ttest','gavg');
