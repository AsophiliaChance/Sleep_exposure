% delete useless channels
%down sampling
%high low band pass
%change marker and seperate into four data
clear;clc;
%%
basedir = 'E:\study2\002\sleep\data_raw';
filt='*.vhdr';
cwd = basedir;
load('E:\study2\002\sleep\script\possibletriger.mat')
data=possibel_triger;
%%
eeglab;
%close(gcf);

%%

cd(basedir);
outputdir = 'E:\study2\002\sleep\data_preprocess';
    
%load('badchan1.mat');
files = dir(filt);
%%
for curfile =1:12%length(files)
    
    file = files(curfile).name;
    EEG = pop_loadbv(pwd,file);
    [pth,nam,ext] = fileparts(file);
    
    filenam = nam(1:12);
    fprintf('Working on %s\n',[nam ext]);
    
%%
%original filter is 0.1-200Hz
    
%% 11111111111111111111111111111111111111111111111111111111111111111111111111111111111111
EEG1 = pop_select( EEG, 'channel',{'1_C4','1_C3','1_FPz','1_EOG1','1_EOG2','1_A2','1_x_acc','1_y_acc','1_z_acc','1_EMG'});
 for i = 1:length(EEG1.chanlocs)
     EEG1.chanlocs(i).labels=EEG1.chanlocs(i).labels(3:end);
 end
EEG1 = pop_saveset( EEG1, 'filename',[filenam '_1.set'],'filepath',outputdir);
        tmpEEG0 = pop_selectevent( EEG1, 'type',{'1','2','3'},'deleteevents','on');

%% 222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222

EEG1 = pop_select( EEG, 'channel',{'2_C4','2_C3','2_FPz','2_EOG1','2_EOG2','2_A2','2_x_acc','2_y_acc','2_z_acc','2_EMG'});

  for i = 1:length(EEG1.chanlocs)
     EEG1.chanlocs(i).labels=EEG1.chanlocs(i).labels(3:end);
 end
 EEG1 = pop_saveset( EEG1, 'filename',[filenam '_2.set'],'filepath',outputdir);

%% 333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
EEG1 = pop_select( EEG, 'channel',{'3_C4','3_C3','3_FPz','3_EOG1','3_EOG2','3_A2','3_x_acc','3_y_acc','3_z_acc','3_EMG'});
  for i = 1:length(EEG1.chanlocs)
     EEG1.chanlocs(i).labels=EEG1.chanlocs(i).labels(3:end);
 end
 EEG1 = pop_saveset( EEG1, 'filename',[filenam '_3.set'],'filepath',outputdir);
% 
%% %444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444  
EEG1 = pop_select( EEG, 'channel',{'4_C4','4_C3','4_FPz','4_EOG1','4_EOG2','4_A2','4_x_acc','4_y_acc','4_z_acc','4_EMG'});
 for i = 1:length(EEG1.chanlocs)
     EEG1.chanlocs(i).labels=EEG1.chanlocs(i).labels(3:end);
 end
 EEG1 = pop_saveset( EEG1, 'filename',[filenam '_4.set'],'filepath',outputdir);    

end
