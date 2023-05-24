
absorbData = [
0.36519 0.78804 0.92500 0.78672 0.90509 0.92500 0.84871 0.90446 0.93436; 
0.36519 0.78804 0.92500 0.78672 0.90509 0.92500 0.84871 0.90446 0.93436; 
0.36519 0.78804 0.92500 0.78672 0.90509 0.92500 0.84871 0.90446 0.93436; 
0.36519 0.78804 0.92500 0.78672 0.90509 0.92500 0.84871 0.90446 0.93436; 
0.36519 0.78804 0.92500 0.78672 0.90509 0.92500 0.84871 0.90446 0.93436; 
0.36519 0.78804 0.92500 0.78672 0.90509 0.92500 0.84871 0.90446 0.93436; ];

% absorbData = [
% 0.35463 1.0 0.50109 1.0 0.50432 1.0 0.72474 1.0 0.846824;
% 0.35463 1.0 0.50109 1.0 0.50432 1.0 0.72474 1.0 0.846824;
% 0.35463 1.0 0.50109 1.0 0.50432 1.0 0.72474 1.0 0.846824;
% 0.35463 1.0 0.50109 1.0 0.50432 1.0 0.72474 1.0 0.846824;
% 0.35463 1.0 0.50109 1.0 0.50432 1.0 0.72474 1.0 0.846824;
% 0.35463 1.0 0.50109 1.0 0.50432 1.0 0.72474 1.0 0.846824;];

% absorbData = [
% 1.0 0.625 1.0 0.68979 1.0 0.40638 1.0 0.665354 1.0;
% 1.0 0.625 1.0 0.68979 1.0 0.40638 1.0 0.665354 1.0;
% 1.0 0.625 1.0 0.68979 1.0 0.40638 1.0 0.665354 1.0;
% 1.0 0.625 1.0 0.68979 1.0 0.40638 1.0 0.665354 1.0;
% 1.0 0.625 1.0 0.68979 1.0 0.40638 1.0 0.665354 1.0;
% 1.0 0.625 1.0 0.68979 1.0 0.40638 1.0 0.665354 1.0;];

% absorbData = [
% 0.35463 0.625 0.50109 0.68979 0.50432 1.0 1.0 1.0 1.0;
% 0.35463 0.625 0.50109 0.68979 0.50432 1.0 1.0 1.0 1.0;
% 0.35463 0.625 0.50109 0.68979 0.50432 1.0 1.0 1.0 1.0;
% 0.35463 0.625 0.50109 0.68979 0.50432 1.0 1.0 1.0 1.0;
% 0.35463 0.625 0.50109 0.68979 0.50432 1.0 1.0 1.0 1.0;
% 0.35463 0.625 0.50109 0.68979 0.50432 1.0 1.0 1.0 1.0;];

% absorbData = [
% 1.0 1.0 1.0 1.0 0.50432 0.40638 0.72474 0.665354 0.846824;
% 1.0 1.0 1.0 1.0 0.50432 0.40638 0.72474 0.665354 0.846824;
% 1.0 1.0 1.0 1.0 0.50432 0.40638 0.72474 0.665354 0.846824;
% 1.0 1.0 1.0 1.0 0.50432 0.40638 0.72474 0.665354 0.846824;
% 1.0 1.0 1.0 1.0 0.50432 0.40638 0.72474 0.665354 0.846824;
% 1.0 1.0 1.0 1.0 0.50432 0.40638 0.72474 0.665354 0.846824;];




%% Open connection to send messages to ISM
ISMPort = 12300;
connectionToISM = InitConnectionToISM(ISMPort);

%% Open OSC server
% https://0110.be/posts/OSC_in_Matlab_on_Windows%2C_Linux_and_Mac_OS_X_using_Java
% https://github.com/hoijui/JavaOSC
listenPort = 12301;
receiver = InitOscServer(listenPort);
[receiver osc_listener] = AddListenerAddress(receiver, '/ready');

%%  Set Ro=3
SendReflecionOrderToISM(connectionToISM, 3);
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


%% configureHybrid (connectionToISM, , receiver, osc_listener, 
%%                                                        DirPth, RevPth, Slope, DistMax, RefOrd, RGain, SaveIR)
%% Enable Reverb
SendReverbEnableToISM(connectionToISM, true);
message = WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message);
pause(2);

%% w file 
configureHybrid (connectionToISM, receiver, osc_listener, false, false,    2,     5,        0,      1.0,   true);
pause(2.0);
%% t file
configureHybrid (connectionToISM, receiver, osc_listener, false, false,   -1,    -1,        20,       -1,   true);
pause(2.0);

%% Disable Reverb
SendReverbEnableToISM(connectionToISM, false);
message = WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message);
pause(2);

%% i file
configureHybrid (connectionToISM, receiver, osc_listener, false, false,  -1,    -1,        -1,       -1,   true);
pause(1);

%% Reflecion Order = 0
SendReflecionOrderToISM(connectionToISM, 0);
% Waiting msg from ISM
message = WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message);
pause(0.5);

% %% BRIR
% configureHybrid (connectionToISM, receiver, osc_listener, false, true,    2,     0.4,     0,       1.0,   true);
% pause(0.1);

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
                         DP, RP, Slope, DistMax, RO, RGain, saveIR)

%     %% Enable Diasable Direct Path
%     SendDirectPathEnableToISM(connectionToISM, DP);
%     % Waiting msg from ISM
%     message = WaitingOneOscMessageStringVector(receiver, osc_listener);
%     disp(message);
%     pause(0.2);
    
%     %% Enable Disable Reverb
%     SendReverbEnableToISM(connectionToISM, RP);
%     % Waiting msg from ISM
%     message = WaitingOneOscMessageStringVector(receiver, osc_listener);
%     disp(message);
%     pause(2);
      
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


