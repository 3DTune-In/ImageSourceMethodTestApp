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


%% Set folder with IRs and Params
cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\SeriesIr\8';
%% cd 'C:\Repos\HIBRIDO PRUEBAS\New LAB 40 2 24\16'

%% Load info
load ("ParamsISM.mat");
load ("FiInfAbsorb.mat");
load ("FiInfSlopes.mat");
load ("EnergyFactor.mat");

%% ---------------------------------------------------------
%% Set TMix & Slope
Dp_Tmix = 30;
W_Slope = 2;            %  It may be a different value than the one used for energy adjustment

%% Set working folder
cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\SeriesIr';
% delete *.wav;
save ('ParamsHYB.mat','RefOrd', 'DpMax','W_Slope','RGain_dB', 'Dp_Tmix','FactorMeanValue');
absorbData= absorbData1;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% RGain = RGain_Linear*EnergyFactor;
RGain = FactorMeanValue*db2mag(RGain_dB); 

%% ---------------------------------------------------------

%% Open connection to send messages to ISM
ISMPort = 12300;
connectionToISM = InitConnectionToISM(ISMPort);

%% Open OSC server
% https://0110.be/posts/OSC_in_Matlab_on_Windows%2C_Linux_and_Mac_OS_X_using_Java
% https://github.com/hoijui/JavaOSC
listenPort = 12301;
receiver = InitOscServer(listenPort);
[receiver osc_listener] = AddListenerAddress(receiver, '/ready');

% %% Set DirectPath Disable
% SendDirectPathEnableToISM(connectionToISM, false);
% message = WaitingOneOscMessageStringVector(receiver, osc_listener);
% disp(message);

%%  Set Ro=1
SendReflecionOrderToISM(connectionToISM, 1);
% Waiting msg from ISM
message = WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Ref Order = 1");

%%  Send Spatialisation Enable To ISM
SendSpatialisationEnableToISM (connectionToISM, true);
message = WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Spatialisation Enable");
pause(0.2);

%%  Send Distance Attenuation Enable To ISM
SendDistanceAttenuationEnableToISM (connectionToISM, true);
message = WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Distance Attenuation Enable");
pause(0.2);

%%  Send Play and Stop To ISM
SendPlayToISM(connectionToISM);
message = WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" PLAY");
pause(1);
SendStopToISM(connectionToISM);
message = WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" STOP");
pause(0.2);

%% Send Initial absortions
walls_absor = zeros(1,54);
absorbDataT = absorbData';
walls_absor = absorbDataT(:);
SendAbsortionsToISM(connectionToISM, walls_absor'); 
pause(0.2);
%% Waiting msg from ISM
message = WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" ABSORPTIONS");
pause(0.1);

%% configureHybrid (connectionToISM, receiver, osc_listener, 
%%                                                       W_Slope, DistMax, RefOrd, RGain, SaveIR)
%% Enable Reverb
SendReverbEnableToISM(connectionToISM, true);
message = WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Enable Reverb");
pause(0.2);

%% w file 

%% LAB_ROOM
% configureHybrid (connectionToISM, receiver, osc_listener,     2,         22,            0,       27.8,   true);
configureHybrid (connectionToISM, receiver, osc_listener,       W_Slope,   Dp_Tmix,      0,       RGain,   true);
%% SMALL_ROOM
%configureHybrid (connectionToISM, receiver, osc_listener,      2,     14,            0,         17.99,   true);
pause(1.0);

%% t file
configureHybrid (connectionToISM, receiver, osc_listener,      W_Slope,      -1,           RefOrd,        -1,   true);
pause(1.0);

%% Disable Reverb
SendReverbEnableToISM(connectionToISM, false);
message = WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Disable Reverb");
pause(1);

%% i file
configureHybrid (connectionToISM, receiver, osc_listener,     -1,    -1,      -1,       -1,   true);
pause(1);

%% Reflecion Order = 0
SendReflecionOrderToISM(connectionToISM, 0);
% Waiting msg from ISM
message = WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message);
pause(0.5);

%% Enable Reverb
SendReverbEnableToISM(connectionToISM, true);
message = WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Enable Reverb");
pause(2);


%% BRIR
%% configureHybrid (connectionToISM, receiver, osc_listener, 
%%                                                           W_Slope, DistMax, RefOrd, RGain, SaveIR)
%% LAB_ROOM
% configureHybrid (connectionToISM, receiver, osc_listener,     2,      1,     0,      27.8,   true);
configureHybrid (connectionToISM, receiver, osc_listener,       2,      1,     0,      RGain,   true);
%% SMALL_ROOM
%configureHybrid (connectionToISM, receiver, osc_listener,      2,      1,     0,     17.99,   true);

pause(0.1);

% Close, doesn't work properly
CloseOscServer(receiver, osc_listener);

%% ------------------------------------------
%% ------------------------------------------

%% Open a UDP connection with a OSC server
function connectionToISM = InitConnectionToISM(port)
    connectionToISM = udp('127.0.0.1',port);
    fopen(connectionToISM);   
end

%% configureHybrid
function configureHybrid (connectionToISM, receiver, osc_listener, ...
                          W_Slope, DistMax, RO, RGain, saveIR)
     
    %% Send MaxDistImages
    if DistMax > 0
        SendDistMaxImgsFloatToISM(connectionToISM, DistMax);
        % Waiting msg from ISM
        message = WaitingOneOscMessageStringVector(receiver, osc_listener);
        disp(message);
        pause(0.5);
    end 

     %% Send WindowSlope
    if W_Slope > 0
        SendWindowSlopeToISM(connectionToISM, W_Slope);
        % Waiting msg from ISM
        message = WaitingOneOscMessageStringVector(receiver, osc_listener);
        disp(message);
        pause(0.5);
    end

     %% Send ReverbGain
    if RGain > 0
        SendReverbGainToISM(connectionToISM, RGain);
        % Waiting msg from ISM
        message = WaitingOneOscMessageStringVector(receiver, osc_listener);
        disp(message);
        pause(0.5);
    end 
    
    %% Send Reflection Order
    if RO ~= -1
        SendReflecionOrderToISM(connectionToISM, RO);
        % Waiting msg from ISM
        message = WaitingOneOscMessageStringVector(receiver, osc_listener);
        disp(message);
        pause(0.5);
    end
    
    if saveIR == true
       %% Send Save IR comand
       SendSaveIRToISM(connectionToISM);
       message = WaitingOneOscMessageStringVector(receiver, osc_listener);
       disp(message);
    end  
    pause(0.1);

end

%% Send DistanceMaxImagesListener to the OSC server (ISM)
function SendDistMaxImgsIntToISM(u, vint)
    oscsend(u,'/distMaxImgs','i',vint);    
end

%% Send DistanceMaxImagesListener to the OSC server (ISM)
function SendDistMaxImgsFloatToISM(u, vfloat)
    oscsend(u,'/distMaxImgs','f',vfloat);    
end

%% Send WindowSlope to the OSC server (ISM)
function SendWindowSlopeToISM(u, vint)
    oscsend(u,'/windowSlope','i',vint);    
end
%% Send ReflectionOrder to the OSC server (ISM)
function SendReflecionOrderToISM(u, vint)
    oscsend(u,'/reflectionOrder','i',vint);    
end

%% Send ReverbGain to the OSC server (ISM)
function SendReverbGainToISM(u, gain)
    oscsend(u,'/reverbGain','f',gain);    
end

%%  Send a SaveIR comand the OSC server (ISM)
function SendSaveIRToISM(u)
    oscsend(u,'/saveIR','N', "");
end

%%  Send a Play comand the OSC server (ISM)
function SendPlayToISM(u)
    oscsend(u,'/play','N', "");
end
%%  Send a Stop comand the OSC server (ISM)
function SendStopToISM(u)
    oscsend(u,'/stop','N', "");
end

%% Send DirectPathEnable comand to the OSC server (ISM)
function SendDirectPathEnableToISM(u, vbool)
    oscsend(u,'/directPathEnable','B',vbool);    
end

%% Send ReverbEnable comand to the OSC server (ISM)
function SendReverbEnableToISM(u, vbool)
    oscsend(u,'/reverbEnable','B',vbool);    
end

%% Send SpatialisationEnable comand to the OSC server (ISM)
function SendSpatialisationEnableToISM(u, vbool)
    oscsend(u,'/spatialisationEnable','B',vbool);    
end

%% Send DistanceAttenuationEnable comand to the OSC server (ISM)
function SendDistanceAttenuationEnableToISM(u, vbool)
    oscsend(u,'/distanceAttenuEnable','B',vbool);    
end



%% Send float vector to the OSC server (ISM)
function SendAbsortionsToISM(u, coefVector)
    m = repmat('f',1,length(coefVector));
    oscsend(u,'/absortions',m, coefVector);    
end

% %% Send string to the OSC server (ISM)
% function SendSringToISM(u, string)
%     oscsend(u,'/reverbGain','s',string);    
% end

%
function receiver = InitOscServer(port)
    cd('C:/Repos/of_v0.11.2_vs2017_release/ImageSourceMethodTestApp/ISM_OSC_Tester/MatlabOscTester')
    %version -java
    disp('Waiting OSC message');
    javaaddpath('javaosctomatlab.jar');    
    %javaclasspath    
    import com.illposed.osc.*;    
    import java.lang.String       
    receiver =  OSCPortIn(port);
%     osc_method = String('/ready');
%     osc_listener = MatlabOSCListener();
%     receiver.addListener(osc_method,osc_listener);
end

%
function [receiver osc_listener] = AddListenerAddress(receiver, address) 
    import com.illposed.osc.*;    
    import java.lang.String    
    osc_method = String(address);
    osc_listener = MatlabOSCListener();
    receiver.addListener(osc_method,osc_listener);
end

%%
function message = WaitingOneOscMessageStringVector(receiver, osc_listener)
    import com.illposed.osc.*;     
    receiver.startListening();
    while true           
        arguments = osc_listener.getMessageArgumentsAsString();
        if ~isempty(arguments) == 1             
            message = string(arguments);
            receiver.stopListening();
            break;
        end
    end
end
%% 

%% This doesn't work very well, I think
function CloseOscServer(receiver, osc_listener)
    import com.illposed.osc.*;         
    receiver.stopListening();
    receiver.close();
    receiver = 0;
    clear receiver;
    clear osc_listener;
    javarmpath('javaosctomatlab.jar');
    clear java;
end


