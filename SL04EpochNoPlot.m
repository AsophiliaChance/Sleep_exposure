%baseline correction, re-reference,plot
%%
clear;clc;
%
datadir={'day1','day2','day3'};
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
