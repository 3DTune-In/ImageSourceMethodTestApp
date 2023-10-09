% Author: Fabian Arrebola (15/05/2023) 
% contact: rfarrebola@uma.es
% 3DDIANA research group. University of Malaga
% Project: SONICOM
% 
% Copyright (C) 2023 Universidad de Málaga

% % SMALL ROOM
% absorbData = [%Factor 12 Initial Gain 1
% 0.50000 0.66864 0.53741 0.42580 0.84758 0.81019 0.92500 0.92500 0.78360; 
% 0.50000 0.66864 0.53741 0.42580 0.84758 0.81019 0.92500 0.92500 0.78360; 
% 0.50000 0.66864 0.53741 0.42580 0.84758 0.81019 0.92500 0.92500 0.78360; 
% 0.50000 0.66864 0.53741 0.42580 0.84758 0.81019 0.92500 0.92500 0.78360; 
% 0.50000 0.66864 0.53741 0.42580 0.84758 0.81019 0.92500 0.92500 0.78360; 
% 0.50000 0.66864 0.53741 0.42580 0.84758 0.81019 0.92500 0.92500 0.78360;  ];

% % SMALL ROOM
% absorbData = [   %Factor 15, InitialGain = 1
% 0.92500 0.39762 0.63895 0.47098 0.77500 0.69863 0.90822 0.92500 0.79111;
% 0.92500 0.39762 0.63895 0.47098 0.77500 0.69863 0.90822 0.92500 0.791119;
% 0.92500 0.39762 0.63895 0.47098 0.77500 0.69863 0.90822 0.92500 0.79111;
% 0.92500 0.39762 0.63895 0.47098 0.77500 0.69863 0.90822 0.92500 0.791119;
% 0.92500 0.39762 0.63895 0.47098 0.77500 0.69863 0.90822 0.92500 0.79111;
% 0.92500 0.39762 0.63895 0.47098 0.77500 0.69863 0.90822 0.92500 0.791119;];


% % SMALL ROOM
% absorbData = [   %Factor 1.57*4= 6.28, InitialGain = 4
% 0.440166, 0.925, 0.925, 0.705045, 0.925, 0.925, 0.976032, 0.925, 0.928249;
% 0.440166, 0.925, 0.925, 0.705045, 0.925, 0.925, 0.976032, 0.925, 0.928249;
% 0.440166, 0.925, 0.925, 0.705045, 0.925, 0.925, 0.976032, 0.925, 0.928249;
% 0.440166, 0.925, 0.925, 0.705045, 0.925, 0.925, 0.976032, 0.925, 0.928249;
% 0.440166, 0.925, 0.925, 0.705045, 0.925, 0.925, 0.976032, 0.925, 0.928249;
% 0.440166, 0.925, 0.925, 0.705045, 0.925, 0.925, 0.976032, 0.925, 0.928249;];

%SMALL ROOM
absorbData = [%Factor 11.0 Initial Gain 2
0.657411, 0.765334, 0.726683, 0.599748, 0.925, 0.83758, 0.901521, 0.782483, 0.925;
0.657411, 0.765334, 0.726683, 0.599748, 0.925, 0.83758, 0.901521, 0.782483, 0.925;
0.657411, 0.765334, 0.726683, 0.599748, 0.925, 0.83758, 0.901521, 0.782483, 0.925;
0.657411, 0.765334, 0.726683, 0.599748, 0.925, 0.83758, 0.901521, 0.782483, 0.925;
0.657411, 0.765334, 0.726683, 0.599748, 0.925, 0.83758, 0.901521, 0.782483, 0.925;
0.657411, 0.765334, 0.726683, 0.599748, 0.925, 0.83758, 0.901521, 0.782483, 0.925;];


% absorbData = [
% 0.52303 0.85176 0.92500 0.54919 0.48370 0.52560 0.81725 0.73209 0.92500;
% 0.52303 0.85176 0.92500 0.54919 0.48370 0.52560 0.81725 0.73209 0.92500;
% 0.52303 0.85176 0.92500 0.54919 0.48370 0.52560 0.81725 0.73209 0.92500;
% 0.52303 0.85176 0.92500 0.54919 0.48370 0.52560 0.81725 0.73209 0.92500;
% 0.52303 0.85176 0.92500 0.54919 0.48370 0.52560 0.81725 0.73209 0.92500;
% 0.52303 0.85176 0.92500 0.54919 0.48370 0.52560 0.81725 0.73209 0.92500;];

% %% pruebas con laboratorio sin atenueción de 3dB en reverb (factor = 11.5 ) 14 de junio
% absorbData = [
% 0.554293, 0.804504, 0.925, 0.95512, 0.449938, 0.484393, 0.814381, 0.730171, 0.75992;
% 0.554293, 0.804504, 0.925, 0.95512, 0.449938, 0.484393, 0.814381, 0.730171, 0.75992;
% 0.554293, 0.804504, 0.925, 0.95512, 0.449938, 0.484393, 0.814381, 0.730171, 0.75992;
% 0.554293, 0.804504, 0.925, 0.95512, 0.449938, 0.484393, 0.814381, 0.730171, 0.75992;
% 0.554293, 0.804504, 0.925, 0.95512, 0.449938, 0.484393, 0.814381, 0.730171, 0.75992;
% 0.554293, 0.804504, 0.925, 0.95512, 0.449938, 0.484393, 0.814381, 0.730171, 0.75992;];

%% pruebas con laboratorio para presentación Sonicom (factor = 9) primera semana de junio
% absorbData = [ 
% 0.52305 0.70175 0.92500 0.69918 0.48369 0.52562 0.81976 0.58208 0.92500;
% 0.52305 0.70175 0.92500 0.69918 0.48369 0.52562 0.81976 0.58208 0.92500;
% 0.52305 0.70175 0.92500 0.69918 0.48369 0.52562 0.81976 0.58208 0.92500;
% 0.52305 0.70175 0.92500 0.69918 0.48369 0.52562 0.81976 0.58208 0.92500;
% 0.52305 0.70175 0.92500 0.69918 0.48369 0.52562 0.81976 0.58208 0.92500;
% 0.52305 0.70175 0.92500 0.69918 0.48369 0.52562 0.81976 0.58208 0.92500;];

% absorbData = [
% 0.99403 0.92500 0.92500 0.57405 0.27155 0.38313 0.91863 0.68211 0.64673;
% 0.99403 0.92500 0.92500 0.57405 0.27155 0.38313 0.91863 0.68211 0.64673;
% 0.99403 0.92500 0.92500 0.57405 0.27155 0.38313 0.91863 0.68211 0.64673;
% 0.99403 0.92500 0.92500 0.57405 0.27155 0.38313 0.91863 0.68211 0.64673;
% 0.99403 0.92500 0.92500 0.57405 0.27155 0.38313 0.91863 0.68211 0.64673;
% 0.99403 0.92500 0.92500 0.57405 0.27155 0.38313 0.91863 0.68211 0.64673;
% ];

% absorbData = [
% 0.35463 0.625 0.50109 0.68979 0.50432 1.0 1.0 1.0 1.0;
% 0.35463 0.625 0.50109 0.68979 0.50432 1.0 1.0 1.0 1.0;
% 0.35463 0.625 0.50109 0.68979 0.50432 1.0 1.0 1.0 1.0;
% 0.35463 0.625 0.50109 0.68979 0.50432 1.0 1.0 1.0 1.0;
% 0.35463 0.625 0.50109 0.68979 0.50432 1.0 1.0 1.0 1.0;
% 0.35463 0.625 0.50109 0.68979 0.50432 1.0 1.0 1.0 1.0;];





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

%%  Set Ro=3
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
pause(2);

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
%%                                                       Slope, DistMax, RefOrd, RGain, SaveIR)
%% Enable Reverb
SendReverbEnableToISM(connectionToISM, true);
message = WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message);
pause(2);

%% w file 
configureHybrid (connectionToISM, receiver, osc_listener,     10,     10,      0,      11,   true);
%configureHybrid (connectionToISM, receiver, osc_listener,     10,    8,      0,        12.4,   true);
pause(1.0);

%% t file Real-Time--> OR 3
configureHybrid (connectionToISM, receiver, osc_listener,    -1,      -1,       4,      -1,   true);
pause(1.0);

%% t file
configureHybrid (connectionToISM, receiver, osc_listener,    -1,      -1,       20,      -1,   true);
pause(1.0);

%% Disable Reverb
SendReverbEnableToISM(connectionToISM, false);
message = WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message);
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
disp(message);
pause(2);


%% BRIR
configureHybrid (connectionToISM, receiver, osc_listener,       2,      1,     0,     11,   true);
%configureHybrid (connectionToISM, receiver, osc_listener,      2,      1,     0,     12.4,   true);
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
                          Slope, DistMax, RO, RGain, saveIR)
     
    %% Send MaxDistImages
    if DistMax > 0
        SendDistMaxImgsFloatToISM(connectionToISM, DistMax);
        % Waiting msg from ISM
        message = WaitingOneOscMessageStringVector(receiver, osc_listener);
        disp(message);
        pause(2);
    end 

     %% Send WindowSlope
    if Slope > 0
        SendWindowSlopeToISM(connectionToISM, Slope);
        % Waiting msg from ISM
        message = WaitingOneOscMessageStringVector(receiver, osc_listener);
        disp(message);
        pause(2);
    end

     %% Send ReverbGain
    if RGain > 0
        SendReverbGainToISM(connectionToISM, RGain);
        % Waiting msg from ISM
        message = WaitingOneOscMessageStringVector(receiver, osc_listener);
        disp(message);
        pause(2);
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

