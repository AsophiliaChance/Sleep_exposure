clear;clc;
%%
basedir = {'G:\study2\002\PreIg','G:\study2\002\PostIg'};
filt ='*_cleandata3.set';
matfileNAM={'pre','post'};
%%
eeglab;
close(gcf);
%%
for md=1
cd(basedir{md});
outputdir = basedir{md};
files = dir(filt);
for curfile =18:length(files)
    
    
    file = files(curfile).name;
    
    EEG = pop_loadset(file,pwd);
    [pth,nam,ext] = fileparts(file);
    ind=strfind(nam,'_');
    filenam = nam(1:19);
    fprintf('Working on %s\n',[nam ext]);
    EEG_forICA = pop_resample(EEG, 100);
    EEG_forICA = pop_eegfiltnew(EEG_forICA, 1, 0, 1650, 0, [], 0);
    EEG_forICA = pop_runica(EEG_forICA, 'icatype', 'runica', 'extended',1,'interrupt','off');
    EEG.icaweights = EEG_forICA.icaweights;
    EEG.icasphere  = EEG_forICA.icasphere;
    % Step 10: Run AMICA using calculated data rank with 'pcakeep' option
%     dataRank = sum(eig(cov(double(EEG.data'))) > 1E-6); % 1E-6 follows pop_runica() line 531, changed from 1E-7.
%     EEG_forICA = pop_resample(EEG, 100);
%     EEG_forICA = pop_eegfiltnew(EEG_forICA, 1, 0, 1650, 0, [], 0);
%     runamica15(EEG_forICA.data, 'num_chans', EEG.nbchan,...
%         'outdir', [basedir{md},'\amicaresult\' filenam(1:7)],...
%         'pcakeep', dataRank, 'num_models', 1,...
%         'do_reject', 1, 'numrej', 15, 'rejsig', 3, 'rejint', 1);
%     EEG.etc.amica  = loadmodout15([basedir{md},'\amicaresult\' filenam(1:7)]);
%     
%     EEG.etc.amica.S = EEG.etc.amica.S(1:EEG.etc.amica.num_pcs, :); % Weirdly, I saw size(S,1) be larger than rank. This process does not hurt anyway.
%     EEG.icaweights = EEG.etc.amica.W;
%     EEG.icasphere  = EEG.etc.amica.S;
%     EEG = eeg_checkset(EEG, 'ica');
     EEG = pop_saveset( EEG, 'filename',[filenam,'_runICA3.set'],'filepath',outputdir);
    %}
end
end
%save('badchan.mat', 'badchan');