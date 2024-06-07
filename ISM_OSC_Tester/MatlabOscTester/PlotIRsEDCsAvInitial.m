%% This script shows the intermediate and final graphical results
%% corresponding to applying the hybrid method (ISM+convolution) 

% Author: Fabian Arrebola (14/05/2024) 
% contact: areyes@uma.es
% 3DDIANA research group. University of Malaga
% Project: SONICOM
% 
% Copyright (C) 2023 Universidad de Málaga

%% Set folder with IRs and Params
cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\4';
% cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\sJuntas 34m17m valorMedio\7';
%% cd 'C:\Repos\HIBRIDO PRUEBAS\New LAB 40 2 24\16'


%% Load info
load ("ParamsISM.mat");
load ("FiInfAbsorb.mat");
load ("FiInfSlopes.mat");
load ("EnergyFactor.mat");

%% Set working folder
cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder';
%cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\sJuntas 34m17m valorMedio';
load ("ParamsHYB.mat");

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
formatFileISM= "iIrRO%iDP%02iW%02i";
nameFileISM = sprintf(formatFileISM, RefOrd, Dp_Tmix, W_Slope)+'.wav';

formatFileWin= "wIrRO0DP%02iW%02i";
nameFileWin = sprintf(formatFileWin, Dp_Tmix, W_Slope)+'.wav';

formatFileHyb= "tIrRO%iDP%02iW%02i";
nameFileHyb = sprintf(formatFileHyb, RefOrd, Dp_Tmix, W_Slope)+'HYB.wav';

%formatFileBRIR= "wIrRO0DP01W02";
formatFileBRIR= "BRIR";
nameFileBRIR = sprintf(formatFileBRIR)+'.wav';
[yBRIR,Fs] = audioread(nameFileBRIR);
[Ism,Fs] = audioread(nameFileISM);
[Hybrid,Fs] = audioread(nameFileHyb);

peak1 = find(Hybrid(:,1).^2==max(Hybrid(:,1).^2));
peak2 = find(Hybrid(:,2).^2==max(Hybrid(:,2).^2));

%rt =zeros (1,3);edt =zeros (1,3);
[rt,drr,cte,cfs,edt] = iosr.acoustics.irStats(nameFileBRIR, 'graph', true);
[rt,drr,cte,cfs,edt] = iosr.acoustics.irStats(nameFileHyb,  'graph', true);
% [rt,drr,cte,cfs,edt] = iosr.acoustics.irStats(nameFileISM,  'graph', true);

% vMaxB = max(abs(yBRIR(:,1))); 
vMaxB = max(abs(yBRIR(:))); 
vMaxH = max(abs(Hybrid(:)));
vMax = max( vMaxB , vMaxH);
Max =   max (vMax);

figure; 
subplot(2,1,1); hold on; grid on;
plot (yBRIR(:,1), 'b'); 
plot (yBRIR(:,2), 'r');
ylim ([-Max, Max]);
legend( 'BRIR_L','BRIR_R','Location','northeast');
title('BRIR'); xlabel('Samples'); 

subplot(2,1,2); hold on; grid on;
plot (Hybrid(:,1), 'b');
plot (Hybrid(:,2), 'r');
ylim ([-Max, Max]);
legend( 'Hybrid_L','Hybrid_R','Location','northeast');
str= ["Hybrid "+ num2str(Room) ]; title(str); xlabel('Samples');

N1 = length(yBRIR);
N2 = length(Hybrid);
N = min( N1,N2);

y= yBRIR(:,1);
temp = cumtrapz(y(end:-1:1).^2); % decay curve
EDCyBRIR(:,1) = temp(end:-1:1);
y= yBRIR(:,2);
temp = cumtrapz(y(end:-1:1).^2); % decay curve
EDCyBRIR(:,2) = temp(end:-1:1);

y= Ism(:,1);
temp = cumtrapz(y(end:-1:1).^2); % decay curve
EDCIsm(:,1) = temp(end:-1:1);
y= Ism(:,2);
temp = cumtrapz(y(end:-1:1).^2); % decay curve
EDCIsm(:,2) = temp(end:-1:1);

y= Hybrid(:,1);
temp = cumtrapz(y(end:-1:1).^2); % decay curve
EDCHybrid(:,1) = temp(end:-1:1);
y= Hybrid(:,2);
temp = cumtrapz(y(end:-1:1).^2); % decay curve
EDCHybrid(:,2) = temp(end:-1:1);

%%%%%%%%%%%%%%%%%% 
vMaxB = max(abs(EDCyBRIR(:))); 
vMaxH = max(abs(EDCHybrid(:)));
vMax = max( vMaxB , vMaxH);
Max =   max (vMax);

EDCyBRIRdB = 10.*log10(EDCyBRIR);           % dB dB
EDCyBRIRdB = EDCyBRIRdB-max(EDCyBRIRdB);    % normalise to max 0
EDCHybriddB =10.*log10(EDCHybrid);          % dB dB
EDCHybriddB = EDCHybriddB-max(EDCHybriddB); % normalise to max 0


%%%%%%%%%%%%%%%%%%
figure; grid on;
subplot(2,1,1); hold on; grid on;
% plot (EDCyBRIR(1:N,1),'b');
% plot (EDCyBRIR(1:N,2),'r');
plot (EDCyBRIRdB(1:N,1),'b');
plot (EDCyBRIRdB(1:N,2),'r');

legend( 'BRIR_L','BRIR_R','Location','northeast');
str= [ 'EDC BRIR ']; title(str);
ylabel('Energy decay'); xlabel('Samples');
ylim([-60 0]);

subplot(2,1,2); hold on; grid on;
plot (EDCHybriddB(1:N,1),'b');
plot (EDCHybriddB(1:N,2),'r');
legend( 'Hybrid_L','Hybrid_R','Location','northeast');
str= [ "EDC Hybrid "+ num2str(Room) ]; title(str);
ylabel('Energy decay'); xlabel('Samples');
ylim([-60 0]);

figure; hold on; grid on;
EDCyBRIRdB(:,1) = 10*log10(EDCyBRIR(:,1)./EDCyBRIR(1,1));
plot(EDCyBRIRdB (1:N,1), 'b');
EDCyBRIRdB(:,2) = 10*log10(EDCyBRIR(:,2)./EDCyBRIR(1,2));
plot(EDCyBRIRdB (1:N,2), 'r');

EDCHybriddB(:,1) = 10*log10(EDCHybrid(:,1)./EDCHybrid(1,1));
plot(EDCHybriddB(1:N,1), '--b');
EDCHybriddB(:,2) = 10*log10(EDCHybrid(:,2)./EDCHybrid(1,2));
plot(EDCHybriddB(1:N,2), '--r');

legend( 'BRIR_L','BRIR_R','Hybrid_L','Hybrid_R','Location','northeast');
ylabel('Energy decay [dB]'); xlabel('Samples');

ylim([-60 0]);
str= [ "EDC BRIR vs Hybrid " + num2str(Room) ]; title(str);
