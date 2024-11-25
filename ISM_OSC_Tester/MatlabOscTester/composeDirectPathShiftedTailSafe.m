
%% Script to generate the IRs formed by the direct path at position L5-S2 
%% and the reverb tail shifted by the distance between L5 and S2

% Authors: Fabian Arrebola (20/11/2024) 
% contact: areyesa@uma.es
% 3DDIANA research group. University of Malaga
% Project: SONICOM
% 
% Copyright (C) 2024 Universidad de Málaga

close all;
clear all;

save_comp_files = 1;

% Path of the folder containing the .wav files (Impulse responses)

folder = 'C:\Users\FABIAN\OneDrive - Universidad de Málaga\3DIANA\Temas de Investigación\Metodo Imagenes HYBRID\2024_11_19_L5S2_TodoColaSinCaminoDirecto_e_HibridoTmix_DP';
%folder = 'C:\Repos\of_v0.12.0_vs_release\ImageSourceMethodTestApp\bin\data\resources\workFolder';
%folder = 'C:\Repos\of_v0.12.0_vs_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\sJun-L5-S2';

% Get list of A108*.wav files in folder
filesa = dir(fullfile(folder, 'A*.wav'));
NumFa = length(filesa);
% Get the length of Impulse response
currentFile = fullfile(folder, filesa(1).name);
[IrA, Fs] = audioread(currentFile);
longA108 = length(IrA);
YA108 = zeros (4,longA108);

% Get list of sJun*.wav files in folder
filess = dir(fullfile(folder, 's*.wav'));
NumFs = length(filess);
% Get the length of Impulse response
currentFile = fullfile(folder, filess(1).name);
[Irs, Fs] = audioread(currentFile);
longsJun = length(Irs);
YsJun = zeros (4,longsJun);

files = dir(fullfile(folder, '*.wav'));
NumF = length(files);

%% Iterate over each .wav file
for i = 1:NumF
    % Read the .wav file
    currentFile = fullfile(folder, files(i).name);
    [Ir, Fs] = audioread(currentFile);
    name = files(i).name;
    room = name(1:4); 
    dp_tail = name(end-11:end-4);
    
    if isequal(room,'A108')
        if  isequal(dp_tail,'ISM-DirP')
            YA108([1:2], [1:longA108])= Ir';
        elseif isequal(dp_tail,'HYB-Tail')
            YA108([3:4], [1:longA108])= Ir';
        end 
        
    elseif isequal(room,'sJun')
        if isequal(dp_tail,'ISM-DirP')
            YsJun([1:2], [1:longsJun])= Ir';
        elseif isequal(dp_tail,'HYB-Tail')
            YsJun([3:4], [1:longsJun])= Ir';
        end 
    end
        

    %% Time 
    figure; plot (Ir);
    xlim([0 10000]);  ylim([-0.3 0.3]);
    str= ['IR ',files(i).name];
    title(str);  % xlabel('Frec (Hz)'); ylabel('Magnitude (dB)')
    grid on;

    clear Ir;
    
end

YA108Comp = zeros(2, longA108);
YsJunComp = zeros(2, longsJun);

%direct path
YA108Comp = YA108 ([1:2], :);
YsJunComp = YsJun ([1:2], :);
% figure; plot (YA108Comp'); title('A108 Dir Path'); grid on; xlim([0 10000]);  ylim([-0.3 0.3]);
% figure; plot (YsJunComp'); title('sJun Dir Path'); grid on; xlim([0 10000]);  ylim([-0.3 0.3]);

oCal = 366;         % samples
oA108 = 1170-oCal;  % 8.2 m. - oCal
osJun = 1370-oCal;  % 9.7 m. - oCal

% eA108 = longA108-oA108+1;
% esJun = longsJun-osJun+1;
% YA108_tail = YA108 ([3:4],[1:end-oA108+1]);
% figure; plot (YA108_tail'); title('A108 tail'); grid on; xlim([0 10000]);  ylim([-0.3 0.3]);
% YsJun_tail = YsJun ([3:4],[1:end-osJun+1]);
% figure; plot (YsJun_tail'); title('sJun tail'); grid on; xlim([0 10000]);  ylim([-0.3 0.3]);


YA108Comp(:, [oA108:end])  = YA108Comp (:, [oA108:end]) + YA108 ([3:4],[1:end-oA108+1]);
figure; plot (YA108Comp'); title('A108 Comp'); grid on; xlim([0 10000]);  ylim([-0.3 0.3]);

YsJunComp(:, [osJun:end])  = YsJunComp (:, [osJun:end]) + YsJun ([3:4],[1:end-osJun+1]);
figure; plot (YsJunComp'); title('sJun Comp'); grid on; xlim([0 10000]);  ylim([-0.3 0.3]);

if save_comp_files
    fileName1 = [folder  '\A108-L5-S2-Comp.wav'];
    audiowrite(fileName1,YA108Comp',Fs);
    fileName2 = [folder  '\sJun-L5-S2-Comp.wav'];
    audiowrite(fileName2,YsJunComp',Fs);
end

disp ('fin');



