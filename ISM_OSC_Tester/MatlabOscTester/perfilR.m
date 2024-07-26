%% This script contains the OSC commands to simulate 
%% the absorption (reflection) profile of the toolkit filters

% Authors: Fabian Arrebola (17/04/2024) 
% contact: areyesa@uma.es
% 3DDIANA research group. University of Malaga
% Project: SONICOM
% 
% Copyright (C) 2023 Universidad de Málaga
addpath ('C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\ISM_OSC_Tester\MatlabOscTester');

%% Open connection to send messages to ISM
ISMPort = 12300;
connectionToISM = HybridOscCmds.InitConnectionToISM(ISMPort);

%% Open OSC server
% https://0110.be/posts/OSC_in_Matlab_on_Windows%2C_Linux_and_Mac_OS_X_using_Java
% https://git
% hub.com/hoijui/JavaOSC
listenPort = 12301;
receiver = HybridOscCmds.InitOscServer(listenPort);
[receiver osc_listener] = HybridOscCmds.AddListenerAddress(receiver, '/ready');
%% Disable Direct Path
HybridOscCmds.SendDirectPathEnableToISM(connectionToISM, false);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Disable Direct Path");

%% Disable Distance Attenuation
HybridOscCmds.SendDistanceAttenuationEnableToISM (connectionToISM, false);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Disable Distance Attenuation");
pause(0.2);

%% Disable Spatialisation
HybridOscCmds.SendSpatialisationEnableToISM (connectionToISM, false);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Disable Spatialisation");
pause(0.2);

%% Disable Reverb
HybridOscCmds.SendReverbEnableToISM(connectionToISM, false);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Disable Reverb");
pause(0.2);
%% Set RGain
% configureHybrid (connectionToISM, receiver, osc_listener,              W_Slope, DistMax, RefOrd, RGain, SaveIR) 
HybridOscCmds.configureHybrid (connectionToISM, receiver, osc_listener,         2,    20,       1,    1,   false);
pause(0.2);
disp(message+" RIR");

% cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\sJuntas 34m17m Pendiente\7';
% %cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\sJuntas 34m17m Pendiente_VM\8';
% %cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\sJuntas 34m17m VM_Pendiente\3';
% %cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\A108 40m20m pendiente\11';
% %cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\A108 40m20m pendiente_VM\12';
% %cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\A108 40m20m VM_pendiente\5';
% load ("FiInfAbsorb.mat");
% %% Send Initial absortions
% walls_absor = zeros(1,54);
% absorbDataT = absorbData1';
% walls_absor = absorbDataT(:);
% HybridOscCmds.SendAbsortionsToISM(connectionToISM, walls_absor'); 
% pause(0.1);

%% -----------------------------------------------------------------------------------------------
%% Send Initial absortions
%% Set Room
% HybridOscCmds.SendChangeRoomToISM(connectionToISM, 'Juntas_room_Ini.xml');
HybridOscCmds.SendChangeRoomToISM(connectionToISM, 'A108_room_VM.xml');
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
%% Set BRIR
%% HybridOscCmds.SendChangeBRIRToISM(connectionToISM, 'SalaJuntasTeleco_listener1_sourceQuad_2m_48kHz_reverb_adjusted.sofa');
%% HybridOscCmds.SendChangeBRIRToISM(connectionToISM, 'Sala108_listener1_sourceQuad_2m_48kHz_reverb_adjusted.sofa');
HybridOscCmds.SendChangeBRIRToISM(connectionToISM, 'Sala108_listener1_sourceQuad_2m_48kHz_Omnidirectional_reverb.sofa');
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
pause(1);

absW = [0.50 0.50 0.50 0.50 0.50 0.50 0.50 0.50 0.10];
%absW = [1.0000    0.0631    0.2512    1.0000    1.0000    1.0000    0.2512    0.0631    1.0000];
%absW = [1.0000    1.0000    0.2512    1.0000    1.0000    0.0631    0.2512    0.0631    1.0000];
%absW = [1.000 0.000 1.000 0.000 1.000 0.000 1.000 0.000 1.000];
absorbData = repmat (absW, 6, 1); 


% % %% Set Absortions
% cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\sJuntas 34m17m valorMedio 48K\12';
% % cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\A108 40m20m valorMedio 48K\9';
cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\A108 CASCADE 30FIT\8';
%cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\sJUNTAS CASCADE 20FIT\10';
%%cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\7';
load ("FiInfAbsorb.mat");
absorbData =absorbData1;

walls_absor = zeros(1,54);
absorbDataT = absorbData';
%absorbDataT = absorbData1';
walls_absor = absorbDataT(:);
HybridOscCmds.SendAbsortionsToISM(connectionToISM, walls_absor');
pause(0.2);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message);
pause(0.1);

% Close, doesn't work properly
HybridOscCmds.CloseOscServer(receiver, osc_listener);