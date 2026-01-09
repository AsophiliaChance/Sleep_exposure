clear;clc;

basedir = {'G:\study2\002\IG\pre','G:\study2\002\IG\post','G:\study2\001control\IG\pre','G:\study2\001control\IG\post'};
filt ='*_deIC4.set';

deviant_types = {'a007','a003'};
standard_type = 'a011';
art_thresh = 120; % +/- uV
twin = [-0.1 0.6];
savedir='G:\study2\results';
%%
eeglab;
close(gcf);
%%
for md=1:4
    cd(basedir{md});
    outputdir = basedir{md};
    files = dir(filt);
    savenam=strrep(basedir{md}, '\', '_');
    savenam=strrep(savenam, 'G:_study2_', 'S');

    for curfile =1:length(files)
        file = files(curfile).name;
        EEG = pop_loadset(file,pwd);
        [pth,nam,ext] = fileparts(file);
        
        nam = nam(1:8);
        fprintf('Working on %s\n',[nam ext]);
        %% 重参考
        %EEG=pop_chanedit(EEG, 'append',1,'changefield',{2,'labels',''},'insert',2,'insert',2,'delete',2,'delete',2,'delete',2,'insert',2,'changefield',{2,'labels','Cz'},'lookup','S:\\Program\\matlab2019toolbox\\eeglab_current\\eeglab2024.0\\plugins\\dipfit\\standard_BESA\\GSN-HydroCel-129.sfp');
        EEG=pop_chanedit(EEG, 'lookup','S:\\Program\\matlab2019toolbox\\eeglab_current\\eeglab2024.0\\plugins\\dipfit\\standard_BESA\\GSN-HydroCel-129.sfp');
        EEG = pop_reref( EEG, []);
%% 去掉不必要的event
        EEG = pop_selectevent( EEG, 'type',{'a003','a007','a011'},'deleteevents','on');
        %%
        %% 去掉不必要的event
        
        for idev=1:length(deviant_types)
            %%
            uniqueToDEV =[];uniqueToSTD = [];indices1=[];indices2=[];indices3=[];indices4=[];
            [EEG1,indices0] = pop_epoch( EEG, { deviant_types{idev}  }, [-1         0.60]);
            epoch = [EEG1.event.epoch].';

            [uniqueVals, ~, idx] = unique(epoch);
            counts = accumarray(idx, 1);
            result = uniqueVals(counts > 2);
             if ~isempty(result)
            EEG = pop_select( EEG, 'rmtrial',result);
             end
            
            [DEV,indices1] = pop_epoch( EEG1, { deviant_types{idev} }, [-0.1         0.60]);
            [STD,indices2] = pop_epoch( EEG1, { 'a011' }, [-0.1         0.60] );
            
            uniqueToDEV = setdiff(indices1(:), indices2(:));
            uniqueToSTD = setdiff(indices2(:), indices1(:));
   %%         
            if ~isempty(uniqueToDEV)
                for i=1:length(uniqueToDEV)
                    [idelete_DEVtrial(i,1),~]=find(indices1==uniqueToDEV(i));
                end
                    [DEV,indices3] = pop_selectevent( DEV, 'omitepoch',[idelete_DEVtrial],'deleteevents','off','deleteepochs','on','invertepochs','off');            
            end
            %
            if ~isempty(uniqueToSTD)
                for i=1:length(uniqueToSTD)
                    [idelete_STDtrial(1,i),~]=find(indices2==uniqueToSTD(i));
                end
                    [STD,indices4]  = pop_selectevent( STD, 'omitepoch',[idelete_STDtrial],'deleteevents','off','deleteepochs','on','invertepochs','off');               
            end
            %% remove baseline
            uniqueToDEV =[];uniqueToSTD = [];indices1=[];indices2=[];%indices3=[];indices4=[];
            DEV = pop_rmbase( DEV, [-100 0] ,[]);
            STD = pop_rmbase( STD, [-100 0] ,[]);            
            [DEV, indices1]  = pop_eegthresh(DEV, 1,[3,4,9,10,11], -120, 120, DEV.xmin, DEV.xmax,1,0);
            [STD,indices2]  = pop_eegthresh(STD, 1,[3,4,9,10,11], -120, 120, STD.xmin, STD.xmax,1,0);
            %%
            uniqueToSTD = unique([indices1(:); indices2(:)]);
            uniqueToDEV = unique([indices2(:); indices1(:)]);
            idelete_STDtrial=[];idelete_DEVtrial=[];
            %
            if ~isempty(uniqueToDEV)
                    [DEV,indices3] = pop_selectevent( DEV, 'omitepoch',uniqueToSTD,'deleteevents','off','deleteepochs','on','invertepochs','off');            
            end
            %
            if ~isempty(uniqueToSTD)
                    [STD,indices4]  = pop_selectevent( STD, 'omitepoch',uniqueToSTD,'deleteevents','off','deleteepochs','on','invertepochs','off');               
            end
            ntrial{md}.dev(curfile,idev)=DEV.trials;
            ntrial{md}.std(curfile,idev)=STD.trials;
            
            DEV = eeglab2fieldtrip(DEV, 'preprocessing');
            STD = eeglab2fieldtrip(STD, 'preprocessing');
            
            %%
            cfg = [];
            cfg.keeptrials = 'yes';
            STD_keeptrials_nsub{curfile,idev}    = ft_timelockanalysis(cfg, STD);
            DEV_keeptrials_nsub{curfile,idev}    = ft_timelockanalysis(cfg, DEV);
            
            cfg = [];
            cfg.keeptrials = 'no';
            STD_avg{curfile,idev}   = ft_timelockanalysis(cfg, STD);
            DEV_avg{curfile,idev}   = ft_timelockanalysis(cfg, DEV);
            
            cfg           = [];
            cfg.operation = 'subtract';
            cfg.parameter = 'trial';
            clssi_Diff{curfile,idev} = ft_math(cfg, DEV_keeptrials_nsub{curfile,idev} , STD_keeptrials_nsub{curfile,idev} );
            cfg.parameter = 'avg';
            Diff_avg{curfile,idev} = ft_math(cfg, DEV_avg{curfile,idev} , STD_avg{curfile,idev} );
            %%

        end
        
    end
    save([savedir,'\',savenam,'_nsubavg'],'STD_avg','DEV_avg','Diff_avg');
    save([savedir,'\',savenam,'_nsubDEVnSTDmvpa'],'STD_keeptrials_nsub','DEV_keeptrials_nsub','clssi_Diff');
 
        
    end
  save([savedir,'\','ntrial'],'ntrial');
