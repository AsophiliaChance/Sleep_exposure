%baseline correction, re-reference,plot
%%
clear;clc;
%
datadir={'day0','day1','day2','day3'};
basedir = 'G:\study2\002\sleep\2ndanalysis\analysis';
savedir =' G:\study2\002\sleep\2ndanalysis\analysis\results';
filt ='*_preprocessed1a.set';
deviant_types = {'2','3'};
elec= {'C4','C3','FPz'};
art_thresh = 120; % +/- uV
twin = [-0.1 0.7];
eeglab;
baseline=[100 200];
%close(gcf);

%%

for md=1:length(datadir)
    STD_avg=[];DEV_avg=[];Diff_avg=[];STD_keeptrials_nsub=[];DEV_keeptrials_nsub=[];clssi_Diff=[];

    cd(fullfile(basedir,datadir{md}))
    files = dir(filt);
        savenam=datadir{md};

        %%
for curfile =1:length(files)
    file = files(curfile).name;
    
    EEG = pop_loadset(file,pwd);
    EEG.nbchan  
    [pth,nam,ext] = fileparts(file);
     filenam = nam(1:14);

    fprintf('Working on %s\n',[nam ext]);



 
        %% »ùÏßÐ£Õý£¬ÖØÐÂ·Ö¶Î¡£
        
        for idev=1:length(deviant_types)
                           
            uniqueToDEV =[];uniqueToSTD = [];indices1=[];indices2=[];indices3=[];indices4=[];
            [EEG1,indices0] = pop_epoch( EEG, { deviant_types{idev}  }, [-1.5         1],'valuelim', [-120   120]);
            EEG1 = pop_rmbase( EEG1, baseline ,[]);
            %badTrialIdx = rejectTrialSTFT(EEG1.data, 3, EEG1.pnts, EEG1.srate, [1 50]);
           % EEG1 = pop_select(EEG1, 'notrial', badTrialIdx);
             EEG.nbchan  
            EEG1 = pop_saveset( EEG1, 'filename',[filenam,'_',deviant_types{idev} 'epoch3.set'],'filepath',pwd);

            
            [DEV,indices1] = pop_epoch( EEG1, { deviant_types{idev} }, [-0.1           0.9]);
            [STD,indices2] = pop_epoch( EEG1, { '1' },[-0.1           0.9]);
            DEV = pop_rmbase(DEV, baseline ,[]);
            STD = pop_rmbase(STD, baseline ,[]);



            %% remove baseline          
            
            DEV = eeglab2fieldtrip(DEV, 'preprocessing');
            STD = eeglab2fieldtrip(STD, 'preprocessing');
%%            
            cfg = [];
            cfg.keeptrials = 'yes';
            STD_keeptrials_nsub{curfile,idev}   = ft_timelockanalysis(cfg, STD);
            DEV_keeptrials_nsub{curfile,idev}   = ft_timelockanalysis(cfg, DEV);
            
            cfg = [];
            cfg.keeptrials = 'no';
            STD_avg{curfile,idev}  = ft_timelockanalysis(cfg, STD);
            DEV_avg{curfile,idev}  = ft_timelockanalysis(cfg, DEV);
            
            cfg           = [];
            cfg.operation = 'subtract';
            cfg.parameter = 'trial';
%             clssi_Diff{curfile,idev}= ft_math(cfg, DEV_keeptrials_nsub{curfile,idev}, STD_keeptrials_nsub{curfile,idev});
            cfg.parameter = 'avg';
            Diff_avg{curfile,idev}= ft_math(cfg, DEV_avg{curfile,idev}, STD_avg{curfile,idev});
        end
    
end
  EEG.nbchan  
  savedir= 'G:\study2\002\sleep\2ndanalysis\results';
     save([savedir,'\',savenam,'_nsubavg',num2str(art_thresh),'.mat'],'STD_avg','DEV_avg','Diff_avg');
%     save([savedir,'\',savenam,'_nsubDEVnSTDmvpa',num2str(art_thresh),'.mat'],'STD_keeptrials_nsub','DEV_keeptrials_nsub','clssi_Diff');
 

end

%%
DEV=[];STD=[];Diff=[];
filename={['G:\study2\002\sleep\2ndanalysis\results\day1_nsubavg',num2str(art_thresh),'.mat'],['G:\study2\002\sleep\2ndanalysis\results\day2_nsubavg',num2str(art_thresh),'.mat'],['G:\study2\002\sleep\2ndanalysis\results\day3_nsubavg',num2str(art_thresh),'.mat']};

cfg = [];
cfg.keepindividual = 'no';
for md=1:3
     load(filename{md});
    for idev=1:2
%         
%         Diff_gavg {md,idev}     = ft_timelockgrandaverage(cfg, Diff_avg{1:10,idev});
%         DEV_gavg {md,idev}     = ft_timelockgrandaverage(cfg, DEV_avg{1:10,idev});
%         STD_gavg {md,idev}     = ft_timelockgrandaverage(cfg, STD_avg{1:10,idev});
%         Diff_gavg {md,idev}     = ft_timelockgrandaverage(cfg, Diff_avg{11:end,idev});
%         DEV_gavg {md,idev}     = ft_timelockgrandaverage(cfg, DEV_avg{11:end,idev});
%         STD_gavg {md,idev}     = ft_timelockgrandaverage(cfg, STD_avg{11:end,idev});
        Diff_gavg {md,idev}     = ft_timelockgrandaverage(cfg, Diff_avg{:,idev});
        DEV_gavg {md,idev}     = ft_timelockgrandaverage(cfg, DEV_avg{:,idev});
        STD_gavg {md,idev}     = ft_timelockgrandaverage(cfg, STD_avg{:,idev});
       
    end
    
end


%% Figure 1
%% plot waveform for each subjects
chaninx=[1,2,3];


n=1;
dataname={'Diff','STD','DEV'};
for md=2%:3
     load(filename{md});
     for isub=1:18
for idev=1%:2
    h = figure('color','w');
for idata=1:3
    if idata==1
    plotdata=Diff_avg;
    elseif idata==2
    plotdata=STD_avg;
    else
    plotdata=DEV_avg;
    end
for i=1:length(chaninx)
     label=DEV_avg{1, 1}.elec.label{i};
    
    data=[];
     ax=subplot(3,3,(idata-1)*3+i);
   % ax=subplot('Position',pos_main(n,:));
    ax.Position(4) = 0.9*ax.Position(4);
    n=n+1;   
    
    axis([-0.1 twin(2) -2.0 2.0]);
    plottime=Diff_gavg{1, 2}.time;
    
    % indices of electrode for plotting and ROI
%     chanind = chaninx(i);
%     channam = label;
%     channalnam{i}=channam;
    single_chan =i;
    
    
 
%four day data    
    plot(plottime, plotdata{isub, idev}.avg(single_chan,:), 'Color',([215,25,28]./255),'LineWidth',1.5);hold on;
    plot(plottime,plotdata{isub, idev}.avg(single_chan,:), 'Color',([43,131,186]./255),'LineWidth', 1.5);hold on;    
    plot(plottime,plotdata{isub, idev}.avg(single_chan,:), 'Color','k','LineWidth', 1.5);hold on; 
    %plot(plottime,Diff_gavg{4, idev}.avg(single_chan,:), 'Color',([43,131,186]./255),'LineWidth', 1.5);hold on;
    line([twin(1)+0.1 twin(1)+0.1],[-2.4 2.3],'linestyle','--', 'Color',[0.5 0.5 0.5], 'LineWidth',1);hold on
    line([twin(1) twin(2)],[0 0],'linestyle','--', 'Color',[0.5 0.5 0.5], 'LineWidth',1);hold on


box off;

graphname=fullfile([dataname{idata},'',label]);

legend1='night2';
legend2='night3';
legend3='night4';
title(graphname,'Position', [twin(1), 3.6, 0],'fontweight','bold');

if (idata-1)*3+i==7
    ylabel('Amplitude (\muV)');
    xlabel('Time (s)');
end
if (idata-1)*3+i==1
    leg=legend(legend1,legend2,legend3,'Location','northwest','Orientation', 'vertical','FontSize', 8,'fontweight','bold','box','off');
   ax.Position
    leg.Position = [ax.Position(1)-0.14, ax.Position(2)+0.1, 0.1, 0.1];

    leg.ItemTokenSize = [9,9];
end
end
end
set(gca, 'xtick', twin(1):0.2:twin(2));
set(gca, 'ytick', -3.5:2:3.5);
set(gca,'ticklength',[0.02 0.01]);
set(gca,'FontSize',9,'fontweight','bold');

axis([twin(1) twin(2) -3.5 3.5]);
set(h,'PaperPositionMode','auto');
end
end
end%%

%% plot waveform for 4days
chaninx=[1,2,3];


n=1;
dataname={'Diff','STD','DEV'};
for idev=1:2
    h = figure('color','w');
for idata=1:3
    if idata==1
    plotdata=Diff_gavg;
    elseif idata==2
    plotdata=STD_gavg;
    else
    plotdata=DEV_gavg;
    end
for i=1:length(chaninx)
     label=DEV_avg{1, 1}.elec.label{i};
    
    data=[];
     ax=subplot(3,3,(idata-1)*3+i);
   % ax=subplot('Position',pos_main(n,:));
    ax.Position(4) = 0.9*ax.Position(4);
    n=n+1;   
    
    axis([-0.1 twin(2) -2.0 2.0]);
    plottime=Diff_gavg{1, 2}.time(1:201);
    
    % indices of electrode for plotting and ROI
%     chanind = chaninx(i);
%     channam = label;
%     channalnam{i}=channam;
    single_chan =i;
    
    
 
%four day data    
    plot(plottime, plotdata{1, idev}.avg(single_chan,50:250), 'Color',([215,25,28]./255),'LineWidth',1.5);hold on;
    plot(plottime,plotdata{2, idev}.avg(single_chan,50:250), 'Color',([43,131,186]./255),'LineWidth', 1.5);hold on;    
    plot(plottime,plotdata{3, idev}.avg(single_chan,50:250), 'Color','k','LineWidth', 1.5);hold on; 
    %plot(plottime,Diff_gavg{4, idev}.avg(single_chan,:), 'Color',([43,131,186]./255),'LineWidth', 1.5);hold on;
    line([twin(1)+0.1 twin(1)+0.1],[-2.4 2.3],'linestyle','--', 'Color',[0.5 0.5 0.5], 'LineWidth',1);hold on
    line([twin(1) twin(2)],[0 0],'linestyle','--', 'Color',[0.5 0.5 0.5], 'LineWidth',1);hold on


box off;

graphname=fullfile([dataname{idata},'',label]);

legend1='night2';
legend2='night3';
legend3='night4';
title(graphname,'Position', [twin(1), 3.6, 0],'fontweight','bold');

if (idata-1)*3+i==7
    ylabel('Amplitude (\muV)');
    xlabel('Time (s)');
end
if (idata-1)*3+i==1
    leg=legend(legend1,legend2,legend3,'Location','northwest','Orientation', 'vertical','FontSize', 8,'fontweight','bold','box','off');
   ax.Position
    leg.Position = [ax.Position(1)-0.14, ax.Position(2)+0.1, 0.1, 0.1];

    leg.ItemTokenSize = [9,9];
end
set(gca, 'xtick', twin(1):0.2:twin(2));
set(gca, 'ytick', -3.5:2:3.5);
set(gca,'ticklength',[0.02 0.01]);
set(gca,'FontSize',9,'fontweight','bold');

axis([twin(1) twin(2) -3.5 3.5]);
set(h,'PaperPositionMode','auto');
end
end
end%%
