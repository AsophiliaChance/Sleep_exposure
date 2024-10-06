clc;clear
folder_path = 'G:\night_time_trigger_correction_renamed';
file_list = dir(fullfile(folder_path, '*.dat'));

basedir = 'E:\study2\002\sleep\data_preprocess';
filt='*.set';
cd(basedir);files = dir(filt);

outputdir = 'E:\study2\002\sleep\data_markchange';
%%
% myStruct=file_list;
% fields = fieldnames(myStruct);
% data=[];
% 
% current_field = fields{1};
% data = {myStruct.name}.';
% 
% temp = data{33, :};
% myStruct(33).name = data{34, :};
% myStruct(34).name = temp;
% file_list=myStruct;
% data=[];
% m=1;
%%
% for i =[1:4,9:length(file_list)]
%     
%     file_path = fullfile(folder_path, file_list(i).name);
%     
%     fid = fopen(file_path, 'r');
%     data = fscanf(fid, '%f %f', [2 Inf]);
%     fclose(fid);
%     
%     file = files(i).name;
%     EEG = pop_loadset(file,pwd);
%     [pth,nam,ext] = fileparts(file);
%     
%     latency = [EEG.event.latency].';
%     temp = struct2cell(EEG.event.').'; type = temp(:, 7); clear temp;
%     for itype = 1:numel(type)
%         type{itype} = repmat('0', 1, 1);
%     end
%     data(1,:)=data(1,:)/4000;
%     loc=[];
%     [isInB, loc] = ismember(data(1,:), latency);
%     for iloc=1:length(loc)
%         type{loc(iloc)}= num2str(data(2,iloc));
%     end
%     if size(data,2)==length(loc)
%         for ievent = 1:length(EEG.event)
%             EEG.event(ievent).type = type{ievent};
%         end
%     else
%         mistak(m)=i;
%         m=m+1;
%     end
%     
%     EEG = pop_saveset( EEG, 'filename',[nam '_MCor.set'],'filepath',outputdir);   
% end

%%
for i = 1:30
    
    file = files(i).name;
    EEG = pop_loadset(file,pwd);
    [pth,nam,ext] = fileparts(file);
    
    temp = struct2cell(EEG.event.').'; type = temp(:, 7); clear temp;
    for i=2:length(type)
        type1(i)=str2num(type{i}(2:end));
        
    end
    
    type2=[]
    type2{1}='0';
    type2{2,1}='0';
    for i=2:length(type)-1
        type2{i+1,1}=num2str(type1(i)-type1(i+1));
        EEG.event(i+1).type = type2{i+1,1};

    end
    
    EEG = pop_saveset( EEG, 'filename',[nam '_MCor0.set'],'filepath',outputdir);
end
