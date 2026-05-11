
%% Script to generate the IRs formed by the direct path at position L5-S2 
%% and the reverb tail shifted by the distance between L5 and S2

% Authors: Fabian Arrebola (20/11/2024) 
% contact: areyesa@uma.es
% 3DDIANA research group. University of Malaga
% Project: SONICOM
% 
% Copyright (C) 2024 Universidad de Málaga

close all;

% Path of the folder containing the .wav files (Impulse responses)

folder = 'C:\Users\FABIAN\OneDrive - Universidad de Málaga\3DIANA\Temas de Investigación\Metodo Imagenes HYBRID\2024_11_19_L5S2_TodoColaSinCaminoDirecto_e_HibridoTmix_DP';
%folder = 'C:\Repos\of_v0.12.0_vs_release\ImageSourceMethodTestApp\bin\data\resources\workFolder';
%folder = 'C:\Repos\of_v0.12.0_vs_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\sJun-L5-S2';

% Get list of .wav files in folder
files = dir(fullfile(folder, '*.wav'));
NumF = length(files);

% Get the length of Impulse response
currentFile = fullfile(folder, files(1).name);
[Ir, Fs] = audioread(currentFile);

YA108 = zeros (4,length(Ir));
YsJun = zeros (4,length(Ir));

%% Iterate over each .wav file
for i = 1:NumF
    % Read the .wav file
    currentFile = fullfile(folder, files(i).name);
    [Ir, Fs] = audioread(currentFile);
    name = files(i).name;
    room = name(1:4); dp_tail = name(end-11:end-4);
    
    if isequal(room,'A108')
        if  isequal(dp_tail,'ISM-DirP')
            YA108([1:2], :)= Ir';
        else
            YA108([3:4], :)= Ir';
        end 
        
    elseif isequal(room,'sJun')
        if isequal(dp_tail,'ISM-DirP')
            YsJun([1:2], [1:size(Ir,1)])= Ir';
        else
            YsJun([3:4], [1:size(Ir,1)])= Ir';
        end 
    end
        

    %% Time 
    figure; plot (Ir);
    xlim([0 10000]);  ylim([-0.3 0.3]);
    str= ['IR ',files(i).name];
    title(str);  % xlabel('Frec (Hz)'); ylabel('Magnitude (dB)')
    grid on;
end

YA108Comp = zeros(2, size (YA108,2));
YsJunComp = zeros(2, size (YsJun,2));

%direct path
YA108Comp = YA108 ([1:2], :);
YsJunComp = YsJun ([1:2], :);
% figure; plot (YA108Comp'); title('A108 Dir Path'); grid on; xlim([0 10000]);  ylim([-0.3 0.3]);
% figure; plot (YsJunComp'); title('sJun Dir Path'); grid on; xlim([0 10000]);  ylim([-0.3 0.3]);

oCal = 366;         % samples
oA108 = 1170-oCal;  % 8.2 m. - oCal
osJun = 1370-oCal;  % 9.7 m. - oCal

YA108Comp([1:2], [oA108:end])  = YA108Comp ([1:2], [oA108:end]) + YA108 ([3:4],[1:end-oA108+1]);
figure; plot (YA108Comp'); title('A108 Comp'); grid on; xlim([0 10000]);  ylim([-0.3 0.3]);
YsJunComp([1:2], [osJun:end])  = YsJunComp ([1:2], [osJun:end]) + YsJun ([3:4],[1:end-osJun+1]);
figure; plot (YsJunComp'); title('sJun Comp'); grid on; xlim([0 10000]);  ylim([-0.3 0.3]);

fileName1 = [folder  '\A108-L5-S2-Comp.wav'];
audiowrite(fileName1,YA108Comp',Fs);
fileName2 = [folder  '\sJun-L5-S2-Comp.wav'];
audiowrite(fileName2,YsJunComp',Fs);

disp ('fin');



