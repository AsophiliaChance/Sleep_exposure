%处理前三周的数据
clc;clear
folder_path = 'G:\study2\002\sleep\night_time_trigger_correction';
datadir={'day0','day1','day2','day3'};
basedir = 'G:\study2\002\sleep\2ndanalysis\analysis';
filt='*.set';


%%
diff2=[];
for md=1:length(datadir)
    cd(fullfile(basedir,datadir{md}))
    outputdir = pwd;
    files = dir(filt);
    savenam=datadir{md};
    file_list = dir( '*.dat');
    file_list = [file_list(7:end); file_list(1:6)];
    %%
    
    for curfile = 1:length(files)%处理前三周的数据
        %%
        file = files(curfile).name;
        EEG = pop_loadset(file,pwd);
        [pth,nam,ext] = fileparts(file);
        
        temp = struct2cell(EEG.event.').'; type = temp(:, 7); clear temp;
        
        for i=2:length(type)
            type1(i)=str2num(type{i}(2:end));
            if curfile>10 && ismember({ 'S195'},type)
                EEG.event(i).type  = num2str(type1(i)-195);
            elseif curfile>10 && ~ismember({ '195'},type)
                EEG.event(i).type  = num2str(type1(i));
            end            
            
        end
        %%
        if curfile<11
            data=load(file_list(curfile).name);
            data(:,1)=data(:,1)/4000;
            
            type2=[];
            type2{1}='0';
            type2{2,1}='0';
            for i=2:length(type)-1
                type2{i+1,1}=num2str(type1(i+1)-type1(i));
                EEG.event(i+1).type = type2{i+1,1};
                
            end
            latency = [EEG.event.latency].';
            diff1 = setdiff(latency, data(:,1));
            diff2{md,curfile} = setdiff(data(:,1), latency );
        end
        EEG = pop_saveset( EEG, 'filename',[nam '_MCor0.set'],'filepath',outputdir);
        filenam=nam;
        
        
        %
        if filenam(end)=='1' && all(ismember({ '1','2','3'},type2))
            EEG = pop_selectevent( EEG, 'type',[1 2 3] ,'deleteevents','on');
            
        elseif filenam(end)=='2' && all(ismember({ '4','8','12'},type2))
            EEG = pop_selectevent( EEG, 'type',[12 4 8] ,'deleteevents','on');
            
        elseif filenam(end)=='3' && all(ismember({ '16','32','48'},type2))
            EEG = pop_selectevent( EEG, 'type',[16,32,48] ,'deleteevents','on');
            
        elseif filenam(end)=='4' && all(ismember({ '64','128','192'},type2))
            EEG = pop_selectevent( EEG, 'type',[64,128,192] ,'deleteevents','on');
        end
        EEG = pop_saveset( EEG, 'filename',[nam '_MCor0.set'],'filepath',outputdir);

    end
    
end
