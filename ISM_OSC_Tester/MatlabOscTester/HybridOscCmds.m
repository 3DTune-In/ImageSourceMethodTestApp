%% This script contains the OSC commands for the hybrid method

% Authors: Fabian Arrebola, Daniel Gonález Toledo (17/10/2023) 
% contact: areyesa@uma.es
% 3DDIANA research group. University of Malaga
% Project: SONICOM
% 
% Copyright (C) 2023 Universidad de Málaga

classdef HybridOscCmds
    methods (Static)        
        
        %% configureHybrid
        function configureHybrid (connectionToISM, receiver, osc_listener, ...
                W_Slope, DistMax, RO, RGain, saveIR)

            %% Send MaxDistImages
            if DistMax > 0
                HybridOscCmds.SendDistMaxImgsFloatToISM(connectionToISM, DistMax);
                % Waiting msg from ISM
                message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
                disp(message+" MaxDistImages");
                pause(0.2);
            end

            %% Send WindowSlope
            if W_Slope > 0
                HybridOscCmds.SendWindowSlopeToISM(connectionToISM, W_Slope);
                % Waiting msg from ISM
                message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
                disp(message+" WindowSlope");
                pause(0.2);
            end

            %% Send ReverbGain
            if RGain > 0
                HybridOscCmds.SendReverbGainToISM(connectionToISM, RGain);
                % Waiting msg from ISM
                message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
                disp(message+" ReverbGain");
                pause(0.2);
            end

            %% Send Reflection Order
            if RO ~= -1
                HybridOscCmds.SendReflecionOrderToISM(connectionToISM, RO);
                % Waiting msg from ISM
                message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
                disp(message+" Set RO");
                pause(0.2);
            end

            if saveIR == true
                %% Send Save IR comand
                HybridOscCmds.SendSaveIRToISM(connectionToISM);
                message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
                disp(message+" SaveIR");
                pause(0.2);
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
            oscsend(u,'/distanceAttAnechoicEnable','B',vbool);
        end

        %% Send DistanceAttenuationReverbEnable comand to the OSC server (ISM)
        function SendDistanceAttenuationReverbEnableToISM(u, vbool)
            oscsend(u,'/distanceAttReverbEnable','B',vbool);
        end

        %% Send float vector to the OSC server (ISM)
        function SendAbsortionsToISM(u, coefVector)
           m = repmat('f',1,length(coefVector));
           oscsend(u,'/absortions',m, coefVector);    
        end


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

        %% InitOscServer
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

        %% AddListenerAddress
        function [receiver osc_listener] = AddListenerAddress(receiver, address)
            import com.illposed.osc.*;
            import java.lang.String
            osc_method = String(address);
            osc_listener = MatlabOSCListener();
            receiver.addListener(osc_method,osc_listener);
        end

        %% WaitingOneOscMessageDoubleVector
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

        %% WaitingOneOscMessageStringVector
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

        %% WaitingOneOscMessageStructVector
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
    end
end