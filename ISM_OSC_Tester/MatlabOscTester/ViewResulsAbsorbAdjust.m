%% This script shows the intermediate and final graphical results 
%% derived from the process of adjusting the absorption values. 
%% The energy factor for the hybrid method is also obtained.
%% (this script replaces EnergyFactor_9Bands_Visual_Fit.m)

% Author: Fabian Arrebola (17/10/2023) 
% contact: areyes@uma.es
% 3DDIANA research group. University of Malaga
% Project: SONICOM
% 
% Copyright (C) 2023 Universidad de Málaga

%% As input parameters are taken:
%% a) Impulse response obtained by the ISM with a sufficiently high 
%%    reflection order 
%% b) BRIR of the room to be simulated (BRIR.wav IR obtained by 
%%    convolution and windowing with a pruning distance of 1 meter).
%% N = DpMax-DpMin+1;
%% DpMin = Initial pruning distance
%% DpMax = Final pruning distance
%% DpMinFit = first distance value to carry out the process of fitting the 
%% slopes of the energy factors

%% Output
%  'EnergyFactor.mat'     <--  'FactorMeanValue'

%% PRUNING DISTANCES &  Configuration parameters for ISM 
cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\SeriesIr';
% cd 'C:\Repos\HIBRIDO PRUEBAS\New LAB 28 2 20';
load ("DistanceRange.mat");
load ("ParamsISM.mat")

x=[DpMin:1:DpMax];               % Initial and final pruning distance

%% Channel
L=1; R=2;         % Channels
%% C= L or R;     % Channel to carry out the adjustment (ParamsISM.mat)


%% Folder with impulse responses
cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\SeriesIr\12';
% cd 'C:\Repos\HIBRIDO PRUEBAS\New LAB 28 2 20\0'
% cd 'C:\Repos\HIBRIDO PRUEBAS\New LAB 32 2 20\12'
load ("FiInfAbsorb.mat");
load ("FiInfSlopes.mat");


%%   BANDS
%    62,5    125     250      500      1000       2000       4000       8000       16000
% B =[44 88; 89 176; 177 353; 354 707; 708 1414; 1415 2828; 2829 5657; 5658 11314; 11315 22016;];

%%   9 BANDS
NB=9;
B =[44 88; 89 176; 177 353; 354 707; 708 1414; 1415 2828; 2829 5657; 5658 11314; 11315 22016;];
Blo=[ 1    89      177      354      708       1415       2829       5658        11315       ];
Bhi=[  88     176      353      707      1414       2828       5657       11314        22016 ];

%% Number of Impulse Responses
NumIRs = DpMax-DpMin+1;

%% Read file with BRIR
BRIRFile=dir(['BRIR*.wav']);  %BRIR obtained with a pruning distance of 1 meter
AudioFile=BRIRFile.name;
[t_BRIR,Fs] = audioread(AudioFile);

%% Read file with ISM
ISMFile=dir(['ISM*.wav']);      %ISM obtained with a pruning max distance 
AudioFile=ISMFile.name;
[t_ISM,Fs] = audioread(AudioFile);

%% BRIR Energy
%%%%%%%%%%%%%%%%
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

%% -------
%% BRIR Energy for each band
E_BandBrir=zeros(NB,2);
%eSumBands=zeros(1,1); %checksum
eSumBands=0; %checksum
for j=1:NB
    %eSumBands = eSumBands+E_BandWin(j,i,:);
    e = calculateEnergyBand(Fs, t_BRIR, Blo(j), Bhi(j))/length(t_BRIR);  %/(Bhi(j)-receiver.stopListening();Blo(j)+1);
    E_BandBrir(j,:) = e;
    eSumBands = eSumBands+E_BandBrir(j,:);
end
eSumBands= squeeze(eSumBands);
%% --------------------------                    % FIGURE 1 -- Total: ISM, Windowed, BRIR-Windowed
figure; hold on;                                 
eL_Ism  = zeros(NumIRs,1);
eL_Win  = zeros(NumIRs,1);
eL_BRIR_W = zeros(NumIRs,1);
eL_Ism = e_TotalIsm(:,C);   % Ism without direct path
eL_Win = e_TotalWin(:,C);   % Reverb files (hybrid windowed order 0 with no direct path)eL_Ism
%eL_Total=e_Total([1:1:length(e_Total)],1);      % TOTAL Ism+Rever sin camino directo

plot (x, eL_Ism,'r--*');   %Ism
plot (x, eL_Win,'g--o');   % Windowed
%plot (x,eL_Total,'b--+'); % Total
grid;

eL_BRIR_W(:,1) = eBRIR_L*ones(length(NumIRs))-eL_Win;
plot (x, eL_BRIR_W,'k--x');
%ylim([0.0 0.8]);
xlabel('Distance (m)');  
ylabel('Energy'); 
title('Total Energy vs Pruning Distance');  
legend('E.Ism',  'E.win','E.RIR-E.win',  'Location','northwest');
%% -----------------------------                 % FIGURE 2 -- Total Factor
figure; 
Factor = zeros(NumIRs,1);
Factor = sqrt (eL_Ism ./ eL_BRIR_W);
plot (x, Factor,'b--*');
%% ylim([0.0 1.2]);

FactorMeanValue=0;
for j=DpMinFit:(DpMax-DpMin)+1
    FactorMeanValue = FactorMeanValue+Factor(j,1);
end
FactorMeanValue = FactorMeanValue/(DpMax-DpMinFit);

xlabel('Distance (m)');  
ylabel('Factor'); 
title('Factor (total) vs Pruning Distance');
%% RGain = RGain_Linear*EnergyFactor;
%RGain = FactorMeanValue*db2mag(RGain_dB); 
formatLegendFactor= "Factor: %.3f -- RGain(dB): %.1f";
legengFactor = sprintf(formatLegendFactor, FactorMeanValue, RGain_dB);  
%legend('SQRT(eTotalIsm/(eRIR-eTotalwin))', 'Location','southeast');
legend(legengFactor, 'Location','southeast');

save ('EnergyFactor.mat','FactorMeanValue');

grid;
%% -----------------------------                 % FIGURE 3 -- Partial: ISM, Windowed, BRIR-Windowed
figure; hold on;                                 
for j=1:NB
    subplot(NB,3,3*j-2);
    y=  E_BandIsm(j,:,C);
    plot (x,y,'r--.');   %Ism
    legend('e-BandIsm', 'Location','northwest');
    ylim([0.0 0.1]);
    %% ylim([0.0 0.01*j]);    grid;
    
    subplot(NB,3,3*j-1);
    y= E_BandWin(j,:,C);
    plot (x,y,'g--.');   % Windowed
    legend('e-BandWin', 'Location','northeast');
    ylim([0.0 0.1]);
    %% ylim([0.0 0.01*j]);    grid;

    subplot(NB,3,3*j);
    eBand=E_BandBrir(j,C);
    y= E_BandWin(j,:,C);
    E_BandBrir_Win(j,:,C)=eBand(1,1)*ones(1, length(NumIRs))-y;
    plot (x, E_BandBrir_Win(j,:,C) ,'b--.');   % Brir-Windowed
    legend('e-Rir-Win', 'Location','southeast');
    ylim([0.0 0.1]);
    %% ylim([0.0 0.01*j]);    grid;
end
% %% color map
% c= [0.3333, 0.0 ,0.5; 0.6667, 0, 0.5; 1.0000, 0, 0.5; 1.0000, 0.3333, 0.5; 1.0000, 0.6667,0.5;
%     1.0000, 0.5000, 0;  1.0000, 0.0000, 0.5000; 0.0000, 0.3333, 1.0000; 0.0000, 0.6667, 0.5000];
% colormap(c);
%% -----------------------------                  % FIGURE 4 -- Factor per Band
figure; hold on;                                  
factorBand =zeros(NB, NumIRs,2);
for j=1:NB
    eBand=E_BandBrir(j,C);
    y= E_BandWin(j,:,C);
    E_BandBrir_Win(j,:,C)=eBand(1,1)*ones(1, length(NumIRs))-y;
    factorBand(j,:,C) = sqrt(E_BandIsm (j,:,C) ./ E_BandBrir_Win(j,:,C)); 
    plot (x, factorBand(j,:,C),"LineWidth",1.5);   % ,'color', [c(j,1) c(j,2) c(j,3)]
end
grid;
%% ylim([0.0 3.5]);
xlabel('Distance (m)');  ylabel('Factor'); 
legend( 'B1','B2','B3','B4', 'B5','B6','B7','B8','B9','Location','northeast');
title('Factor per Band vs Pruning Distance');  


%% Curve Fitting                                   % FIGURE 5 -- Fit for each Band     
xf=[DpMinFit:1:DpMax]; % from 10 meters to the end
figure; hold on;                                     
leg = {'B1', 'a1','B2', 'a2','B3','a3','B4','a4','B5', 'a5','B6','a6','B7','a7','B8','a8','B9','a9'};

%fitObj= cfit.empty(0,NB); % Create empty array of specified class cfit
%cfitData = struct(cfit);
%cfitArray = repmat (cfitData, 1, NB);

gof = struct([]);                                   % Create empty struct
gofplus = struct('gof', gof , 'p1', 0, 'p2', 0);    % Create struct to load data per band
gofpArray = repmat (gofplus, 1, NB);                % Array of structures to store information for each band

for j=1:NB
   Ff=factorBand(j, NumIRs-(DpMax-DpMinFit) : NumIRs, C);  % from 10 meters to the end
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
%% ylim([0.0 3.5]);
xlabel('Distance (m)');  ylabel('Factor'); 
legend( leg, 'Location','northwest'); grid;
title('CURVE FIT (9B)- Factor per Band vs Pruning Distance'); 
%hold off;
