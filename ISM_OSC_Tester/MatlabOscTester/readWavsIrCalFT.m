%% This script generates and draws the frequency spectrum of a 
%% of a set of impulse responses wav format

% Authors: Fabian Arrebola (16/05/2024) 
% contact: areyesa@uma.es
% 3DDIANA research group. University of Malaga
% Project: SONICOM
% 
% Copyright (C) 2024 Universidad de Málaga

close all;

% Path of the folder containing the .wav files (Impulse responses)
%folder = 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\A108-sJun DIFERENTES POSICIONES CASCADE\sin camino directo\A108-L1-S1';
%folder = 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\A108-L1-S1';
%folder = 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\SimulacionPosicionesAjuste TEyring\sJun-L5-S2';
%folder = 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\14';
%folder = 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\SimulacionPosicionesAjuste Omni\A108-L1-S1';
folder = 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder';
% folder = 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\Omni_Binaural_RIs';

% Get list of .wav files in folder
files = dir(fullfile(folder, '*.wav'));
NumF = length(files);

% Get the length of Impulse response
currentFile = fullfile(folder, files(1).name);
[Ir, Fs] = audioread(currentFile);
T=1/Fs; N=length(Ir); n = nextpow2(N); Lini= 2^n; 

%Lini=Fs;

Y = fft(Ir, Lini);
YArr = zeros (NumF,length(Y));

%% Iterate over each .wav file
for i = 1:NumF
    % Read the .wav file
    currentFile = fullfile(folder, files(i).name);
    [Ir, Fs] = audioread(currentFile);

    %% --------------------------------------
    T=1/Fs; N=length(Ir); n = nextpow2(N); L= 2^n; 
    if L<Lini 
        L=Lini; 
    end
    t=(0:L-1)*T; %Time vector
    Y = fft(Ir, L);
    module = abs(Y); phase = angle(Y);
    MdB= 20*log10(module);

    Yaux= Y(:,1);
    YArr(i,:) = Yaux';

    f = Fs*(0:L-1)/L; 

    %% dBs
    figure;
    % subplot(2,1,1);
    semilogx(f, MdB);
    %semilogx(f, module);
    xlim([10 24000]); ylim([-60 15]);
    str= ['Spectrum ',files(i).name];
    title(str);  xlabel('Frec (Hz)'); ylabel('Magnitude (dB)'); grid on;

    %% Time 
    figure;
    % subplot(2,1,1);
    plot (Ir);
    xlim([0 10000]);  ylim([-0.3 0.3]);
    str= ['IR ',files(i).name];
    title(str);  % xlabel('Frec (Hz)'); ylabel('Magnitude (dB)')
    grid on;


%     %%  Linear
%     figure;
%     %subplot(2,1,1);
%     semilogx(f, module);
%     %semilogx(f, module);
%     xlim([10 24000]); ylim([0.5 1]);
%     str= ['Spectrum ',files(i).name];
%     title(str);  xlabel('Frec (Hz)'); ylabel('Magnitude (linear)'); grid on;

  
%     subplot(2,1,2);
%     %figure;
%     semilogx(f, phase);
%     %semilogx(f, module);
%     xlim([10 24000]);
%     title('phase FFT');  xlabel('Frec (Hz)');  ylabel('radians'); grid on;
end

% %% transfer functions
% for i = 1:NumF-1
%    Y1= YArr(i,:);
%    Y2= YArr(NumF,:);
%    Y3= Y1./Y2;
%    
%    module = abs(Y3); phase = angle(Y3); MdB= 20*log10(module);
%    f = Fs*(0:L-1)/L; 
% 
%    figure;
% %   subplot(2,1,1);
%    semilogx(f, MdB);
%    %semilogx(f, module);
%    xlim([10 24000]);  %ylim([-6 3]);
%    str= ['Transfer Function ',files(i).name];
%    title(str);  xlabel('Frec (Hz)'); ylabel('Magnitude (dB)'); grid on;
% %    subplot(2,1,2);
% %    semilogx(f, phase);
% %    xlim([10 22100]);
% %    title('Phase FFT');  xlabel('Frec (Hz)');  ylabel('radians'); grid on;
% end
