clear;clc;
eeglab
datadir={'day0','day1','day2','day3'};
filt='*_MCor1.set';
load('G:\study2\002\sleep\data_preprocess\possibletriger.mat')
basedir = 'G:\study2\002\sleep\2ndanalysis\analysis';
filt='*_MCor0.set';
cd(basedir);
files = dir(filt);
art_thresh=125;
load('G:\study2\002\sleep\result\dataname_3day.mat');
duration1=177;duration2=185;

diff2=[];trials=[];
%%
for md=1:length(datadir)
    cd(fullfile(basedir,datadir{md}))
    outputdir = pwd;
    files = dir(filt);
%%
for curfile =1:length(files)
    file = files(curfile).name;
    
    EEG = pop_loadset(file,pwd);
    [pth,nam,ext] = fileparts(file);
    filenam = nam(1:14);
    
    EEG = pop_eegfiltnew(EEG, 'locutoff',1);
    EEG = pop_eegfiltnew(EEG,'hicutoff',30);
    EEG = pop_eegfiltnew(EEG, 'locutoff',49,'hicutoff',51,'revfilt',1);

    
    %% 去除长空余
    temp = struct2cell(EEG.event.').'; type = temp(:, 7); clear temp;%find(ismember(type,'boundary'));
    ind=find(ismember(type,'0')==0);ind=[1;ind];
    latency = [EEG.event.latency].';
    
    latenci=latency(ind);
    latenci_a=latenci;latenci_a(end)=[];
    latenci_b=latenci;latenci_b(1)=[];
    tmp=latenci_b-latenci_a;
    %temp=sort(tmp,'descend');
    delect_ind=find(tmp>200);
    
    pre_latenci=[latenci(delect_ind);latenci(end)+200];
    post_latenci=[latenci(delect_ind+1);length(EEG.times)];
    pre_latenci(:,2)=post_latenci;
    
    EEG = eeg_eegrej( EEG, pre_latenci);%934351
   % EEG = pop_saveset( EEG, 'filename',[filenam '_antiblank1b.set'],'filepath',outputdir);
    
    
    %%
    ind= str2num(filenam(end));
    trigger{1}=num2str(possibel_triger(1,(ind-1)*3+2));
    trigger{2}=num2str(possibel_triger(1,(ind-1)*3+3));
    
    %%
    EEG = pop_epoch( EEG, {  trigger{1}  trigger{2}  }, [-2  1], 'epochinfo', 'yes');
    EEG = pop_rmbase(EEG, [-100 0]);
    % Artifact rejection based on amplitude, gradient, and low signal thresholds
    % Reject epochs with:
    % - Amplitudes greater than 120 ?V
    % - Gradients greater than 75 ?V
    % - Low signal below 0.01 ?V
    EEG = pop_epoch( EEG, {  trigger{1}  trigger{2}  }, [-2         1],'valuelim', [-art_thresh   art_thresh]);
%%    
    threshold = 75; % 梯度阈值
    bad_epochs = []; % 保存有异常梯度的 epoch 索引
    
    for epoch_idx = 1:EEG.trials
        % 获取当前 epoch 数据，维度：[通道数 x 时间点数]
        data = EEG.data(1:3,:,epoch_idx);
        
        % 计算每个通道的梯度
        gradient = abs(diff(data, 1, 2)); % 对时间轴取差分
        
        % 检查是否有通道超过阈值
        if any(gradient(:) > threshold)
            bad_epochs = [bad_epochs, epoch_idx];
        end
    end
    
    % 标记或剔除异常 epoch
    EEG = pop_select(EEG, 'notrial', bad_epochs); % 删除异常 epoch
    %%
threshold = 0.01;  % 设置低信号值的阈值

% 计算每个 epoch 的最大绝对值
max_abs_values = squeeze(max(max(abs(EEG.data), [], 2), [], 1));

% 找到低于阈值的 epochs 索引
invalid_epochs = find(max_abs_values < threshold);
if ~isempty(invalid_epochs)
    EEG = pop_select(EEG, 'notrial', invalid_epochs);
end
%%
    type = {EEG.event.type}.';
    latency = [EEG.event.latency].';
    epoch = [EEG.event.epoch].';

    epoch2delete=[];
    diff1=[];diff3=[];
    for itrigger=1:2
        index = find(strcmp(type, trigger(itrigger)));
        
        for ii=1:length(index)
            i=index(ii);
            if 2<i && i<length(latency)
                diff1(ii) = latency(i+1) - latency(i);
                diff21{md,curfile}(ii) = latency(i) - latency(i-1);
                diff3(ii) = latency(i-1) - latency(i-2);
                
                if curfile>25
                    if any(epoch(i) ~= epoch(i-2:i+1))||any([diff1(ii), diff21{md,curfile}(ii), diff3(ii)] < duration1 | [diff1(ii), diff21{md,curfile}(ii), diff3(ii)] > duration2)
                        epoch2delete=[epoch2delete,epoch(i) ];
                    end
                else
                    T = tabulate(epoch);
                    epoch2delete=[epoch2delete, (T(T(:,2) ~= 4, 1))'];
                end
            else
                epoch2delete=[epoch2delete,i];
                
            end
        end
    end
    %%
    epoch2delete=unique(epoch2delete);
    ndelete(md,curfile)=length(epoch2delete);
    if ndelete(md,curfile)>1 &&  EEG.trials-ndelete(md,curfile)>100
        EEG = pop_selectevent( EEG, 'epoch',epoch2delete ,'deleteevents','off','deleteepochs','on','invertepochs','on');
    end  
        trials1(md,curfile)=EEG.trials;
    %%
    ind_boundary=[];
    for i=1:length(EEG.event)
        if ismember(str2num(EEG.event(i).type),[1,4,16,64])
            EEG.event(i).type='1';
            
        elseif ismember(str2num(EEG.event(i).type),[3,12,48,192])
            EEG.event(i).type='3';
            
        elseif ismember(str2num(EEG.event(i).type),[2,8,32,128])
            EEG.event(i).type='2';
        elseif ismember('boundary',EEG.event(i).type)
            ind_boundary=[ind_boundary;i];
        end
    end
    

    EEG = pop_saveset( EEG, 'filename',[filenam, '_preprocessed1a.set'],'filepath',outputdir);
      %  EEG = pop_saveset( EEG, 'filename',[filenam,num2str(duration1),'_',num2str(duration2),num2str(art_thresh) '_preprocessed1a.set'],'filepath',outputdir);

    end  
    
end

%save(fullfile('G:\study2\002\sleep\2ndanalysis\results',[num2str(duration1),'_',num2str(duration2), '_trials_diff2.mat']),'trials1','diff21');

