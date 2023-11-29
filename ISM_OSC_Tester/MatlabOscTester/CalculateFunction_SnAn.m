%% This script generates the slopes associated with ITER_MAX (20) 
%% absorption values from 0 to 1

% Author: Fabian Arrebola (25/10/2023) 
% contact: areyes@uma.es
% 3DDIANA research group. University of Malaga
% Project: SONICOM
% 
% Copyright (C) 2023 Universidad de Málaga


%% Absorption saturation values
absorMax=1.0;
absorMin=0.0;
maxChange=1.0;
reductionAbsorChange=1.0;

%% MAX ITERATIONS 
ITER_MAX = 20;

%% Absortions and Slopes
An=zeros(1,ITER_MAX+1);
An(1,1)=0;
for i=2:ITER_MAX+1
    An(1,i) = An(1,i-1) + 1.0/ITER_MAX;
end
Sn=zeros(ITER_MAX+1, 9);

%% PRUNING DISTANCES
% DpMax=15; DpMin=2;
% DpMinFit = 10;                   %% small distance values are not parsed
DpMax=24; DpMin=2;
DpMinFit = 18;                   %% small distance values are not parsed


%% Folder with impulse responses
cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\SeriesIr';
delete *.wav;
addpath 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\ISM_OSC_Tester\MatlabOscTester'

%% SAVE Configuration parameters for ISM simulation
RefOrd=40; 
W_Slope=2;                       % Value for energy adjustment
RGain_dB = 0;
RGain = db2mag(RGain_dB);
save ('ParamsISM.mat','RefOrd', 'DpMax','W_Slope','RGain_dB');

%% File name associated with ISM simulation
formatFileISM= "iIrRO%iDP%02iW%02i";
nameFileISM = sprintf(formatFileISM, RefOrd, DpMax, W_Slope)+'.wav';

%% SAVE PRUNING DISTANCES
save ('DistanceRange.mat','DpMax', 'DpMin','DpMinFit');

x=[DpMin:1:DpMax];               % Initial and final pruning distance0.25

L=1; R=2;                        % ChannelITER_MAX
%% ABSORTIONS
%% 6 it

%% Initial absorptions
absorbData = [
0.50 0.50 0.50 0.50 0.50 0.50 0.50 0.50 0.50;
0.50 0.50 0.50 0.50 0.50 0.50 0.50 0.50 0.50;
0.50 0.50 0.50 0.50 0.50 0.50 0.50 0.50 0.50;
0.50 0.50 0.50 0.50 0.50 0.50 0.50 0.50 0.50;
0.50 0.50 0.50 0.50 0.50 0.50 0.50 0.50 0.50;
0.50 0.50 0.50 0.50 0.50 0.50 0.50 0.50 0.50;];

%% 1 KHz band
for k=1:6
  absorbData (k,5) = 0;
end  

absorbData0 = absorbData;
absorbData1 = absorbData;
absorbData2 = absorbData;

maximumAbsorChange=[maxChange, maxChange, maxChange, maxChange, maxChange, maxChange, maxChange, maxChange, maxChange];

formatSlope = "Slope: %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f ";
formatAbsor = "Absor: %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f ";
formatAbsorChange= "AbChg: %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f ";
formaTotalMaxSlope= "TotalSlope: %.5f  MaxPartialSlope: %.5f";

%% Open connection to send messages to ISM
ISMPort = 12300;
connectionToISM = HybridOscCmds.InitConnectionToISM(ISMPort);

%% Open OSC server
% https://0110.be/posts/OSC_in_Matlab_on_Windows%2C_Linux_and_Mac_OS_X_using_Java
% https://github.com/hoijui/JavaOSC
listenPort = 12301;
receiver = HybridOscCmds.InitOscServer(listenPort);
[receiver osc_listener] = HybridOscCmds.AddListenerAddress(receiver, '/ready');

%% Reflecion Order = 0
HybridOscCmds.SendReflecionOrderToISM(connectionToISM, 0);
% Waiting msg from ISM
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Ref Order = 0");
pause(0.2);

%% Enable Reverb
HybridOscCmds.SendReverbEnableToISM(connectionToISM, true);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Enable Reverb");
pause(0.2);

%%  Send Play and Stop ToISM
HybridOscCmds.SendPlayToISM(connectionToISM);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Play");
pause(0.2);

HybridOscCmds.SendStopToISM(connectionToISM);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Stop");
pause(0.2);

%% BRIR
%             configureHybrid (connectionToISM, receiver, osc_listener, W_Slope, DistMax, RefOrd, RGain, SaveIR) 
HybridOscCmds.configureHybrid (connectionToISM, receiver, osc_listener,       2,         1,       0,    RGain,   true);
pause(0.2);
disp(message+" RIR");

%% Disable Reverb
HybridOscCmds.SendReverbEnableToISM(connectionToISM, false);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Dissable Reverb");
pause(0.2);

%% Rename to BRIR.wav
cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\SeriesIr';
movefile 'wIrRO0DP01W02.wav' 'BRIR.wav';

%% Send Initial absortions
walls_absor = zeros(1,54);
absorbDataT = absorbData';
walls_absor = absorbDataT(:);
HybridOscCmds.SendAbsortionsToISM(connectionToISM, walls_absor'); 
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Initial absortions");
pause(0.2);

%% Reflecion Order
HybridOscCmds.SendReflecionOrderToISM(connectionToISM, RefOrd);
% Waiting msg from ISM
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
msg = sprintf('%s Ref Order = %d', message, RefOrd);
disp (msg);
pause(0.2);
%% ISM_DpMax
%             configureHybrid (connectionToISM, receiver, osc_listener,   W_Slope, DistMax,   RefOrd,     RGain, SaveIR) 
HybridOscCmds.configureHybrid (connectionToISM, receiver, osc_listener,   W_Slope,    DpMax,     -1,        -1,   true);
pause(0.2);
disp(message+ " ISM DpMax ");
%% Rename to ISM_DpMax.wav
cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\SeriesIr';
movefile (nameFileISM, "ISM_DpMax.wav");

%%   BANDS
%    62,5    125     250      500      1000       2000       4000       8000       16000
% B =[44 88; 89 176; 177 353; 354 707; 708 1414; 1415 2828; 2829 5657; 5658 11314; 11315 22016;];
% 
% Blo=[ 1    89      177      354      708       1415       2829       5658        11315       ];
% Bhi=[  88     176      353      707      1414       2828       5657       11314        22016 ];

%%   9 BANDS
NB=9;
B =[44 88; 89 176; 177 353; 354 707; 708 1414; 1415 2828; 2829 5657; 5658 11314; 11315 22016;];
Blo=[ 1    89      177      354      708       1415       2829       5658        11315       ];
Bhi=[  88     176      353      707      1414       2828       5657       11314        22016 ];

%% Working loop
rng('default');
iLoop = 0;

%% Read file with BRIR
BRIRFile=dir(['BRIR*.wav']);         %BRIR obtained with a pruning distance of 1 meter
AudioFile=BRIRFile.name;
[t_BRIR,Fs] = audioread(AudioFile);

%% Read file with ISM
ISMFile=dir(['ISM_DpMax.wav']);      %ISM obtained with a pruning max distance 
AudioFile=ISMFile.name;
[t_ISM,Fs] = audioread(AudioFile);
pause(0.5);
delete (ISMFile.name);

iLoop = 1;

while ( iLoop <= ITER_MAX+1)
    disp(iLoop);
    %% Folder with impulse responses
    cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\SeriesIr';
        
    %% FILES with Impulse Response in de folder
    NumIRs = DpMax-DpMin+1;

    %% BRIR Energy
    e_BRIR= calculateEnergy(t_BRIR);
    %%%%%%% PARSEVAL RELATION --> e_BRIR (in time) == E_BRIR (in frec)
    E_BRIR= calculateEnergyFrec(Fs, t_BRIR)/length(t_BRIR);
    eBRIR_L= e_BRIR(L); eBRIR_R= e_BRIR(R);
    %% --------------
    %% Total Energy in time domain
    e_TotalIsm=zeros(NumIRs,2);
    e_TotalWin=zeros(NumIRs,2);
    e_Total=zeros(NumIRs,2);
    %% Energy per band in frequency domain
    E_BandIsm =zeros(NB,NumIRs,2);
    E_BandWin=zeros(NB,NumIRs,2);
    E_BandBrir_Win=zeros(NB,NumIRs,2);        %BRIR-Win

    %% Calculate total and partial energies
    maxDistSL = DpMin;
    for i=1:NumIRs
        %%  Ism IRs -------------------------------------
        ir_Ism =  windowingISM_RIR (Fs, t_ISM, maxDistSL, 2, 1);
%         subplot(2,1,1);
%         plot (ir_Ism);
        e= calculateEnergy(ir_Ism);
        e_TotalIsm(i,:)= e;
        % PARSEVAL RELATION --> e_TotalIsm (in time) == E_TotalIsm (in frec)
        E_TotalIsm= calculateEnergyFrec(Fs, ir_Ism)/length(ir_Ism);
        E_TotalIsm2= calculateEnergyBand(Fs, ir_Ism, Blo(1), Bhi(NB))/length(ir_Ism);
        %eSumBandsI=zeros(1,2);
        eSumBandsI=0; %checksum
        for j=1:NB
            e = calculateEnergyBand(Fs, ir_Ism, Blo(j), Bhi(j)) / length(ir_Ism);  %(Bhi(j)-Blo(j)+1);
            E_BandIsm(j,i,:) = e;
            eSumBandsI = eSumBandsI+E_BandIsm(j,i,:);
        end
        eSumBandsI= squeeze(eSumBandsI);

        %%  Windowed IRs -------------------------------
        ir_Win =  windowingISM_RIR (Fs, t_BRIR, maxDistSL, 2, 0);
%         subplot(2,1,2);
%         plot (ir_Win);
        e = calculateEnergy(ir_Win);
        e_TotalWin(i,:)= e;
        %% PARSEVAL RELATION --> e_Totalwin (in time) == E_TotalWin (in frec)
        E_TotalWin= calculateEnergyFrec(Fs, ir_Win)/length(ir_Win);
        E_TotalWin2= calculateEnergyBand(Fs, ir_Win, Blo(1), Bhi(NB))/length(ir_Ism); %(Bhi(NB)-Blo(1)+1);
        %eSumBandsW=zeros(1,2); %checksum
        eSumBandsW=0; %checksum
          
        for j=1:NB
            e = calculateEnergyBand(Fs, ir_Win, Blo(j), Bhi(j))/length(ir_Win); %/(Bhi(j)-Blo(j)+1);
            E_BandWin(j,i,:) = e;
            eSumBandsW= eSumBandsW+E_BandWin(j,i,:);
        end
        eSumBandsW= squeeze(eSumBandsW);

         maxDistSL = maxDistSL+1;
    end
    %% -------figure
    %% BRIR Energy for each band
    E_BandBrir=zeros(NB,2);
    %eSumBands=zeros(1,1); %checksum
    eSumBands=0; %checksum
    for j=1:NB
        %eSumBands = eSumBands+E_BandWin(j,i,:);
        e = calculateEnergyBand(Fs, t_BRIR, Blo(j), Bhi(j))/length(t_BRIR);  %/(Bhi(j)-Blo(j)+1);
        E_BandBrir(j,:) = e;
        eSumBands = eSumBands+E_BandBrir(j,:);
    end
    eSumBands= squeeze(eSumBands);
    %% --------------------------                    % FIGURE 1 -- Total: ISM, Windowed, BRIR-Windowed
    figure; hold on;
    eL_Ism  = zeros(NumIRs,L);
    eL_Win  = zeros(NumIRs,L);
    eL_BRIR_W = zeros(NumIRs,L);
    eL_Ism = e_TotalIsm(:,L);   % Ism without direct path
    eL_Win = e_TotalWin(:,L);   % Reverb files (hybrid windowed order 0 with no direct path)
    %eL_Total=e_Total([1:1:length(e_Total)],1);      % TOTAL Ism+Rever sin camino directo

    plot (x, eL_Ism,'r--*');   %Ism
    plot (x, eL_Win,'g--o');   % Windowed
    %plot (x,eL_Total,'b--+'); % Total
    grid;

    eL_BRIR_W(:,L) = eBRIR_L*ones(length(NumIRs))-eL_Win;
    plot (x, eL_BRIR_W,'k--x');
    %ylim([0.0 0.8]);
    xlabel('Distance (m)');
    ylabel('Energy');
    title('Total Energy vs Pruning Distance');
    legend('E-Ism',  'E-win','EBRIR-E-win',  'Location','northwest');
    %% -----------------------------                 % FIGURE 2 -- Total Factor
    figure;
    Factor = sqrt (eL_Ism ./ eL_BRIR_W);
    plot (x, Factor,'b--*');
    %ylim([0.0 1.5]);
    xlabel('Distance (m)');
    ylabel('Factor');
    title('Factor (total) vs Pruning Distance');
    legend('SQRT(eTotalIsm/(eBRIR-eTotalWin))', 'Location','southwest');
    grid;
    %% -----------------------------                 % FIGURE 3 -- Partial: ISM, Windowed, BRIR-Windowed
    figure; hold on;
    y=zeros(1,length(NumIRs));
    for j=1:NB
        eBand=E_BandBrir(j,L);
        y = E_BandWin(j,:,L);
        E_BandBrir_Win(j,:,L)=abs(eBand(1,L)*ones(1, length(NumIRs))-y);
        plot (x, E_BandBrir_Win(j,:,L));
    end
    title('E.BRIR-E.WIN-vs Pruning Distance');
    %% -----------------------------                  % FIGURE 4 -- Factor per Band
    figure; hold on;
    factorBand =zeros(NB, NumIRs,2);
    for j=1:NB
        eBand=E_BandBrir(j,L);
        y= E_BandWin(j,:,L);
        E_BandBrir_Win(j,:,L)=abs(eBand(1,L)*ones(1, length(NumIRs))-y);
        factorBand(j,:,L) = sqrt(E_BandIsm (j,:,L) ./ E_BandBrir_Win(j,:,L));
        plot (x, factorBand(j,:,L),"LineWidth",1.5);   % ,'color', [c(j,1) c(j,2) c(j,3)]
    end
    %ylim([0.0 2.5]); grid;
    xlabel('Distance (m)');  ylabel('Factor');
    legend( 'B1','B2','B3','B4', 'B5','B6','B7','B8','B9','Location','northeast');
    title('Factor per Band vs Pruning Distance');

    
    %% Curve Fitting                                   % FIGURE 5 -- Fit for each Band
    xf=[DpMinFit:1:DpMax]; % from DpMinFit meters to the end
    figure; hold on;
    leg = {'B1', 'a1','B2', 'a2','B3','a3','B4','a4','B5', 'a5','B6','a6','B7','a7','B8','a8','B9','a9'};

    %fitObj= cfit.empty(0,NB); % Create empty array of specified class cfit
    %cfitData = struct(cfit);
    %cfitArray = repmat (cfitData, 1, NB);

    gof = struct([]);                                   % Create empty struct
    gofplus = struct('gof', gof , 'p1', 0, 'p2', 0);    % Create struct to load data per band
    gofpArray = repmat (gofplus, 1, NB);                % Array of structures to store information for each band

    %% Total Slope
    Ff=Factor(NumIRs-(DpMax-DpMinFit) : NumIRs);  % from DpMinFit meters to the end
    xft=xf'; % transpose
    [fitObj, gofplus.gof] = fit(xft,Ff,'poly1');
    % gofpArray(NB+1).gof = gofplus.gof;
    totalSlope  = fitObj.p1;
    % gofpArray(NB+1).p2  = fitObj.p2;


    %% Partial Slopes
    for j=1:NB
        Ff=factorBand(j, NumIRs-(DpMax-DpMinFit) : NumIRs, L);  % from DpMinFit meters to the end
        xft=xf'; Fft= Ff'; % transpose
        % [fitObj, gof] = fit(xft,Fft,'poly1');
        [fitObj, gofplus.gof] = fit(xft,Fft,'poly1');
        % cfitArray(j) = struct(fitObj);
        gofpArray(j).gof = gofplus.gof;
        gofpArray(j).p1  = fitObj.p1;
        gofpArray(j).p2  = fitObj.p2;
        % disp(fitObj)  % disp(cfitArray(j));
        % fitObj.p1;    % cfitArray(j).coeffValues(1,1);
        p=plot(fitObj, xft,Fft, '--o');
        p(2,1).Color = 'b'; p(1,1).LineWidth=1.5;
    end
    %ylim([0.0 2.5]);
    xlabel('Distance (m)');  ylabel('Factor');
    legend( leg, 'Location','northwest'); grid;
    title('CURVE FIT (9B)- Factor per Band vs Pruning Distance');
    hold off;


    %% -----------------------------------------------------------------
    %% Extrac slopes and new absortions (only 1ª and 2ª iterations) to send to ISM
    alfa = 0.01;
    slopes=zeros(1,9);
    ordO=zeros(1,9);
    slopeMax=0;
    for j=1:NB
        slopes(1,j) = gofpArray(j).p1;
        ordO(1,j)   = gofpArray(j).p2;
        slopeB = slopes (1,j);
        if (abs(slopeB)>slopeMax)
            slopeMax=abs(slopeB);
        end
        ordOB = ordO (1,j);
    end 
    
    %% update absorption values
    absorbData0 = absorbData1;
    absorbData1 = absorbData2;

    %% calculate new absorptions
    %% 1 KHz band
    for k=1:6
       absorbData2 (k,5) = An(1,iLoop);
    end

    Sn(iLoop, :) = slopes;

    %% ---------------------------------
 
    vSlope = sprintf(formatSlope,slopes);
    disp(vSlope);
    vAbsor = sprintf(formatAbsor,absorbData2(1,:));
    disp(vAbsor);
   
    %% send new abssortion values (if any of the slopes exceeds the threshold)
    absorbDataT = absorbData2';
    walls_absor = absorbDataT(:);
    HybridOscCmds.SendAbsortionsToISM(connectionToISM, walls_absor');
    message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
    disp(message+" New Absortions");
    pause(0.5);
    HybridOscCmds.SendSaveIRToISM(connectionToISM);
    message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
    disp(message+" SaveIR");
    pause(0.5);

    cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\SeriesIr';
    movefile (nameFileISM, "ISM_DpMax.wav");

    AudioFile=ISMFile.name;
    [t_ISM,Fs] = audioread(AudioFile);

%% ----------- ------------------
    
%% -------------------------------

    if (iLoop<ITER_MAX)
        close all;
    end
    iLoop=iLoop+1;
end

plot (Sn);
legend( 'B1','B2','B3','B4', 'B5','B6','B7','B8','B9','Location','southeast');

%% Reflecion Order = 0
HybridOscCmds.SendReflecionOrderToISM(connectionToISM, 0);
% Waiting msg from ISM
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Ref Order = 0");
pause(0.2);

%% Close, doesn't work properly
HybridOscCmds.CloseOscServer(receiver, osc_listener);

%%  File with Sn values
t = datetime('now','Format','HH:mm:ss.SSS');
[h,m,s] = hms(t);
H = int2str (h);
M = int2str (m);
S = int2str (s);
current_folder = pwd;
nameFile= "SnFile_"+ H +"_"+ M + "_" + S;
save(fullfile( current_folder,   nameFile), 'Sn');

