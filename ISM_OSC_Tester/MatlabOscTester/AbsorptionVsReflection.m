
%% This script attempts to calculate the relationship between absorption 
%% and reflection coefficients.
%% Using the ISM simulator -and through OSC commands- two impulse responses
%% are generated with the following characteristics:
%% 1) Image (and only one) with Non-spatialization. No distance attenuation. No Direct Path. 
%% 2) Direct Path with Non-spatialization. No distance attenuation. No images.
%% for each band calculate the ratio E_image/E_anechoic
%% Before running the script, make sure that all walls are disabled except one of them

% Author: Fabian Arrebola (28/11/2023) 
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
1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000;
1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000;
1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000;
1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000;
1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000;
1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000 1.000;];

%% Open connection to send messages to ISM
ISMPort = 12300;
connectionToISM = HybridOscCmds.InitConnectionToISM(ISMPort);

%% Open OSC server
% https://0110.be/posts/OSC_in_Matlab_on_Windows%2C_Linux_and_Mac_OS_X_using_Java
% https://github.com/hoijui/JavaOSC
listenPort = 12301;
receiver = HybridOscCmds.InitOscServer(listenPort);
[receiver osc_listener] = HybridOscCmds.AddListenerAddress(receiver, '/ready');

%% Frequency bands
NB=9; 

B =[44 88; 89 176; 177 353; 354 707; 708 1414; 1415 2828; 2829 5657; 5658 11314; 11315 22016;];
Blo=[ 1    89      177      354      708       1415       2829       5658        11315       ];
Bhi=[    88     176      353      707      1414       2828       5657       11314        22600 ];
Bc = [63 125 250 500 1000 2000 4000 8000 16000];


f0=  figure;
% f1=  figure;
f2=  figure;

LimAbsorp=10;
An=zeros(1,LimAbsorp+1);
An(1,1)=0;
for ii=2:LimAbsorp+1
    
    An(1,ii) = An(1,ii-1) + 1.0/LimAbsorp;
end
AmpSpec=zeros(1,LimAbsorp+1);
ImageAnech=zeros(NB,LimAbsorp+1);

%% For ecah absorpion value
for ii=1:LimAbsorp+1 %%  from Absorption = 0 to Absorption = 1
    %% For ecah frequency band
    NBi=5; NBf=5;    %%  initial and final band
    for BF=NBi:NBf  

        for k=1:6
            absorbData (k,BF) = An(1,ii);
        end

        %% Send Initial absortions
        walls_absor = zeros(1,54);
        absorbDataT = absorbData';
        walls_absor = absorbDataT(:);
        HybridOscCmds.SendAbsortionsToISM(connectionToISM, walls_absor');
        pause(0.2);
        message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
        disp(message);
        pause(0.1);

        %% Disable Direct Path
        HybridOscCmds.SendDirectPathEnableToISM(connectionToISM, false);
        message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
        disp(message+" Disable Direct Path");

        %% Disable Distance Attenuation
        HybridOscCmds.SendDistanceAttenuationEnableToISM (connectionToISM, false);
        message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
        disp(message+" Disable Distance Attenuation");
        pause(0.2);

        %% Disable Spatialisation
        HybridOscCmds.SendSpatialisationEnableToISM (connectionToISM, false);
        message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
        disp(message+" Disable Spatialisation");
        pause(0.2);

        %% Disable Reverb
        HybridOscCmds.SendReverbEnableToISM(connectionToISM, false);
        message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
        disp(message+" Disable Reverb");
        pause(0.2);

        %% LAB_ROOM
        %% configureHybrid (connectionToISM, receiver, osc_listener,
        %%                                                              W_Slope, DistMax, RefOrd, RGain, SaveIR)
        HybridOscCmds.configureHybrid (connectionToISM, receiver, osc_listener,       W_Slope,  Dp_Tmix,      1,       RGain,   true);

        %% Set working folder
        cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\SeriesIr';

        irFiles=dir(['iIr*.wav']);
        NumFiles = length(irFiles);
        for i=1:NumFiles
            IRFile=irFiles(i).name;
            [y1,Fs] = audioread(IRFile);
            Y1 = SSA_Spectrum(Fs, y1, 1, f0);
            IR=y1;
            ax = gca;
            ax.XScale = "log";
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

        %     figure(f1);
        %     hold on;
        %     plot(E_Band, '--*');
        %     xlabel('Band');
        %     ylabel('Sum(abs( Y(n)^2))');
        %     title('Power per Band: Image');
        %     grid on;

        save ('EB_Imag.mat','E_Band');

        EBImag= E_Band;

        movefile 'iIrRO1*.wav' 'IR_image';

        pause(1);

        %% Enable Direct Path
        HybridOscCmds.SendDirectPathEnableToISM(connectionToISM, true);
        message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
        disp(message+" Enable Direct Path");

        %% Set RO = 0
        %% configureHybrid (connectionToISM, receiver, osc_listener,
        %%                                                              W_Slope, DistMax, RefOrd, RGain, SaveIR)
        HybridOscCmds.configureHybrid (connectionToISM, receiver, osc_listener,       -1,        -1,      0,      -1,   true);


        irFiles=dir(['iIr*.wav']);
        NumFiles = length(irFiles);
        for i=1:NumFiles
            IRFile=irFiles(i).name;
            [y2,Fs] = audioread(IRFile);
            Y2 = SSA_Spectrum(Fs, y2, 0, f0);
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
        %     figure;
        %     plot(E_Band, 'b--*');
        %     xlabel('Band');
        %     ylabel('Sum(abs( Y(n)^2))');
        %     title('Power per Band Direct Path');
        %     grid on;

        save ('EB_Dp.mat','E_Band');

        EBDp= E_Band;

        movefile 'iIrRO0*.wav' 'IR_DP';

        R1=EBImag./EBDp;
        LR1=10*log10(R1);
        figure(f2);
        hold on;
        plot(R1, '--*');
        %% plot(LR1, '--*');
        ylabel('EnergyBandImage/EnergyBandAnechoic');
        xlabel('Band');

        %title("Power Image vs Direct Path for Absor =" + mat2str(absorbData(1,1)));
        title("Power Image vs Direct Path") ;   %for Absor =" + mat2str(absorbData(1,1)));
        grid on;

        % ylim([-20 3]);
        ylim([0 1.0]);
        xlim([1 9]);

        for k=1:6
            absorbData (k,BF) = 1.000;
        end

    end

   AmpSpec(1,ii)=Y1(Bc(BF));   %central frequency of the frequency band
   ImageAnech(:,ii)=R1(:,1);
end
figure;
plot (An,AmpSpec);
ylabel('Max |P1(f)| central frequency of the frequency band');
xlabel('Absorption'); 
title("Max |P1(f)| vs Absorption") ;  
figure;
hold on;
for i=1:9
   plot (An,ImageAnech(i,:));
end
%plot (An,ImageAnech);
ylabel('Reflection');
xlabel('Absorption'); 
title("Reflection vs Absorption") ;  

% Close, doesn't work properly
HybridOscCmds.CloseOscServer(receiver, osc_listener);

%% ------------------------------------------
%% ------------------------------------------


%Single-Sided Amplitude Spectrum 
function [SSAS]= SSA_Spectrum(Fs, IR, view, f0)

   T=1/Fs;
   L=length(IR);
   t=(0:L-1)*T; %Time vector

   Yfrec =  fft(IR / L);

   P2 = abs(Yfrec);
   P1 = P2(1:L/2+1);
   P1(2:end-1) = 2*P1(2:end-1);

   if (view)
       f = Fs*(0:(L/2))/L;
       figure(f0); 
       hold on;
       %semilogx(f,P1);
       semilogx(f,20*log10(P1));
       grid on;
       title('Single-Sided Amplitude Spectrum')
       xlabel('f (Hz)');
       ylabel('|P1(f)|');
       ylim([-100 -80]);
       xlim ([10 100000])
       %ticks = [1 10 100 1000 10000];
       %xticks(ticks);
   end

   SSAS= P1;
end

