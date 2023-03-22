% Open connection to send messages to ISM
ISMPort = 12300;
connectionToISM = InitConnectionToISM(ISMPort);

% Open OSC server
% https://0110.be/posts/OSC_in_Matlab_on_Windows%2C_Linux_and_Mac_OS_X_using_Java
% https://github.com/hoijui/JavaOSC
listenPort = 12301;
receiver = InitOscServer(listenPort);
[receiver osc_listener] = AddListenerAddress(receiver, '/ready');

% Working loop, just as example
rng('default');
i = 0;
while ( i < 5)
    x=rand(1,9); %Generate a random vector of 9 doubles
    SendCoefficientsVectorToISM(connectionToISM, x);

    message = WaitingOneOscMessageStringVector(receiver, osc_listener);    
    disp(message);
        
    pause (2)
    i=i+1;
end

% Close, doesn't work properly
CloseOscServer(receiver, osc_listener);


%% Open a UDP connection with a OSC server
function connectionToISM = InitConnectionToISM(port)
    connectionToISM = udp('127.0.0.1',port);
    fopen(connectionToISM);   
end

%% Send float vector to the OSC server (ISM)
function SendCoefficientsVectorToISM(u, coefVector)
    m = repmat('f',1,length(coefVector));
    oscsend(u,'/coefficients',m, coefVector);    
end

%% Send a signal to the OSC server (ISM)
function SendImpulseToISM()
    %oscsend(u,'/3DTI-OSC/v1/source1/anechoic/nearfield','s','false');
    oscsend(u,'/play','N', "");
end

%% 
function receiver = InitOscServer(port)
    %cd('G:/Repos/3daudio/of_v0.11.2_vs2017_release/ImageSourceMethodTestApp/ISM_OSC_Tester/MatlabOscTester/')
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

%%
function [receiver osc_listener] = AddListenerAddress(receiver, address) 
    import com.illposed.osc.*;    
    import java.lang.String    
    osc_method = String(address);
    osc_listener = MatlabOSCListener();
    receiver.addListener(osc_method,osc_listener);
end

%%
function message = WaitingOneOscMessageDoubleVector(receiver, osc_listener)
    import com.illposed.osc.*;    
    receiver.startListening();
    while true            
        arguments = osc_listener.getMessageArgumentsAsDouble();
        if ~isempty(arguments) == 1
             message = double(arguments);
             receiver.stopListening();
            break;
        end
    end
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
function message = WaitingOneOscMessageStructVector(receiver, osc_listener)
    import com.illposed.osc.*;     
    receiver.startListening();
    while true            
        arguments = osc_listener.getMessageArguments();        
        if ~isempty(arguments) == 1   
             message = struct(arguments);
             receiver.stopListening();
            break;
        end
    end
end

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
