%% This Scritp carry out the process of adjusting absorptions 
%% using parameters C80 and EDT

% Author: Fabian Arrebola (09/10/2024) 
% contact: areyes@uma.es
% 3DDIANA research group. University of Malaga
% Project: SONICOM
% 
% Copyright (C) 2024 Universidad de Málaga

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

%% BRIR used for adjustment: measured ('M') or simulated ('S') and ROOM
BRIR_used = 'S'; Room = 'A108'; %sJun
%% MAX ITERATIONS 
ITER_MAX = 60;
%% Direct Path ###  Threshold Average ##
directPath = true; CX0Threshold = 1;  % CX0Threshold = 0.01 for Average
%% Reverb Gain
RGain_dB = -6;  
%RGain_dB = 4.8428 

%% parameter used for adjustment
paramAdj =  'C80'; % 'EDT', 'C50','C80', 'D50', 'C50'
if paramAdj == 'EDT'
   thError = 0.05;    DpTmix = 28;  % 81 ms
elseif paramAdj == 'C80'
   thError = 0.01;    DpTmix = 28;  % 81 ms
elseif paramAdj == 'C50'
   thError = 0.075;    DpTmix = 17.15+2.73;   % 50 ms
else
end
NB=9;

%% Absorption saturation values
absorMax=0.9999; absorMin=0.0001;
maxChange=0.1;                %0.1
reductionAbsorChange=0.8;     %0.6
% maxChange=0.15;
% reductionAbsorChange=0.75;

%% Channel: Left (L) or Right (R)
L=1; R=2;         % Channels
C=0;              % Channel to carry out the adjustment

%% PRUNING DISTANCES
if Room == 'A108'            % Aula 108  
   DpMax=40; DpMin=2;   DpMinFit = 40;  
elseif Room == 'sJun'        % Sala Juntas
   DpMax=34; DpMin=2;   DpMinFit = 34;
elseif Room == 'Lab'         % Lab  
   DpMax=38; DpMin=2;   DpMinFit = 17; 
elseif Room == 'Sm'          % Small
   DpMax=17; DpMin=2;   DpMinFit = 8;
else
   disp('Error: Room to be simulated must be indicated');
   exit;
end

%% OpenFramework version
[resourcesFolder, pathSc]= verOpenF();
%% Path
addpath(pathSc); 

%% Folder with impulse responses
nameFolder='\workFolder';
workFolder = strcat(resourcesFolder,nameFolder);
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
% RGain_dB = 0;
RGain = db2mag(RGain_dB);
save ('ParamsISM.mat','RefOrd', 'DpTmix','W_Slope','RGain_dB','C','BRIR_used','Room');

%% File name associated with HYB-ISM simulation
formatFileHYB= "tIrRO%iDP%02iW%02iHYB";
nameFileHYB = sprintf(formatFileHYB, RefOrd, floor(DpTmix), W_Slope)+'.wav';

%% SAVE PRUNING DISTANCES
save ('DistanceRange.mat','DpMax', 'DpMin','DpMinFit','DpTmix');

x=[DpMin:1:DpMax];               % Initial and final pruning distance

%% ABSORTIONS
if Room == 'A108'
    AEr = [0.106628119171042	0.0976080804785569	0.114348257012995	0.164057076979350	0.193742369190673	0.196620381435978	0.224669662309288	0.273602103381712	0.388069385485122];
    %AEr = [0.106628119	0.09760808	0.114348257	0.164057077	0.193742369	0.196620381	0.224669662	0.273602103	0.38806938];
elseif Room == 'sJun'
    AEr= [0.119983157652694	0.122043633632542	0.161949594699940	0.260336220141102	0.286622820285472	0.247208724772500	0.240230767404492	0.327752061756642	0.405951830716490];
    %AEr= [0,119983158	0,122043634	0,161949595	0,26033622	0,28662282	0,247208725	0,240230767	0,327752062	0,405951831];
else
    error('Error: Room not specified');
end
absorbData = repmat (AEr, 6, 1); 

% if exist('FiInfAbsorb.mat', 'file') == 2
%     load ("FiInfAbsorb.mat");
%     absorbData =absorbData1;
% else
%     absorbData = [0.50 0.50 0.50 0.50 0.50 0.50 0.50 0.50 0.50;
%                   0.50 0.50 0.50 0.50 0.50 0.50 0.50 0.50 0.50;
%                   0.50 0.50 0.50 0.50 0.50 0.50 0.50 0.50 0.50;
%                   0.50 0.50 0.50 0.50 0.50 0.50 0.50 0.50 0.50;
%                   0.50 0.50 0.50 0.50 0.50 0.50 0.50 0.50 0.50;
%                   0.50 0.50 0.50 0.50 0.50 0.50 0.50 0.50 0.50;];
% end    

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
Dau =zeros(ITER_MAX, 9);

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

%% Enable-Disable Direct Path
HybridOscCmds.SendDirectPathEnableToISM(connectionToISM, directPath);
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
BRIRFile=dir(['BRIR*.wav']);         %BRIR 
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
HYBFile=dir(['IR_Hyb.wav']);         %HYB obtained with a tmix=81 ms 
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
    distAu=zeros(1,NB); 
    aC50r = zeros(1,NB); bC50h = zeros(1,NB); cC50 = zeros(1,NB);
    aC80r = zeros(1,NB); bC80h = zeros(1,NB); cC80 = zeros(1,NB);
    aEDTr = zeros(1,NB); bEDTh = zeros(1,NB); cEDT = zeros(1,NB);
    aLinear = zeros(1,NB); bLinear = zeros(1,NB);
    for j=2:NB-1
        if paramAdj == 'C50'
           aC50r (1,j) = (raResults_reference.C50.freqData(j,1) + raResults_reference.C50.freqData(j,2)) / 2;
           bC50h (1,j) = (raResults_hybrid.C50.freqData(j,1) + raResults_hybrid.C50.freqData(j,1) ) / 2; 
           distAu(1,j) = (aC50r (1,j) - bC50h (1,j)) / aC50r (1,j); 
           aLinear (1,j) = 10 ^ (aC50r (1,j)/10);
           bLinear (1,j) = 10 ^ (bC50h (1,j)/10);
           distAu(1,j) = (aLinear - bLinear)/aLinear;
           cC50  (1,j) = distAu(1,j);
        elseif paramAdj == 'C80'
           aC80r (1,j) = (raResults_reference.C80.freqData(j,1) + raResults_reference.C80.freqData(j,2))/2;
           bC80h (1,j) = (raResults_hybrid.C80.freqData(j,1) + raResults_hybrid.C80.freqData(j,2)) / 2;      
           distAu(1,j) = (aC80r (1,j) - bC80h (1,j))  / aC80r (1,j);    % abs(aC80r (1,j)); 
           aLinear (1,j) = 10 ^ (aC80r (1,j)/10);
           bLinear (1,j) = 10 ^ (bC80h (1,j)/10);
           distAu(1,j) = (aLinear - bLinear)/aLinear;
           cC80  (1,j) = distAu(1,j);
         elseif paramAdj == 'EDT'
           aEDTr (1,j) = (raResults_reference.EDT.freqData(j,1) + raResults_reference.EDT.freqData(j,2)) / 2;
           bEDTh (1,j) = (raResults_hybrid.EDT.freqData(j,1) + raResults_hybrid.EDT.freqData(j,1) ) / 2; 
           distAu(1,j) = (aEDTr (1,j) - bEDTh (1,j)) / aEDTr (1,j); 
           cEDT  (1,j) = distAu(1,j);
        end    
        DistAuB = distAu(1,j);
        if (abs (DistAuB)  > 0)
             for k=1:6    %% 6 walls
                if paramAdj ==     'EDT'   newAbsorb = absorbData (k,j) - distAu(1,j)*0.01;
                elseif paramAdj == 'C80'   newAbsorb = absorbData (k,j) - distAu(1,j)*0.01;
                elseif paramAdj == 'C50'   newAbsorb = absorbData (k,j) - distAu(1,j)*0.01;
                end
%                 if abs (newAbsorb - absorbData(k,j) ) > maximumAbsorChange(j);
%                     if newAbsorb > absorbData(k,j)  newAbsorb = absorbData(k,j) + maximumAbsorChange(j);
%                     else                            newAbsorb = absorbData(k,j) - maximumAbsorChange(j);
%                     end
%                 end
                if newAbsorb >= absorMin  && newAbsorb <= absorMax  absorbData (k,j) = newAbsorb;
                elseif newAbsorb < absorMin                        absorbData (k,j) = absorMin;
                elseif newAbsorb > absorMax                        absorbData (k,j) = absorMax;
                end
            end 
        end
    end 

    if paramAdj == 'C50'
        C50AverR =  0.15 * aC50r(1,4) + 0.25 * aC50r(1,5) + 0.35 * aC50r(1,6) + 0.25 * aC50r(1,7);
        C50AverH =  0.15 * bC50h(1,4) + 0.25 * bC50h(1,5) + 0.35 * bC50h(1,6) + 0.25 * bC50h(1,7);
        CX0AvErr =  (C50AverR - C50AverH) / C50AverR;
    elseif paramAdj == 'C80'
        C80AverR =  aC80r(1,4)/3 + aC80r(1,5)/3 + aC80r(1,6)/3;
        C80AverH =  bC80h(1,4)/3 + bC80h(1,5)/3 + bC80h(1,6)/3;
        CX0AvErr =  (C80AverR - C80AverH) / C80AverR;
    else
        CX0AvErr = 0.001;
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
       changeAbsor = 9;            %This forces more than two iterations to be done.
    else
        %% calculate new absorptions
        for j=2:NB-1
            %% newAbsorb = (-distAu0(1,j)) * (absorbData1(1,j)-absorbData0(1,j))/(distAu1(1,j)-distAu0(1,j))+absorbData0(1,j); 
            newAbsorb = (-distAu1(1,j)) * (absorbData1(1,j)-absorbData0(1,j))/(distAu1(1,j)-distAu0(1,j))+absorbData1(1,j); 

            if sign(distAu1(1,j)) ~= sign(distAu0(1,j))
                maximumAbsorChange(j)= maximumAbsorChange(j)*reductionAbsorChange;
            end
            if abs (newAbsorb - absorbData1(1,j) ) > maximumAbsorChange(j)
                if newAbsorb > absorbData1(1,j)      newAbsorb = absorbData1(1,j) + maximumAbsorChange(j);
                else                                 newAbsorb = absorbData1(1,j) - maximumAbsorChange(j);
                end
            end
            if (newAbsorb <= absorMin)         newAbsorb = absorMin;
            elseif (newAbsorb >= absorMax)     newAbsorb = absorMax;
            end

            for k=1:6
                absorbData2 (k,j) = newAbsorb;
            end  
            if (abs(distAu(1,j)) > thError)  && (j > 1) && (j < 9) 
                changeAbsor = changeAbsor + 1;
            end
        end
    end
    %%%%%
    % if abs (CX0AvErr) > CX0Threshold
    %    changeAbsor = changeAbsor + 1;
    % end
    %%%%%
 
    vSlope = sprintf(formatParAd,distAu0);                   disp(vSlope);
    vSlope = sprintf(formatParAd,distAu1);                   disp(vSlope);
    vAbsor = sprintf(formatAbsorChange,maximumAbsorChange);  disp(vAbsor);
    vAbsor = sprintf(formatAbsor,absorbData0(1,:));          disp(vAbsor);
    vAbsor = sprintf(formatAbsor,absorbData1(1,:));          disp(vAbsor);
    vAbsor = sprintf(formatAbsor,absorbData2(1,:));          disp(vAbsor);
       
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
       pause(1);
 
       cd (workFolder); 
       delete (HYBFile.name);
       movefile (nameFileHYB, "IR_Hyb.wav");

       AudioFile=HYBFile.name;
       [t_HYB,Fs] = audioread(AudioFile);

       % plot (t_BRIR,'r'); hold on;
       % plot (t_HYB,'b');
       % xlim ([0, 8000]);
       pause (2);
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
    Dau(iLoop, :) = distAu;

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

figure;
subplot(2,1,1);
plot (t_BRIR,'r'); 
xlim ([0, 8000]); hold on;
subplot(2,1,2);
plot (t_HYB,'b');
xlim ([0, 8000]);

%% File with An values
t = datetime('now','Format','HH:mm:ss.SSS');
[h,m,s] = hms(t);
H = int2str (h);
M = int2str (m);
S = int2str (s);
current_folder = pwd;
nameFile= "AnFile_"+ H +"_"+ M + "_" + S;
save(fullfile( current_folder,   nameFile), 'An');
nameFile= "DauFile_"+ H +"_"+ M + "_" + S;
save(fullfile( current_folder,   nameFile), 'Dau');

