%% This Scritp carry out the process of adjusting absorptions 
%% using the EEY parameter
%% Adjustment method: Averages + Secant + Direct or Indirect
%% Channel used:      Average of L and R.

% Author: Fabian Arrebola (19/10/2024) 
% contact: areyes@uma.es
% 3DDIANA research group. University of Malaga
% Project: SONICOM
% 
% Copyright (C) 2023 Universidad de Málaga


%% Input - Configure
% BRIR_used --> BRIR used for adjustment: measured ('M') or simulated ('S')
% Room      --> Room to simulate: A108, sJun, Lab or Sm (Small) 
% ITER_MAX  --> MAX ITERATIONS
% nameFolder --> Folder with impulse responses

% DpMax; DpMin; DpMinFit; --> (PRUNING DISTANCES)
% RefOrd; 
% W_Slope;                      
% RGain_dB;

%% Output
%  'ParamsISM.mat',      <-- 'RefOrd', 'DpMax','W_Slope','RGain_dB'
%  'DistanceRange.mat'   <-- 'DpMax', 'DpMin','DpMinFit'
%  'FiInfError.mat'     <-- 'Errors'     slope values for each iteration
%  'FiInfAbsorb.mat'     <-- 'absorption' absorption values for each iteration
%  'SnFile_HH_MM_SS.mat' <-- 'Sn'         slope values for all iterations
%  'AnFile_HH_MM_SS.mat' <-- 'An'         absorption values for all iterations
%  'BRIR.wav'            <-- IR_Reverb
%  'ISMDpMax.wav'        <-- IR_ISM

clear all;

%% Error Threshold ## Direct Path 
thError = 0.01;  directPath = true;  
%% Reverb Gain
RGain_dB = -6;  
%RGain_dB = 4.8428 


%% Absorption saturation values
absorMax=0.9999;
absorMin=0.0001;
maxChange=0.1;                %0.1
reductionAbsorChange=0.8;     %0.6
% maxChange=0.15;
% reductionAbsorChange=0.75;

%% BRIR used for adjustment: measured ('M') or simulated ('S')
BRIR_used = 'S';

%% Room to simulate: A108, sJun, Lab or Sm (Small) 
Room = 'sJun';

%% MAX ITERATIONS 
ITER_MAX = 80;

%% Channel: Left (L) or Right (R)
L=1; R=2;         % Channels
C=0;              % Channel to carry out the adjustment

%% PRUNING DISTANCES
if Room == 'A108'            % Aula 108  
   DpMax=40; DpMin=2;
   DpMinFit = 40;                %% Smaller distance values will be discarded
elseif Room == 'sJun'            % Sala Juntas
   DpMax=34; DpMin=2;
   DpMinFit = 34;                %% Smaller distance values will be discarded
elseif Room == 'Lab'         % Lab  
   DpMax=38; DpMin=2;
   DpMinFit = 17;            %% Smaller distance values will be discarded
elseif Room == 'Sm'          % Small
   DpMax=17; DpMin=2;
   DpMinFit = 8;                 %% Smaller distance values will be discarded
else
   disp('Error: Room to be simulated must be indicated');
   exit;
end

%% OpenFramework version
[resourcesFolder, pathSc]= verOpenF();
%% Path
addpath(pathSc); 

%% Folder with impulse responses
nameFolder='\workFolder';
workFolder = strcat(resourcesFolder,nameFolder);
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
if Room == 'A108';
    AEr = [0.106628119171042	0.0976080804785569	0.114348257012995	0.164057076979350	0.193742369190673	0.196620381435978	0.224669662309288	0.273602103381712	0.388069385485122];
    %AEr = [0.106628119	0.09760808	0.114348257	0.164057077	0.193742369	0.196620381	0.224669662	0.273602103	0.38806938];
elseif Room == 'sJun';
    AEr= [0.119983157652694	0.122043633632542	0.161949594699940	0.260336220141102	0.286622820285472	0.247208724772500	0.240230767404492	0.327752061756642	0.405951830716490];
    %AEr= [0,119983158	0,122043634	0,161949595	0,26033622	0,28662282	0,247208725	0,240230767	0,327752062	0,405951831];
else
    error('Error: Room not specified');
end
absorbData = repmat (AEr, 6, 1); 

% if exist('FiInfAbsorb.mat', 'file') == 2
%     load ("FiInfAbsorb.mat");
%     absorbData =absorbData1;
% else
%     absorbData = [0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5;
%                   0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5;
%                   0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5;
%                   0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5;
%                   0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5;
%                   0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5;];
% end

absorbData0 = absorbData;
absorbData1 = absorbData;
absorbData2 = absorbData;

distAu0 = zeros(1,9);
distAu1 = zeros(1,9);
distAu2 = zeros(1,9);

% bandAdjust = [0, 0, 0, 0, 0, 0, 0, 0, 0];

Sn=zeros(ITER_MAX, 9);
An=zeros(ITER_MAX, 9);

maximumAbsorChange=[maxChange, maxChange, maxChange, maxChange, maxChange, maxChange, maxChange, maxChange, maxChange];

formatDiff = "DifAu: %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f ";
formatAbsor = "Absor: %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f ";
formatAbsorChange= "AbChg: %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f ";

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

%% Enable - Disable Direct Path: Enable
HybridOscCmds.SendDirectPathEnableToISM(connectionToISM, directPath);
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

%% BRIR used for adjustment: measured (M) or simulated (S)
cd (workFolder);
if BRIR_used == 'S'
   movefile 'wIrRO0DP01W02.wav' 'BRIR.wav';    % simulated
elseif BRIR_used == 'M'
    if     Room == 'A108'
       copyfile '..\A108RIR.wav' 'BRIR.wav';      % measured
    elseif Room == 'sJun'
       copyfile '..\sJunRIR.wav' 'BRIR.wav';      % measured
    elseif Room == 'Lab'
       copyfile '..\LabBRIR.wav' 'BRIR.wav';      % measured
    elseif Room == 'Sm'
       copyfile '..\SmallBRIR.wav' 'BRIR.wav';    % measured
    else
       disp('Error: Room to be simulated must be indicated');
       exit;
    end
else
   disp('Error: It must be indicated whether the adjustment is going to be made with the measured or simulated BRIR');
   exit;
end


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

%% Set Time to Record Impulse Response
HybridOscCmds.SendTimeRecordIRToISM(connectionToISM, 0.150);
% Waiting msg from ISM
message = HybridOscCmds.WaitingOneOscMessageStringVector(receiver, osc_listener);
msg = sprintf('%s Time to Record Impulse Response = %d', message, 0.150);
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

%%   9 BANDS
Nf=48000;
NB=9;
B =[44 88; 89 176; 177 353; 354 707; 708 1414; 1415 2828; 2829 5657; 5658 11314; 11315 22050;];
Blo=[ 1    89      177      354      708       1415       2829       5658        11315       ];
Bhi=[  88     176      353      707      1414       2828       5657       11314        22630 ];

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
% delete (ISMFile.name);

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

    %% Average of both channels
    eBRIR_A = (e_BRIR(L)+e_BRIR(R))./2;

    %% --------------
    %% Total Energy in time domain
    e_TotalIsm=zeros(NumIRs,2);
    e_TotalWin=zeros(NumIRs,2);
    e_Total=zeros(NumIRs,2);
    %% Energy per band in frequency domain 
    E_BandIsm =zeros(NB,NumIRs,2);
    E_BandWin=zeros(NB,NumIRs,2);
    E_BandBrir_Win=zeros(NB,NumIRs,2);       %BRIR-Win
    E_BandBrirDir=zeros(NB,NumIRs,2);        %BRIR Direct

    %% Calculate total and partial energies
    maxDistSL = DpMin;
    for i=1:NumIRs
        %%  Ism IRs -------------------------------------
        ir_Ism =  windowingISM_RIR (Fs, t_ISM, maxDistSL, 2, 1);
        e= calculateEnergy(ir_Ism);
        e_TotalIsm(i,:)= e;
        % PARSEVAL RELATION --> e_TotalIsm (in time) == E_TotalIsm (in frec)
        E_TotalIsm= calculateEnergyFrec(Fs, ir_Ism)/length(ir_Ism);
        E_TotalIsm2= calculateEnergyBandWr(Nf, ir_Ism, Blo(1), Bhi(NB))/ Nf;     
        %eSumBandsI=zeros(1,2);
        eSumBandsI=0; %checksum
        for j=1:NB
            e = calculateEnergyBand   (Nf, ir_Ism, Blo(j), Bhi(j)) / Nf;          
            e2 =calculateEnergyBandWr (Nf, ir_Ism, Blo(j), Bhi(j)) / Nf;
            E_BandIsm(j,i,:) = e;
            eSumBandsI = eSumBandsI+E_BandIsm(j,i,:);
        end
        eSumBandsI= squeeze(eSumBandsI);

        %%  Windowed IRs -------------------------------
        ir_Win =  windowingISM_RIR (Fs, t_BRIR, maxDistSL, 2, 0);
        e = calculateEnergy(ir_Win);
        e_TotalWin(i,:)= e;
        %% PARSEVAL RELATION --> e_Totalwin (in time) == E_TotalWin (in frec)
        E_TotalWin= calculateEnergyFrec(Fs, ir_Win)/length(ir_Win);
        E_TotalWin2= calculateEnergyBandWr(Nf, ir_Win, Blo(1), Bhi(NB)) / Nf;    
        %eSumBandsW=zeros(1,2); %checksum
        eSumBandsW=0; %checksum 
        for j=1:NB
            e = calculateEnergyBand   (Nf, ir_Win, Blo(j), Bhi(j))/ Nf;           
            e2 =calculateEnergyBandWr (Nf, ir_Win, Blo(j), Bhi(j))/ Nf;
            E_BandWin(j,i,:) = e;
            eSumBandsW= eSumBandsW+E_BandWin(j,i,:);
        end
        eSumBandsW= squeeze(eSumBandsW);
        %%  Direct BRIRs IRs -------------------------------
        ir_Brir = windowingISM_RIR (Fs, t_BRIR, maxDistSL, 2, 1);
        e = calculateEnergy(ir_Brir);
        e_TotalBrir(i,:)= e;
        %% PARSEVAL RELATION --> e_Totalwin (in time) == E_TotalWin (in frec)
        E_TotalBrir= calculateEnergyFrec(Fs, ir_Brir)/length(ir_Brir);
        E_TotalBrir2= calculateEnergyBandWr(Nf, ir_Brir, Blo(1), Bhi(NB)) / Nf;    
        %eSumBandsW=zeros(1,2); %checksum
        eSumBandsD=0; %checksum   
        for j=1:NB
            e = calculateEnergyBandWr (Nf, ir_Brir, Blo(j), Bhi(j))/ Nf; 
            e2 =calculateEnergyBand   (Nf, ir_Brir, Blo(j), Bhi(j))/ Nf;
            E_BandBrirDir(j,i,:) = e;
            eSumBandsD= eSumBandsD+E_BandBrirDir(j,i,:);
        end
        eSumBandsD= squeeze(eSumBandsD);

        maxDistSL = maxDistSL+1;
    end
    %% BRIR Energy for each band
    E_BandBrir=zeros(NB,2);
    %eSumBands=zeros(1,1); %checksum
    eSumBands=0; %checksum
    for j=1:NB
        %eSumBands = eSumBands+E_BandWin(j,i,:);
        e = calculateEnergyBand    (Nf, t_BRIR, Blo(j), Bhi(j))/Nf;                    
        e2 = calculateEnergyBandWr (Nf, t_BRIR, Blo(j), Bhi(j))/Nf;
        E_BandBrir(j,:) = e2;
        eSumBands = eSumBands+E_BandBrir(j,:);
    end
    eSumBands= squeeze(eSumBands);
    %% --------------------------                    % FIGURE 1 -- Total: ISM, Windowed, BRIR-Windowed
    figure; hold on;
    aA_Ism  = zeros(NumIRs,1);
    eA_Win  = zeros(NumIRs,1);
    eA_BRIR_W = zeros(NumIRs,1);
    %% channels L and E
    eL_Ism = e_TotalIsm(:,L);   
    eR_Ism = e_TotalIsm(:,R);   % Ism without direct path
    %eL_Win = e_TotalWin(:,L);   % Reverb files (hybrid windowed order 0 with no direct path)
    %% Average of both channels
    eA_Ism = (e_TotalIsm(:,L)+e_TotalIsm(:,R))./2;   % Ism without direct path
    eA_Win = (e_TotalWin(:,L)+e_TotalWin(:,R))./2;   % Reverb files (hybrid windowed order 0 with no direct path)
    eA_Brir= (e_TotalBrir(:,L)+e_TotalBrir(:,R))./2;
    
    plot (x, eA_Ism,'m--.');   %Ism
    plot (x, eL_Ism, 'b--.');
    plot (x, eR_Ism,'r--.');
    plot (x, eA_Win,'g--o');   % Windowed
    %plot (x,eL_Total,'b--+'); % Total
    grid;

    eA_BRIR_W(:,1) = eBRIR_A*ones(length(NumIRs))-eA_Win;
    plot (x, eA_BRIR_W,'k--x');
    plot (x, eA_Brir,'k.');
    %ylim([0.0 0.8]);
    xlabel('Distance (m)');
    ylabel('Energy');
    title('Total Energy vs Pruning Distance');
    legend('E-Ism', 'E-Ism_L', 'E-Ism_R', 'E-win','EBRIR-E-win', 'E-Brir',  'Location','northwest');
    %% -----------------------------                 % FIGURE 2 -- Total eFactor
    figure; hold on;
    FactorI = sqrt (eA_Ism ./ eA_BRIR_W);
    FactorD = sqrt (eA_Ism ./ eA_Brir);
    FCropI = FactorI(DpMinFit:DpMax-DpMin+1);
    FCropD = FactorD(DpMinFit:DpMax-DpMin+1);
    if NumIRs > 1
       factorMeanValueI = mean(FCropI);
       factorMeanValueD = mean(FCropD);
    else 
       factorMeanValueI = FCropI;
       factorMeanValueD = FCropD;
    end

    %% -----------------------------
    Factor = FactorD;                    % for adjustment (FactorI: BRIR-Win) 
    factorMeanValue = factorMeanValueD;  % for adjustment (factorMeanValueI)
    %%                                   % factorBand = factorBandD or factorBandI;             
    %% -----------------------------
    plot (x, FactorI,'b*');
    plot (x, FactorD,'k--.');
    %ylim([0.0 1.5]);
    xlabel('Distance (m)');
    ylabel('eFactor');
    title('eFactor (total) vs Pruning Distance');
    legend('SQRT(eTotalIsm/(eBRIR-eTotalWin))', 'SQRT(eTotalIsm/(eBrir))', 'Location','southwest');
    grid;
    %% -----------------------------                 % FIGURE 3 -- Partial: ISM, Windowed, BRIR-Windowed, BRIR
    %% figure; hold on;
    y=zeros(1,length(NumIRs));
    for j=1:NB
       %% Average of both channels
        eBand=E_BandBrir(j,L);
        y =E_BandWin(j,:,L);
        E_BandBrir_Win(j,:,L)=abs(eBand(1,1)*ones(1, length(NumIRs))-y);
        eBand=E_BandBrir(j,R);
        y = E_BandWin(j,:,R);
        E_BandBrir_Win(j,:,R)=abs(eBand(1,1)*ones(1, length(NumIRs))-y);
        %% plot (x, (E_BandBrir_Win(j,:,L)+E_BandBrir_Win(j,:,R))./2);
        %% plot (x, (E_BandBrirDir(j,:,L)+E_BandBrirDir(j,:,R))./2 , '--.');      
    end
    %% title('E.BRIR-E.WIN & E-Brir(direct) -vs Pruning Distance');
    %% legend('EBRIR-E-win', 'E-Brir',  'Location','northwest');
    %% -----------------------------                  % FIGURE 4 -- eFactor per Band
    figure; hold on;
    factorBandI =zeros(NB, NumIRs,2);      % Indirect
    FactorMeanBandI=zeros(1,NB);
    factorBandD =zeros(NB, NumIRs,2);      % Direct
    FactorMeanBandD=zeros(1,NB);

    factorBand = factorBandD;              % for adjustment
    FactorMeanBand=zeros(1,NB);
    for j=1:NB
        % eBand=E_BandBrir(j,L);
        % y= E_BandWin(j,:,L);
        %% Average of both channels
        eBand=E_BandBrir(j,L);
        y =E_BandWin(j,:,L);
        E_BandBrir_Win(j,:,L)=abs(eBand(1,1)*ones(1, length(NumIRs))-y);

        eBand=E_BandBrir(j,R);
        y =E_BandWin(j,:,R);
        E_BandBrir_Win(j,:,R)=abs(eBand(1,1)*ones(1, length(NumIRs))-y);

        E_BandIsm (j,:,L) = (E_BandIsm (j,:,L)+E_BandIsm (j,:,R))./2;
        E_BandBrir_Win(j,:,L) = (E_BandBrir_Win(j,:,L)+E_BandBrir_Win(j,:,R))./2;
        E_BandBrirDir(j,:,L) = (E_BandBrirDir(j,:,L)+E_BandBrirDir(j,:,R))./2;
        
        factorBandI(j,:,L) = sqrt(E_BandIsm (j,:,L) ./ E_BandBrir_Win(j,:,L));
        factorBandD(j,:,L) = sqrt(E_BandIsm (j,:,L) ./ E_BandBrirDir(j,:,L));
        plot (x, factorBandI(j,:,L));   
        plot (x, factorBandD(j,:,L) , '--.');       
    end
    %ylim([0.0 2.5]); grid;
    xlabel('Distance (m)');  ylabel('eFactor');
    legend( 'B1','1d','B2','2d', 'B3','3d','B4','4d','B5', '5d','B6','6d','B7', '7d','B8','8d','B9','9d','Location','northeast');
    title('eFactor per Band vs Pruning Distance');

    
    %% Curve Fitting                                   % FIGURE 5 -- Fit for each Band
    xf=[DpMinFit:1:DpMax]; % from DpMinFit meters to the end
    %% figure; hold on;
    %% leg = {'B1', 'a1','B2', 'a2','B3','a3','B4','a4','B5', 'a5','B6','a6','B7','a7','B8','a8','B9','a9'};

    gof = struct([]);                                   % Create empty struct
    gofplus = struct('gof', gof , 'p1', 0, 'p2', 0);    % Create struct to load data per band
    gofpArray = repmat (gofplus, 1, NB);                % Array of structures to store information for each band

    %% Total Slope
    Ff=Factor(NumIRs-(DpMax-DpMinFit) : NumIRs);  % from DpMinFit meters to the end
    xft=xf'; % transpose
    if length(xft)>1
        [fitObj, gofplus.gof] = fit(xft,Ff,'poly1');
        totalSlope  = fitObj.p1;
    end
    totalSlope = 0;

    %% Partial Slopes
    factorBand=factorBandD;              % for adjustment
    for j=1:NB
        Ff=factorBand(j, NumIRs-(DpMax-DpMinFit) : NumIRs, L);  % from DpMinFit meters to the end
        xft=xf'; Fft= Ff'; % transpose
        if length(xft)>1
            [fitObj, gofplus.gof] = fit(xft,Fft,'poly1');
            gofpArray(j).gof = gofplus.gof;
            gofpArray(j).p1  = fitObj.p1;
            gofpArray(j).p2  = fitObj.p2;
            p=plot(fitObj, xft,Fft, '--o');
            p(2,1).Color = 'b'; p(1,1).LineWidth=1.5;
            FactorMeanBand(1,j) = mean(Ff);
        end
        FactorMeanBand(1,j) = Ff;
    end
    %% xlabel('Distance (m)');  ylabel('eFactor');
    %% legend( leg, 'Location','northwest'); grid;
    %% title('CURVE FIT (9B)- eFactor per Band vs Pruning Distance');
    %% hold off;


    %% -----------------------------------------------------------------
    %% Extrac distAu and new absortions (only 1ª and 2ª iterations) to send to ISM
    distAu=zeros(1,NB);
    for j=2:NB-1                 %First and last bands are not taken into account 
        distAu(1,j) = FactorMeanBand (1,j) -1;
        DistAuB = distAu(1,j);
        if (abs (DistAuB)  > 0)
             for k=1:6           %% 6 walls
                newAbsorb = absorbData (k,j) + (DistAuB )*0.05;
                if abs (newAbsorb - absorbData(k,j) ) > maximumAbsorChange(j);
                    if newAbsorb > absorbData(k,j)  newAbsorb = absorbData(k,j) + maximumAbsorChange(j);
                    else                            newAbsorb = absorbData(k,j) - maximumAbsorChange(j);
                    end
                end
                if newAbsorb > 0.0 && newAbsorb < 1.0  absorbData (k,j) = newAbsorb;
                elseif newAbsorb <= 0.0                absorbData (k,j) = absorMin;
                elseif newAbsorb >= 1.0                absorbData (k,j) = absorMax;
                end
            end 
        end
    end 
    %% update absorption values
    absorbData0 = absorbData1;
    absorbData1 = absorbData2;
    %% update calculated differences
    distAu0=distAu1;
    distAu1=distAu;
    %% ---------------------------------
    changeAbsor = 0;
    if (iLoop < 2 )
        %% first new absortions
       absorbData2 = absorbData; 
       changeAbsor = 9;            %This forces more than two iterations to be done.
    else
        %% calculate new absorptions
        for j=2:NB-1               %First and last bands are not taken into account      
            newAbsorb = (-distAu1(1,j)) * (absorbData1(1,j)-absorbData0(1,j))/(distAu1(1,j)-distAu0(1,j))+absorbData0(1,j); 
            if sign(distAu1(1,j)) ~= sign(distAu0(1,j))
                maximumAbsorChange(j)= maximumAbsorChange(j)*reductionAbsorChange;
            end
            if abs (newAbsorb - absorbData1(1,j) ) > maximumAbsorChange(j)
                if newAbsorb > absorbData1(1,j)      newAbsorb = absorbData1(1,j) + maximumAbsorChange(j);
                else                                 newAbsorb = absorbData1(1,j) - maximumAbsorChange(j);
                end
            end
            if (newAbsorb <= 0.0)         newAbsorb = absorMin;
            elseif (newAbsorb >= 1.0)     newAbsorb = absorMax;
            end

            for k=1:6
                absorbData2 (k,j) = newAbsorb;
            end  
            %if (abs(FactorMeanBand (1,j)-1) > thError) && j>1 && j<9
             if (abs(distAu(1,j)) >= thError) && j>1 && j<9 
                changeAbsor = changeAbsor + 1;
             end
        end
    end
    vSlope = sprintf(formatDiff,distAu0);                   disp(vSlope);
    vSlope = sprintf(formatDiff,distAu1);                   disp(vSlope);
    vAbsor = sprintf(formatAbsorChange,maximumAbsorChange); disp(vAbsor);
    vAbsor = sprintf(formatAbsor,absorbData0(1,:));         disp(vAbsor);
    vAbsor = sprintf(formatAbsor,absorbData1(1,:));         disp(vAbsor);
    vAbsor = sprintf(formatAbsor,absorbData2(1,:));         disp(vAbsor);
       
    %% send new abssortion values (if any of the error exceeds the threshold)
    if changeAbsor > 0 %|| abs(factorMeanValue-1.0) > 0.01
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
       delete (ISMFile.name);
       movefile (nameFileISM, "ISM_DpMax.wav");

       AudioFile=ISMFile.name;
       [t_ISM,Fs] = audioread(AudioFile);
    else
       fitSlopes=true;
    end
    % disp(message);
    % pause (1)
%% ----------- ------------------
    b = mod(iLoop,1 ) ;
    if (b==0)|| (fitSlopes == true) || (iLoop==ITER_MAX-1)
        % actual folder
        current_folder = pwd;
        % new folder
        new_folder = num2str(iLoop);
        mkdir( current_folder, new_folder);
        % save slopes and absortions
        nameFile= 'FiInfError';
        save(fullfile( current_folder,   nameFile), 'distAu');
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
    Sn(iLoop, :) = distAu;
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

