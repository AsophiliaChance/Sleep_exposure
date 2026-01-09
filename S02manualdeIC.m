%1
EEG = pop_loadset('filename','SM103Ig 20140417 1159006_ICA3.set','filepath','G:\\study2\\001control\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1   3  15], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'pre_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\pre\\');

%2
EEG = pop_loadset('filename','SM104PreIg 20140417 1418004_ICA3.set','filepath','G:\\study2\\001control\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1  2  3  4  6], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'pre_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\pre\\');
%3
EEG = pop_loadset('filename','SM105PreIg 20140424 1418004_ICA3.set','filepath','G:\\study2\\001control\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1  5], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'pre_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\pre\\');
%4
EEG = pop_loadset('filename','SM106PreIg 20140424 1011006_ICA3.set','filepath','G:\\study2\\001control\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1  2  5], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'pre_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\pre\\');
%5
EEG = pop_loadset('filename','SM107PreIg 20140424 0807006_ICA3.set','filepath','G:\\study2\\001control\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1   4   7  17], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'pre_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\pre\\');
%6
EEG = pop_loadset('filename','SM108PreIg 20140424 1205006_ICA3.set','filepath','G:\\study2\\001control\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1  11], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'pre_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\pre\\');
%7
EEG = pop_loadset('filename','SM109PreIg 20140502 0741006_ICA3.set','filepath','G:\\study2\\001control\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1  2  5], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'pre_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\pre\\');
%8
EEG = pop_loadset('filename','SM110PreIg 20140502 1005004_ICA3.set','filepath','G:\\study2\\001control\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1  2  3  5], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'pre_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\pre\\');
%9
EEG = pop_loadset('filename','SM1113PReIg 20140522 0952008_ICA3.set','filepath','G:\\study2\\001control\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1  2  4], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename([1:2,4:6]),'pre_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\pre\\');
%10
EEG = pop_loadset('filename','SM111PreIg 20140502 1216004_ICA3.set','filepath','G:\\study2\\001control\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1  5], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'pre_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\pre\\');
%11
EEG = pop_loadset('filename','SM112PreIg 20140522 0731 006_ICA3.set','filepath','G:\\study2\\001control\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1  2  3], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'pre_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\pre\\');
%12
EEG = pop_loadset('filename','SM114PreIg 20140530 0932 008_ICA3.set','filepath','G:\\study2\\001control\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1  2  5], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'pre_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\pre\\');
%13
EEG = pop_loadset('filename','SM115PreIg 20140603 0941 006_ICA3.set','filepath','G:\\study2\\001control\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1  3], 0);
%14
EEG = pop_loadset('filename','SM116PreIg 20140609 1536 004_ICA3.set','filepath','G:\\study2\\001control\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1  2  4], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'pre_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\pre\\');
%15
EEG = pop_loadset('filename','SM117PreIg 20140612 1756 004_ICA3.set','filepath','G:\\study2\\001control\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1  4], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'pre_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\pre\\');
%16
EEG = pop_loadset('filename','SM118Preig 20140623 1001 006_ICA3.set','filepath','G:\\study2\\001control\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1  2  3  6], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'pre_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\pre\\');
%17
EEG = pop_loadset('filename','SM119PreIg 20140624 0738 002_ICA3.set','filepath','G:\\study2\\001control\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1  2  5], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'pre_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\pre\\');
%18
EEG = pop_loadset('filename','SM120PreIg 20140624 1139 002_ICA3.set','filepath','G:\\study2\\001control\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1  2  3  8], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'pre_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\pre\\');
%19
EEG = pop_loadset('filename','SM121PreIg 20140624 1422 002_ICA3.set','filepath','G:\\study2\\001control\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1  2  3  4  5], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'pre_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\pre\\');
%20
EEG = pop_loadset('filename','SM122PreIg 20140626 1009 002_ICA3.set','filepath','G:\\study2\\001control\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1  4  7], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'pre_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\pre\\');
%21
EEG = pop_loadset('filename','SM_123_PreIg 20140626 1200 002_ICA3.set','filepath','G:\\study2\\001control\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1  2], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename([1:2,4:6]),'pre_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\pre\\');

%% ц╩сп112
%1
EEG = pop_loadset('filename',{'SM_111_PostIg 20140506 1202 004_ICA3.set'},'filepath','G:\\study2\\001control\\IG\\post\\');
EEG = pop_subcomp( EEG, [2  3  6], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename([1:2,4:6]),'post_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\post\\');
%2
EEG = pop_loadset('filename',{'SM123PostIg 20140701 0902  002_ICA3.set'},'filepath','G:\\study2\\001control\\IG\\post\\');
EEG = pop_subcomp( EEG, [1  3], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\post\\');
%3
EEG = pop_loadset('filename',{'SM122PostIg 20140630 1325 002_ICA3.set'},'filepath','G:\\study2\\001control\\IG\\post\\');
EEG = pop_subcomp( EEG, [1  2  4  11], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\post\\');
%4
EEG = pop_loadset('filename',{'SM121PostIg 20140627 1401 002_ICA3.set'},'filepath','G:\\study2\\001control\\IG\\post\\');
EEG = pop_subcomp( EEG, [1  2  3  5], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\post\\');
%5
EEG = pop_loadset('filename',{'SM120PostIg 20140627 1151 002_ICA3.set'},'filepath','G:\\study2\\001control\\IG\\post\\');
EEG = pop_subcomp( EEG, [1  2  4  5], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\post\\');
%6
EEG = pop_loadset('filename',{'SM119PostIg 20140627 0711002_ICA3.set'},'filepath','G:\\study2\\001control\\IG\\post\\');
EEG = pop_subcomp( EEG, [1  3], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\post\\');
%7
EEG = pop_loadset('filename',{'SM118PostIg 20140627 0956 006_ICA3.set'},'filepath','G:\\study2\\001control\\IG\\post\\');
EEG = pop_subcomp( EEG, [1  2  3  5  6  9], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\post\\');
%8
EEG = pop_loadset('filename',{'SM117PostIg2 20140616 173 004_ICA3.set'},'filepath','G:\\study2\\001control\\IG\\post\\');
EEG = pop_subcomp( EEG, [1  2  3  5], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\post\\');
%9
EEG = pop_loadset('filename',{'SM116PostIg 20140612 1602 004_ICA3.set'},'filepath','G:\\study2\\001control\\IG\\post\\');
EEG = pop_subcomp( EEG, [1  2  3], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\post\\');
%10
EEG = pop_loadset('filename',{'SM115PostIg 20140606 0834 006_ICA3.set'},'filepath','G:\\study2\\001control\\IG\\post\\');
EEG = pop_subcomp( EEG, [1  5], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\post\\');
%11
EEG = pop_loadset('filename',{'SM114PostIg 20140603 1348 008_ICA3.set'},'filepath','G:\\study2\\001control\\IG\\post\\');
EEG = pop_subcomp( EEG, [1  2  7], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\post\\');
%12
EEG = pop_loadset('filename',{'SM113PostIg 20140526 1007008_ICA3.set'},'filepath','G:\\study2\\001control\\IG\\post\\');
EEG = pop_subcomp( EEG, [1  3], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\post\\');
%13
EEG = pop_loadset('filename',{'SM110PostIg 20140506 0947004_ICA3.set'},'filepath','G:\\study2\\001control\\IG\\post\\');
EEG = pop_subcomp( EEG,[1  2  3] , 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\post\\');
%14
EEG = pop_loadset('filename',{'SM109PostIg 20140506 0748006_ICA3.set'},'filepath','G:\\study2\\001control\\IG\\post\\');
EEG = pop_subcomp( EEG,[1  2  3  4] , 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\post\\');
%15
EEG = pop_loadset('filename',{'SM108PostIg 20140428 1152008_ICA3.set'},'filepath','G:\\study2\\001control\\IG\\post\\');
EEG = pop_subcomp( EEG,[1  2  5] , 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\post\\');
%16
EEG = pop_loadset('filename',{'SM107PostIg 20140428 0952008_ICA3.set'},'filepath','G:\\study2\\001control\\IG\\post\\');
EEG = pop_subcomp( EEG, [1  4  6], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\post\\');
%17
EEG = pop_loadset('filename',{'SM106PostIg 20140428 0746006_ICA3.set'},'filepath','G:\\study2\\001control\\IG\\post\\');
EEG = pop_subcomp( EEG,[1  3] , 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\post\\');
%18
EEG = pop_loadset('filename',{'SM105PostIg 20140428 1344004_ICA3.set'},'filepath','G:\\study2\\001control\\IG\\post\\');
EEG = pop_subcomp( EEG, [1  4  6], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\post\\');
%19
EEG = pop_loadset('filename',{'SM104PostIg 20140422 1339004_ICA3.set'},'filepath','G:\\study2\\001control\\IG\\post\\');
EEG = pop_subcomp( EEG, [1  4  5  9], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\post\\');
%20
EEG = pop_loadset('filename',{'SM103PostIg 20140422 0706006_ICA3.set'},'filepath','G:\\study2\\001control\\IG\\post\\');
EEG = pop_subcomp( EEG, [1  2], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\001control\\IG\\post\\');
%1
EEG = pop_loadset('filename','SM_219PreIg 20140512 1402002_ICA3.set','filepath','G:\\study2\\002\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1   2  3], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename([1:2,4:6]),'pre_deIC4.set'],'filepath','G:\\study2\\002\\IG\\pre\\');
%2
EEG = pop_loadset('filename','SM_216_PreIg 20140505 1418 4_ICA3.set','filepath','G:\\study2\\002\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1  2  3  9], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename([1:2,4:6]),'pre_deIC4.set'],'filepath','G:\\study2\\002\\IG\\pre\\');
%3
EEG = pop_loadset('filename','SM224PreIg 20140519 1351002_ICA3.set ','filepath','G:\\study2\\002\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1  6], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'pre_deIC4.set'],'filepath','G:\\study2\\002\\IG\\pre\\');
%4
EEG = pop_loadset('filename','SM223PreIg 20140519 1159002_ICA3.set','filepath','G:\\study2\\002\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1  2  4], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'pre_deIC4.set'],'filepath','G:\\study2\\002\\IG\\pre\\');
%5
EEG = pop_loadset('filename','SM222PreIg 20140519 1007002_ICA3.set','filepath','G:\\study2\\002\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1   2  3], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'pre_deIC4.set'],'filepath','G:\\study2\\002\\IG\\pre\\');
%6
EEG = pop_loadset('filename','SM221PreIg 20140519 0749002_ICA3.set','filepath','G:\\study2\\002\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1  2], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'pre_deIC4.set'],'filepath','G:\\study2\\002\\IG\\pre\\');
%7
EEG = pop_loadset('filename','SM220PreIg 20140512 1205002_ICA3.set','filepath','G:\\study2\\002\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1  3  5], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'pre_deIC4.set'],'filepath','G:\\study2\\002\\IG\\pre\\');
%8
EEG = pop_loadset('filename','SM218PreIg 20140512 1011006_ICA3.set','filepath','G:\\study2\\002\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1  4], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'pre_deIC4.set'],'filepath','G:\\study2\\002\\IG\\pre\\');
%9%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
EEG = pop_loadset('filename','SM217PreIg 20140512 0811004_ICA3.set','filepath','G:\\study2\\002\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1  3], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'pre_deIC4.set'],'filepath','G:\\study2\\002\\IG\\pre\\');
%10
EEG = pop_loadset('filename','SM215PreIg 20140505 1209006_ICA3.set','filepath','G:\\study2\\002\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1  3], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'pre_deIC4.set'],'filepath','G:\\study2\\002\\IG\\pre\\');
%11
EEG = pop_loadset('filename','SM212PreIg 20140407 1415006_ICA3.set','filepath','G:\\study2\\002\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1  2], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'pre_deIC4.set'],'filepath','G:\\study2\\002\\IG\\pre\\');
%12
EEG = pop_loadset('filename','SM211PreIg 20140407 1212004_ICA3.set','filepath','G:\\study2\\002\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1  3], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'pre_deIC4.set'],'filepath','G:\\study2\\002\\IG\\pre\\');
%13
EEG = pop_loadset('filename','SM209PreIg 20140407 1853006_ICA3.set','filepath','G:\\study2\\002\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1  2  5], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'pre_deIC4.set'],'filepath','G:\\study2\\002\\IG\\pre\\');
%14
EEG = pop_loadset('filename','SM207PreIg 20140331 0756009_ICA3.set','filepath','G:\\study2\\002\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1  2  4  6], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'pre_deIC4.set'],'filepath','G:\\study2\\002\\IG\\pre\\');
%15
EEG = pop_loadset('filename','SM206PreIg 20140331 1040006_ICA3.set','filepath','G:\\study2\\002\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1  2  4  6], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'pre_deIC4.set'],'filepath','G:\\study2\\002\\IG\\pre\\');
%16
EEG = pop_loadset('filename','SM204PreIg 20140324 1439004_ICA3.set','filepath','G:\\study2\\002\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1  3  4], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'pre_deIC4.set'],'filepath','G:\\study2\\002\\IG\\pre\\');
%17
EEG = pop_loadset('filename','SM203PreIg 20140324 1222006_ICA3.set','filepath','G:\\study2\\002\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1  2  3  5], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'pre_deIC4.set'],'filepath','G:\\study2\\002\\IG\\pre\\');
%18
EEG = pop_loadset('filename','SM202PreIg 20140324 1014008_ICA3.set','filepath','G:\\study2\\002\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1  2  5], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'pre_deIC4.set'],'filepath','G:\\study2\\002\\IG\\pre\\');
%19
EEG = pop_loadset('filename','SM201bPreIg 20140324 0908003_ICA3.set','filepath','G:\\study2\\002\\IG\\pre\\');
EEG = pop_subcomp( EEG, [1  3  5], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'pre_deIC4.set'],'filepath','G:\\study2\\002\\IG\\pre\\');


%% 
%1
EEG = pop_loadset('filename',{'SM224PostIg 20140523 1339002_ICA3.set'},'filepath','G:\\study2\\002\\IG\\post\\');
EEG = pop_subcomp( EEG, [1  3  4], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\002\\IG\\post\\');
%2
EEG = pop_loadset('filename',{'SM223PostIg 20140523 1142002_ICA3.set'},'filepath','G:\\study2\\002\\IG\\post\\');
EEG = pop_subcomp( EEG, [1  3  4  5], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\002\\IG\\post\\');
%3
EEG = pop_loadset('filename',{'SM222PostIg 20140523 0952002_ICA3.set'},'filepath','G:\\study2\\002\\IG\\post\\');
EEG = pop_subcomp( EEG, [1  2  4], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\002\\IG\\post\\');
%4
EEG = pop_loadset('filename',{'SM221PostIg 20140523 0745002_ICA3.set'},'filepath','G:\\study2\\002\\IG\\post\\');
EEG = pop_subcomp( EEG, [1  2  4  5  6], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\002\\IG\\post\\');
%5
EEG = pop_loadset('filename',{'SM220PostIg 20140516 1354002_ICA3.set'},'filepath','G:\\study2\\002\\IG\\post\\');
EEG = pop_subcomp( EEG, [1  2  3  4  6], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\002\\IG\\post\\');
%6
EEG = pop_loadset('filename',{'SM219PostIg 20140516 1201002_ICA3.set'},'filepath','G:\\study2\\002\\IG\\post\\');
EEG = pop_subcomp( EEG, [1  2  3  4  5  6  8  10], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\002\\IG\\post\\');
%7
EEG = pop_loadset('filename',{'SM218PostIg_part_2 2014051 004_ICA3.set'},'filepath','G:\\study2\\002\\IG\\post\\');
EEG = pop_subcomp( EEG, [1  2  3  5], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\002\\IG\\post\\');
%8
EEG = pop_loadset('filename',{'SM217PostIg 20140516 0757004_ICA3.set'},'filepath','G:\\study2\\002\\IG\\post\\');
EEG = pop_subcomp( EEG, [1  2  3  4  5  6  13], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\002\\IG\\post\\');
%9
EEG = pop_loadset('filename',{'SM216PostIg 20140509 0954004_ICA3.set'},'filepath','G:\\study2\\002\\IG\\post\\');
EEG = pop_subcomp( EEG, [1  2  7], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\002\\IG\\post\\');
%10
EEG = pop_loadset('filename',{'SM215PostIg 20140509 0753006_ICA3.set'},'filepath','G:\\study2\\002\\IG\\post\\');
EEG = pop_subcomp( EEG, [1  2  3  4], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\002\\IG\\post\\');
%11
EEG = pop_loadset('filename',{'SM212PostIg 20140411 1354006_ICA3.set'},'filepath','G:\\study2\\002\\IG\\post\\');
EEG = pop_subcomp( EEG, [1  5], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\002\\IG\\post\\');
%12
EEG = pop_loadset('filename',{'SM211PostIg 20140411 1157004_ICA3.set'},'filepath','G:\\study2\\002\\IG\\post\\');
EEG = pop_subcomp( EEG, [1  2  3  4  5  6  8  9], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\002\\IG\\post\\');
%13
EEG = pop_loadset('filename',{'SM210PostIg 20140411 0951004_ICA3.set'},'filepath','G:\\study2\\002\\IG\\post\\');
EEG = pop_subcomp( EEG,[1  2  3  4  5] , 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\002\\IG\\post\\');
%14
EEG = pop_loadset('filename',{'SM209PostIg 20140411 0748006_ICA3.set'},'filepath','G:\\study2\\002\\IG\\post\\');
EEG = pop_subcomp( EEG,[1  5] , 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\002\\IG\\post\\');
%15
EEG = pop_loadset('filename',{'SM207PostIg 20140404 0759008_ICA3.set'},'filepath','G:\\study2\\002\\IG\\post\\');
EEG = pop_subcomp( EEG,[1  2  9] , 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\002\\IG\\post\\');
%16
EEG = pop_loadset('filename',{'SM206PostIg 20140404 1031006_ICA3.set'},'filepath','G:\\study2\\002\\IG\\post\\');
EEG = pop_subcomp( EEG, [1  5], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\002\\IG\\post\\');
%17
EEG = pop_loadset('filename',{'SM204PostIg 20140328 0807004_ICA3.set'},'filepath','G:\\study2\\002\\IG\\post\\');
EEG = pop_subcomp( EEG,[1  2  3] , 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\002\\IG\\post\\');
%18
EEG = pop_loadset('filename',{'SM203PostIg 20140328 1202006_ICA3.set'},'filepath','G:\\study2\\002\\IG\\post\\');
EEG = pop_subcomp( EEG, [1  2  4  5  6], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\002\\IG\\post\\');
%19
EEG = pop_loadset('filename',{'SM202PostIg 20140328 1416008_ICA3.set'},'filepath','G:\\study2\\002\\IG\\post\\');
EEG = pop_subcomp( EEG, [2  4], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\002\\IG\\post\\');
%20
EEG = pop_loadset('filename',{'SM201PostIg 20140328 1001008_ICA3.set'},'filepath','G:\\study2\\002\\IG\\post\\');
EEG = pop_subcomp( EEG, [1  4  5], 0);
EEG = pop_saveset( EEG, 'filename',[EEG.filename(1:5),'post_deIC4.set'],'filepath','G:\\study2\\002\\IG\\post\\');
%% EEG=pop_chanedit(EEG, 'lookup','S:\\Program\\matlab2019toolbox\\eeglab_current\\eeglab2024.0\\plugins\\dipfit\\standard_BESA\\egi133_GSN.sfp','lookup','S:\\Program\\matlab2019toolbox\\eeglab_current\\eeglab2024.0\\sample_locs\\GSN128.sfp','lookup','S:\\Program\\matlab2019toolbox\\eeglab_current\\eeglab2024.0\\sample_locs\\GSN129.sfp','lookup','S:\\Program\\matlab2019toolbox\\eeglab_current\\eeglab2024.0\\sample_locs\\GSN-HydroCel-257.sfp','lookup','S:\\Program\\matlab2019toolbox\\eeglab_current\\eeglab2024.0\\plugins\\dipfit\\standard_BESA\\egi133_GSN.sfp','lookup','S:\\Program\\matlab2019toolbox\\eeglab_current\\eeglab2024.0\\plugins\\dipfit\\standard_BESA\\IGNORE.sfp','lookup','S:\\Program\\matlab2019toolbox\\eeglab_current\\eeglab2024.0\\plugins\\dipfit\\standard_BESA\\GSN-HydroCel-129.sfp');
