

%% Script to generate the IRs formed by the direct path at position L5-S2 
%% and the reverb tail shifted by the distance between L5 and S2

% Authors: Fabian Arrebola (13/12/2024) 
% contact: areyesa@uma.es
% 3DDIANA research group. University of Malaga
% Project: SONICOM
% 
% Copyright (C) 2024 Universidad de Málaga

%close all;
clear all;

propagationDelay = 0;   % 0 --> 2024_12_19; 
                        % 1 --> 2024_11_19
save_comp_files = 0;

% Path of the folder containing the .wav files (Impulse responses)
path_general = 'C:\Users\Fabian\OneDrive - Universidad de Málaga\3DIANA\Temas de Investigación\Metodo Imagenes HYBRID\';
%folderColaDirpath = '2024_12_12_ColaSinCaminoDirecto_y_CaminoDitrectoNoRetPropNoAttReverb';
folderColaDirpath = '2024_12_12_ColaSinCaminoDirecto_y_CaminoDirecto_NoRetProp_SiAttReverb';
%folderColaDirpath = '2024_11_19_ColaSinCaminoDirecto_y_CaminoDirecto_SiRetProp_NoAttReverb';
%folderColaDirpath = '2024_11_19_ColaSinCaminoDirecto_y_CaminoDitrecto_SiAttReverb';
folder = [path_general folderColaDirpath];

pS=2;
pL=5;  

posS_A108 = [1.55  0.02 -0.68;     %1
        2.68  0.02 -0.68;     %2
        2.68 -2.48 -0.68;     %3
        2.68 -4.89 -0.68;];   %4
                      
posL_A108 = [-0.45  0.02 -0.68;    %1
        -0.45 -2.48 -0.68;    %2
        -0.45 -4.98 -0.68;    %3
        -2.23 -2.48 -0.68;    %4 
        -3.24 -4.98 -0.68;];  %5

posS_sJun = [2.0  0.0 0.15;   %1
        4.3  0.0 0.15;   %2
        4.3 -2.0 0.15;   %3
        4.3 -4.0 0.15];  %4 

posL_sJun = [0.0  0.0 0.15;   %1
        0.0 -2.0 0.15;   %2 
        0.0 -4.0 0.15;   %3 
       -2.0 -2.0 0.15;   %4
       -4.0 -4.0 0.15];  %5

positionL = posL_A108(pL,:);
positionS = posS_A108(pS,:);
dist_LS_A108 = norm (positionS-positionL);

positionL = posL_sJun(pL,:);
positionS = posS_sJun(pS,:);
dist_LS_sJun = norm (positionS-positionL);

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
    % figure; plot (Ir);
    % xlim([0 10000]);  ylim([-0.3 0.3]);
    % str= ['IR ',files(i).name];
    % title(str);  % xlabel('Frec (Hz)'); ylabel('Magnitude (dB)')
    % grid on;
    clear Ir; 
end

YA108Comp = zeros(2, longA108);
YsJunComp = zeros(2, longsJun);

%% Direct path
YA108Comp = YA108 ([1:2], :);
YsJunComp = YsJun ([1:2], :);
figure; plot (YA108Comp'); title('A108 Dir Path'); grid on; xlim([0 3000]);  ylim([-0.3 0.3]);
figure; plot (YsJunComp'); title('sJun Dir Path'); grid on; xlim([0 3000]);  ylim([-0.3 0.3]);

if ~propagationDelay     % Disable propagation delay
    oTail = 366;         % samples
    oDirP = 70;
    % oA108 = floor((dist_LS_A108 - 2) * Fs / 343) ;
    % osJun = floor((dist_LS_sJun - 2) * Fs / 343) ;

    oA108 = 1;
    osJun = 1;

    %% ---------------------
    YA108 ([3:4],[oDirP:end-oTail+oDirP]) = YA108 ([3:4],[oTail:end]); % shift Tail 366-->70
    YsJun ([3:4],[oDirP:end-oTail+oDirP]) = YsJun ([3:4],[oTail:end]); % shift Tail 366-->70
    TailA108 = YA108 ([3:4],:);
    TailsJun = YsJun ([3:4],:);
    figure; plot (TailA108'); title('A108 Shift Tail'); grid on; xlim([0 3000]);  ylim([-0.3 0.3]);
    figure; plot (TailsJun'); title('sJun Shift Tail'); grid on; xlim([0 3000]);  ylim([-0.3 0.3]);
    %% ---------------------

    YA108Comp(:, [1:end])  = YA108Comp (:, [1:end]) + TailA108 (:, [1:end]);
    figure; plot (YA108Comp'); title('A108 Comp'); grid on; xlim([0 3000]);  ylim([-0.3 0.3]);
    YsJunComp(:, [1:end])  = YsJunComp (:, [1:end]) + TailsJun (:, [1:end]);
    figure; plot (YsJunComp'); title('sJun Comp'); grid on; xlim([0 3000]);  ylim([-0.3 0.3]);
   
else                    % Enable propagation delay
    oCal = 366;         % samples
    %oA108 = 1161-oCal;  % DirectPath L5-S2 - oCal
    %osJun = 1370-oCal;  % DirectPath L5-S2 - oCal
    oA108 = floor((dist_LS_A108 - 2) * Fs / 343) ;
    osJun = floor((dist_LS_sJun - 2) * Fs / 343) ;


    TailA108 = YA108 ([3:4],:);
    TailsJun = YsJun ([3:4],:);
    figure; plot (TailA108'); title('A108 Shift Tail'); grid on; xlim([0 3000]);  ylim([-0.3 0.3]);
    figure; plot (TailsJun'); title('sJun Shift Tail'); grid on; xlim([0 3000]);  ylim([-0.3 0.3]);

    YA108Comp(:, [oA108:end])  = YA108Comp (:, [oA108:end]) + YA108 ([3:4],[1:end-oA108+1]);
    figure; plot (YA108Comp'); title('A108 Comp'); grid on; xlim([0 3000]);  ylim([-0.3 0.3]);

    YsJunComp(:, [osJun:end])  = YsJunComp (:, [osJun:end]) + YsJun ([3:4],[1:end-osJun+1]);
    figure; plot (YsJunComp'); title('sJun Comp'); grid on; xlim([0 3000]);  ylim([-0.3 0.3]);
end

if save_comp_files
    fileName1 = [folder  '\A108-L5-S2-Comp.wav'];
    audiowrite(fileName1,YA108Comp',Fs);
    fileName2 = [folder  '\sJun-L5-S2-Comp.wav'];
    audiowrite(fileName2,YsJunComp',Fs);
end

disp ('fin');



