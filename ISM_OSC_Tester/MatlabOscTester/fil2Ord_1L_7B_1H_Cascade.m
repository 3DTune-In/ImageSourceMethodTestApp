%% This script generates and draws the frequency spectrum of a 
%% Butterwoth filter bank 1 Low Pass 7 BandPass and 1 High Pass

% Authors: Fabian Arrebola (09/05/2024) 
% contact: areyesa@uma.es
% 3DDIANA research group. University of Malaga
% Project: SONICOM
% 
% Copyright (C) 2024 Universidad de Málaga


% cd  'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder';
cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\A108 40m20m valorMedio\6';
%cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\sJuntas 34m17m valorMedio\7';

str= pwd; s = str(90:end); disp (s);
load ("FiInfAbsorb.mat");
formatAbsor = "Absor: %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f ";
vAbsor = sprintf(formatAbsor,absorbData1(1,:));
disp(vAbsor);

NB=9; Fs= 48000; % Hz
Signal= zeros (1,Fs); 
Signal(1) =1.0;
yFilt  = zeros (NB,Fs);
yFiltG = zeros (NB,Fs);

%B =[44 88; 89 176; 177 353; 354 707; 708 1414; 1415 2828; 2829 5657; 5658 11314; 11315 22000;];
Blo2=[ 44    89      177      354      708       1415       2829       5658        11315      ];
Bhi2=[   88     176      353      707      1414       2828       5657       11314        22600];

Blo=zeros(1,NB); Bhi=zeros(1, NB);Bce=zeros(1,NB);
Q=sqrt(2); % Q=Fc/(F2-F1);
fcIni=62.5;
for i=1:NB
    Bce(i)=fcIni;
    Blo(i)=fcIni/Q; % fc / (2)^0.5 ; 2^(1/6) si fuera un tercio de octava
    Bhi(i)=fcIni*Q; % fc * (2)^0.5 ; 2^(1/6) si fuera un tercio de octava
    fcIni=fcIni*2;
end

a =zeros(NB,3); b=zeros(NB,3); sos=zeros(NB,6); g=zeros(NB,1);

d = designfilt('bandpassiir','FilterOrder',2, ...
         'HalfPowerFrequency1',Blo(1),'HalfPowerFrequency2',Bhi(1), ...
         'SampleRate',Fs);

bpFilt = repmat (d, 1, NB);                % Array of filters to store information for each band

%% Low
[B, A] = butter(1,Bhi(1)/(Fs/2), 'low');
bL= B; aL = A;
[sos(1,:), g(1)] = tf2sos(bL,aL);
bpFilt(1) = designfilt('lowpassiir','FilterOrder',1,'PassbandFrequency', Bhi(1), ...
        'SampleRate',Fs);
%% BandPass
for n=2:NB-1
  [B, A] = butter(1,[Blo(n) Bhi(n)]/(Fs/2), 'bandpass' );
  b(n,:) = B; a(n,:) = A;
  [sos(n,:), g(n)] = tf2sos(b(n),a(n));
  
  bpFilt(n) = designfilt('bandpassiir','FilterOrder',2, ...
            'HalfPowerFrequency1',Blo(n),'HalfPowerFrequency2',Bhi(n), ...
            'SampleRate',Fs);
end
%% High
[B, A] = butter(1,Blo(NB)/(Fs/2), 'high' );
bH= B; aH = A;
[sos(NB,:), g(NB)] = tf2sos(bH,aH);
bpFilt(NB) = designfilt('highpassiir','FilterOrder',1,'PassbandFrequency', Blo(NB), ...
             'SampleRate',Fs);

%% Filter with Butter
Tot= zeros(1,Fs); 
yFilt(1,:) = filter(bL, aL, Signal);
Signal = yFilt(1,:);
for n=2:NB-1
    yFilt(n,:) = filter(b(n,:), a(n,:), Signal);
    %yFilt(n,:) = yFilt(n,:) .* sqrt(1-absorbData1(1,n));
    Signal = yFilt(n,:);
end
yFilt(NB,:) = filter(bH, aH, Signal);
Tot = yFilt(NB,:);

%% Filter with designfilt
Tot2= zeros(1,Fs);
yFiltG(1,:) = filter(bpFilt(1), Signal);
Signal = yFiltG(1,:);
for n=2:NB-1
    yFiltG(n,:) = filter(bpFilt(n), Signal);
    %yFiltG(n,:) = yFiltG(n,:) .* sqrt(1-absorbData1(1,n));
    Signal = yFiltG(n,:);
end
yFiltG(NB,:) = filter(bpFilt(NB), Signal);
Tot2 = yFiltG(NB,:);

T=1/Fs; N=length(Tot); n = nextpow2(N); L= 2^n; t=(0:L-1)*T; %Time vector
Y = fft(Tot, L);
module = abs(Y); phase = angle(Y);
MdB= 10*log10(module);
f = Fs*(0:L-1)/L;
figure;
subplot(2,1,1); semilogx(f, MdB);
xlim([10 22000]); % ylim([-6 3]);
str= ['L-7BP-H Butterworth  - Spectrum (dB) '];
title(str);  xlabel('Frec (Hz)'); ylabel('Magnitude (dB)'); grid on;
subplot(2,1,2); semilogx(f, module);
%ylim([0 2.5]); 
xlim([10 22000]);
title('Butterworth  - Spectrum');  xlabel('Frec (Hz)');  ylabel('Magnitude'); grid on;

Y = fft(Tot2, L);
module = abs(Y); phase = angle(Y);
MdB= 10*log10(module);
f = Fs*(0:L-1)/L;
figure;
subplot(2,1,1); semilogx(f, MdB);
xlim([10 22000]); % ylim([-3 3]);
str= ['L-7BP-H bpiir2Order - Spectrum (dB) '];
title(str);  xlabel('Frec (Hz)'); ylabel('Magnitude (dB)'); grid on;
subplot(2,1,2); semilogx(f, module);
% ylim([0 2.5]); 
xlim([10 22000]);
title('bpiir2Order - Spectrum');  xlabel('Frec (Hz)');  ylabel('Magnitude'); grid on;
