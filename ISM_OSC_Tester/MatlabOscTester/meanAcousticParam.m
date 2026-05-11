

%% This script, from the acoustic parameters obtained for the 8 listener-source positions, 
%% calculates the average value of such parameters in the 9 frequency bands  
%% It is applied to the folder containing the evaluation of the acoustic parameters for all Tmix values
%% ​​(20, 28, 34 and 40 meters). For each room and Tmix value, it generates the associated graphs.

% Author: Fabian Arrebola (07/11/2024) 
% contact: areyes@uma.es
% 3DDIANA research group. University of Malaga
% Project: SONICOM
% 
% Copyright (C) 2024 Universidad de Málaga

clear all;
close all;

f = [62.5 125 250 500 1000 2000 4000 8000 16000];
ft = f';
fc = repmat (ft, 1, 6);

sInFolder = 'C:\Users\FABIAN\OneDrive - Universidad de Málaga\3DIANA\Temas de Investigación\Metodo Imagenes HYBRID\2024_11_07_Acoustic_parameter_evaluation_TABLES'
path_save = sInFolder;
% Conversion
eFolders = dir(fullfile(sInFolder,'Ac*'));
for j=1:length(eFolders)
    folder= [sInFolder '\' eFolders(j).name];
    eFiles=dir(fullfile(folder,'*.mat'));
    for i=1:length(eFiles)
        sMatFile=fullfile(folder,eFiles(i).name);
        name = eFiles(i).name;
        load (sMatFile);
        room = name(1:4);    param = name(6:8);   tMix = name (end-5:end-4);
        if isequal(param,'C80')
            %C80p (:,:) = Err_C80rs_t;     
            C80p (:,:) = Tab_C80_t; 
            if isequal(room,'A108')        C80_A108cell{j} = C80p; Tab_C80_A108 = Tab_C80; Er_C80_A108 = Err_C80rs;
            elseif isequal(room,'sJun')    C80_sJuncell{j} = C80p; Tab_C80_sJun = Tab_C80; E_C80_sJun = Err_C80rs;
            end
        elseif isequal(param,'EEy')
            %EEyp (:,:) = Err_EEyrs_t;      
            EEyp (:,:) = Tab_EEy_t;      
            if isequal(room,'A108')        EEy_A108cell{j} = EEyp; Tab_EEy_A108 = Tab_EEy; Er_EEy_A108 = Err_EEyrs;
            elseif isequal(room,'sJun')    EEy_sJuncell{j} = EEyp; Tab_EEy_sJun = Tab_EEy; Er_EEy_A108 = Err_EEyrs;
            end
        elseif isequal(param,'T20')
            %T20p (:,:) = Err_T20rs_t;      
            T20p (:,:) = Tab_T20_t;      
            if isequal(room,'A108')        T20_A108cell{j} = T20p; Tab_T20_A108 = Tab_T20; Er_T20_A108 = Err_T20rs;
            elseif isequal(room,'sJun')    T20_sJuncell{j} = T20p; Tab_T20_sJun = Tab_T20; Er_T20_sJun = Err_T20rs;
            end
        elseif isequal(param,'EDT')
            %EDTp (:,:) = Err_EDTrs_t;   
            EDTp (:,:) = Tab_EDT_t; 
            if isequal(room,'A108')        EDT_A108cell{j} = EDTp; Tab_EDT_A108 = Tab_EDT; Er_EDT_A108 = Err_EDTrs;
            elseif isequal(room,'sJun')    EDT_sJuncell{j} = EDTp; Tab_EDT_sJun = Tab_EDT; Er_EDT_sJun = Err_EDTrs;
            end
        else 
            param = name(6:11);
            if isequal(param,'IACC_e')
                %IACC_ep (:,:) = Err_IACC_early_rs_t; 
                IACC_ep (:,:) = Tab_IACC_early_t; 
                if isequal(room,'A108')                   IACC_e_A108cell{j} = IACC_ep;
                elseif isequal(room,'sJun')               IACC_e_sJuncell{j} = IACC_ep;
                end
            end
        end      
    end

    %% ----------------- Mean A108 -----------------------------
    C80_A108_mean = zeros (size(Tab_C80,1), size(Tab_C80,2));
    T20_A108_mean = zeros (size(Tab_T20,1), size(Tab_T20,2));
    EDT_A108_mean = zeros (size(Tab_EDT,1), size(Tab_EDT,2));
    EEy_A108_mean = zeros (size(Tab_EEy,1), size(Tab_EEy,2));
    for i=1:size(Tab_C80,3)
        C80_A108_mean(:,:) = C80_A108_mean(:,:)+Tab_C80_A108(:,:,i);
        T20_A108_mean(:,:) = T20_A108_mean(:,:)+Tab_T20_A108(:,:,i);
        EDT_A108_mean(:,:) = EDT_A108_mean(:,:)+Tab_EDT_A108(:,:,i);
        EEy_A108_mean(:,:) = EEy_A108_mean(:,:)+Tab_EEy_A108(:,:,i);
    end
    C80_A108_mean = C80_A108_mean./size(Tab_C80,3);
    T20_A108_mean = T20_A108_mean./size(Tab_T20,3);
    EDT_A108_mean = EDT_A108_mean./size(Tab_EDT,3);
    EEy_A108_mean = EEy_A108_mean./size(Tab_EEy,3);
    %% ----------------- Mean sJun -----------------------------
    C80_sJun_mean = zeros (size(Tab_C80,1), size(Tab_C80,2));
    T20_sJun_mean = zeros (size(Tab_T20,1), size(Tab_T20,2));
    EDT_sJun_mean = zeros (size(Tab_EDT,1), size(Tab_EDT,2));
    EEy_sJun_mean = zeros (size(Tab_EEy,1), size(Tab_EEy,2));
    for i=1:size(Tab_C80,3)
        C80_sJun_mean(:,:) = C80_sJun_mean(:,:)+Tab_C80_sJun(:,:,i);
        T20_sJun_mean(:,:) = T20_sJun_mean(:,:)+Tab_T20_sJun(:,:,i);
        EDT_sJun_mean(:,:) = EDT_sJun_mean(:,:)+Tab_EDT_sJun(:,:,i);
        EEy_sJun_mean(:,:) = EEy_sJun_mean(:,:)+Tab_EEy_sJun(:,:,i);
    end
    C80_sJun_mean = C80_sJun_mean./size(Tab_C80,3);
    T20_sJun_mean = T20_sJun_mean./size(Tab_T20,3);
    EDT_sJun_mean = EDT_sJun_mean./size(Tab_EDT,3);
    EEy_sJun_mean = EEy_sJun_mean./size(Tab_EEy,3);
    %% ----------------------------------------------

    %% JNDs -- Plots -- save files

    legend_names = {'Reference omni'; 'Hybrid OurAdj EEy'; 'Hybrid OurAdj C80'; 'Hybrid TEyring';'jnd1'; 'jnd2'};
    newcolors = [0 0 0; 0 0.4470 0.7410; 0.93,0.69,0.13; 0.8500 0.3250 0.0980; 0 0 0];
    
    if ~(strcmp(tMix,'40'))
        C80_sJun_mean(:,5) = C80_sJun_mean(:,1)+1;
        C80_sJun_mean(:,6) = C80_sJun_mean(:,1)-1;
        T20_sJun_mean(:,5) = 1.05*T20_sJun_mean(:,1); % +5% (1 JND)
        T20_sJun_mean(:,6) = 0.95*T20_sJun_mean(:,1); % -5% (1 JND)
        EDT_sJun_mean(:,5) = 1.05*EDT_sJun_mean(:,1); % +5% (1 JND)
        EDT_sJun_mean(:,6) = 0.95*EDT_sJun_mean(:,1); % -5% (1 JND)

        fig_mean{j} = figure;
        tcl = tiledlayout(1,3,"TileSpacing","compact");
        nexttile(1);       
        semilogx(fc, T20_sJun_mean); title (['T20 Average']); colororder(newcolors);  grid on;
        nexttile(2); 
        semilogx(fc, EDT_sJun_mean); title (['EDT Average']); colororder(newcolors);  grid on;
        nexttile(3);
        semilogx(fc, C80_sJun_mean); title (['C80 Average']); colororder(newcolors); legend(legend_names, 'Location','eastoutside'); grid on;
        %figure; semilogx(fc, EEy_sJun_mean); title ('EEy sJun');
        set(fig_mean{j},'Units','normalized');
        set(fig_mean{j},'Position',[0.180729166666667,0.159259259259259,0.708854166666667,0.348148148148148]);
        title(tcl,['Room ' 'sJun '  ' Tmix ' tMix]);
        room = 'sJun';
        saveas(fig_mean{j},fullfile(path_save,[room '_average_params_Tmix_' tMix '.fig']));
        saveas(fig_mean{j},fullfile(path_save,[room '_average_params_Tmix_' tMix '.png']));
    end

    if ~(strcmp(tMix,'34'))
        C80_A108_mean(:,5) = C80_A108_mean(:,1)+1;
        C80_A108_mean(:,6) = C80_A108_mean(:,1)-1;
        T20_A108_mean(:,5) = 1.05*T20_A108_mean(:,1); % +5% (1 JND)
        T20_A108_mean(:,6) = 0.95*T20_A108_mean(:,1); % -5% (1 JND)
        EDT_A108_mean(:,5) = 1.05*EDT_A108_mean(:,1); % +5% (1 JND)
        EDT_A108_mean(:,6) = 0.95*EDT_A108_mean(:,1); % -5% (1 JND)
        fig_mean{j+1} = figure;
        tcl = tiledlayout(1,3,"TileSpacing","compact");
        nexttile(1);
        semilogx(fc, T20_A108_mean); title (['T20 Average' ]); colororder(newcolors); grid on;
        nexttile(2); 
        semilogx(fc, EDT_A108_mean); title (['EDT Average' ]); colororder(newcolors); grid on;
        nexttile(3);
        semilogx(fc, C80_A108_mean); title (['C80 Average' ]); colororder(newcolors); legend(legend_names, 'Location','eastoutside'); grid on;
        %figure; semilogx(fc, EEy_A108_mean); title ('EEy A108');
        set(fig_mean{j+1},'Units','normalized');
        set(fig_mean{j+1},'Position',[0.180729166666667,0.159259259259259,0.708854166666667,0.348148148148148]);
        title(tcl,['Room ' 'A108 '  ' Tmix ' tMix]);
        room = 'A108';
        saveas(fig_mean{j+1},fullfile(path_save,[room '_average_params_Tmix_' tMix '.fig']));
        saveas(fig_mean{j+1},fullfile(path_save,[room '_average_params_Tmix_' tMix '.png']));
    end
end