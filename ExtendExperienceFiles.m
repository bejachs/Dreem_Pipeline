%01.10.2020 Barbara Jachs
% this script:
% 1. extends the cluster files to match the EEG files
% 2. removes the epochs in rej.epochs from the cluster files
% 3. saves them in the format fileId??_long.mat
% 4. removes all the non meditation epochs (this is commented out)
% 5. saves meditation EEG data only in 7-med (this is commented out)
% 6. it skips files that are too short (line 84)


% Inputs: 
% 1 - Mat file where each column is an experience dimension 
% (works also if categorical data is included as columns, eg. group or session id,
% as it uses imresize function and replicates existing values without smoothing)
% 2 - the cleaned EEG file with EEG.urevent information or EEG.history if
% that doesn't work

clear all
close all

Participant={'1425',...
    '1733_BandjarmasinKomodoDragon',...
    '1871',... 
    '1991_MendozaCow',...
    '2222_JiutaiChicken',...
    '2743_HuaianKoi',...
    '2965',... 
    '3604',...
    '3614',...
    '3938_UlsanAlligator',...
    '8683_CotonouFox',...
    '8725',...
    }; 

 %Participant={'1425'}
eeglab

for part=1:length(Participant)
    
    participant=Participant{part}
    
    infolder='/20-SubjExp/';
    outfolder='/21-SubjExpLong/';
    filepath='/Users/jachs/Desktop/Jamyang_Project/DreemEEG/';
    TETinpath=[filepath participant infolder ];
    EEGinpath=[filepath participant '/6-rej_epoch/'];
    TEToutpath=[filepath participant outfolder];
%     EEGoutpath=[filepath participant '/7-med/'];
    mkdir(TEToutpath)
%     mkdir(EEGoutpath)
    
    TETfiles=dir([TETinpath '*_TET.mat']);
    
    %for each of the existing TET constructs (101 length) load the EEG file
    for i = 1:length(TETfiles)
        m3=[];m2=[];nepochs=[];B=[];A=[];ismem=[];
        load ([TETinpath TETfiles(i).name ]);
        
        Columns=size(Subjective,2)
        TETfileID= erase(TETfiles(i).name, '_TET.mat');
        fileIDinTable=[TETfileID '.h5'];
        
        %EEGlab inputs
        findfiles=dir([EEGinpath '/*' TETfileID '*.set']);
        if isempty(findfiles)
            continue
        end
        EEGfilename=findfiles.name;
        EEG=[];
        EEG = pop_loadset('filename',EEGfilename,'filepath',EEGinpath);
      
        nepochs=length(EEG.urevent);
        
% % % % UNCOMMENT to select certain epoch types and save them as a separate EEG file    
%         %select only Med epochs and save
%         try
%             EEG=pop_selectevent(EEG,'type', 'Med')
%             %skip if the EEG file is less than 5 minutes
%             EEG = pop_saveset( EEG, 'filename',[TETfileID '_med.set'],'filepath', EEGoutpath);
%         catch
%             disp(['empty file ' TETfileID])
%         end         
        
%         skips EEG files that are shorter than 75 epochs (5 minutes)
        if length(EEG.epoch)<75
            continue
        end
        %what's the first event of meditation
        urmedstart=EEG.event(1).urevent
        urmedend=EEG.event(end).urevent
        
        meddur=urmedend-urmedstart
        %copy the epochs to reject
        try
            a=EEG.rejepoch;
            b=a;
            %remove from epochs to reject all epochs that happen after
            %meditation
            b(a>(urmedstart+meddur-1))=[];
            %remove from epochs to reject all epochs that happen before
            %onset
            b(a<urmedstart)=[];
            % renumber the events so that first event is the first event in
            % meditation
            c=b-(urmedstart-1);
            m2 = imresize(Subjective, [meddur Columns], 'nearest');
            m3=m2;
            m3(c,:)=[];
            
            save([TEToutpath TETfileID '_long'], 'm3')
        catch
            disp('incatch')
            %extract the string of removed epochs from EEG history
            newStr=extractBetween(EEG.history,'pop_rejepoch( EEG, ',' ,0)');
            %in case there were multiple rounds of cleaning, remove the
            %epochs found in each line
            for cleaningrounds=1:length(newStr)
                rejepoch=str2num(cell2mat(newStr(cleaningrounds)));
                a=rejepoch;
                b=a;
                %remove from epochs to reject all epochs that happen after
                %meditation
                b(a>(urmedstart+meddur-1))=[];
                %remove from epochs to reject all epochs that happen before
                %onset
                b(a<urmedstart)=[];
                % renumber the events so that first event is the first event in
                % meditation
                c=b-(urmedstart-1);
                m2 = imresize(Subjective, [meddur Columns], 'nearest');
                m3=m2;
                m3(c,:)=[];
            end
        save([TEToutpath TETfileID '_long'], 'm3')
        end
        
        
        if length(EEG.epoch)~=length(m3)
                 warning (['The TET and EEG epochs are not the same length in file ' TETfileID])
                %cop out
                m3=imresize(Subjective,[length(EEG.epoch) Columns],'nearest');
                length(EEG.epoch)~=length(m3)
                save([TEToutpath TETfileID '_long'], 'm3')
        
        end
 
    end
end




