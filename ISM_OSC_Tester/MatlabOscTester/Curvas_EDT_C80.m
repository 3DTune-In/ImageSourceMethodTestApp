%% This scritp calculates the evolution of the relative error corresponding 
%% to the comparison of the C80/EDT parameter in the cases: 
%% a) RIR_reverb_only and b) RIR_hybrid.
%% The starting point is the Eyring absorptions, 
%% a band is chosen and the absorption in that band is varied from 0 to 1 
%% (all bands except the chosen one maintain the absorption value). 
%% For each set of absorption values, the C80/EDT of each RIR (tail only or hybrid) 
%% is calculated and finally the relative error is obtained.

% Author: Fabian Arrebola (09/10/2024) 
% contact: areyes@uma.es
% 3DDIANA research group. University of Malaga
% Project: SONICOM
% 
% Copyright (C) 2024 Universidad de Málaga

clear all;

BAND = 2;

%% BRIR used for adjustment: measured ('M') or simulated ('S') and ROOM
BRIR_used = 'S'; Room = 'sJun'; %'A108' or'sJun'
%% MAX ITERATIONS 
ITER_MAX = 10;
%% Direct Path ###  Threshold Average ##
directPath = true; 
%% Reverb Gain
RGain_dB = -6;  
%RGain_dB = 4.8428 

%% parameter used for adjustment
paramAdj =  'C80'; % 'EDT', 'C50','C80', 'D50', 'C50'
if paramAdj == 'EDT'
   thError = 0.075;    DpTmix = 28;  % 81 ms
elseif paramAdj == 'C80'
   thError = 0.05;    DpTmix = 28;  % 81 ms
elseif paramAdj == 'C50'
   thError = 0.075;    DpTmix = 17.15+2.73;   % 50 ms
else
end
NB=9;

%% Absorption saturation values
absorMax=1.0;
absorMin=0.0;
maxChange=1.0;
reductionAbsorChange=1.0;

%% Absortions 
An=zeros(1,ITER_MAX+1);
An(1,1)=0;
for i=2:ITER_MAX+1
    An(1,i) = An(1,i-1) + 1.0/ITER_MAX;
end
pRef=zeros(ITER_MAX+1, 9);
pSim=zeros(ITER_MAX+1, 9);
pAbs=zeros(ITER_MAX+1, 9);
ErrVsAbs=zeros(ITER_MAX+1, 9);

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
   error('Error: Room not specified');
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

%% 1 KHz band is 5
for k=1:6
  absorbData (k,BAND) = 0;
end  

formatParR =  "parRef: %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f ";
formatParS =  "parSim: %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f ";
formatAbsor=  "Absorp: %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f ";
formatError = "Error:  %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f ";

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
%itaObj_hybrid = itaAudio;
%% Set sampling rate
itaObj_reference.samplingRate = Fs;
%itaObj_hybrid.samplingRate = Fs;
%% Set the time data
itaObj_reference.time = t_BRIR;
%% Change the length of the audio track
itaObj_reference.trackLength = size(t_BRIR)/Fs;

%% Compute acoustic parameters
freqRange = [50 20000];
bandsPerOctave = 1;
disp('Computed acoustic parameters:');
[raResults_reference] = ita_roomacoustics(itaObj_reference, 'freqRange',freqRange, 'bandsPerOctave',bandsPerOctave, paramAdj);
while ( iLoop <= ITER_MAX)
    disp(iLoop);

    %% Folder with impulse responses
    cd (workFolder);
    %% Create empty audio objects
    itaObj_hybrid = itaAudio;
    %% Set sampling rate
    itaObj_hybrid.samplingRate = Fs;
    %% Set the time data
    itaObj_hybrid.time = t_HYB;
    %% Change the length of the audio track
    itaObj_hybrid.trackLength = size(t_HYB)/Fs;
    %% Compute acoustic parameters
    disp('Computed acoustic parameters:');
    [raResults_hybrid] = ita_roomacoustics(itaObj_hybrid, 'freqRange',freqRange, 'bandsPerOctave',bandsPerOctave, paramAdj);

    %% -----------------------------------------------------------------

    Error=zeros(1,NB);
    aC50r = zeros(1,NB); bC50h = zeros(1,NB); cC50 = zeros(1,NB);
    aC80r = zeros(1,NB); bC80h = zeros(1,NB); cC80 = zeros(1,NB);
    aEDTr = zeros(1,NB); bEDTh = zeros(1,NB); cEDT = zeros(1,NB);
    aLinear = zeros(1,NB); bLinear = zeros(1,NB);
    for j=1:NB
        if paramAdj == 'C50'
            aC50r (1,j) = (raResults_reference.C50.freqData(j,1) + raResults_reference.C50.freqData(j,2)) / 2;
            bC50h (1,j) = (raResults_hybrid.C50.freqData(j,1) + raResults_hybrid.C50.freqData(j,1) ) / 2;
            Error(1,j) = (aC50r (1,j) - bC50h (1,j)) / aC50r (1,j);
            aLinear (1,j) = 10 ^ (aC50r (1,j)/10);
            bLinear (1,j) = 10 ^ (bC50h (1,j)/10);
            Error(1,j) = (aLinear - bLinear)/aLinear;
            cC50  (1,j) = Error(1,j);
        elseif paramAdj == 'C80'
            aC80r (1,j) = (raResults_reference.C80.freqData(j,1) + raResults_reference.C80.freqData(j,2))/2;
            bC80h (1,j) = (raResults_hybrid.C80.freqData(j,1) + raResults_hybrid.C80.freqData(j,2)) / 2;
            Error(1,j) = (aC80r (1,j) - bC80h (1,j))  / aC80r (1,j);    % abs(aC80r (1,j));
            aLinear (1,j) = 10 ^ (aC80r (1,j)/10);
            bLinear (1,j) = 10 ^ (bC80h (1,j)/10);
            Error(1,j) = (aLinear - bLinear)/aLinear;
            cC80  (1,j) = Error(1,j);
        elseif paramAdj == 'EDT'
            aEDTr (1,j) = (raResults_reference.EDT.freqData(j,1) + raResults_reference.EDT.freqData(j,2)) / 2;
            bEDTh (1,j) = (raResults_hybrid.EDT.freqData(j,1) + raResults_hybrid.EDT.freqData(j,1) ) / 2;
            Error(1,j) = (aEDTr (1,j) - bEDTh (1,j)) / aEDTr (1,j);
            cEDT  (1,j) = Error(1,j);
        end
    end

    %% ---------------------------------

    %% calculate new absorptions

    iLoop=iLoop+1;
    %% 1 KHz band
    for k=1:6
        absorbData(k,BAND) = An(1,iLoop);
    end

    %% Save Param
    if paramAdj ==     'EDT'   pRef(iLoop, :) = aEDTr;  pSim(iLoop, :) = bEDTh;
        %elseif paramAdj == 'C80'   pRef(iLoop, :) = aC80r;  pSim(iLoop, :) = bC80h;
        %elseif paramAdj == 'C50'   pRef(iLoop, :) = aC50r;  pSim(iLoop, :) = bC50h;
    elseif paramAdj == 'C80'   pRef(iLoop, :) = aLinear;  pSim(iLoop, :) = bLinear;
    elseif paramAdj == 'C50'   pRef(iLoop, :) = aLinear;  pSim(iLoop, :) = bLinear;
    end
    %% Save Absorp
    pAbs(iLoop, :)       = absorbData (1,:);
    ErrVsAbs (iLoop, :)  = Error;

    %% ---------------------------------------------------
    vParam = sprintf(formatParR,pRef(iLoop, :));             disp(vParam);
    vParam = sprintf(formatParS,pSim(iLoop, :));             disp(vParam);
    vError = sprintf(formatError,Error);                    disp(vError);
    vAbsor = sprintf(formatAbsor,pAbs(iLoop, :));            disp(vAbsor);


    %% send new abssortion values

    absorbDataT = absorbData';
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

    pause (2);

    % disp(message);
    % pause (1)
    %% ----------- ------------------
    % actual folder
    current_folder = pwd;
    % % new folder
    % new_folder = num2str(iLoop);
    % mkdir( current_folder, new_folder);
    % save absortions
    nameFile= ['Absorb_' num2str(BAND) '_' num2str(iLoop)];
    save(fullfile( current_folder,   nameFile), 'absorbData');

    % copy files
    % copyfi le(fullfile( current_folder,'BR*'), new_folder);
    % copyfile(fullfile( current_folder,'Ir_Hyb*'), new_folder);
    % copyfile(fullfile( current_folder,'*.mat'), new_folder);
    %% -------------------------------
    clear itaObj_hybrid;
    clear raResults_hybrid;
end
 
% actual folder
current_folder = pwd;
% new folder
new_folder = [Room '-' paramAdj '-' num2str(BAND)];
mkdir( current_folder, new_folder);

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
nameFile= "pAbsFile_"+ H +"_"+ M + "_" + S;
save(fullfile( current_folder,   nameFile), 'pAbs');
nameFile= "pRefFile_"+ H +"_"+ M + "_" + S;
save(fullfile( current_folder,   nameFile), 'pRef');
nameFile= "pSimFile_"+ H +"_"+ M + "_" + S;
save(fullfile( current_folder,   nameFile), 'pSim');
nameFile= "ErrFile_"+ H +"_"+ M + "_" + S;
save(fullfile( current_folder,   nameFile), 'ErrVsAbs');

copyfile(fullfile( current_folder,'*.mat'), new_folder);
delete *.mat

% plot (ejeX,pSim(:,5));