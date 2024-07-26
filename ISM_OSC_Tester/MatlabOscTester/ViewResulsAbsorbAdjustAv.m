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
cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder';
%cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\sJUNTAS CASCADE 20FIT';
%cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\A108 CASCADE 20FIT';
load ("DistanceRange.mat");
load ("ParamsISM.mat");


x=[DpMin:1:DpMax];               % Initial and final pruning distance

L=1; R=2;                        % Channel

%% Folder with impulse responses
%cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\7';
%cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\sJUNTAS CASCADE 20FIT\10';
%cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\A108 CASCADE 20FIT\9';
cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\A108 Omni\7';

load ("FiInfAbsorb.mat");
load ("FiInfSlopes.mat");

colormap =[0.6350 0.0780 0.1840; 0 1 0; 0 0 1; 0 1 1; 1 0 1; 1 0 0; 0 0 0; 0.9290 0.6940 0.1250; 0.4660 0.6740 0.1880 ];

%%   BANDS
%    62,5    125     250      500      1000       2000       4000       8000       16000
% B =[44 88; 89 176; 177 353; 354 707; 708 1414; 1415 2828; 2829 5657; 5658 11314; 11315 22016;];

%%   9 BANDS
Nf=48000;
NB=9;
B =[44 88; 89 176; 177 353; 354 707; 708 1414; 1415 2828; 2829 5657; 5658 11314; 11315 22050;];
Blo=[ 1    89      177      354      708       1415       2829       5658        11315       ];
Bhi=[  88     176      353      707      1414       2828       5657       11314        22630 ];

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
%% Only one channel 
% eBRIR_L= e_BRIR(L); eBRIR_R= e_BRIR(R);
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
     E_TotalIsm2= calculateEnergyBandWr(Nf, ir_Ism, Blo(1), Bhi(NB))/Nf;         %length(ir_Ism);                            
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
     E_TotalWin2= calculateEnergyBandWr(Nf, ir_Win, Blo(1), Bhi(NB))/Nf;         %length(ir_Ism); %(Bhi(NB)-Blo(1)+1); 
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
         e = calculateEnergyBand   (Nf, ir_Brir, Blo(j), Bhi(j))/ Nf;
         e2 =calculateEnergyBandWr (Nf, ir_Brir, Blo(j), Bhi(j))/ Nf;
         E_BandBrirDir(j,i,:) = e;
         eSumBandsD= eSumBandsD+E_BandBrirDir(j,i,:);
     end
     eSumBandsD= squeeze(eSumBandsD);
     maxDistSL = maxDistSL+1;
end

%% -------
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
eA_Ism  = zeros(NumIRs,1);
eA_Win  = zeros(NumIRs,1);
eA_BRIR_W = zeros(NumIRs,1);
%% Only one channel
eL_Ism = e_TotalIsm(:,L);   % Ism without direct path
eR_Ism = e_TotalIsm(:,R);   % Ism without direct path
%% Average of both channels
eA_Ism = (e_TotalIsm(:,L)+e_TotalIsm(:,R))./2;   % Ism without direct path
eA_Win = (e_TotalWin(:,L)+e_TotalWin(:,R))./2;   % Reverb files (hybrid windowed order 0 with no direct path)
eA_Brir= (e_TotalBrir(:,L)+e_TotalBrir(:,R))./2;

plot (x, eL_Ism,'b--.');   % Ism
plot (x, eR_Ism,'r--.');   % Ism

plot (x, eA_Ism,'m--.');   % Ism
%plot (x, eA_Win,'g--o');   % Windowed
%plot (x,eL_Total,'b--+'); % Total
grid;

eA_BRIR_W(:,1) = eBRIR_A*ones(length(NumIRs))-eA_Win;
plot (x, eA_Brir,'k--.');
plot (x, eA_BRIR_W,'ko');
%ylim([0.0 0.8]);
xlabel('Distance (m)');  
ylabel('Energy'); 
title('Total Energy vs Pruning Distance');  
legend ('E.IsmL','E.IsmR','E.IsmAv','E.Brir.Dir','E.Brir.Ind', 'Location','northwest');
%% -----------------------------                 % FIGURE 2 -- Total eFactor
figure; hold on;                                     
FactorI = sqrt (eA_Ism ./ eA_BRIR_W);
FactorD = sqrt (eA_Ism ./ eA_Brir);
plot (x, FactorD,'k--.');
plot (x, FactorI,'ko');
%% ylim([0.0 1.2]);

FCropI = FactorI(DpMinFit:DpMax-DpMin+1);
factorMeanValueI = mean(FCropI);
FCropD = FactorD(DpMinFit:DpMax-DpMin+1);
factorMeanValueD = mean(FCropD);
%% -----------------------------
Factor = FactorD;                    % for adjustment (FactorI: BRIR-Win)
factorMeanValue = factorMeanValueD;  % for adjustment (factorMeanValueI)

xlabel('Distance (m)');  
ylabel('Factor'); 
title('Factor (total) vs Pruning Distance');
%% RGain = RGain_Linear*EnergyFactor;
formatLegendFactor= "FactorD: %.3f -- RGain(dB): %.1f";
legengFactor = sprintf(formatLegendFactor, factorMeanValue, RGain_dB);  
%legend('SQRT(eTotalIsm/(eRIR-eTotalwin))', 'Location','southeast');
legend(legengFactor, 'FactorI', 'Location','southeast');

save ('EnergyFactor.mat','factorMeanValue');

grid;
%% -----------------------------                 % FIGURE 3 -- Partial: ISM, Windowed, BRIR-Windowed
figure; hold on;                                 
for j=1:NB
    subplot(NB,3,3*j-2);
    %% Only one channel
    % y=  E_BandIsm(j,:,L);
    %% Average of both channels
    y =(E_BandIsm(j,:,L)+ E_BandIsm(j,:,R))./2;
    plot (x,y,'r--.');   %Ism
    legend('e-BandIsm', 'Location','northwest');
    ylim([0.0 0.1]);
    %% ylim([0.0 0.01*j]);    grid;
    
    subplot(NB,3,3*j-1);
    %% Only one channel
    % y= E_BandWin(j,:,L);
    %% Average of both channels
    y =(E_BandWin(j,:,L)+ E_BandWin(j,:,R))./2;
    plot (x,y,'g--.');   % Windowed
    legend('e-BandWin', 'Location','northeast');
    ylim([0.0 0.1]);
    %% ylim([0.0 0.01*j]);    grid;

    subplot(NB,3,3*j);
    %% Only one channel
    % eBand=E_BandBrir(j,L);
    % y= E_BandWin(j,:,L);
    %% Average of both channels
    eBand=E_BandBrir(j,L);
    y =E_BandWin(j,:,L);
    E_BandBrir_Win(j,:,L)=abs(eBand(1,1)*ones(1, length(NumIRs))-y);
    eBand=E_BandBrir(j,R);
    y = E_BandWin(j,:,R);
    E_BandBrir_Win(j,:,R)=abs(eBand(1,1)*ones(1, length(NumIRs))-y);
    plot (x, (E_BandBrir_Win(j,:,L)+E_BandBrir_Win(j,:,R))./2);
    legend('e-Rir-Win', 'Location','southeast');
    ylim([0.0 0.1]);
    %% ylim([0.0 0.01*j]);    grid;
end

%% -----------------------------                  % FIGURE 4 -- eFactor per Band
figure; hold on;
factorBandI =zeros(NB, NumIRs,2);      % Indirect
FactorMeanBandI=zeros(1,NB);
factorBandD =zeros(NB, NumIRs,2);      % Direct
FactorMeanBandD=zeros(1,NB);

factorBand = factorBandD;              % for adjustment
FactorMeanBand=zeros(1,NB);
vMaxT=0.0;
for j=2:NB
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

    vMaxB = max (factorBandD(j,:,L));
    if (vMaxT < vMaxB) 
        vMaxT=vMaxB; 
    end
    RGB= colormap(j,:);
    %plot (x, factorBandI(j,:,L),"LineWidth",1.2, "Color", RGB );   % ,'color', [c(j,1) c(j,2) c(j,3)]
    %plot (x, factorBandD(j,:,L),"LineWidth",1.2, "Color", RGB, '--.' );   % ,'color', [c(j,1) c(j,2) c(j,3)]
    plot (x, factorBandI(j,:,L));   
    plot (x, factorBandD(j,:,L) , '--.'); 
end
grid;
ylim([0 vMaxT]);
xlabel('Distance (m)');  ylabel('Factor'); 
% legend( 'B2','B3','B4', 'B5','B6','B7','B8','B9','Location','northeast');
legend( 'B1i','B1d','B2i','B2d', 'B3i','B3d','B4i','B4d','B5i','B5d','B6i','B6d','B7i', 'B7d','B8i','B8d','B9i','B9d','Location','northeast');
title('eFactor per Band vs Pruning Distance');

%% Curve Fitting                                   % FIGURE 5 -- Fit for each Band     
xf=[DpMinFit:1:DpMax]; % from 10 meters to the end
figure; hold on;                                     
leg = {'B2', 'a2','B3','a3','B4','a4','B5', 'a5','B6','a6','B7','a7','B8','a8','B9','a9'};

%fitObj= cfit.empty(0,NB); % Create empty array of specified class cfit
%cfitData = struct(cfit);
%cfitArray = repmat (cfitData, 1, NB);

gof = struct([]);                                   % Create empty struct
gofplus = struct('gof', gof , 'p1', 0, 'p2', 0);    % Create struct to load data per band
gofpArray = repmat (gofplus, 1, NB);                % Array of structures to store information for each band

for j=2:NB
   Ff=factorBandD(j, NumIRs-(DpMax-DpMinFit) : NumIRs, L);  % from 10 meters to the end
   xft=xf'; Fft= Ff'; % transpose
      % [fitObj, gof] = fit(xft,Fft,'poly1');
   [fitObj, gofplus.gof] = fit(xft,Fft,'poly1');
      % cfitArray(j) = struct(fitObj);
   gofpArray(j).gof = gofplus.gof;
   gofpArray(j).p1  = fitObj.p1;
   gofpArray(j).p2  = fitObj.p2;
      % disp(fitObj)  % disp(cfitArray(j)); 
      % fitObj.p1;    % cfitArray(j).coeffValues(1,1);

   p=plot(fitObj, xft, Fft, '--o');
   RGB= colormap(j,:);
   p(2,1).Color = RGB; p(1,1).Color = RGB; p(1,1).LineWidth=1.25;
end   
ylim([0 vMaxT]);
xlabel('Distance (m)');  ylabel('Factor'); 
legend( leg, 'Location','northwest'); grid;
title('CURVE FIT (9B)- Factor per Band vs Pruning Distance'); 
%hold off;
