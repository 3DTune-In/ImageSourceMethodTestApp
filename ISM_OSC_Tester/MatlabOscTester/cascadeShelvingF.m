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
gCmdB = zeros (1,NF); gDesiredIni = ones(NF,1); g=zeros(1,NF);

%gDesired = gDesired.*0.25;    % They should come from the toolkit

%gDesiredIni = [0  -24  -12  0  0  0  -12  -24  0]; 
gDesiredIni = [0  0  -12  0  0 -24  -12  -24  0];
%gDesiredIni = [-30  -30  -30  -30  0  0  0  0  0];
%gDesiredIni = [ -18  -6  -12 -18  -6  -18   -9  -18  0];

folderAbsor = 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\NUEVO\8';
% %folderAbsor = 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\A108 40m20m valorMedio 48k\5';
% %folderAbsor = 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\A108-L5-S2';
%cd (folderAbsor); 
%load ("FiInfAbsorb.mat");
%gDesiredIni = 20*log10(absorbData1(1,:));
gDesiredIni = [0.75 0.5 0.5 0.5 0.75 0.5 0.5 0.5 0.75];
gDesiredIni = 20*log10(gDesiredIni);



% aIni = absorbData1(1,:);
% aIni = [0.8467, 0.1001, 0.6690, 0.3320, 0.4998, 0.7406, 0.7966, 0.6849, 0.9192];
% gDesiredIni = aIni .* -12;

gMean = mean(gDesiredIni);
gDesiredAC = gDesiredIni-gMean;
gCmdB = Binv*gDesiredAC';
gCmdLinear = db2mag(gCmdB);
g=gCmdLinear;

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
formGainD = "%.1f %.1f %.1f %.1f %.1f %.1f %.1f %.1f %.1f";
formGainC = "%.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f";

T=1/Fs; N=length(Tot); n = nextpow2(N); L= 2^n; t=(0:L-1)*T; %Time vector
Y  = zeros(NF,L); mod  = zeros(NF,L); MdB=zeros(NF,L);  ph= zeros(NF,L); 
yP = zeros(NF,L); modP = zeros(NF,L); MdBP=zeros(NF,L); phP= zeros(NF,L); 
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
  MdBP(i,:)= 20*log10(modP(i,:));

end

f = Fs*(0:L-1)/L;
figure;
for i=1:NF
   subplot(NF,2, 2*(i-1)+1); 
   semilogx(f,MdBP(i,:));
   xlim([10 24000]);    grid;
   subplot(NF,2,2*i); 
   semilogx(f,MdB(i,:));
   xlim([10 24000]);    grid;
end


figure; hold on;
semilogx(f,MdBP(1,:))
xlim([10 24000]);
for i=1:NF
    semilogx(f,MdBP(i,:));
    grid on;  set(gca, 'XScale', 'log');
end
str= ['PartialFilters ', ' Qs= ', num2str(Qs, formatF), ' Qbp= ', num2str(Qbp, formatF)];
vGainC = sprintf(formGainC,g);
title (str, "gCmdAC linear: "+ vGainC);
xlabel('Frec (Hz)'); ylabel('Magnitude (dB)'); grid on;

figure; hold on;
semilogx(f,MdB(1,:))
xlim([10 24000]);
for i=1:NF
    semilogx(f,MdB(i,:));
    grid on;  set(gca, 'XScale', 'log');
end
str= ['SerialFilter ', ' Qs= ', num2str(Qs, formatF), ' Qbp= ', num2str(Qbp, formatF)];
vGainC = sprintf(formGainC,g);
title (str, "gCmdAC linear: "+ vGainC);
xlabel('Frec (Hz)'); ylabel('Magnitude (dB)'); grid on;

figure; hold on; semilogx(f,MdB(NF,:));
grid on; xlim([10 24000]);
set(gca, 'XScale', 'log');
xlabel('Frec (Hz)'); ylabel('Magnitude (dB)'); grid on;

vGainD = sprintf(formGainD,gDesiredIni);
vGainC = sprintf(formGainC,gCmdB);
title ("Desired: "+ vGainD,"gCmd in dB: "+ vGainC);

%ylim ([-15 0])

%% ---------------
Tot(NF,:) = Tot (NF,:) .* db2mag (gMean);
y = fft(Tot(NF,:), L);
module = abs(y); phase = angle(y);
mod(NF,:) = module; ph(NF,:)= phase;
Y (NF,:) = y;
MdB(NF,:)= 20*log10(mod(NF,:));
semilogx(f,MdB(NF,:),'--.');
legend('Mod AC', 'Mod', 'Location','northeast');

% ylim ([-15 3])
%% ---------------

disp('end');