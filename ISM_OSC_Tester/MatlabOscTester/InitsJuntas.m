%% This script contains the OSC script to initialize the LAB ROOM

% Authors: Fabian Arrebola (13/12/2023) 
% contact: areyesa@uma.es
% 3DDIANA research group. University of Malaga
% Project: SONICOM
% 
% Copyright (C) 2023 Universidad de Málaga
addpath ('C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\ISM_OSC_Tester\MatlabOscTester');

posS = [2.0 0.0 0.15];
posL = [0.0 0.0 0.15];
[yaw, pitch, roll] = relativePos2Orientation(posL, posS);

% %% source_2
% posS = [4.30 0.0 0.15];
% %% listener_4
% posL = [-2.0 -2.0 0.15]; 

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

%% Listener Location 
positionL = posL;
HybridOscCmds.SendListenerLocationToISM (connectionToISM, positionL);
% Waiting msg from ISM
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
%% Listener Orientation
orientationL= zeros(1,3);
orientationL(1) = yaw; orientationL(2) = pitch; orientationL(3) = roll;
HybridOscCmds.SendListenerOrientationToISM (connectionToISM, orientationL);
% Waiting msg from ISM
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
%% Set Room
HybridOscCmds.SendChangeRoomToISM(connectionToISM, 'Juntas_room_Ini.xml');
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
%% Set Source Location 
positionS = posS;
HybridOscCmds.SendSourceLocationToISM (connectionToISM, positionS);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);

%% Set BRIR Binaural
% HybridOscCmds.SendChangeBRIRToISM(connectionToISM, 'SalaJuntasTeleco_listener1_sourceQuad_2m_48kHz_reverb_adjusted.sofa');
%% Set RIR Omni
HybridOscCmds.SendChangeBRIRToISM(connectionToISM, 'SalaJuntasTeleco_listener1_sourceQuad_2m_48kHz_Omnidirectional_reverb.sofa');

message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
pause(1);
%%  Send Play and Stop ToISM
HybridOscCmds.SendPlayToISM(connectionToISM);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Play");
pause(0.5);
HybridOscCmds.SendStopToISM(connectionToISM);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Stop");
pause(0.5);
%% Set RGain
% configureHybrid (connectionToISM, receiver, osc_listener,              W_Slope, DistMax, RefOrd, RGain, SaveIR) 
HybridOscCmds.configureHybrid (connectionToISM, receiver, osc_listener,         2,    20,       4,    1,   false);

pause(0.2);
disp(message+" RIR");

%%  Enable Distance Attenuation Reverb Enable To ISM
HybridOscCmds.SendDistanceAttenuationReverbEnableToISM (connectionToISM, false);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Distance Attenuation Reverb Enable");
pause(0.2);

%% Set Absortions Binaural
%cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\sJUNTAS CASCADE 20FIT\10';
%% Set Absortions Omni
cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\sJuntas Omni\7';

load ("FiInfAbsorb.mat");
%% Send Initial absortions
walls_absor = zeros(1,54);
absorbDataT = absorbData1';
walls_absor = absorbDataT(:);
HybridOscCmds.SendAbsortionsToISM(connectionToISM, walls_absor'); 
pause(0.1);

% cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources';
% [yM,Fs] = audioread('LabBRIR.wav');
% cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder';
% [yS,Fs] = audioread('wIrRO0DP01W02.wav');
% figure;
% plot(yM,'DisplayName','yM');
% title ('LAB -- Measured');
% grid on
% ylim([-0.1 0.1]);
% figure;
% plot(yS,'DisplayName','yS');
% title ('LAB -- Simulated');
% grid on
% ylim([-0.1 0.1]);

% Close, doesn't work properly
HybridOscCmds.CloseOscServer(receiver, osc_listener);