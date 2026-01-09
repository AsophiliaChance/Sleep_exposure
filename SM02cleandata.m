clear;clc;
%%
basedir = {'E:\study2\002\PreIg','E:\study2\002\PostIg'};
filt ='*_antiblank2.set';
matfileNAM={'pre','post'};
%%
eeglab;
close(gcf);

%%
for md=1:2
cd(basedir{md});
outputdir = basedir{md};
rawData = dir(filt);
for subjID = 1:length(rawData)
    loadName = rawData(subjID).name;
    
    % Step1: Import data.
    EEG = pop_loadset(loadName);
    [pth,nam,ext] = fileparts(loadName);
    dataName = nam(1:19);
    
%     %Step2: add reference electrode
%     EEG.nbchan = EEG.nbchan+1;
%     EEG.data(end+1,:) = zeros(1, EEG.pnts);
%     EEG.chanlocs(1,EEG.nbchan).labels = 'Cz';
%     
%     %Step3: detect bad channel
     EEG=pop_chanedit(EEG, {'lookup','S:\\Program\\matlab2019toolbox\\eeglab_current\\eeglab2024.0\\plugins\\dipfit\\standard_BEM\\elec\\standard_1005.elc'},'lookup','S:\\Program\\matlab2019toolbox\\eeglab_current\\eeglab2024.0\\plugins\\dipfit\\standard_BESA\\GSN-HydroCel-129.sfp');
    EEG1 = pop_clean_rawdata(EEG,'FlatlineCriterion','off','ChannelCriterion',0.85,'LineNoiseCriterion','off','Highpass','off','BurstCriterion','off','WindowCriterion','off','BurstRejection','off','Distance','Euclidian');
    a=EEG1.etc;
    
    if isfield(a,'clean_channel_mask')
        a.clean_channel_mask(126)=1;
        a.clean_channel_mask(127)=1;

        badchan_SM{subjID,1}=find(a.clean_channel_mask==0);
    else
        badchan_SM{subjID,1}=[];
    end
    
    [EEG2,  Channels_Excluded] = pop_rejchan(EEG, 'elec',[1:125,128],'threshold',4,'norm','on','measure','spec' );
    
    % Save information about Bad Channels excluded from ICA
    badchan_SM{subjID,2}=Channels_Excluded;
    badchan_SM{subjID,3}=unique([(badchan_SM{subjID,1})',badchan_SM{subjID,2}]);
    
    %interpolate
    EEG = pop_interp(EEG,badchan_SM{subjID,3} , 'spherical');
    
    
    
    %Step5: Detect artefact
    % automated FFT based continuous data rejection
    [~,rejections,~] = pop_rejcont(EEG,'freqlimit',[70 125],'onlyreturnselection','on','threshold',10,'epochlength',0.5,'contiguous',4,'addlength',0.25,'taper','hamming');
    rejdataSM{subjID}=rejections;
%                    toplot = [rejections repmat([0 1 0],size(rejections,1),1) repmat(1:129,size(rejections,1),1)];
%                    eegplot(EEG.data,'srate',EEG.srate,'winlength',5,'winrej',toplot,'eloc_file',EEG.chanlocs);
    EEGlen(subjID,1)=EEG.xmax;
    EEG = pop_select(EEG,'nopoint',rejections);
    EEGlen(subjID,2)=EEG.xmax;
    EEGlen(subjID,3)=EEGlen(subjID,1)-EEGlen(subjID,2);
    
    % save data
    EEG = pop_saveset(EEG, 'filename',[dataName '_cleandata3.set'], 'filepath', outputdir);
end
 save([matfileNAM{md},'_cleanlog.mat'],'badchan_SM','rejdataSM','EEGlen');
end
