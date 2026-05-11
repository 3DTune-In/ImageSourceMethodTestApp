

addpath('C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder'); 
cd  'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder';
%cd 'C:\Users\FABIAN\OneDrive - Universidad de Málaga\3DIANA\Temas de Investigación\Metodo Imagenes HYBRID\2024_03_22_Sala_Juntas_Ajuste&RIs\AjusteValorMedio\RIs source2_listener4';
%cd 'C:\Users\FABIAN\OneDrive - Universidad de Málaga\3DIANA\Temas de Investigación\Metodo Imagenes HYBRID\2024_03_22_Sala_Juntas_Ajuste&RIs\AjustePendientes\RIs source2_listener4';
%cd 'C:\Users\FABIAN\OneDrive - Universidad de Málaga\3DIANA\Temas de Investigación\Metodo Imagenes HYBRID\2024_03_22_Aula108_Ajuste&RIs\Ajuste valorMedio\RIs source2_listener4';
%cd 'C:\Users\FABIAN\OneDrive - Universidad de Málaga\3DIANA\Temas de Investigación\Metodo Imagenes HYBRID\2024_03_22_Aula108_Ajuste&RIs\Ajuste Pendientes\RIs source2_listener4';
%cd 'C:\Users\FABIAN\OneDrive - Universidad de Málaga\3DIANA\Temas de Investigación\Metodo Imagenes HYBRID\2024_03_22_Sala_Juntas_Ajuste&RIs\AjusteValorMedio\RIs Con CaminoDirecto centro';
%cd 'C:\Users\FABIAN\OneDrive - Universidad de Málaga\3DIANA\Temas de Investigación\Metodo Imagenes HYBRID\2024_03_22_Sala_Juntas_Ajuste&RIs\AjustePendientes\RIs Con CaminoDirecto centro';
%cd 'C:\Users\FABIAN\OneDrive - Universidad de Málaga\3DIANA\Temas de Investigación\Metodo Imagenes HYBRID\2024_03_22_Aula108_Ajuste&RIs\Ajuste valorMedio\RIs Con Camino Directo centro';

% get current path
currentPath = getCurrentPath();

allFiles = dir(currentPath);

% List .WAV files
wavFiles = listWavFiles(allFiles);

% number of wavfiles
N = length(wavFiles);

% to obtain the length of the impulse responses
[y1,Fs] = audioread(wavFiles{1});
Y1 = SSA_Spectrum(Fs, y1, 0, 0);
YArr = zeros (N,length(Y1));

% to to calculate the energies of each frequency band
Nf=48000;
NB=9;
B =[44 88; 89 176; 177 353; 354 707; 708 1414; 1415 2828; 2829 5657; 5658 11314; 11315 22600;];
Blo=[ 1    89      177      354      708       1415       2829       5658        11315       ];
Bhi=[  88     176      353      707      1414       2828       5657       11314        22600 ];

maxTot=0;
E_B=zeros (N,NB,2);
for i=1:N
    f0 =  figure;
    [y1,Fs] = audioread(wavFiles{i});
    Y1 = SSA_Spectrum(Fs, y1, 1, f0);                       % single-sided spectrum 
    YArr(i,:) = Y1;

    %% ------------------
    e= calculateEnergy(y1);                                 % energy in time
    E= calculateEnergyFrec(Fs, y1)/length(y1);              % energy in frequency
    E2 =calculateEnergyBand(Fs, y1, Blo(1), Bhi(NB))/Nf;    
    eSumB=0; %checksum
    
    for j=1:NB                                              % energy in each frecuency band
        e = calculateEnergyBand(Fs, y1, Blo(j), Bhi(j)) / Nf;
        E_B(i,j,:) = e;
        eSumB = eSumB+E_B(i,j,:);
    end
    %% ------------------


    maxIr = max(Y1,[], [1 2]);
    if maxIr> maxTot
        maxTot=maxIr;
    end
end

for i = 1:N
    figure(i);
    ylim([0 maxTot]);
    %xlim([10 22100]);
    str= ['SS Spectrum ',wavFiles{i}];
    title(str);
    grid on;
end

% energy profile by bands
% E_B(N,:,:) --> profile for direct path (rIdp.wav)
R_B=zeros (N,NB,2);
LR_B=zeros (N,NB,2);
figure; hold on;
for i = 1:N
    R_B(i,:,:)= E_B(i,:,:)./E_B(N,:,:);
    LR_B(i,:,:)= 10*log10(R_B(i,:,:));
    plot(R_B(i,:,1), '-.');
end
title('EnergyImage/EnergyDirectPath');
xlabel('Bands');
legend(wavFiles, 'Location','northeast');

% reflection profile: E_wall/E_directPath
n = nextpow2(length(Y1)); L= 2^n;
f = Fs*(0:(L/2))/L; 
for i = 1:N
    Y1= YArr(i,:);
    YArr(i,:) = Y1 ./ YArr(N,:);
    Y2= YArr(i,:);
    figure; subplot(2,1,1); semilogx(f,Y1);
    xlim([10 22100]);
    str= ['SS Spectrum ',wavFiles{i}];
    title(str);
    grid on;
    subplot(2,1,2); semilogx (f,Y2);
    ylim([0 2]); xlim([10 22100]);
    %title('Fil-A-coef/Direct-Path');
    str= ['Profile Image/DP ',wavFiles{i}];
    title(str);
    grid on;
end

disp('fin');

% get curren paht
function currentPath = getCurrentPath()
    currentPath = pwd;
end

% list wavs files
function wavFiles = listWavFiles(allFiles)
    % Get list of all files in folder
   
    % Filter the list to get only .WAV files
    wavFiles = cell(0);
    for i = 1:length(allFiles)
        file = allFiles(i).name;
        if length (file)>4
            extension = file(end-3:end);
            if strcmpi(extension, '.wav')
                wavFiles{end+1} = allFiles(i).name;
            end
        end
    end
end

%Single-Sided Amplitude Spectrum 
function [SSAS]= SSA_Spectrum(Fs, IR, view, f0)

   T=1/Fs;    N=length(IR);    n = nextpow2(N);    L= 2^n;
   t=(0:L-1)*T; %Time vector
  
   % Yfrec =  fft(IR/L, L);
   Yfrec =  fft(IR, L);

   P2 = abs(Yfrec);
   P1 = P2(1:L/2+1);
   P1(2:end-1) = 2*P1(2:end-1);

   if (view)
       f = Fs*(0:(L/2))/L; 
       semilogx(f,P1);
   end

   SSAS= P1;
end