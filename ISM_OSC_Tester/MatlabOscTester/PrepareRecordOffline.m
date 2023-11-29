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
cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\SeriesIr\16';
%% cd 'C:\Repos\HIBRIDO PRUEBAS\New LAB 32 2 20\12'

%% Load info
load ("ParamsISM.mat");
load ("FiInfAbsorb.mat");
load ("FiInfSlopes.mat");
load ("EnergyFactor.mat");
%% ---------------------------------------------------------
%% Set PruningDistance-->TMix
Dp_Tmix = 14;
W_Slope = 2;            %  It may be a different value than the one used for energy adjustment

%% %% Set working folder
cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\SeriesIr';
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

% %% SetsDirectPath Disable
% SendDirectPathEnableToISM(connectionToISM, false);
% message = WaitingOneOscMessageStringVector(receiver, osc_listener);
% disp(message);

%%  Set Ro=1
SendReflecionOrderToISM(connectionToISM, 1);
% Waiting msg from ISM
message = WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message);

%%  Send Play and Stop ToISM
SendPlayToISM(connectionToISM);
message = WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message);
pause(1);
SendStopToISM(connectionToISM);
message = WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message);
pause(1);

%% Send Initial absortions
walls_absor = zeros(1,54);
absorbDataT = absorbData';
walls_absor = absorbDataT(:);
SendAbsortionsToISM(connectionToISM, walls_absor'); 
pause(0.2);
%% Waiting msg from ISM
message = WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message);
pause(0.1);


%% configureHybrid (connectionToISM, receiver, osc_listener, 
%%                                                       W_Slope, DistMax, RefOrd, RGain, SaveIR)
%% Enable Reverb
SendReverbEnableToISM(connectionToISM, true);
message = WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message);
pause(2);

%% t file 
configureHybrid (connectionToISM, receiver, osc_listener,       W_Slope,   Dp_Tmix,      RefOrd,       RGain,   false);

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

