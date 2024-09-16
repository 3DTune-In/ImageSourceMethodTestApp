%% This script Contains the OSC command set to simulate the room 
%% corresponding to the "Sala de Juntas" by placing the listener and the source 
%% in locations specified in the physical measurements carried out

% Authors: Fabian Arrebola (13/12/2024) 
% contact: areyesa@uma.es
% 3DDIANA research group. University of Malaga
% Project: SONICOM
% 
% Copyright (C) 2024 Universidad de Málaga

%% Folder with impulse responses
nameFolder='\workFolder';
resourcesFolder = 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\';
workFolder = strcat(resourcesFolder,nameFolder);

addpath ('C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\ISM_OSC_Tester\MatlabOscTester');
%% ------------------
DirectPath=true;
%% ------------------
pS=2;
posS = [2.0  0.0 0.15;   %1
        4.3  0.0 0.15;   %2
        4.3 -2.0 0.15;   %3
        4.3 -4.0 0.15];  %4 
pL=5;                                                      
posL = [0.0  0.0 0.15;   %1
        0.0 -2.0 0.15;   %2 
        0.0 -4.0 0.15;   %3 
       -2.0 -2.0 0.15;   %4
       -4.0 -4.0 0.15];  %5


%% Set HRTF Omni
HRTFFile = 'SalaJuntasTeleco_listener1_sourceQuad_2m_48kHz_Omnidirectional_direct_path.sofa')
%% Sofa Omni
sofaFile = 'SalaJuntasTeleco_listener1_sourceQuad_2m_48kHz_Omnidirectional_reverb.sofa';

%% HRTF Binaural
% HRTFFile = 'HRTF_SADIE_II_D1_48K_24bit_256tap_FIR_SOFA_aligned.sofa';
%% Sofa Binaural
% sofaFile = 'SalaJuntasTeleco_listener1_sourceQuad_2m_48kHz_reverb_adjusted.sofa';

%% Absor Binaural
% folderAbsor = 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\sJUNTAS CASCADE 20FIT\10';
%% Absor Omni
folderAbsor = 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\sJuntas Omni\7';
%% Absor Eyring
%folderAbsor = 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\AbsorEyring\sJuntas';

roomFile = 'Juntas_room_Ini.xml';
dp_Tmix = 34;

% %% source_2
% posS = [4.30 0.0 0.15];
% %% listener_4
% posL = [-2.0 -2.0 0.15]; 

%% Open connection to send messages to ISM
ISMPort = 12300;
connectionToISM = HybridOscCmds.InitConnectionToISM(ISMPort);
%% Open OSC server
listenPort = 12301;
receiver = HybridOscCmds.InitOscServer(listenPort);
[receiver osc_listener] = HybridOscCmds.AddListenerAddress(receiver, '/ready');
%% Listener Location 
positionL = posL(pL,:);
HybridOscCmds.SendListenerLocationToISM (connectionToISM, positionL);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
%% Set Room
HybridOscCmds.SendChangeRoomToISM(connectionToISM, roomFile);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
%% Set Source Location 
positionS = posS(pS,:);
HybridOscCmds.SendSourceLocationToISM (connectionToISM, positionS);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
%% Set HRTF
HybridOscCmds.SendChangeHRTFToISM(connectionToISM, HRTFFile);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
pause(1);
%% Set BRIR
HybridOscCmds.SendChangeBRIRToISM(connectionToISM, sofaFile);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
pause(1);
%% Set W_Slope, DistMax, RefOrd, RGain,
% configureHybrid (connectionToISM, receiver, osc_listener,              W_Slope, DistMax, RefOrd, RGain, SaveIR) 
HybridOscCmds.configureHybrid (connectionToISM, receiver, osc_listener,         2,    dp_Tmix,       1,    1,   false);
pause(0.2);
disp(message+" RIR");
%% Set Absortions
cd (folderAbsor);
load ("FiInfAbsorb.mat");
load ("ParamsISM.mat");

%% Send Initial absortions
walls_absor = zeros(1,54);
absorbDataT = absorbData1';
walls_absor = absorbDataT(:);
HybridOscCmds.SendAbsortionsToISM(connectionToISM, walls_absor'); 
pause(0.1);
%%  Send Spatialisation Enable To ISM
HybridOscCmds.SendSpatialisationEnableToISM (connectionToISM, true);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Spatialisation Enable");
pause(0.1);
%%  Send Distance Attenuation Enable To ISM
HybridOscCmds.SendDistanceAttenuationEnableToISM (connectionToISM, true);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Distance Attenuation Enable");
pause(0.1);
%% Enable/Disable Direct Path
HybridOscCmds.SendDirectPathEnableToISM(connectionToISM, DirectPath);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Enable Direct Path");
%% Enable Reverb
HybridOscCmds.SendReverbEnableToISM(connectionToISM, true);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Enable Reverb");
pause(0.2);
%%  Enable/Disable Distance Attenuation Reverb 
HybridOscCmds.SendDistanceAttenuationReverbEnableToISM (connectionToISM, false);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Distance Attenuation Reverb Disable");
pause(0.1);
%%  Set Ro=4
HybridOscCmds.SendReflecionOrderToISM(connectionToISM, 4);
% Waiting msg from ISM
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Ref Order = 4");
%%  Send Play and Stop
HybridOscCmds.SendPlayToISM(connectionToISM);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" PLAY");
pause(1);
HybridOscCmds.SendStopToISM(connectionToISM);
%% Set W_Slope, DistMax, RefOrd, RGain,
% configureHybrid (connectionToISM, receiver, osc_listener,              W_Slope, DistMax, RefOrd, RGain, SaveIR) 
HybridOscCmds.configureHybrid (connectionToISM, receiver, osc_listener,         -1,    -1,       40,    -1,   true);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
pause(0.2);

%% Disable Reverb
HybridOscCmds.SendReverbEnableToISM(connectionToISM, false);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Disable Reverb");
pause(2);

%% Set W_Slope, DistMax, RefOrd, RGain,
% configureHybrid (connectionToISM, receiver, osc_listener,              W_Slope, DistMax, RefOrd, RGain, SaveIR) 
HybridOscCmds.configureHybrid (connectionToISM, receiver, osc_listener,         -1,    -1,       40,    -1,   true);
% message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
pause(0.2);
disp(message+" RIR");

% Close, doesn't work properly
HybridOscCmds.CloseOscServer(receiver, osc_listener);

formatFileISM= "iIrRO%iDP%02iW%02i";
nameFileISM = sprintf(formatFileISM, RefOrd, dp_Tmix, W_Slope)+'.wav';
formatFileWin= "wIrRO0DP%02iW%02i";
nameFileWin = sprintf(formatFileWin, dp_Tmix, W_Slope)+'.wav';
formatFileHyb= "tIrRO%iDP%02iW%02i";
nameFileHyb = sprintf(formatFileHyb, RefOrd, dp_Tmix, W_Slope)+'HYB.wav';
%formatFileBRIR= "wIrRO0DP01W02";
formatFileBRIR= "BRIR";
nameFileBRIR = sprintf(formatFileBRIR)+'.wav';

formatNewFileHyb = "%s-L%i-S%i-";
newNameFileHyb  = sprintf(formatNewFileHyb,Room, pL, pS )+'HYB.wav';
formatNewFileISM = "%s-L%i-S%i-";
newNameFileISM  = sprintf(formatNewFileHyb,Room, pL, pS )+'ISM.wav';
cd (workFolder);
movefile (nameFileHyb, newNameFileHyb);
movefile (nameFileISM, newNameFileISM);

% actual folder
current_folder = pwd;
% new folder
formatNameNewFolder = "%s-L%i-S%i";
nameNewFolder  = sprintf(formatNameNewFolder,Room, pL, pS );
mkdir(current_folder, nameNewFolder);
% save data simulations
save ('DataSimulation.mat','Room','roomFile' , 'pL', 'pS', 'positionS', 'positionL','sofaFile', 'folderAbsor', 'dp_Tmix', 'DirectPath');
% copy files
movefile(newNameFileHyb, nameNewFolder);
movefile(newNameFileISM, nameNewFolder);
movefile('DataSimulation.mat', nameNewFolder);
copyfile(fullfile( folderAbsor,'FiInfAbsorb.mat'), nameNewFolder);
% copyfile(fullfile( folderAbsor,'*.wav'), nameNewFolder);

%copyfile nameFileHyb newNameFileHyb;
disp(message+" END");