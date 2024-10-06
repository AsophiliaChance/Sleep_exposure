% for last two week
clear;clc;eeglab
load('E:\study2\002\sleep\script\possibletriger.mat')
data=possibel_triger;
%¸Ämarker
filt='*.set';
basedir = 'E:\study2\002\sleep\data_preprocess';
cd(basedir);
outputdir = 'E:\study2\002\sleep\data_markchange';
files = dir(filt);

%%
for curfile = 31:length(files)
    file = files(curfile).name;
     EEG = pop_loadset(file,pwd);
    [pth,nam,ext] = fileparts(file);
    filenam = nam;
    xx = length(EEG.event);
    
    %%
    % search for triggers within sound duration (needs subtraction)
    Sessiontest=[];
    %latency
    temp = struct2cell(EEG.urevent.').'; urevent = table([EEG.urevent.latency].', 'VariableNames', {'latency'});clear temp
    urevent=table2array(urevent);
    urevent=urevent.*4000;
    Sessiontest(:,1)=urevent;
   
    %marker
    temp = struct2cell(EEG.event.').'; event = table(temp(:, 7), 'VariableNames', {'type'});clear temp
    event=table2array(event);
    Idx=find(ismember(event,'boundary'));
    for i=1:length(Idx)
        
    event{Idx(i)}='S 0  '; 
    end
    event1=[];
    for ii=1:length(event)
        event1(ii)= str2num(event{ii}(2:4));       
    end  
    Sessiontest=[];
    Sessiontest(:,3)=event1;
  Sessiontest_correct=[];
    clear temp;
    for i=2:xx-3
    y = Sessiontest(i+1,1)-Sessiontest(i,1);
    if y < 240000 
        Sessiontest_correct(i+1,3) = Sessiontest(i+1,3)-Sessiontest(i,3);
    end
    y2 = Sessiontest(i+2,1)-Sessiontest(i,1);
    if y2 < 240000 
        Sessiontest_correct(i+2,3) = Sessiontest(i+2,3)-Sessiontest(i+1,3)-Sessiontest(i,3);
    end
    y3 = Sessiontest(i+3,1)-Sessiontest(i,1);
    if y3 < 240000 
        Sessiontest_correct(i+3,3) = Sessiontest(i+3,3)-Sessiontest(i+2,3)-Sessiontest(i+1,3)-Sessiontest(i,3);
    end
end

%%replace 0 and unnecessary corrections with original value  and negatives with 0

clearvars xx

xx = length(Sessiontest_correct);
for i=2:xx
    if Sessiontest_correct(i,3) == 0
        Sessiontest_correct(i,3) = Sessiontest(i,3); 
    end
    
    if Sessiontest_correct(i,3) < 0 && (Sessiontest(i-1,3) == 1 || Sessiontest(i-1,3) == 2 || Sessiontest(i-1,3) == 3 || Sessiontest(i-1,3) == 4 || Sessiontest(i-1,3) == 8 || Sessiontest(i-1,3) == 12 || Sessiontest(i-1,3) == 16 || Sessiontest(i-1,3) == 32 || Sessiontest(i-1,3) == 48 || Sessiontest(i-1,3) ==  64 || Sessiontest(i-1,3) == 128  || Sessiontest(i-1,3) == 192)
        Sessiontest_correct(i,3) =  Sessiontest(i,3);
    end
    if Sessiontest_correct(i,3) < 0
        Sessiontest_correct(i,3) = 0;
    end
    if Sessiontest_correct(i,3) > 0 && (Sessiontest(i,3) == 1 || Sessiontest(i,3) == 2 || Sessiontest(i,3) == 3 || Sessiontest(i,3) == 4 || Sessiontest(i,3) == 8 || Sessiontest(i,3) == 12 || Sessiontest(i,3) == 16 || Sessiontest(i,3) == 32 || Sessiontest(i,3) == 48 || Sessiontest(i,3) ==  64 || Sessiontest(i,3) == 128  || Sessiontest(i,3) == 192)
        Sessiontest_correct(i,3) =  Sessiontest(i,3);
    end
end


%%copy other information
clearvars y y2 y3 xx
 %% divide into rooms, fix simultaneous and remove zeros
Session_room =[];
Session_room1 = Sessiontest_correct(:,:);
xx = length(Sessiontest_correct);
iroom=str2num(filenam(end));
EEG1=EEG;
for i=2:xx
    if ismember(Session_room1(i,3),data(:,(iroom-1)*3+1))
         Session_room{i} = num2str(data(1,(iroom-1)*3+1));
  
    elseif ismember(Session_room1(i,3),data(:,(iroom-1)*3+2))
          Session_room{i} = num2str(data(1,(iroom-1)*3+2));

    elseif ismember(Session_room1(i,3),data(:,(iroom-1)*3+3))
         Session_room{i} = num2str(data(1,(iroom-1)*3+3));

    else
        Session_room{i}= '0';
    end
    EEG1.event(i).type=Session_room{i};
end
EEG1.event(1).type='0';
EEG1 = pop_saveset( EEG1, 'filename',[filenam '_MCor0.set'],'filepath',outputdir);  
end