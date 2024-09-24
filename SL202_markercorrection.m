clc;clear
folder_path = 'G:\night_time_trigger_correction_renamed';
file_list = dir(fullfile(folder_path, '*.dat'));

basedir = 'E:\study2\002\sleep\data_preprocess';
filt='*.set';
cd(basedir);files = dir(filt);

outputdir = 'E:\study2\002\sleep\data_preprocess';
%%
myStruct=file_list;
fields = fieldnames(myStruct);
data=[];

current_field = fields{1};
data = {myStruct.name}.';

temp = data{33, :};
myStruct(33).name = data{34, :};
myStruct(34).name = temp;
file_list=myStruct;
data=[];
m=1;
%%
for i = 1:length(file_list)
    
    file_path = fullfile(folder_path, file_list(i).name);
    
    fid = fopen(file_path, 'r');
    data = fscanf(fid, '%f %f', [2 Inf]);
    fclose(fid);
    
    file = files(i).name;
    EEG = pop_loadset(file,pwd);
    [pth,nam,ext] = fileparts(file);
    
    latency = [EEG.event.latency].';
    temp = struct2cell(EEG.event.').'; type = temp(:, 7); clear temp;
    for itype = 1:numel(type)
        type{itype} = repmat('0', 1, 1);
    end
    data(1,:)=data(1,:)/4000;
    [isInB, loc] = ismember(data(1,:), latency);
    for iloc=1:length(loc)
        type{loc(iloc)}= num2str(data(2,iloc));
    end
    if size(data,2)==length(loc)
        for ievent = 1:length(EEG.event)
            EEG.event(ievent).type = type{ievent};
        end
    else
        mistak(m)=i;
        m=m+1;
    end
    
    EEG = pop_saveset( EEG, 'filename',[nam '_MCor.set'],'filepath',outputdir);   
end
