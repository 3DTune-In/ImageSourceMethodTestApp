%% This Scritp carry out the process of adjusting absorptions 
%% and obtaining the Energy Factor for the hybrid method
%% (this script replaces EnergyFactor_9Bands_OSC_FAST5.m)

% Author: Fabian Arrebola (28/11/2023) 
% contact: areyes@uma.es
% 3DDIANA research group. University of Malaga
% Project: SONICOM
% 
% Copyright (C) 2023 Universidad de Málaga

%% This version operates only with two impulse responses
%% generated by the Hybrid Simulator (ISM+CONV):
%% the RIR and the ISM for DpMax
%
%% This script:
%  1) Open a connection to send/receive messages to ISM simulator
%  2) Generate the BRIR file from a simulation with 
%     DistMax=1m, RO=0, W_Slope=2 ms and RGain value set by the user
%  3) Send Initial absortions
%  4) Generate the IR file associated with ISM with Maximum pruning distance
%     ISM_DpMax:  DistMax=DpMax, RO=40. 
%  5) Read file with BRIR and file with ISM_DpMax
%  
%% 6) Working Loop:
%  6.1) Varying the pruning distance (from DpMin to DpMax) 
%       generate 2N impulse responses by applying raised cosine windowing
%       - N IRs are generated by windowing (fadeOut) ISM_DpMax
%       - N IRs are generated by windowing (fadeIn) BRIR    
%  6.2) Calculate total and partial energies for each IR (2N IRs)
%       Calculate BRIR energy. Total and partial (for each band)
%  6.3) Plot: Total Energy for 2N IRs: ISM, Windowed, BRIR-Windowed
%  6.4) Plot: Total Factor: SQRT(e_TotalIsm/(eBRIR-e_TotalWin))
%  6.5) Plot: Partial Energies (per band): ISM, Windowed, BRIR-Windowed
%  6.6) Plot: Partial Factor (per band): SQRT(E_BandIsm(j)/E_BandBrir_Win(j));
%  6.7) Curve Fitting: Fit for each Band. 
%       Calculates slope for each band. Plot slopeswindowIsm
%  6.8) Update slopes and calculate and update absortions 
%  6.9) Send new absortions to ISM and generate IR associated 
%       with ISM with Maximum pruning distance DpMax
%  6.10) Wait msg from ISM  (this indicates that ISM has finished 
%        execution for ISM_DpMax)
%  6.11) Create new folder to save slopes, absortions, IRs files (see
%        output)

%% Input
% ITER_MAX 
% DpMax; DpMin; DpMinFit;  (PRUNING DISTANCES)
% RefOrd; 
% W_Slope;                      
% RGain_dB;
% C;       % Channel to carry out the adjustment

%% Output
%  'ParamsISM.mat',      <-- 'RefOrd', 'DpMax','W_Slope','RGain_dB'
%  'DistanceRange.mat'   <-- 'DpMax', 'DpMin','DpMinFit'
%  'FiInfSlopes.mat'     <-- 'slopes'     slope values for each iteration
%  'FiInfAbsorb.mat'     <-- 'absorption' absorption values for each iteration
%  'SnFile_HH_MM_SS.mat' <-- 'Sn'         slope values for all iterations
%  'AnFile_HH_MM_SS.mat' <-- 'An'         absorption values for all iterations
%  'BRIR.wav'            <-- IR_Reverb
%  'ISMDpMax.wav'        <-- IR_ISM

%% Absorption saturation values
% absorMax=0.95;
% absorMin=0.05;
% maxChange=0.50;
% reductionAbsorChange=0.9;
absorMax=0.999;
absorMin=0.001;
maxChange=0.15;
reductionAbsorChange=0.6;

%% BRIR used for adjustment: measured ('M') or simulated ('S')
BRIR_used = 'M';

%% Room to simulate: Lab ('Lab') or Small ('Sm') 
Room = 'Lab';

%% MAX ITERATIONS 
ITER_MAX = 13;

%% Channel: Left (L) or Right (R)
L=1; R=2;         % Channels
C=R;              % Channel to carry out the adjustment

%% PRUNING DISTANCES
if Room == 'Lab'          % Lab  
   DpMax=38; DpMin=2;
   DpMinFit = 17;                  %% Smaller distance values will be discarded
elseif Room == 'Sm'      % Small
   DpMax=16; DpMin=2;
   DpMinFit = 10;                   %% Smaller distance values will be discarded
else
   disp('Error: Room to be simulated must be indicated');
   exit;
end


%% Path
addpath('C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\ISM_OSC_Tester\MatlabOscTester'); 

%% Folder with impulse responses
nameFolder='\workFolder';
resourcesFolder = 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources';
workFolder = strcat(resourcesFolder,nameFolder);
% workFolder = "C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\"+ nameFolder;
if exist(workFolder, 'dir') == 7
    disp('folder exist');
else
    mkdir(workFolder);
    disp('created work folder');
end
cd (workFolder);
delete *.wav;

%% SAVE Configuration parameters for ISM simulation
RefOrd=40; 
W_Slope=2;                       % Value for energy adjustment
RGain_dB = 0;
RGain = db2mag(RGain_dB);
save ('ParamsISM.mat','RefOrd', 'DpMax','W_Slope','RGain_dB','C','BRIR_used','Room');

%% File name associated with ISM simulation
formatFileISM= "iIrRO%iDP%02iW%02i";
nameFileISM = sprintf(formatFileISM, RefOrd, DpMax, W_Slope)+'.wav';

% nameFileISM = generateNameFile( RefOrd, DpMax, W_Slope);

%% SAVE PRUNING DISTANCES
save ('DistanceRange.mat','DpMax', 'DpMin','DpMinFit');

x=[DpMin:1:DpMax];               % Initial and final pruning distance

%% ABSORTIONS

if exist('FiInfAbsorb.mat', 'file') == 2
    load ("FiInfAbsorb.mat");
    absorbData =absorbData1;
else
    absorbData = [0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5;
        0.5 0.5 0.5	0.5 0.5	0.5	0.5 0.5	0.5;
        0.5 0.5 0.5	0.5 0.5	0.5	0.5 0.5	0.5;
        0.5 0.5 0.5	0.5 0.5	0.5	0.5 0.5	0.5;
        0.5 0.5 0.5	0.5 0.5	0.5	0.5 0.5	0.5;
        0.5 0.5 0.5	0.5 0.5	0.5	0.5 0.5	0.5;];
end

absorbData0 = absorbData;
absorbData1 = absorbData;
absorbData2 = absorbData;

slopes0 = zeros(1,9);
slopes1 = zeros(1,9);
slopes2 = zeros(1,9);

Sn=zeros(ITER_MAX, 9);
An=zeros(ITER_MAX, 9);

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

%% Set Working Folder
HybridOscCmds.SendWorkFolderToISM(connectionToISM, nameFolder);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+"Work Folder");

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

%% Enable Spatialisation
HybridOscCmds.SendSpatialisationEnableToISM (connectionToISM, true);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Enable Spatialisation");
pause(0.2);

%% Enable Distance Attenuation
HybridOscCmds.SendDistanceAttenuationEnableToISM (connectionToISM, true);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Enable Distance Attenuation");
pause(0.2);

%%  Disable Distance Attenuation Reverb Enable To ISM
HybridOscCmds.SendDistanceAttenuationReverbEnableToISM (connectionToISM, false);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Distance Attenuation Reverb Enable");
pause(0.2);

%% Disable Direct Path
HybridOscCmds.SendDirectPathEnableToISM(connectionToISM, false);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Disable Direct Path");

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
% configureHybrid (connectionToISM, receiver, osc_listener,              W_Slope, DistMax, RefOrd, RGain, SaveIR) 
HybridOscCmds.configureHybrid (connectionToISM, receiver, osc_listener,       2,    1,       0,    RGain,   true);
pause(0.2);
disp(message+" RIR");

%% Disable Reverb
HybridOscCmds.SendReverbEnableToISM(connectionToISM, false);
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Dissable Reverb");
pause(0.2);

%% Rename to BRIR.wav
cd (workFolder);
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
% configureHybrid (connectionToISM, receiver, osc_listener,                W_Slope, DistMax,   RefOrd,     RGain, SaveIR) 
HybridOscCmds.configureHybrid (connectionToISM, receiver, osc_listener,    W_Slope,    DpMax,     -1,        -1,   true);
pause(0.2);
disp(message+ " ISM DpMax ");
%% Rename to ISM_DpMax.wav
cd (workFolder);
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

fitSlopes=false;
while ( iLoop < ITER_MAX)
    disp(iLoop);
    %% Folder with impulse responses
    cd (workFolder);
        
    %% Number of Impulse Responses
    NumIRs = DpMax-DpMin+1;

    %% BRIR Energy
    e_BRIR= calculateEnergy(t_BRIR);
    %%%%%%% PARSEVAL RELATION --> e_BRIR (in time) == E_BRIR (in frec)
    E_BRIR= calculateEnergyFrec(Fs, t_BRIR)/length(t_BRIR);
    eBRIR_L= e_BRIR(C);
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
    eL_Ism  = zeros(NumIRs,1);
    eR_Ism  = zeros(NumIRs,1);
    eL_Win  = zeros(NumIRs,1);
    eL_BRIR_W = zeros(NumIRs,1);
    eL_Ism = e_TotalIsm (:,C);   % Ism without direct path
    if (C==L) C2=R;
    else C2=L;    
    end    
    eR_Ism = e_TotalIsm (:,C2);
    eR_Win = e_TotalWin(:,C2);
    eL_Win = e_TotalWin(:,C);   % Reverb files (hybrid windowed order 0 with no direct path)
    %eL_Total=e_Total([1:1:length(e_Total)],1);      % TOTAL Ism+Rever sin camino directo

    plot (x, eL_Ism,'m--*');   %Ism
    plot (x, eR_Ism,'c--*');
    plot (x, eL_Win,'g--o');   % Windowed
    %plot (x,eL_Total,'b--+'); % Total
    grid;

    eL_BRIR_W(:,1) = eBRIR_L*ones(length(NumIRs))-eL_Win;
    plot (x, eL_BRIR_W,'k--x');
    %ylim([0.0 0.8]);
    xlabel('Distance (m)');
    ylabel('Energy');
    title('Total Energy vs Pruning Distance');
    legend('E-IsmAd', 'E-IsmOt', 'E-win','EBRIR-E-win',  'Location','northwest');
    %% -----------------------------                 % FIGURE 2 -- Total Factor
    figure;
    Factor = zeros(NumIRs,1);
    Factor = sqrt (eL_Ism ./ eL_BRIR_W);
    plot (x, Factor,'k--*');
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
        eBand=E_BandBrir(j,C);
        y = E_BandWin(j,:,C);
        E_BandBrir_Win(j,:,C)=abs(eBand(1,1)*ones(1, length(NumIRs))-y);
        plot (x, E_BandBrir_Win(j,:,C));
    end
    title('E.BRIR-E.WIN-vs Pruning Distance');
    %% -----------------------------                  % FIGURE 4 -- Factor per Band
    figure; hold on;
    factorBand =zeros(NB, NumIRs,2);
    for j=1:NB
        eBand=E_BandBrir(j,C);
        y= E_BandWin(j,:,C);
        E_BandBrir_Win(j,:,C)=abs(eBand(1,1)*ones(1, length(NumIRs))-y);
        factorBand(j,:,C) = sqrt(E_BandIsm (j,:,C) ./ E_BandBrir_Win(j,:,C));
        plot (x, factorBand(j,:,C),"LineWidth",1.5);   % ,'color', [c(j,1) c(j,2) c(j,3)]
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
        Ff=factorBand(j, NumIRs-(DpMax-DpMinFit) : NumIRs, C);  % from DpMinFit meters to the end
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
        if (abs (slopeB)  > 0)
            % for k=1:4    %excluding ceil and floor
             for k=1:6
                newAbsorb = absorbData (k,j) + slopeB*alfa; 
                if newAbsorb > 0.0 && newAbsorb < 1.0
                    absorbData (k,j) = newAbsorb;
                elseif newAbsorb <= 0.0
                    absorbData (k,j) = absorMin;
                elseif newAbsorb >= 1.0
                    absorbData (k,j) = absorMax;
                end
            end 
        end
    end 
    %% update calculated slopes
    slopes0=slopes1;
    slopes1=slopes;
    %slopes2=slopes;
    %% update absorption values
    absorbData0 = absorbData1;
    absorbData1 = absorbData2;

    %% ---------------------------------

    if (iLoop < 2 )
        %% first new absortions
       absorbData2 = absorbData;            
    else
        %% calculate new absorptions
        for j=1:NB
            if (abs (slopes0(1,j) - slopes1(1,j) ) > 0.0000001)
                newAbsorb = (-slopes0(1,j)) * (absorbData1(1,j)-absorbData0(1,j))/(slopes1(1,j)-slopes0(1,j))+absorbData0(1,j); 

                if sign(slopes1(1,j)) ~= sign(slopes0(1,j))
                    maximumAbsorChange(j)= maximumAbsorChange(j)*reductionAbsorChange;
                end

                if abs (newAbsorb - absorbData1(1,j) ) > maximumAbsorChange(j)
                   if newAbsorb > absorbData1(1,j)  
                      newAbsorb = absorbData1(1,j) + maximumAbsorChange(j);
                   else 
                      newAbsorb = absorbData1(1,j) - maximumAbsorChange(j);
                   end
                end

            else 
                newAbsorb =  absorbData1(1,j)+slopes1(1,j); %%%%%%%%%%%
                disp("Very similar slopes. Band: "+ int2str(j) ); 
                % disp (newAbsorb);
            end

            if (newAbsorb <= 0.0)
                newAbsorb = absorMin;
            elseif (newAbsorb >= 1.0)
                newAbsorb = absorMax;
            end

            for k=1:6
                absorbData2 (k,j) = newAbsorb;
            end  
        end
    end

 
    vSlope = sprintf(formatSlope,slopes0);
    disp(vSlope);
    vSlope = sprintf(formatSlope,slopes1);
    disp(vSlope);
    vSlope = sprintf(formaTotalMaxSlope, totalSlope, slopeMax);  
    disp(vSlope);
    vAbsor = sprintf(formatAbsorChange,maximumAbsorChange);
    disp(vAbsor);
    vAbsor = sprintf(formatAbsor,absorbData0(1,:));
    disp(vAbsor);
    vAbsor = sprintf(formatAbsor,absorbData1(1,:));
    disp(vAbsor);
    vAbsor = sprintf(formatAbsor,absorbData2(1,:));
    disp(vAbsor);
       
    %% send new abssortion values (if any of the slopes exceeds the threshold)
    if slopeMax > 0.002 || abs(totalSlope)> 0.002
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

       cd (workFolder);
       movefile (nameFileISM, "ISM_DpMax.wav");

       AudioFile=ISMFile.name;
       [t_ISM,Fs] = audioread(AudioFile);


    else
       fitSlopes=true;
    end
    % disp(message);
    % pause (1)
%% ----------- ------------------
    b = mod( iLoop , 1 ) ;
    if (b==0)|| (fitSlopes == true) || (iLoop==ITER_MAX-1)
        % actual folder
        current_folder = pwd;
        % new folder
        new_folder = num2str(iLoop);
        mkdir( current_folder, new_folder);
        % save slopes and absortions
        nameFile= 'FiInfSlopes';
        save(fullfile( current_folder,   nameFile), 'slopes');
        nameFile= 'FiInfAbsorb';
        save(fullfile( current_folder,   nameFile), 'absorbData1');

        % copy files
        copyfile(fullfile( current_folder,'BR*'), new_folder);
        % copyfile(fullfile( current_folder,'wIr*'), new_folder);
        copyfile(fullfile( current_folder,'ISM*'), new_folder);
        % copyfile(fullfile( current_folder,'iIr*'), new_folder);
        copyfile(fullfile( current_folder,'*.mat'), new_folder);
    end
%% -------------------------------

    if (iLoop<ITER_MAX-1 && fitSlopes == false)
        close all;
    end
    iLoop=iLoop+1;

    %% Save slopes in Sn
    Sn(iLoop, :) = slopes;
    An(iLoop, :) = absorbData1(1,:);

    if (fitSlopes == true)
        break;
    end

end

%% Reflecion Order = 0
HybridOscCmds.SendReflecionOrderToISM(connectionToISM, 0);
% Waiting msg from ISM
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
disp(message+" Ref Order = 0");
pause(0.2);


%% Close, doesn't work properly
HybridOscCmds.CloseOscServer(receiver, osc_listener);

%% File with Sn and An values
%%  Files with Sn values
t = datetime('now','Format','HH:mm:ss.SSS');
[h,m,s] = hms(t);
H = int2str (h);
M = int2str (m);
S = int2str (s);
current_folder = pwd;
nameFile= "SnFile_"+ H +"_"+ M + "_" + S;
save(fullfile( current_folder,   nameFile), 'Sn');
nameFile= "AnFile_"+ H +"_"+ M + "_" + S;
save(fullfile( current_folder,   nameFile), 'An');

