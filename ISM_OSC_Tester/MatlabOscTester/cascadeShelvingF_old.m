%% This script, from the coefficients of the inverse matrix B 
%% (created from: generateShelMatrix) and a gain profile, generates the 
%% coefficients of the "peak and night" filters for a cascade of filters

% Authors: Fabian Arrebola (21/05/2024) 
% contact: areyesa@uma.es
% 3DDIANA research group. University of Malaga
% Project: SONICOM
% 
% Copyright (C) 2024 Universidad de Málaga

addpath 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\ISM_OSC_Tester\MatlabOscTester';
%% Folder with Binv Matrix
nameFolder='\workFolder';
resourcesFolder = 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\';
workFolder = strcat(resourcesFolder,nameFolder);
%% Load Binv matrix
cd (workFolder);
load ("matrixBinv.mat");
%% Calculate gain profile
NF=9;              % number of frequencies
gOp = zeros (1,NF); gIni = ones(NF,1); g=zeros(1,NF);

%gIni = gIni.*0.25;    % They should come from the toolkit

gInidB = [0  -12  0  0  0  0  0  -12  0];
% gInidB = [-0.1  -0.1  -0.1  -0.1  -3 -6  -6  -6  -6 ];
gIni = db2mag (gInidB);
gOp = Binv*gIni';
%g=1./gOp;
g=gOp;

% %folderAbsor = 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\sJuntas 34m17m valorMedio 48k\5';
% %folderAbsor = 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\A108 40m20m valorMedio 48k\5';
% folderAbsor = 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\A108-L5-S2';
% cd (folderAbsor); 
% load ("FiInfAbsorb.mat");

% gIni = absorbData1(1,:);
% gOp = Binv*gIni';
% g=gOp';
% 
g(g<0)=0.01;


gdB = mag2db(g);
gMean = mean(gdB);
gdB = gdB -gMean;
g=  db2mag(gdB);
% gMean =0;

%% Initial params
Fs = 48000; NF = 9; F0=62.5;
Qs = 1/sqrt(2);      % for Shelving
Qbp = sqrt(2);       % for Peak
formatF = '%.2f';

a =zeros(NF,3); b=zeros(NF,3); 
sos=zeros(NF,6); % g=zeros(NF,1);

                                 %% LowPass (Fs,    Fc,       Q,   gain)
[b0,b1,b2,a0,a1,a2] = calculateShelCoef.LowP (Fs, F0*sqrt(2), Qs, g(1));
a(1,:)= [a0, a1, a2];
b(1,:)= [b0, b1, b2];
% sosLp = tf2sos(b(1,:),a(1,:));
% sos(1,:) = sosLp;

Fc=F0; 
for i=2:NF-1
    Fc=Fc*2;
                                %% BandPass_Valimak (Fs, Fcen,   Q,    gain)                 
    [b0,b1,b2,a0,a1,a2] = calculateShelCoef.BandP_Valimak (Fs, Fc, Qbp, g(i));
    a(i,:)= [a0, a1, a2];
    b(i,:)= [b0, b1, b2];
%     sosBp = tf2sos(b(i,:),a(i,:));
%     sos(i,:)= sosBp;
end

Fc=Fc*2;
                                %% HighPass (Fs,     Fc,        Q,    gain)
[b0,b1,b2,a0,a1, a2] = calculateShelCoef.HighP (Fs, Fc/sqrt(2), Qs, g(NF));
a(NF,:)= [a0, a1, a2];
b(NF,:)= [b0, b1, b2];
% sosHp = tf2sos(b(NF,:),a(NF,:));
% sos(NF,:) = sosHp;

% %% shelvFilt = shelvingFilter(gain,slope,cutoffFreq,type)
%  shelvFiltLP = shelvingFilter  (12,1,F0*sqrt(2),"lowpass");
%  shelvFiltHP = shelvingFilter  (12,1,Fc/sqrt(2),"highpass");
%  visualize(shelvFiltLP);
%  visualize (shelvFiltHP);

%% apply filter bank in cascade to obtain the impulse response
Impulse= zeros (1,Fs); 
Signal= zeros (1,Fs);
Signal(1) =1.0; Impulse(1) =1.0;
yFilt  = zeros (NF,Fs); Tot = zeros(NF,Fs); Partial=zeros(NF,Fs);

for n=1:NF
    Partial(n,:) = filter(b(n,:), a(n,:), Impulse);
    yFilt(n,:)   = filter(b(n,:), a(n,:), Signal); 
    Tot (n,:)    = yFilt(n,:);
    Signal       = yFilt(n,:);
end

%% Draw the graphs associated with the filter bank
T=1/Fs; N=length(Tot); n = nextpow2(N); L= 2^n; t=(0:L-1)*T; %Time vector
Y  = zeros(NF,L); mod  = zeros(NF,L); MdB=zeros(NF,L);  ph= zeros(NF,L); 
yP = zeros(NF,L); modP = zeros(NF,L); MPdB=zeros(NF,L); phP= zeros(NF,L); 
for i=1:NF
  y = fft(Tot(i,:), L);
  module = abs(y); phase = angle(y);
  mod(i,:) = module; ph(i,:)= phase;
  Y (i,:) = y;
  MdB(i,:)= 20*log10(mod(i,:));

  y = fft(Partial(i,:), L);
  module = abs(y); phase = angle(y);
  modP(i,:) = module; phP(i,:)= phase;
  yP (i,:) = y;
  MPdB(i,:)= 20*log10(mod(i,:));
end

f = Fs*(0:L-1)/L;
figure;
for i=1:NF
   subplot(NF,2, 2*(i-1)+1); 
   semilogx(f,mod(i,:));
   xlim([10 24000]);    grid;
   subplot(NF,2,2*i); 
   semilogx(f,MdB(i,:));
   xlim([10 24000]);    grid;
end

figure; hold on;
semilogx(f,MdB(1,:))
xlim([10 24000]);
for i=1:NF
    semilogx(f,MdB(i,:));
    grid on;  set(gca, 'XScale', 'log');
end
%str= ['Equaliz ', ' Qs= ', num2str(Qs, formatF), ' Qbp= ', num2str(Qbp, formatF), ' G= ', num2str(g, formatF)  ];
g1KHz = g(5)+gMean;
str= ['Equaliz ', ' Qs= ', num2str(Qs, formatF), ' Qbp= ', num2str(Qbp, formatF), ' G 1KHz= ', num2str(g1KHz, formatF)  ];
title(str);  xlabel('Frec (Hz)'); ylabel('Magnitude (dB)'); grid on;

figure; hold on; semilogx(f,MdB(NF,:));
grid on; xlim([10 24000]);
set(gca, 'XScale', 'log');
title(str);  xlabel('Frec (Hz)'); ylabel('Magnitude (dB)'); grid on;
%ylim ([-15 0])

%% ---------------
Tot(NF,:) = Tot (NF,:) .* db2mag (gMean);
y = fft(Tot(NF,:), L);
module = abs(y); phase = angle(y);
mod(NF,:) = module; ph(NF,:)= phase;
Y (NF,:) = y;
MdB(NF,:)= 20*log10(mod(NF,:));
semilogx(f,MdB(NF,:));
legend('Mod', 'Mod*gMean', 'Location','northeast');

% ylim ([-15 3])
%% ---------------

disp('end');