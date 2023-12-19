%% This script shows the intermediate and final graphical results
%% corresponding to applying the hybrid method (ISM+convolution) 

% Author: Fabian Arrebola (19/10/2023) 
% contact: areyes@uma.es
% 3DDIANA research group. University of Malaga
% Project: SONICOM
% 
% Copyright (C) 2023 Universidad de Málaga
 
%% Set folder with IRs and Params
cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\12';
%% cd 'C:\Repos\HIBRIDO PRUEBAS\New LAB 40 2 24\16'


%% Load info
load ("ParamsISM.mat");
load ("FiInfAbsorb.mat");
load ("FiInfSlopes.mat");
load ("EnergyFactor.mat");

%% Set working folder
cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder';
load ("ParamsHYB.mat");

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
formatFileISM= "iIrRO%iDP%02iW%02i";
nameFileISM = sprintf(formatFileISM, RefOrd, Dp_Tmix, W_Slope)+'.wav';

formatFileWin= "wIrRO0DP%02iW%02i";
nameFileWin = sprintf(formatFileWin, Dp_Tmix, W_Slope)+'.wav';

formatFileHyb= "tIrRO%iDP%02iW%02i";
nameFileHyb = sprintf(formatFileHyb, RefOrd, Dp_Tmix, W_Slope)+'HYB.wav';

formatFileBRIR= "wIrRO0DP01W02";
nameFileBRIR = sprintf(formatFileBRIR)+'.wav';
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[yBRIR,Fs] = audioread(nameFileBRIR);
[Ism,Fs] = audioread(nameFileISM);
[Wind,Fs] = audioread(nameFileWin);
[Hybrid,Fs] = audioread(nameFileHyb);
%[HybridRT, Fs] = audioread (nameFileRT);

ySum=Ism+Wind;
%ySum=HybridRT;

%yBRIR_2 = yBRIR.^2;
yBRIR_2 = yBRIR.^2;
Ism_2 = Ism.^2;
Wind_2 = Wind.^2;
ySum_2 = ySum.^2;
Hybrid_2 = Hybrid.^2;

% yBRIR_a = (yBRIR_2(:,1) + yBRIR_2(:,2))./2;
% Ism_a = (Ism_2(:,1) + Ism_2(:,2))./2;
% Wind_a = (Wind_2(:,1) + Wind_2(:,2))./2;
% ySum_a = (ySum_2(:,1) + ySum_2(:,2))./2;
% Hybrid_a = (Hybrid_2(:,1) + Hybrid_2(:,2))./2;

EDCyBRIR  = zeros(length(yBRIR),2);
EDCyBRIRdB= zeros(length(yBRIR),2);
N= length(yBRIR);
for I= 1:N
   EDCyBRIR(I,1) = sum (yBRIR_2(I:N,1)) / (N);
   EDCyBRIR(I,2) = sum (yBRIR_2(I:N,2)) / (N);
end
   
EDCIsm= zeros(length(yBRIR),2);
N= length(Ism);
for I= 1:N
   EDCIsm(I,1) = sum (Ism_2(I:N,1)) / (N);
   EDCIsm(I,2) = sum (Ism_2(I:N,1)) / (N);
end

EDCWind= zeros(length(yBRIR),2);
N= length(Wind);
for I= 1:N
   EDCWind(I,1) = sum (Wind_2(I:N,1)) / (N);
   EDCWind(I,2) = sum (Wind_2(I:N,2)) / (N);
end

EDCySum= zeros(length(yBRIR),2);
N= length(ySum);
for I= 1:N
   EDCySum(I,1) = sum (ySum_2(I:N,1)) / (N);
   EDCySum(I,2) = sum (ySum_2(I:N,2)) / (N);
end

EDCHybrid= zeros(length(yBRIR),2);
EDCHybriddB= zeros(length(yBRIR),2);
N= length(Hybrid);
for I= 1:N
   EDCHybrid(I,1) = sum (Hybrid_2(I:N,1)) / (N);
   EDCHybrid(I,2) = sum (Hybrid_2(I:N,2)) / (N);
end

subplot(2,5,1);
plot (yBRIR(1:30000));
ylim([-0.08 0.08]);
title('BRIR.WAV');

subplot(2,5,2);
plot (Ism(1:30000));
ylim([-0.08 0.08]);
title('ISM');

subplot(2,5,3);
plot (Wind(1:30000));
ylim([-0.08 0.08]);
title('Wind');

subplot(2,5,4);
plot (ySum(1:30000));
title('Sum');
ylim([-0.08 0.08]);

subplot(2,5,5);
plot (Hybrid(1:30000));
title('Hybrid');
ylim([-0.08 0.08]);

subplot(2,5,6);
plot (EDCyBRIR(1:30000,1));
plot (EDCyBRIR(1:30000,2));
title('EDC-BRIR');
%ylim([0.0 2e-5]);

subplot(2,5,7);
plot (EDCIsm(1:30000,1));
plot (EDCIsm(1:30000,2));
title('EDC-ISM');
%ylim([0.0 2e-5]);

subplot(2,5,8);
plot (EDCWind(1:30000,1));
plot (EDCWind(1:30000,2));
title('EDC-WIND');
%ylim([0.0 2e-5]);

subplot(2,5,9);
plot (EDCySum(1:30000,1));
plot (EDCySum(1:30000,2));
title('EDC-Sum');
%ylim([0.0 2e-5]);

subplot(2,5,10);
plot (EDCHybrid(1:30000,1));
plot (EDCHybrid(1:30000,2)); 
title('EDCHybrid');
%ylim([0.0 2e-5]);

figure; 
hold on;
plot (EDCyBRIR(1:30000,1),'b');
plot (EDCyBRIR(1:30000,2),'--b');

plot (EDCHybrid(1:30000,1),'r');
plot (EDCHybrid(1:30000,2),'--r');
legend( 'BRIR_L','BRIR_R','Hybrid_L','Hybrid_R','Location','northeast');
title('EDC BRIR vs Hybrid');
ylabel('Energy decay');
xlabel('Samples');
%ylim([0.0 1e-4]);

figure;
hold on;
plot (yBRIR(1:30000,1), 'b');
plot (yBRIR(1:30000,2), '--b');

plot (Hybrid(1:30000,1), 'r');
plot (Hybrid(1:30000,2), '--r');
legend( 'BRIR_L','BRIR_R','Hybrid_L','Hybrid_R','Location','northeast');
% plot (ySum(1:30000));
title('IRs: BRIR vs Hybrid');
xlabel('Samples');
hold off;

figure;
hold on;
EDCyBRIRdB(:,1) = 10*log10(EDCyBRIR(:,1)./EDCyBRIR(1,1));
plot(EDCyBRIRdB (1:44000,1), 'b');
EDCyBRIRdB(:,2) = 10*log10(EDCyBRIR(:,2)./EDCyBRIR(1,2));
plot(EDCyBRIRdB (1:44000,2), '--b');

EDCHybriddB(:,1) = 10*log10(EDCHybrid(:,1)./EDCHybrid(1,1));
plot(EDCHybriddB(1:44000,1), 'r');
EDCHybriddB(:,2) = 10*log10(EDCHybrid(:,2)./EDCHybrid(1,2));
plot(EDCHybriddB(1:44000,2), '--r');

legend( 'BRIR_L','BRIR_R','Hybrid_L','Hybrid_R','Location','northeast');
%EDCySumdB = 10*log10(EDCySum./EDCySum(1));
%plot(EDCySumdB(1:44000), 'k');

ylabel('Energy decay [dB]');
xlabel('Samples');
title('EDC BRIR vs Hybrid');