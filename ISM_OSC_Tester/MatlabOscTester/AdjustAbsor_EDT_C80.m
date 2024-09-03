%% This Scritp carry out the process of adjusting absorptions 
%% Channel used:      Average of L and R.

% Author: Fabian Arrebola (25/07/2024) 
% contact: areyes@uma.es
% 3DDIANA research group. University of Malaga
% Project: SONICOM
% 
% Copyright (C) 2024 Universidad de Málaga

%% This version operates only with two impulse responses
%% generated by the Hybrid Simulator (ISM+CONV):
%% the RIR and the ISM for DpMax
%

%% Input - Configure
% BRIR_used --> BRIR used for adjustment: measured ('M') or simulated ('S')
% Room      --> Room to simulate: A108, sJun, Lab or Sm (Small) 
% ITER_MAX  --> MAX ITERATIONS
% nameFolder --> Folder with impulse responses

% DpMax; DpMin; DpMinFit; --> (PRUNING DISTANCES)
% RefOrd; 
% W_Slope;                      
% RGain_dB;

%% Output
%  'ParamsISM.mat',      <-- 'RefOrd', 'DpMax','W_Slope','RGain_dB'
%  'DistanceRange.mat'   <-- 'DpMax', 'DpMin','DpMinFit'
%  'FiInfSlopes.mat'     <-- 'slopes'     slope values for each iteration
%  'FiInfAbsorb.mat'     <-- 'absorption' absorption values for each iteration
%  'AnFile_HH_MM_SS.mat' <-- 'An'         absorption values for all iterations
%  'BRIR.wav'            <-- IR_Reverb
%  'ISMDpMax.wav'        <-- IR_ISM

clear all;

%% parameter used for adjustment
paramAdj =  'EDT'; % 'T20', 'C50','C80', 'D50', 'C50'
DiffMax = 0.05;

NB=9;

%% Set Distance por Tmix
DpTmix = 30;

%% Absorption saturation values
absorMax=0.9999;
absorMin=0.0001;
maxChange=0.1;                %0.1
reductionAbsorChange=0.75;     %0.6
% maxChange=0.15;
% reductionAbsorChange=0.75;

%% BRIR used for adjustment: measured ('M') or simulated ('S')
BRIR_used = 'M';

%% Room to simulate: A108, sJun, Lab or Sm (Small) 
Room = 'A108';

%% MAX ITERATIONS 
ITER_MAX = 15;

%% Channel: Left (L) or Right (R)
L=1; R=2;         % Channels
C=0;              % Channel to carry out the adjustment

%% PRUNING DISTANCES
if Room == 'A108'            % Aula 108  
   DpMax=40; DpMin=2;   DpMinFit = 30;  
elseif Room == 'sJun'        % Sala Juntas
   DpMax=34; DpMin=2;   DpMinFit = 17;
elseif Room == 'Lab'         % Lab  
   DpMax=38; DpMin=2;   DpMinFit = 17; 
elseif Room == 'Sm'          % Small
   DpMax=17; DpMin=2;   DpMinFit = 8;
else
   disp('Error: Room to be simulated must be indicated');
   exit;
end

%% Path
addpath('C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\ISM_OSC_Tester\MatlabOscTester'); 

%% Folder with impulse responses
nameFolder='\workFolder';
resourcesFolder = 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\';
workFolder = strcat(resourcesFolder,nameFolder);
% workFolder = "C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\"+ nameFolder;
if exist(workFolder, 'dir') == 7
    disp('folder exist');
else
    mkdir(workFolder);
    disp('created work folder');
end
cd (workFolder);
delete *.wav;

%% SAVE Configuration parameters for ISM simulation
RefOrd=40; 
W_Slope=2;                       % Value for energy adjustment
RGain_dB = 0;
RGain = db2mag(RGain_dB);
save ('ParamsISM.mat','RefOrd', 'DpTmix','W_Slope','RGain_dB','C','BRIR_used','Room');

%% File name associated with ISM simulation
formatFileHYB= "tIrRO%iDP%02iW%02iHYB";
nameFileHYB = sprintf(formatFileHYB, RefOrd, DpTmix, W_Slope)+'.wav';

%% SAVE PRUNING DISTANCES
save ('DistanceRange.mat','DpMax', 'DpMin','DpMinFit','DpTmix');

x=[DpMin:1:DpMax];               % Initial and final pruning distance

%% ABSORTIONS

% if exist('FiInfAbsorb.mat', 'file') == 2
%     load ("FiInfAbsorb.mat");
%     absorbData =absorbData1;
% else
%     absorbData = [0.30 0.30 0.30 0.30 0.30 0.30 0.30 0.30 0.30;
%                   0.30 0.30 0.30 0.30 0.30 0.30 0.30 0.30 0.30;
%                   0.30 0.30 0.30 0.30 0.30 0.30 0.30 0.30 0.30;
%                   0.30 0.30 0.30 0.30 0.30 0.30 0.30 0.30 0.30;
%                   0.30 0.30 0.30 0.30 0.30 0.30 0.30 0.30 0.30;
%                   0.30 0.30 0.30 0.30 0.30 0.30 0.30 0.30 0.30;];
% end    

absorbData = [0.30 0.30 0.30 0.30 0.30 0.30 0.30 0.30 0.30;
                  0.30 0.30 0.30 0.30 0.30 0.30 0.30 0.30 0.30;
                  0.30 0.30 0.30 0.30 0.30 0.30 0.30 0.30 0.30;
                  0.30 0.30 0.30 0.30 0.30 0.30 0.30 0.30 0.30;
                  0.30 0.30 0.30 0.30 0.30 0.30 0.30 0.30 0.30;
                  0.30 0.30 0.30 0.30 0.30 0.30 0.30 0.30 0.30;];

absorbData0 = absorbData;
absorbData1 = absorbData;
absorbData2 = absorbData;

distAu0 = zeros(1,9);
distAu1 = zeros(1,9);
distAu2 = zeros(1,9);

pAdjus0 = zeros(1,9);
pAdjus1= zeros(1,9);
pAdjus2 = zeros(1,9);

An=zeros(ITER_MAX, 9);

maximumAbsorChange=[maxChange, maxChange, maxChange, maxChange, maxChange, maxChange, maxChange, maxChange, maxChange];

formatParAd = "parAd: %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f ";
formatAbsor = "Absor: %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f ";
formatAbsorChange= "AbChg: %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f ";
formaTotalMaxSlope= "TotalSlope: %.5f  factorMeanValue: %.5f";

%% Open connection to send messages to ISM
ISMPort = 12300;
connectionToISM = HybridOscCmds.InitConnectionToISM(ISMPort);

%% Open OSC server
% https://0110.be/posts/OSC_in_Matlab_on_Windows%2C_Linux_and_Mac_OS_X_using_Java
% https://github.com/hoijui/JavaOSC
listenPort = 12301;
receiver = HybridOscCmds.InitOscServer(listenPort);
[receiver osc_listener] = HybridOscCmds.AddListenerAddress(receiver, '/ready');

%% Set Working Folder
HybridOscCmds.SendWorkFolderToISM(connectionToISM, nameFolder);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+"Work Folder");

%% Reflecion Order = 0
HybridOscCmds.SendReflecionOrderToISM(connectionToISM, 0);
% Waiting msg from ISM
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Ref Order = 0");
pause(0.2);

%% Enable Reverb
HybridOscCmds.SendReverbEnableToISM(connectionToISM, true);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Enable Reverb");
pause(0.2);

%% Enable Spatialisation
HybridOscCmds.SendSpatialisationEnableToISM (connectionToISM, true);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Enable Spatialisation");
pause(0.2);

%% Enable Distance Attenuation
HybridOscCmds.SendDistanceAttenuationEnableToISM (connectionToISM, true);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Enable Distance Attenuation");
pause(0.2);

%%  Disable Distance Attenuation Reverb Enable To ISM
HybridOscCmds.SendDistanceAttenuationReverbEnableToISM (connectionToISM, false);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Distance Attenuation Reverb Enable");
pause(0.2);

%% Disable Direct Path
HybridOscCmds.SendDirectPathEnableToISM(connectionToISM, false);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Disable Direct Path");

%%  Send Play and Stop ToISM
HybridOscCmds.SendPlayToISM(connectionToISM);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Play");
pause(0.2);

HybridOscCmds.SendStopToISM(connectionToISM);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Stop");
pause(0.2);

%% BRIR
% configureHybrid (connectionToISM, receiver, osc_listener,              W_Slope, DistMax, RefOrd, RGain, SaveIR) 
HybridOscCmds.configureHybrid (connectionToISM, receiver, osc_listener,       2,    1,       0,    RGain,   true);
pause(0.2);
disp(message+" RIR");

% %% Disable Reverb
% HybridOscCmds.SendReverbEnableToISM(connectionToISM, false);
% message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
% disp(message+" Dissable Reverb");
% pause(0.2);

%% BRIR used for adjustment: measured (M) or simulated (S)
cd (workFolder);
if BRIR_used == 'S'
   movefile 'wIrRO0DP01W02.wav' 'BRIR.wav';    % simulated
elseif BRIR_used == 'M'
    if     Room == 'A108'
       copyfile '..\A108RIR_omni.wav' 'BRIR.wav';      % measured
    elseif Room == 'sJun'
       copyfile '..\sJunRIR_omni.wav' 'BRIR.wav';      % measured
    else
       disp('Error: Room to be simulated must be indicated');
       exit;
    end
else
   disp('Error: It must be indicated whether the adjustment is going to be made with the measured or simulated BRIR');
   exit;
end

%% Read file with BRIR
BRIRFile=dir(['BRIR*.wav']);         %BRIR obtained with a pruning distance of 1 meter
AudioFile=BRIRFile.name;
[t_BRIR,Fs] = audioread(AudioFile);

%% Send Initial absortions
walls_absor = zeros(1,54);
absorbDataT = absorbData';
walls_absor = absorbDataT(:);
HybridOscCmds.SendAbsortionsToISM(connectionToISM, walls_absor'); 
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Initial absortions");
pause(0.2);

%% Reflecion Order
HybridOscCmds.SendReflecionOrderToISM(connectionToISM, RefOrd);
% Waiting msg from ISM
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
msg = sprintf('%s Ref Order = %d', message, RefOrd);
disp (msg);
pause(0.2);

Time2Record = (length (t_BRIR) / Fs);

%% Set Time to Record Impulse Res
HybridOscCmds.SendTimeRecordIRToISM(connectionToISM, Time2Record);
% Waiting msg from ISM
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
msg = sprintf('%s Time to Record Impulse Response = %d', message, Time2Record);
disp (msg);
pause(0.2);

%% Generate Hybrid IR
% configureHybrid (connectionToISM, receiver, osc_listener,                W_Slope,   DistMax,   RefOrd,     RGain, SaveIR) 
HybridOscCmds.configureHybrid (connectionToISM, receiver, osc_listener,    W_Slope,    DpTmix,     -1,        -1,   true);
pause(0.2);
disp(message+ " IR HYB  ");
%% Rename to IR_Hyb.wav
cd (workFolder);
movefile (nameFileHYB, "IR_Hyb.wav");

%% Working loop
rng('default');
iLoop = 0;

%% Read file with IR HYB
HYBFile=dir(['IR_Hyb.wav']);      %ISM obtained with a pruning max distance 
AudioFile=HYBFile.name;
[t_HYB,Fs] = audioread(AudioFile);
pause(0.5);
% delete (HYBFile.name);

%% Create empty audio objects
itaObj_reference  = itaAudio;
itaObj_hybrid = itaAudio;
%% Set sampling rate
itaObj_reference.samplingRate = Fs;
itaObj_hybrid.samplingRate = Fs;
%% Set the time data
itaObj_reference.time = t_BRIR;
%% Change the length of the audio track
itaObj_reference.trackLength = size(t_BRIR)/Fs;

%% Compute acoustic parameters
freqRange = [50 20000];
bandsPerOctave = 1;
disp('Computed acoustic parameters:');
[raResults_reference] = ita_roomacoustics(itaObj_reference, 'freqRange',freqRange, 'bandsPerOctave',bandsPerOctave, paramAdj);


fitParam=false;
while ( iLoop < ITER_MAX)
    disp(iLoop);
    %% Folder with impulse responses
    cd (workFolder);
    %% Set the time data
    itaObj_hybrid.time = t_HYB;
    %% Change the length of the audio track
    itaObj_hybrid.trackLength = size(t_HYB)/Fs;
    %% Compute acoustic parameters
    disp('Computed acoustic parameters:');
    [raResults_hybrid] = ita_roomacoustics(itaObj_hybrid, 'freqRange',freqRange, 'bandsPerOctave',bandsPerOctave, paramAdj);

    
    %% -----------------------------------------------------------------
    %% Extrac new absortions (only 1ª and 2ª iterations) to send to ISM
    alfa = 0.01;
    distAu=zeros(1,NB);
    
    for j=1:NB
     
        %distAu(1,j) = FactorMeanBand (1,j) -1;
        distAu(1,j) = raResults_hybrid.EDT.freqData(j,1)- raResults_reference.EDT.freqData(j,1);
                
        DistAuB = distAu(1,j);
        if (abs (DistAuB)  > 0)
            % for k=1:4    %excluding ceil and floor
             for k=1:6
                newAbsorb = absorbData (k,j) - distAu(1,j)*0.01;

                if abs (newAbsorb - absorbData(k,j) ) > maximumAbsorChange(j);
                    if newAbsorb > absorbData(k,j)
                        newAbsorb = absorbData(k,j) + maximumAbsorChange(j);
                    else
                        newAbsorb = absorbData(k,j) - maximumAbsorChange(j);
                    end
                end

                if newAbsorb > 0.0 && newAbsorb < 1.0
                    absorbData (k,j) = newAbsorb;
                elseif newAbsorb <= 0.0
                    absorbData (k,j) = absorMin;
                elseif newAbsorb >= 1.0
                    absorbData (k,j) = absorMax;
                end
            end 
        end
    end 
    %% update absorption values
    absorbData0 = absorbData1;
    absorbData1 = absorbData2;
    %% update calculated differences
    distAu0=distAu1;
    distAu1=distAu;
    %% ---------------------------------
    changeAbsor = 0;
    if (iLoop < 2 )
        %% first new absortions
       absorbData2 = absorbData; 
       changeAbsor = changeAbsor + 5;
    else
        %% calculate new absorptions
        for j=1:NB
          
            if (abs(distAu(1,j)) > DiffMax)
                newAbsorb = (-distAu0(1,j)) * (absorbData1(1,j)-absorbData0(1,j))/(distAu1(1,j)-distAu0(1,j))+absorbData0(1,j); 
            else
                newAbsorb = absorbData1(1,j);
            end

            if sign(distAu1(1,j)) ~= sign(distAu0(1,j))
                maximumAbsorChange(j)= maximumAbsorChange(j)*reductionAbsorChange;
            end

            if (newAbsorb < absorMin) newAbsorb = absorMin; end
            if (newAbsorb > absorMax) newAbsorb = absorMax; end

            if abs (newAbsorb - absorbData1(1,j) ) > maximumAbsorChange(j) 
                if newAbsorb > absorbData1(1,j) 
                    newAbsorb = absorbData1(1,j) + maximumAbsorChange(j);
                else
                    newAbsorb = absorbData1(1,j) - maximumAbsorChange(j);
                end
            end
   
            if (newAbsorb <= 0.0)     newAbsorb = absorMin;
            elseif (newAbsorb >= 1.0) newAbsorb = absorMax;
            end

            for k=1:6
                absorbData2 (k,j) = newAbsorb;
            end  
            if (abs(distAu(1,j)) > DiffMax)
                changeAbsor = changeAbsor + 1;
            end
        end
    end

 
    vSlope = sprintf(formatParAd,distAu0);
    disp(vSlope);
    vSlope = sprintf(formatParAd,distAu1);
    disp(vSlope);
    vAbsor = sprintf(formatAbsorChange,maximumAbsorChange);
    disp(vAbsor);
    vAbsor = sprintf(formatAbsor,absorbData0(1,:));
    disp(vAbsor);
    vAbsor = sprintf(formatAbsor,absorbData1(1,:));
    disp(vAbsor);
    vAbsor = sprintf(formatAbsor,absorbData2(1,:));
    disp(vAbsor);
       
    %% send new abssortion values (if not adjust)
    if changeAbsor > 0 
       absorbDataT = absorbData2';
       walls_absor = absorbDataT(:);
       HybridOscCmds.SendAbsortionsToISM(connectionToISM, walls_absor');
       message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
       disp(message+" New Absortions");
       pause(0.5);
       HybridOscCmds.SendSaveIRToISM(connectionToISM);
       message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
       disp(message+" SaveIR");
       pause(0.5);

       cd (workFolder);
       delete (HYBFile.name);
       movefile (nameFileHYB, "IR_Hyb.wav");

       AudioFile=HYBFile.name;
       [t_HYB,Fs] = audioread(AudioFile);


    else
       fitParam=true;
    end
    % disp(message);
    % pause (1)
%% ----------- ------------------
    b = mod(iLoop,1 ) ;
    if (b==0)|| (fitParam == true) || (iLoop==ITER_MAX-1)
        % actual folder
        current_folder = pwd;
        % new folder
        new_folder = num2str(iLoop);
        mkdir( current_folder, new_folder);
        % save absortions
        nameFile= 'FiInfAbsorb';
        save(fullfile( current_folder,   nameFile), 'absorbData1');

        % copy files
        copyfile(fullfile( current_folder,'BR*'), new_folder);
        copyfile(fullfile( current_folder,'Ir_Hyb*'), new_folder);
        copyfile(fullfile( current_folder,'*.mat'), new_folder);
    end
%% -------------------------------

    if (iLoop<ITER_MAX-1 && fitParam == false)
        close all;
    end
    iLoop=iLoop+1;

    %% Save Absorb
    An(iLoop, :) = absorbData1(1,:);

    if (fitParam == true)
        break;
    end
end

%% Reflecion Order = 0
HybridOscCmds.SendReflecionOrderToISM(connectionToISM, 0);
% Waiting msg from ISM
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Ref Order = 0");
pause(0.2);


%% Close, doesn't work properly
HybridOscCmds.CloseOscServer(receiver, osc_listener);

%% File with An values
t = datetime('now','Format','HH:mm:ss.SSS');
[h,m,s] = hms(t);
H = int2str (h);
M = int2str (m);
S = int2str (s);
current_folder = pwd;
nameFile= "AnFile_"+ H +"_"+ M + "_" + S;
save(fullfile( current_folder,   nameFile), 'An');

