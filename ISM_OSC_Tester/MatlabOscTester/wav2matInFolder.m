

addpath('C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder'); 
%cd 'C:\Users\FABIAN\OneDrive - Universidad de Málaga\3DIANA\Temas de Investigación\Metodo Imagenes HYBRID\2024_03_22_Sala_Juntas_Ajuste&RIs\AjusteValorMedio\RIs source2_listener4';
%cd 'C:\Users\FABIAN\OneDrive - Universidad de Málaga\3DIANA\Temas de Investigación\Metodo Imagenes HYBRID\2024_03_22_Sala_Juntas_Ajuste&RIs\AjustePendientes\RIs source2_listener4';
%cd 'C:\Users\FABIAN\OneDrive - Universidad de Málaga\3DIANA\Temas de Investigación\Metodo Imagenes HYBRID\2024_03_22_Aula108_Ajuste&RIs\Ajuste valorMedio\RIs source2_listener4';
%cd 'C:\Users\FABIAN\OneDrive - Universidad de Málaga\3DIANA\Temas de Investigación\Metodo Imagenes HYBRID\2024_03_22_Aula108_Ajuste&RIs\Ajuste Pendientes\RIs source2_listener4';
%cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder';
%cd 'C:\Users\FABIAN\OneDrive - Universidad de Málaga\3DIANA\Temas de Investigación\Metodo Imagenes HYBRID\2024_03_22_Sala_Juntas_Ajuste&RIs\AjusteValorMedio\RIs Con CaminoDirecto centro';
%cd 'C:\Users\FABIAN\OneDrive - Universidad de Málaga\3DIANA\Temas de Investigación\Metodo Imagenes HYBRID\2024_03_22_Sala_Juntas_Ajuste&RIs\AjustePendientes\RIs Con CaminoDirecto centro';
%cd 'C:\Users\FABIAN\OneDrive - Universidad de Málaga\3DIANA\Temas de Investigación\Metodo Imagenes HYBRID\2024_03_22_Sala_Juntas_Ajuste&RIs\AjusteValorMedio\RIs Sin CaminoDirecto centro';
%cd 'C:\Users\FABIAN\OneDrive - Universidad de Málaga\3DIANA\Temas de Investigación\Metodo Imagenes HYBRID\2024_03_22_Sala_Juntas_Ajuste&RIs\AjustePendientes\RIs Sin CaminoDirecto centro';
%cd 'C:\Users\FABIAN\OneDrive - Universidad de Málaga\3DIANA\Temas de Investigación\Metodo Imagenes HYBRID\2024_03_22_Aula108_Ajuste&RIs\Ajuste valorMedio\RIs Con Camino Directo centro';
cd 'C:\Users\FABIAN\OneDrive - Universidad de Málaga\3DIANA\Temas de Investigación\Metodo Imagenes HYBRID\2024_03_22_Aula108_Ajuste&RIs\Ajuste valorMedio\RIs Sin CaminoDirecto centro';
%cd 'C:\Users\FABIAN\OneDrive - Universidad de Málaga\3DIANA\Temas de Investigación\Metodo Imagenes HYBRID\2024_03_22_Aula108_Ajuste&RIs\Ajuste Pendientes\RIs Con Camino Directo centro';
%cd 'C:\Users\FABIAN\OneDrive - Universidad de Málaga\3DIANA\Temas de Investigación\Metodo Imagenes HYBRID\2024_03_22_Aula108_Ajuste&RIs\Ajuste Pendientes\RIs Sin Camino Directo centro';

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

    fileName = wavFiles{i};
    extension = fileName(end-3:end);
    fileName(end-3:end) = ".mat";
    wavFiles{i}=fileName;

    figure; plot (ir);
    title(fileName);
    save (wavFiles{i},'ir', 'Fs');

    fileName(end-3:end) = ".fig";
    wavFiles{i}=fileName;
    savefig(wavFiles{i});
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