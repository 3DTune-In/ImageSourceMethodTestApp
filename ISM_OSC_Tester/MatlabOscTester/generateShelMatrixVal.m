%% This script generates the coefficients of the inverse matrix associated 
%% with a cascade filter bank of the "peak and night" type 
%% (the low pass and the high pass are of the shelving type)

% Authors: Fabian Arrebola (21/05/2024) 
% contact: areyesa@uma.es
% 3DDIANA research group. University of Malaga
% Project: SONICOM
% 
% Copyright (C) 2024 Universidad de Málaga

addpath 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\ISM_OSC_Tester\MatlabOscTester';
%% Folder where to save the inverse matrix of coefficients
nameFolder='\workFolder';
resourcesFolder = 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\';
workFolder = strcat(resourcesFolder,nameFolder);
%% Initial params
Fs = 48000; NF = 9; F0=62.5;
Qs = 1/sqrt(2);      % for Shelving
Qbp = sqrt(2);   % for Peak
formatF = '%.2f';

a =zeros(NF,3); b=zeros(NF,3); Fc = zeros (1,NF);
sos=zeros(NF,6); % G=zeros(NF,1);

G=4;
Fcent(1)= F0;
                                 %% LowPass (Fs,    Fc,       Q,   gain)
[b0,b1,b2,a0,a1,a2] = calculateShelCoefVal.LowP_Valimak (Fs, F0*sqrt(2), Qs, G);
a(1,:)= [a0, a1, a2];
b(1,:)= [b0, b1, b2];
sosLp = tf2sos(b(1,:),a(1,:));
sos(1,:) = sosLp;

Fc=F0; 
for i=2:NF-1
    Fc=Fc*2; Fcent(i)=Fc;
                                %% BandPass_Valimak (Fs, Fcen,   Q,    gain)                 
    [b0,b1,b2,a0,a1,a2] = calculateShelCoefVal.BandP_Valimak (Fs, Fc, Qbp, G);
    a(i,:)= [a0, a1, a2];
    b(i,:)= [b0, b1, b2];
    sosBp = tf2sos(b(i,:),a(i,:));
    sos(i,:)= sosBp;
end

Fc=Fc*2; Fcent(NF)=Fc;
                                %% HighPass (Fs,     Fc,        Q,    gain)
[b0,b1,b2,a0,a1, a2] = calculateShelCoefVal.HighP_Valimak (Fs, Fc/sqrt(2), Qs, G);
a(NF,:)= [a0, a1, a2];
b(NF,:)= [b0, b1, b2];
sosHp = tf2sos(b(NF,:),a(NF,:));
sos(NF,:) = sosHp;

% %% shelvFilt = shelvingFilter(gain,slope,cutoffFreq,type)
%  shelvFiltLP = shelvingFilter  (12,1,F0*sqrt(2),"lowpass");
%  shelvFiltHP = shelvingFilter  (12,1,Fc/sqrt(2),"highpass");
%  visualize(shelvFiltLP); 
%  visualize (shelvFiltHP);

%% obtaining the impulse response of each filter
Signal= zeros (1,Fs); 
Signal(1) =1.0;
yFilt  = zeros (NF,Fs);
Tot = zeros(NF,Fs); 
for n=1:NF
    yFilt(n,:) = filter(b(n,:), a(n,:), Signal);  
    Tot (n,:) = yFilt(n,:);
end

%% obtaining the frequency response of each filter
T=1/Fs; N=length(Tot); n = nextpow2(N); L= 2^n; t=(0:L-1)*T; %Time vector
Y =zeros(NF,L); mod = zeros(NF,L); MdB=zeros(NF,L); ph= zeros(NF,L);
for i=1:NF
  y = fft(Tot(i,:), L);
  module = abs(y); phase = angle(y);
  mod(i,:) = module; ph(i,:)= phase;
  Y (i,:) = y;
  MdB(i,:)= 20*log10(mod(i,:));
end

%% plot
f = Fs*(0:L-1)/L;
figure;
for i=1:NF
   subplot(NF,2, 2*(i-1)+1);    semilogx(f,mod(i,:));
   xlim([10 24000]);    grid;
   subplot(NF,2,2*i);           semilogx(f,mod(i,:));
   xlim([10 24000]);    grid;
end

figure; hold on;
semilogx(f,MdB(1,:))
xlim([10 24000]);
for i=2:NF
    semilogx(f,MdB(i,:));
    grid on;
    set(gca, 'XScale', 'log');
   end
str= ['Equaliz ', ' Qs= ', num2str(Qs, formatF), ' Qbp= ', num2str(Qbp, formatF), ' G= ', num2str(G, formatF)  ];
title(str);  xlabel('Frec (Hz)'); ylabel('Magnitude (dB)'); grid on;


%% Generate the inverse matrix for subsequent calculation of the gain profile 
B = zeros( NF, NF);
for i=1:NF
    for j=1:NF
        col = floor(Fcent(j)*L/Fs);
        B(i,j) = MdB (i, col)/(20*log10(G));
        % B(i,j) = mod (i, col)/G;
    end
end
MaxB = max(B(:));
% B= B./MaxB;

Binv = inv (B);

%% save Binv matrix
cd (workFolder); 
save ('matrixBinv.mat','Binv');

disp('end');