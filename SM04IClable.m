clear;clc;
%%
basedir = {'G:\study2\002\PreIg','G:\study2\002\PostIg'};
filt ='*_runICA3.set';
matfileNAM={'pre','post'};
%%
eeglab;
close(gcf);
%%
for md=1:2
cd(basedir{md});
outputdir = basedir{md};
files = dir(filt);
 ICtotal_brain_delete=[];
for curfile = 1:length(files)
    file = files(curfile).name;
    EEG = pop_loadset(file,pwd);
    [pth,nam,ext] = fileparts(file);
    
    filenam = nam(1:19);
    fprintf('Working on %s\n',[nam ext]);
    
    EEG       = iclabel(EEG, 'default');
    [~,I]=max(EEG.etc.ic_classification.ICLabel.classifications,[],2);
    ICtotal_brain_delete(curfile,1)=length(EEG.etc.ic_classification.ICLabel.classifications(:,1));
    brainIdx  = find(I==1);
    othersIdx  = find(I==7);
    badIdx=find( I~=1& I~=7);
%     Idx=find(badIdx<=35);
%     badIdx=badIdx(Idx);
    goodIcIdx = sort([brainIdx;othersIdx]);
    EEG = pop_subcomp(EEG, badIdx, 0, 0);
    EEG = pop_saveset( EEG, 'filename',[filenam,'_IClabelallbad4.set'],'filepath',outputdir);
    ICtotal_brain_delete(curfile,2)=length(brainIdx);
    ICtotal_brain_delete(curfile,3)=length(badIdx);
    
end
 save([matfileNAM{md},'_ICtotal_brain_delete.mat'], 'ICtotal_brain_delete');
end