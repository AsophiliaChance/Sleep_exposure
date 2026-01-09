clear;clc;
%%
basedir = {'E:\study2\002\PreIg','E:\study2\002\PostIg'};
filt ='*_lphp1.set';
matfileNAM={'pre','post'};
%%
eeglab;
close(gcf);

%%
for md=1:2
cd(basedir{md});
outputdir = basedir{md};
files = dir(filt);
for curfile =1:length(files)
    
    file = files(curfile).name;
    EEG = pop_loadset(file,pwd);
    [pth,nam,ext] = fileparts(file);
    
    filenam = nam(1:19);
    fprintf('Working on %s\n',[nam ext]);
    
%% anti blank
temp = struct2cell(EEG.event.').'; type = temp(:, 2); clear temp;%
latency = [EEG.event.latency].';
latency = [0;latency];
latenci_a=latency;latenci_a(end)=[];
latenci_b=latency;latenci_b(1)=[];
tmp=latenci_b-latenci_a;
%temp=sort(tmp,'descend');
delect_ind=find(tmp>195);

pre_latenci=[latenci_a(delect_ind);latenci_a(end)+200];
post_latenci=[latenci_b(delect_ind+3);length(EEG.times)];
pre_latenci(:,2)=post_latenci;

EEG = eeg_eegrej( EEG, pre_latenci);%934351
%±£´æÊý¾Ý
EEG = pop_saveset( EEG, 'filename',[filenam,'_antiblank2.set'],'filepath',outputdir);
end
end