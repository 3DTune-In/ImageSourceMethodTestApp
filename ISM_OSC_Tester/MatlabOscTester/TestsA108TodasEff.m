%% This script Contains the OSC command set to simulate the room 
%% corresponding to the "Aula 108" by placing the listener and the source 
%% in locations specified in the physical measurements carried out

% Authors: Fabian Arrebola (17/09/2024) 
% contact: areyesa@uma.es
% 3DDIANA research group. University of Malaga
% Project: SONICOM
% 
% Copyright (C) 2024 Universidad de Málaga

%% Reverb Gain
%RGain_dB = -6;       %Omni
RGain_dB = -4.8428;  %Binaural
RGain = db2mag(RGain_dB);

%% Folder with impulse responses
nameFolder='\workFolder';
resourcesFolder = 'C:\Repos\of_v0.12.0_vs_release\ImageSourceMethodTestApp\bin\data\resources\';
workFolder = strcat(resourcesFolder,nameFolder);
cd(resourcesFolder);

addpath ('C:\Repos\of_v0.12.0_vs_release\ImageSourceMethodTestApp\ISM_OSC_Tester\MatlabOscTester');
%% ------------------
DirectPath=true;
%% ------------------
pS=2;
posS = [1.55  0.02 -0.68;     %1
        2.68  0.02 -0.68;     %2
        2.68 -2.48 -0.68;     %3
        2.68 -4.89 -0.68;];   %4
pL=5;                        
posL = [-0.45  0.02 -0.68;    %1
        -0.45 -2.48 -0.68;    %2
        -0.45 -4.98 -0.68;    %3
        -2.23 -2.48 -0.68;    %4 
        -3.24 -4.98 -0.68;];  %5
% % HRTF Omni
% HRTFFile = 'Sala108_listener1_sourceQuad_2m_48kHz_Omnidirectional_direct_path.sofa';
% % Sofa Omni
% sofaFile = 'Sala108_listener1_sourceQuad_2m_48kHz_Omnidirectional_reverb.sofa';

%% HRTF Binaural
HRTFFile = 'HRTF_SADIE_II_D1_48K_24bit_256tap_FIR_SOFA_aligned.sofa';
%% Sofa Binaural
sofaFile = 'Sala108_listener1_sourceQuad_2m_48kHz_reverb_adjusted.sofa';

%% Absor Binaural
% folderAbsor = 'C:\Repos\of_v0.12.0_vs_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\A108 CASCADE 20FIT\9';
%% Absor Omni
%folderAbsor = 'C:\Repos\of_v0.12.0_vs_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\A108 Omni\7';
folderAbsor = 'C:\Repos\of_v0.12.0_vs_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\Ab_A108\Eyy';
%% Absor Eyring
%folderAbsor = 'C:\Repos\of_v0.12.0_vs_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\AbsorEyring\A108';

roomFile = 'A108_room_Ini.xml';
dp_Tmix = 20;
RefOrd = 40;

%% Num Bytes BRIR 
brirInfo = SOFAload(sofaFile);
dataBRIRtotal = brirInfo.Data.IR;
dataBRIRsimple = squeeze(dataBRIRtotal(3,:,:));
dataBRIRsimple = dataBRIRsimple';
Fs = brirInfo.Data.SamplingRate; 
NumBytesBRIR = length (dataBRIRsimple) * 4;

%% Open connection to send messages to ISM
ISMPort = 12300;
connectionToISM = HybridOscCmds.InitConnectionToISM(ISMPort);
%% Open OSC server
listenPort = 12301;
receiver = HybridOscCmds.InitOscServer(listenPort);
[receiver osc_listener] = HybridOscCmds.AddListenerAddress(receiver, '/ready');

%% Set Room
HybridOscCmds.SendChangeRoomToISM(connectionToISM, roomFile);
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
% configureHybrid (connectionToISM, receiver, osc_listener,                   W_Slope, DistMax,   RefOrd, RGain, SaveIR)
HybridOscCmds.configureHybrid (connectionToISM, receiver, osc_listener,         2,    dp_Tmix,       1,    RGain,   false);
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

for pL=1:5
    if pL==1  
        min_pS = 1; max_pS = 4;
    else
        min_pS = 2; max_pS = 2;
    end
    for pS= min_pS:max_pS
        %% ------------------------------
        disp ("Init -- pL: " + int2str(pL) + " pS: " + int2str(pS));
        %% Listener Location
        positionL = posL(pL,:);
        HybridOscCmds.SendListenerLocationToISM (connectionToISM, positionL);
        message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
        %% Set Source Location
        positionS = posS(pS,:);
        HybridOscCmds.SendSourceLocationToISM (connectionToISM, positionS);
        message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);

        %% Set W_Slope, DistMax, RefOrd, RGain,
        % configureHybrid (connectionToISM, receiver, osc_listener,              W_Slope, DistMax, RefOrd, RGain, SaveIR)
       
        HybridOscCmds.configureHybrid (connectionToISM, receiver, osc_listener,      -1,    -1,     RefOrd,    -1,   true);
        pause(1);
       
        %% Wait for impulse response file is generated by the ISM simulator
        cd (workFolder);
        formatFileHyb= "tIrRO%iDP%02iW%02i";
        nameFileHyb = sprintf(formatFileHyb, RefOrd, dp_Tmix, W_Slope)+'HYB.wav';
        fullPath = fullfile(workFolder, nameFileHyb);
        % Wait until the file is generated by the ISM simulator
        disp(['waiting: ' nameFileHyb]);
        while ~exist(fullPath, 'file')
            pause(1); % Wait 1 second before checking again
        end
        prevSize=0;
        infoFile = dir(fullPath);
        actualSize = infoFile.bytes;
        while prevSize < actualSize || prevSize < NumBytesBRIR*0.99
            prevSize = actualSize;
            pause (3);
            infoFile = dir(fullPath);
            actualSize = infoFile.bytes;
            disp("waiting: " + int2str(actualSize));
        end

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
        % movefile (nameFileISM, newNameFileISM);

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
        % movefile(newNameFileISM, nameNewFolder);
        movefile('DataSimulation.mat', nameNewFolder);
        copyfile(fullfile( folderAbsor,'FiInfAbsorb.mat'), nameNewFolder);
        % copyfile(fullfile( folderAbsor,'*.wav'), nameNewFolder);

        disp ("End -- pL: " + int2str(pL) + " pS: " + int2str(pS));
        %% ------------------------------
    end 
    
end



% Close, doesn't work properly
HybridOscCmds.CloseOscServer(receiver, osc_listener);

%copyfile nameFileHyb newNameFileHyb;
disp(message+" END");