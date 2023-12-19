%% This script generates the impulse response associated with the Hybrid Method
%% To do this, it generates 4 impulse responses:
%%   the one associated with ISM with fade-out
%%   the corresponding to RIR with fade-in
%%   the one associated with the hybrid method
%%   the one that corresponds to the BRIR 

% Author: Fabian Arrebola (17/10/2023) 
% contact: areyesa@uma.es
% 3DDIANA research group. University of Malaga
% Project: SONICOM
% 
% Copyright (C) 2023 Universidad de Málaga


% %% LAB ROOM
% absorbData = [   %Gain 27.8
% 0.92500 0.92500 0.89221 0.85145 0.35311 0.27687 0.18218 0.44888 0.82130;
% 0.92500 0.92500 0.89221 0.85145 0.35311 0.27687 0.18218 0.44888 0.82130;
% 0.92500 0.92500 0.89221 0.85145 0.35311 0.27687 0.18218 0.44888 0.82130;
% 0.92500 0.92500 0.89221 0.85145 0.35311 0.27687 0.18218 0.44888 0.82130;
% 0.92500 0.92500 0.89221 0.85145 0.35311 0.27687 0.18218 0.44888 0.82130;
% 0.92500 0.92500 0.89221 0.85145 0.35311 0.27687 0.18218 0.44888 0.82130; ];

% %% SMALL ROOM (17-2-10)
% absorbData = [   % Gain = 17.99  slope= 2ms (17-2-10)
% 0.92500 0.34816 0.38625 0.46871 0.70101 0.65432 0.72194 0.72926 0.92500  ;
% 0.92500 0.34816 0.38625 0.46871 0.70101 0.65432 0.72194 0.72926 0.92500  ;
% 0.92500 0.34816 0.38625 0.46871 0.70101 0.65432 0.72194 0.72926 0.92500  ;
% 0.92500 0.34816 0.38625 0.46871 0.70101 0.65432 0.72194 0.72926 0.92500  ;
% 0.92500 0.34816 0.38625 0.46871 0.70101 0.65432 0.72194 0.72926 0.92500  ;
% 0.92500 0.34816 0.38625 0.46871 0.70101 0.65432 0.72194 0.72926 0.92500  ;];

%% Output
%  'ParamsHYB.mat'   <--  'RefOrd', 'DpMax','W_Slope','RGain_dB', 'Dp_Tmix','FactorMeanValue'


%% Set folder with IRs and Params
cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\12';
%% cd 'C:\Repos\HIBRIDO PRUEBAS\New LAB 40 2 24\16'

%% Load info
load ("ParamsISM.mat");
load ("FiInfAbsorb.mat");
load ("FiInfSlopes.mat");
load ("EnergyFactor.mat");

%% ---------------------------------------------------------
%% Set TMix & Slope
Dp_Tmix = 11;
W_Slope = 2;            %  It may be a different value than the one used for energy adjustment

%% Set working folder
cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder';
% delete *.wav;
save ('ParamsHYB.mat','RefOrd', 'DpMax','W_Slope','RGain_dB', 'Dp_Tmix','FactorMeanValue');
absorbData= absorbData1;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% RGain = RGain_Linear*EnergyFactor;
RGain = FactorMeanValue*db2mag(RGain_dB); 

%% ---------------------------------------------------------

%% Open connection to send messages to ISM
ISMPort = 12300;
connectionToISM = HybridOscCmds.InitConnectionToISM(ISMPort);

%% Open OSC server
% https://0110.be/posts/OSC_in_Matlab_on_Windows%2C_Linux_and_Mac_OS_X_using_Java
% https://github.com/hoijui/JavaOSC
listenPort = 12301;
receiver = HybridOscCmds.InitOscServer(listenPort);
[receiver osc_listener] = HybridOscCmds.AddListenerAddress(receiver, '/ready');

% %% Set DirectPath Disable
% SendDirectPathEnableToISM(connectionToISM, false);
% message = WaitingOneOscMessageStringVector(receiver, osc_listener);
% disp(message);
%% -----------------

%%  Set Ro=1
HybridOscCmds.SendReflecionOrderToISM(connectionToISM, 1);
% Waiting msg from ISM
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Ref Order = 1");

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

%%  Enable Distance Attenuation Reverb 
HybridOscCmds.SendDistanceAttenuationReverbEnableToISM (connectionToISM, false);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Distance Attenuation Reverb Disable");
pause(0.1);

%%  Send Play and Stop To ISM
HybridOscCmds.SendPlayToISM(connectionToISM);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" PLAY");
pause(0.1);
HybridOscCmds.SendStopToISM(connectionToISM);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" STOP");
pause(0.1);

%% Send Initial absortions
walls_absor = zeros(1,54);
absorbDataT = absorbData';
walls_absor = absorbDataT(:);
HybridOscCmds.SendAbsortionsToISM(connectionToISM, walls_absor'); 
pause(0.1);
%% Waiting msg from ISM
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" ABSORPTIONS");
pause(0.1);

%% Enable Reverb
HybridOscCmds.SendReverbEnableToISM(connectionToISM, true);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Enable Reverb");
pause(0.1);

%% w file 

%% LAB_ROOM
%% configureHybrid (connectionToISM, receiver, osc_listener,                W_Slope,  DistMax,       RefOrd,   RGain,  SaveIR)
%             configureHybrid (connectionToISM, receiver, osc_listener,     2,         22,            0,       27.8,   true);
HybridOscCmds.configureHybrid (connectionToISM, receiver, osc_listener,     W_Slope,  Dp_Tmix,        0,       RGain,  true);
%% SMALL_ROOM
%             configureHybrid (connectionToISM, receiver, osc_listener,      2,     14,            0,         17.99,   true);
pause(0.5);

%% t file
HybridOscCmds.configureHybrid (connectionToISM, receiver, osc_listener,      W_Slope,      -1,           RefOrd,        -1,   true);
pause(0.5);

%% Disable Reverb
HybridOscCmds.SendReverbEnableToISM(connectionToISM, false);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Disable Reverb");
pause(0.5);

%% i file
HybridOscCmds.configureHybrid (connectionToISM, receiver, osc_listener,     -1,    -1,      -1,       -1,   true);
pause(0.5);

%% Reflecion Order = 0
HybridOscCmds.SendReflecionOrderToISM(connectionToISM, 0);
% Waiting msg from ISM
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message);
pause(0.5);

%% Enable Reverb
HybridOscCmds.SendReverbEnableToISM(connectionToISM, true);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Enable Reverb");
pause(0.5);


%% BRIR
%% configureHybrid (connectionToISM, receiver, osc_listener, 
%%                                                           W_Slope, DistMax, RefOrd, RGain, SaveIR)
%% LAB_ROOM
%             configureHybrid (connectionToISM, receiver, osc_listener,     2,      1,     0,      27.8,   true);
HybridOscCmds.configureHybrid (connectionToISM, receiver, osc_listener,     2,      1,     0,      RGain,   true);
%% SMALL_ROOM
%             configureHybrid (connectionToISM, receiver, osc_listener,      2,      1,     0,     17.99,   true);

pause(0.1);

% Close, doesn't work properly
HybridOscCmds.CloseOscServer(receiver, osc_listener);

