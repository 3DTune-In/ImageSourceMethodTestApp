%% This script contains the OSC script to initialize the SMALL ROOM

% Authors: Fabian Arrebola (13/12/2023) 
% contact: areyesa@uma.es
% 3DDIANA research group. University of Malaga
% Project: SONICOM
% 
% Copyright (C) 2023 Universidad de Málaga


%% Open connection to send messages to ISM
ISMPort = 12300;
connectionToISM = HybridOscCmds.InitConnectionToISM(ISMPort);

%% Open OSC server
% https://0110.be/posts/OSC_in_Matlab_on_Windows%2C_Linux_and_Mac_OS_X_using_Java
% https://github.com/hoijui/JavaOSC
listenPort = 12301;
receiver = HybridOscCmds.InitOscServer(listenPort);
[receiver osc_listener] = HybridOscCmds.AddListenerAddress(receiver, '/ready');

%% Set Room
HybridOscCmds.SendChangeRoomToISM(connectionToISM, 'small_room_A_Izq.xml');
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);

%% Listener Location 
position =[0.2 0.0 -0.59];
HybridOscCmds.SendListenerLocationToISM (connectionToISM, position);
% Waiting msg from ISM
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);

%% Set BRIR
HybridOscCmds.SendChangeBRIRToISM(connectionToISM, 'sofa_reverb140cm_quad_reverb_44100.sofa');
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);

%% Set Source Location 
position =[-1.2 0.0 -0.59];
HybridOscCmds.SendSourceLocationToISM (connectionToISM, position);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);

%% configureHybrid (connectionToISM, receiver, osc_listener,                W_Slope,  DistMax,       RefOrd,   RGain  ,  SaveIR)
  HybridOscCmds.configureHybrid (connectionToISM, receiver, osc_listener,     2,         30,            3,       15.8489,   false);

%%  Send Play 
HybridOscCmds.SendPlayToISM(connectionToISM);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Play");
pause(0.2);

% Close, doesn't work properly
HybridOscCmds.CloseOscServer(receiver, osc_listener);