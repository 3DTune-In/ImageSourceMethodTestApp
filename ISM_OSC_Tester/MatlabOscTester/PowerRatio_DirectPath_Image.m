%% This script, using the ISM simulator -and through OSC commands- 
%% generated two impulse responses with the following characteristics:
%% 1) Image (and only one) with Non-spatialization. No distance attenuation. No Direct Path. 
%% 2) Direct Path with Non-spatialization. No distance attenuation. No image.
%% For each impulse response, the energy in the 9 frequency bands is calculated and compared.
%% Before running the script, make sure that spatialization and distance attenuation are disabled.
%% In addition, only one of the walls must be left open.

% Author: Fabian Arrebola (31/10/2023) 
% contact: areyes@uma.es
% 3DDIANA research group. University of Malaga
% Project: SONICOM
% 
% Copyright (C) 2023 Universidad de Málaga

close all;
addpath ("C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\ISM_OSC_Tester\MatlabOscTester");

%% Set folder with Absor and Params
% cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\SeriesIr';
cd 'C:\Repos\HIBRIDO PRUEBAS\New LAB 40 2 24\16';
load ("FiInfAbsorb.mat");
load ("ParamsHYB.mat");
load ("EnergyFactor.mat");

%% RGain = RGain_Linear*EnergyFactor;
RGain = FactorMeanValue*db2mag(RGain_dB);

%% Initial absorptions
% absorbData= absorbData1;
absorbData = [
0.700 0.700 0.700 0.700 0.700 0.700 0.700 0.700 0.700;
0.700 0.700 0.700 0.700 0.700 0.700 0.700 0.700 0.700;
0.700 0.700 0.700 0.700 0.700 0.700 0.700 0.700 0.700;
0.700 0.700 0.700 0.700 0.700 0.700 0.700 0.700 0.700;
0.700 0.700 0.700 0.700 0.700 0.700 0.700 0.700 0.700;
0.700 0.700 0.700 0.700 0.700 0.700 0.700 0.700 0.700;];

for k=1:6
  absorbData (k,5) = 0.000;
end  

%% Open connection to send messages to ISM
ISMPort = 12300;
connectionToISM = InitConnectionToISM(ISMPort);

%% Open OSC server
% https://0110.be/posts/OSC_in_Matlab_on_Windows%2C_Linux_and_Mac_OS_X_using_Java
% https://github.com/hoijui/JavaOSC
listenPort = 12301;
receiver = InitOscServer(listenPort);
[receiver osc_listener] = AddListenerAddress(receiver, '/ready');

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

%% Disable Direct Path
SendDirectPathEnableToISM(connectionToISM, false);
message = WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Disable Direct Path");

%% Distance Attenuation Disable
SendDistanceAttenuationEnableToISM (connectionToISM, false);
message = WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Disable Distance Attenuation");
pause(0.2);

%% Spatialisation Disable
SendSpatialisationEnableToISM (connectionToISM, false);
message = WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Disable Spatialisation");
pause(0.2);

%% Disable Reverb
SendReverbEnableToISM(connectionToISM, false);
message = WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message);
pause(0.2);

%% LAB_ROOM
%% configureHybrid (connectionToISM, receiver, osc_listener, 
%%                                                              W_Slope, DistMax, RefOrd, RGain, SaveIR)
configureHybrid (connectionToISM, receiver, osc_listener,       W_Slope,  Dp_Tmix,      1,       RGain,   true);

%% Set working folder
cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\SeriesIr';

irFiles=dir(['iIr*.wav']); 
NumFiles = length(irFiles);
for i=1:NumFiles
   IRFile=irFiles(i).name;
   [y1,Fs] = audioread(IRFile);
   % figure;
   SSA_Spectrum(Fs, y1, 1);
   ylim([-130 -80]);
   xlim ([1 50000])
   IR=y1;
end

NB=9;
B =[44 88; 89 176; 177 353; 354 707; 708 1414; 1415 2828; 2829 5657; 5658 11314; 11315 22016;];
Blo=[ 1    89      177      354      708       1415       2829       5658        11315       ];
Bhi=[  88     176      353      707      1414       2828       5657       11314        22016 ];

e= calculateEnergy(IR);
eTotal(1,:)= e;
% PARSEVAL RELATION --> eTotal (in time) == E_Total (in frec)
E_Total= calculateEnergyFrec(Fs, IR)/length(IR);
E_Total2= calculateEnergyBand(Fs, IR, Blo(1), Bhi(NB))/length(IR);
eSumBandsI=0; %checksum
E_Band=zeros (NB,2);
for j=1:NB
   e = calculateEnergyBand(Fs, IR, Blo(j), Bhi(j)) / length(IR);  %(Bhi(j)-Blo(j)+1);
   E_Band(j,:) = e;
   eSumBandsI = eSumBandsI+E_Band(j,:);
end
figure;
plot(E_Band, 'b--*');
xlabel('Band');
ylabel('Sum(abs( Y(n)^2))');
title('Power per Band: Image');
grid on;

save ('EB_Imag.mat','E_Band');

EBImag= E_Band;

movefile 'iIrRO1*.wav' 'IR_image';

pause(1);

%% Enable Direct Path
SendDirectPathEnableToISM(connectionToISM, true);
message = WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Enable Direct Path");
%% -------------------------------------
%% LAB_ROOM
%% configureHybrid (connectionToISM, receiver, osc_listener, 
%%                                                              W_Slope, DistMax, RefOrd, RGain, SaveIR)
configureHybrid (connectionToISM, receiver, osc_listener,       -1,        -1,      0,      -1,   true);


irFiles=dir(['iIr*.wav']); 
NumFiles = length(irFiles);
for i=1:NumFiles
   IRFile=irFiles(i).name;
   [y2,Fs] = audioread(IRFile);
   % figure;
   SSA_Spectrum(Fs, y2, 0);
   IR=y2;
end

e= calculateEnergy(IR);
eTotal(1,:)= e;
% PARSEVAL RELATION --> eTotal (in time) == E_Total (in frec)
E_Total= calculateEnergyFrec(Fs, IR)/length(IR);
E_Total2= calculateEnergyBand(Fs, IR, Blo(1), Bhi(NB))/length(IR);
eSumBandsI=0; %checksum
E_Band=zeros (NB,2);
for j=1:NB
   e = calculateEnergyBand(Fs, IR, Blo(j), Bhi(j)) / length(IR);  %(Bhi(j)-Blo(j)+1);
   E_Band(j,:) = e;
   eSumBandsI = eSumBandsI+E_Band(j,:);
end
figure;
plot(E_Band, 'b--*');
xlabel('Band');
ylabel('Sum(abs( Y(n)^2))');
title('Power per Band Direct Path');
grid on;

save ('EB_Dp.mat','E_Band');

EBDp= E_Band;

movefile 'iIrRO0*.wav' 'IR_DP';

R1=EBImag./EBDp;
LR1=10*log10(R1);
figure;
% plot(LR1, 'b--*');
plot(R1, 'b--*');
% ylabel('10*Log (Image/DiretPath');
xlabel('Band');
%title("Power Image vs Direct Path for Absor =" + mat2str(absorbData(1,1)));
title("Power Image vs Direct Path") ;   %for Absor =" + mat2str(absorbData(1,1)));
grid on;

%ylim([-14 3]);
ylim([0 3]);
xlim([1 9]);

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




%Single-Sided Amplitude Spectrum 
function [SSAS]= SSA_Spectrum(Fs, IR, view)

T=1/Fs;
L=length(IR);
t=(0:L-1)*T; %Time vector

Yfrec =  fft(IR / L);

P2 = abs(Yfrec);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);

if (view)
    f = Fs*(0:(L/2))/L;
    figure;
    %plot(f,P1);
    semilogx(f,20*log10(P1));
    title('Single-Sided Amplitude Spectrum')
    xlabel('f (Hz)');
    ylabel('|P1(f)|');
    grid on;
end

SSAS= P1;
end

