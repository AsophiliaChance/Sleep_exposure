%
clear;clc;
%
resamp_srate = 250;
basedir = {'G:\study2\002\IG\pre','G:\study2\002\IG\post','G:\study2\001control\IG\pre','G:\study2\001control\IG\post'};
%EEG = pop_fileio('E:\study2\001\pre\SM_111_preIg 20140506 1202 004.raw', 'dataformat','auto');

filt ='*.raw';
%%
eeglab;
close(gcf);

%%
for md=4
     i=0;
    cd(basedir{md});
    outputdir = basedir{md};
    files = dir(filt);
    %%
    for curfile = 1:length(files)
        %70-72pre√ª”–event
        
        file = files(curfile).name;
        EEG =pop_readegi([pwd,'\',file], [],[],'auto');
        [pth,nam,ext] = fileparts(file);
        
        filenam = strtrim(nam);
        %trimmedString = strtrim(originalString);
        fprintf('Working on %s\n',[nam ext]);
        if ismember('a011',{EEG.event.type}.')
            i=i+1;
            
             [~,rejections,~] = pop_rejcont(EEG,'onlyreturnselection','on','taper','hamming');
           
            xmax(md,i,1)=EEG.xmax ;
            EEG = pop_select(EEG,'nopoint',rejections);
            xmax(md,i,2)=EEG.xmax;
            xmax(md,i,3)=xmax(md,i,1)-xmax(md,i,2);
            EEG = pop_saveset( EEG, 'filename',[filenam '_mas1.set'],'filepath',outputdir);
            %EEG = pop_resample( EEG, resamp_srate);
                      
            EEG=pop_chanedit(EEG, {'lookup','S:\\Program\\matlab2019toolbox\\eeglab_current\\eeglab2024.0\\plugins\\dipfit\\standard_BEM\\elec\\standard_1005.elc'},'lookup','S:\\Program\\matlab2019toolbox\\eeglab_current\\eeglab2024.0\\plugins\\dipfit\\standard_BESA\\egi128_GSN.sfp');
            
            %     %Step3: detect bad channel
            EEG1 = pop_clean_rawdata(EEG,'FlatlineCriterion','off','ChannelCriterion',0.7,'LineNoiseCriterion','off','Highpass','off','BurstCriterion','off','WindowCriterion','off','BurstRejection','off','Distance','Euclidian');
            a=EEG1.etc;
            
            if isfield(a,'clean_channel_mask')
                a.clean_channel_mask(126)=1;
                a.clean_channel_mask(127)=1;
                
                badchan_SM{i,1}=find(a.clean_channel_mask==0);
            else
                badchan_SM{i,1}=[];
            end
            
            [EEG2,  Channels_Excluded] = pop_rejchan(EEG, 'elec',[1:125,128],'threshold',4,'norm','on','measure','spec' );
            
            % Save information about Bad Channels excluded from ICA
            badchan_SM{i,2}=Channels_Excluded;
            badchan_SM{i,3}=unique([(badchan_SM{i,1})',badchan_SM{i,2}]);
            
            %interpolate
            EEG = pop_interp(EEG,badchan_SM{i,3} , 'spherical');
            EEG = pop_saveset( EEG, 'filename',[filenam '_clean2.set'],'filepath',outputdir);           
            
            EEG = pop_resample( EEG, resamp_srate);
            EEG = pop_eegfiltnew(EEG, 'locutoff',0.1);
            EEG = pop_eegfiltnew(EEG,'hicutoff',30);
            %% ICA
            EEG_forICA = pop_resample(EEG, 100);
            EEG_forICA = pop_eegfiltnew(EEG_forICA, 1, 0, 1650, 0, [], 0);
            EEG_forICA = pop_runica(EEG_forICA, 'icatype', 'runica', 'extended',1,'interrupt','off');
            
            
            EEG.icaweights = EEG_forICA.icaweights;
            EEG.icasphere  = EEG_forICA.icasphere;
            
            EEG = pop_saveset( EEG, 'filename',[filenam,'_ICA3.set'],'filepath',outputdir);
            
        end
    end
   
end
