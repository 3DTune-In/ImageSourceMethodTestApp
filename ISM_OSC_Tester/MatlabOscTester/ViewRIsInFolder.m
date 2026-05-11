

addpath('C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder'); 
cd     'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder';
%cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder';

%cd 'C:\Users\FABIAN\OneDrive - Universidad de Málaga\3DIANA\Temas de Investigación\Metodo Imagenes HYBRID\2024_03_22_Sala_Juntas_Ajuste&RIs\AjusteValorMedio\RIs Sin CaminoDirecto';

% get current path
currentPath = getCurrentPath();

allFiles = dir(currentPath);

% List .WAV files
wavFiles = listWavFiles(allFiles);

% Mostrar los nombres de los archivos por pantalla
maxTot=0;
for i = 1:length(wavFiles)
    disp(wavFiles{i});
    [ir,Fs] = audioread(wavFiles{i});

    absIr = zeros(length(ir),2);
    absIr = abs(ir);
    maxIr = max(absIr,[], [1 2]);
    if maxIr> maxTot
        maxTot=maxIr;
    end
    figure; plot (ir);
    title(wavFiles{i});
end

for i = 1:length(wavFiles)
    figure(i);
    ylim([-maxTot maxTot]);
    xlim([0 45000])
    grid;
end



% get curren paht
function currentPath = getCurrentPath()
    currentPath = pwd;
end

% list wavs files
function wavFiles = listWavFiles(allFiles)
    % Obtener la lista de todos los archivos en la carpeta
   
    % Filtrar la lista para solo archivos .WAV
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

% %[ir_Ism,Fs] = audioread('ISM_DpMax.wav');
% %[ir_BRIR,Fs] = audioread('BRIR.wav');
% [ir_HYB1,Fs] = audioread('tIrRO40DP01W02HYB.wav');
% [ir_HYB2,Fs] = audioread('tIrRO40DP20W02HYB.wav');
% load ("FiInfAbsorb.mat");
% load ("ParamsISM.mat");
% 
% % %subplot(3,1,1);
% % figure;
% % plot (ir_Ism);
% % %subplot(3,1,2);
% % figure;
% % plot (ir_BRIR);
% % subplot(3,1,3);
% figure; plot (ir_HYB1);
% % subplot(4,1,4);
% figure; plot (ir_HYB2);