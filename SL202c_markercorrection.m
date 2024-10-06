%只保留有效mark
clear;clc;eeglab
filt='*_MCor0.set';
basedir = 'E:\study2\002\sleep\data_markchange';
cd(basedir);
outputdir = 'E:\study2\002\sleep\data_markchange';
files = dir(filt);
%%
for curfile = 1:length(files)
    file = files(curfile).name;
    
    EEG = pop_loadset(file,pwd);
    [pth,nam,ext] = fileparts(file);
    
    filenam = nam(1:14);
    temp = struct2cell(EEG.event.').'; type3 = temp(:, 7); clear temp;
    if filenam(end)=='1' && all(ismember({ '1','2','3'},type3))
        EEG = pop_selectevent( EEG, 'type',[1 2 3] ,'deleteevents','on');
        
    elseif nam(14)=='2' && all(ismember({ '4','8','12'},type3))
        EEG = pop_selectevent( EEG, 'type',[12 4 8] ,'deleteevents','on');
  
    elseif nam(14)=='3' && all(ismember({ '16','32','48'},type3))
        EEG = pop_selectevent( EEG, 'type',[16,32,48] ,'deleteevents','on');
    
    elseif nam(14)=='4' && all(ismember({ '64','128','192'},type3))
        EEG = pop_selectevent( EEG, 'type',[64,128,192] ,'deleteevents','on');
    end
        EEG = pop_saveset( EEG, 'filename',[filenam '_MCor1.set'],'filepath',outputdir);
end
