

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

sInFolder = 'C:\Users\FABIAN\OneDrive - Universidad de Málaga\3DIANA\Temas de Investigación\Metodo Imagenes HYBRID\2024_11_07_Acoustic_parameter_evaluation_TABLES_averages_meanError'
%sInFolder = 'C:\Repos\2024_10_17_Evaluation_Acoustic_Params\Acoustic_parameters_v4_250-4000Hz_tmix28m';
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
            if isequal(room,'A108')        C80_A108cell{j} = C80p; Tab_C80_A108 = Tab_C80; Err_C80_A108 = Err_C80rs;
            elseif isequal(room,'sJun')    C80_sJuncell{j} = C80p; Tab_C80_sJun = Tab_C80; Err_C80_sJun = Err_C80rs;
            end
        elseif isequal(param,'EEy')
            %EEyp (:,:) = Err_EEyrs_t;      
            EEyp (:,:) = Tab_EEy_t;      
            if isequal(room,'A108')        EEy_A108cell{j} = EEyp; Tab_EEy_A108 = Tab_EEy; Err_EEy_A108 = Err_EEyrs;
            elseif isequal(room,'sJun')    EEy_sJuncell{j} = EEyp; Tab_EEy_sJun = Tab_EEy; Err_EEy_sJun = Err_EEyrs;
            end
        elseif isequal(param,'T20')
            %T20p (:,:) = Err_T20rs_t;      
            T20p (:,:) = Tab_T20_t;      
            if isequal(room,'A108')        T20_A108cell{j} = T20p; Tab_T20_A108 = Tab_T20; Err_T20_A108 = Err_T20rs;
            elseif isequal(room,'sJun')    T20_sJuncell{j} = T20p; Tab_T20_sJun = Tab_T20; Err_T20_sJun = Err_T20rs;
            end
        elseif isequal(param,'EDT')
            %EDTp (:,:) = Err_EDTrs_t;   
            EDTp (:,:) = Tab_EDT_t; 
            if isequal(room,'A108')        EDT_A108cell{j} = EDTp; Tab_EDT_A108 = Tab_EDT; Err_EDT_A108 = Err_EDTrs;
            elseif isequal(room,'sJun')    EDT_sJuncell{j} = EDTp; Tab_EDT_sJun = Tab_EDT; Err_EDT_sJun = Err_EDTrs;
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
    C80_A108_mean = mean (Tab_C80_A108,3) ;     squeeze (C80_A108_mean);
    T20_A108_mean = mean (Tab_T20_A108,3) ;     squeeze (T20_A108_mean);
    EDT_A108_mean = mean (Tab_EDT_A108,3) ;     squeeze (EDT_A108_mean);
    EEy_A108_mean = mean (Tab_EEy_A108,3) ;     squeeze (EEy_A108_mean);



    %% ----------------- Mean sJun -----------------------------
    C80_sJun_mean = mean (Tab_C80_A108,3) ;     squeeze (C80_sJun_mean);
    T20_sJun_mean = mean (Tab_T20_A108,3) ;     squeeze (T20_sJun_mean);
    EDT_sJun_mean = mean (Tab_EDT_A108,3) ;     squeeze (EDT_sJun_mean);
    EEy_sJun_mean = mean (Tab_EEy_A108,3) ;     squeeze (EEy_sJun_mean);

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
        room = 'sJun';
        title(tcl,['Room ' room  ' Tmix ' tMix]);
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
        room = 'A108';
        title(tcl,['Room ' room  ' Tmix ' tMix]);
        saveas(fig_mean{j+1},fullfile(path_save,[room '_average_params_Tmix_' tMix '.fig']));
        saveas(fig_mean{j+1},fullfile(path_save,[room '_average_params_Tmix_' tMix '.png']));
    end

    %% ----------------- Error Mean A108 -----------------------------
    g1 = repmat({'Ref'},     1,8);
    g2 = repmat({'Our_EEy'}, 1,8);
    g3 = repmat({'Our_C80'}, 1,8);
    g4 = repmat({'TEyring'}, 1,8);
    g5 = repmat({'jnd1'},    1,8);
    g = [g1; g2; g3; g4; g5];

    C80_A108_E_mean = mean (Err_C80_A108 (2:end-1, :, :),1);  % only 2-8 bands, 1 and 9 bands are no used 
    T20_A108_E_mean = mean (Err_T20_A108 (2:end-1, :, :),1);
    EDT_A108_E_mean = mean (Err_EDT_A108 (2:end-1, :, :),1);
    EEy_A108_E_mean = mean (Err_EEy_A108 (2:end-1, :, :),1);

    C80_sJun_E_mean = mean (Err_C80_sJun (2:end-1, :, :),1);
    T20_sJun_E_mean = mean (Err_T20_sJun (2:end-1, :, :),1);
    EDT_sJun_E_mean = mean (Err_EDT_sJun (2:end-1, :, :),1);
    EEy_sJun_E_mean = mean (Err_EEy_sJun (2:end-1, :, :),1);

    C80_A108_E_mean = squeeze (C80_A108_E_mean);
    T20_A108_E_mean = squeeze (T20_A108_E_mean);
    EDT_A108_E_mean = squeeze (EDT_A108_E_mean);
    EEy_A108_E_mean = squeeze (EEy_A108_E_mean);

    C80_sJun_E_mean = squeeze (C80_sJun_E_mean);
    T20_sJun_E_mean = squeeze (T20_sJun_E_mean);
    EDT_sJun_E_mean = squeeze (EDT_sJun_E_mean);
    EEy_sJun_E_mean = squeeze (EEy_sJun_E_mean);
    
    
    %% JNDs -- Plots -- save files
    %xvalues = {'RefOmni'; 'Hyb OurAdjEEy'; 'Hyb OurAdjC80'; 'Hyb TEyring';'jnd'};
    xvalues = {'RefOmni'; 'Hyb OurAdjEEy'; 'Hyb OurAdjC80'; 'Hyb TEyring'};
    yvalues = {'Pos1'; 'Pos2'; 'Pos3';'Pos4';'Pos5';'Pos6';'Pos7';'Pos8'};

    newcolors = [0 0 0; 0 0.4470 0.7410; 0.93,0.69,0.13; 0.8500 0.3250 0.0980; 0 0 0];
    
    if ~(strcmp(tMix,'40'))
        fig_mean{j} = figure;
        tcl = tiledlayout(1,4,"TileSpacing","compact");
        nexttile(1);       
        h = heatmap(xvalues, yvalues, T20_sJun_E_mean([1:4],:)'); title (['T20 Error']); 
        h.ColorMethod = 'min'; h.Colormap = sky(10); %h.ColorScaling = 'scaledcolumns';
        nexttile(2); 
        h = heatmap(xvalues, yvalues, EDT_sJun_E_mean([1:4],:)'); title (['EDT Error']); 
        h.ColorMethod = 'min'; h.Colormap = sky(10); %h.ColorScaling = 'scaledcolumns';
        nexttile(3);
        h= heatmap(xvalues, yvalues, C80_sJun_E_mean([1:4],:)'); title (['C80 Error']);  
        h.ColorMethod = 'min'; h.Colormap = sky(10); %h.ColorScaling = 'scaledcolumns';
        nexttile(4);
        h = heatmap(xvalues, yvalues, EEy_sJun_E_mean'); title (['EEy Error']); 
        h.ColorMethod = 'min'; h.Colormap = sky(10); %h.ColorScaling = 'scaledcolumns'; 
        set(fig_mean{j},'Units','normalized');
        set(fig_mean{j},'Position',[0.180729166666667,0.159259259259259,0.708854166666667,0.348148148148148]);
        room = 'sJun';
        title(tcl,['Room ' room  ' Tmix ' tMix]);
        saveas(fig_mean{j},fullfile(path_save,[room '_Error_params_Tmix_' tMix '.fig']));
        saveas(fig_mean{j},fullfile(path_save,[room '_Error_params_Tmix_' tMix '.png']));
    end

    if ~(strcmp(tMix,'34'))
        fig_mean{j+1} = figure;
        tcl = tiledlayout(1,4,"TileSpacing","compact");
        nexttile(1);
        h = heatmap(xvalues, yvalues, T20_A108_E_mean([1:4],:)'); title (['T20 Error ' ]);  
        h.ColorMethod = 'min'; h.Colormap = sky(10); %h.ColorScaling = 'scaledcolumns';
        nexttile(2); 
        h = heatmap(xvalues, yvalues, EDT_A108_E_mean([1:4],:)'); title (['EDT Error ' ]);  
         h.ColorMethod = 'min'; h.Colormap = sky(10); %h.ColorScaling = 'scaledcolumns';
        nexttile(3);
        h = heatmap(xvalues, yvalues, C80_A108_E_mean([1:4],:)'); title (['C80 Error ' ]);  
         h.ColorMethod = 'min'; h.Colormap = sky(10); %h.ColorScaling = 'scaledcolumns';
        nexttile(4);
        h = heatmap(xvalues, yvalues, EEy_A108_E_mean'); title (['EEy Error']); 
        h.ColorMethod = 'min'; h.Colormap = sky(10); %h.ColorScaling = 'scaledcolumns';
        set(fig_mean{j+1},'Units','normalized');
        set(fig_mean{j+1},'Position',[0.180729166666667,0.159259259259259,0.708854166666667,0.348148148148148]);
        room = 'A108';
        title(tcl,['Room ' room  ' Tmix ' tMix]);
        saveas(fig_mean{j+1},fullfile(path_save,[room '_Error_params_Tmix_' tMix '.fig']));
        saveas(fig_mean{j+1},fullfile(path_save,[room '_Error_params_Tmix_' tMix '.png']));
    end

   
    %% -------------- Dist ----------------------------------
    xvalues = {'RefOmni'; 'Hyb OurAdjEEy'; 'Hyb OurAdjC80'; 'Hyb TEyring'};
    yvalues = {'Pos1'; 'Pos2'; 'Pos3';'Pos4';'Pos5';'Pos6';'Pos7';'Pos8'};

    if ~(strcmp(tMix,'40'))
        Tab_C80_sJun_cp = Tab_C80_sJun; % _cp --> a copy
        Tab_T20_sJun_cp = Tab_T20_sJun;
        Tab_EDT_sJun_cp = Tab_EDT_sJun;  
        Tab_EEy_sJun_cp = Tab_EEy_sJun;
        for k=1:size(Tab_EEy,3) %pos
            Tab_C80_sJun_cp(1,:,k) = 0;     Tab_C80_sJun_cp(9,:,k) = 0;    % bands 1 & 9  = 0
            Tab_T20_sJun_cp(1,:,k) = 0;     Tab_T20_sJun_cp(9,:,k) = 0;    % bands 1 & 9  = 0
            Tab_EDT_sJun_cp(1,:,k) = 0;     Tab_EDT_sJun_cp(9,:,k) = 0;    % bands 1 & 9  = 0
            Tab_EEy_sJun_cp(1,:,k) = 0;     Tab_EEy_sJun_cp(9,:,k) = 0;    % bands 1 & 9  = 0
            for i=1:size(Tab_EEy,2)
                C80_sJun_dist(:,i,k) = norm (Tab_C80_sJun_cp(:,1,k)  -  Tab_C80_sJun_cp(:,i,k));
                T20_sJun_dist(:,i,k) = norm (Tab_T20_sJun_cp(:,1,k)  -  Tab_T20_sJun_cp(:,i,k));
                EDT_sJun_dist(:,i,k) = norm (Tab_EDT_sJun_cp(:,1,k)  -  Tab_EDT_sJun_cp(:,i,k));
                EEy_sJun_dist(:,i,k) = norm (Tab_EEy_sJun_cp(:,1,k)  -  Tab_EEy_sJun_cp(:,i,k));
            end
        end
        C80_sJun_dist= squeeze (C80_sJun_dist); 
        T20_sJun_dist= squeeze (T20_sJun_dist);
        EDT_sJun_dist= squeeze (EDT_sJun_dist);
        EEy_sJun_dist= squeeze (EEy_sJun_dist);

        fig_dist{j} = figure;
        tcl = tiledlayout(1,4,"TileSpacing","compact");
        nexttile(1);       
        h = heatmap(xvalues, yvalues, T20_sJun_dist([1:4],:)'); title (['T20 Distance to ref']); 
        h.ColorMethod = 'min'; h.Colormap = sky(10); %h.ColorScaling = 'scaledcolumns';
        nexttile(2); 
        h = heatmap(xvalues, yvalues, EDT_sJun_dist([1:4],:)'); title (['EDT Distance to ref']); 
        h.ColorMethod = 'min'; h.Colormap = sky(10); %h.ColorScaling = 'scaledcolumns';
        nexttile(3);
        h= heatmap(xvalues, yvalues, C80_sJun_dist([1:4],:)'); title (['C80 Distance to ref']);  
        h.ColorMethod = 'min'; h.Colormap = sky(10); %h.ColorScaling = 'scaledcolumns';
        nexttile(4);
        h = heatmap(xvalues, yvalues, EEy_sJun_dist'); title (['EEy Distance to ref']); 
        h.ColorMethod = 'min'; h.Colormap = sky(10); %h.ColorScaling = 'scaledcolumns';
        set(fig_dist{j},'Units','normalized');
        set(fig_dist{j},'Position',[0.180729166666667,0.159259259259259,0.708854166666667,0.348148148148148]);
        room = 'sJun';
        title(tcl,['Room ' room  ' Tmix ' tMix]);
        saveas(fig_dist{j},fullfile(path_save,[room '_dist_params_Tmix_' tMix '.fig']));
        saveas(fig_dist{j},fullfile(path_save,[room '_dist_params_Tmix_' tMix '.png']));
    end

    if ~(strcmp(tMix,'34'))
        Tab_C80_A108_cp = Tab_C80_A108; % _cp --> a copy
        Tab_T20_A108_cp = Tab_T20_A108;
        Tab_EDT_A108_cp = Tab_EDT_A108;  
        Tab_EEy_A108_cp = Tab_EEy_A108;
        for k=1:size(Tab_EEy,3) %pos
            Tab_C80_A108_cp(1,:,k) = 0;  Tab_C80_A108_cp(9,:,k) = 0;    % bands 1 & 9  = 0
            Tab_T20_A108_cp(1,:,k) = 0;  Tab_T20_A108_cp(9,:,k) = 0;    % bands 1 & 9  = 0
            Tab_EDT_A108_cp(1,:,k) = 0;  Tab_EDT_A108_cp(9,:,k) = 0;    % bands 1 & 9  = 0
            Tab_EEy_A108_cp(1,:,k) = 0;  Tab_EEy_A108_cp(9,:,k) = 0;    % bands 1 & 9  = 0
            for i=1:size(Tab_EEy,2)
                C80_A108_dist(:,i,k) = norm (Tab_C80_A108_cp(:,1,k)  -  Tab_C80_A108_cp(:,i,k));
                T20_A108_dist(:,i,k) = norm (Tab_T20_A108_cp(:,1,k)  -  Tab_T20_A108_cp(:,i,k));
                EDT_A108_dist(:,i,k) = norm (Tab_EDT_A108_cp(:,1,k)  -  Tab_EDT_A108_cp(:,i,k));
                EEy_A108_dist(:,i,k) = norm (Tab_EEy_A108_cp(:,1,k)  -  Tab_EEy_A108_cp(:,i,k));
            end
        end
        C80_A108_dist= squeeze (C80_A108_dist);
        T20_A108_dist= squeeze (T20_A108_dist);
        EDT_A108_dist= squeeze (EDT_A108_dist);
        EEy_A108_dist= squeeze (EEy_A108_dist);
    
   
        fig_dist{j+1} = figure;
        tcl = tiledlayout(1,4,"TileSpacing","compact");
        nexttile(1);       
        h = heatmap(xvalues, yvalues, T20_A108_dist([1:4],:)'); title (['T20 Distance to ref']); 
        h.ColorMethod = 'min'; h.Colormap = sky(10); %h.ColorScaling = 'scaledcolumns';
        nexttile(2); 
        h = heatmap(xvalues, yvalues, EDT_A108_dist([1:4],:)'); title (['EDT Distance to ref']); 
        h.ColorMethod = 'min'; h.Colormap = sky(10); %h.ColorScaling = 'scaledcolumns';
        nexttile(3);
        h= heatmap(xvalues, yvalues, C80_A108_dist([1:4],:)'); title (['C80 Distance to ref']);  
        h.ColorMethod = 'min'; h.Colormap = sky(10); %h.ColorScaling = 'scaledcolumns';
        nexttile(4);
        h = heatmap(xvalues, yvalues, EEy_A108_dist'); title (['EEy Distance to ref']); 
        h.ColorMethod = 'min'; h.Colormap = sky(10); %h.ColorScaling = 'scaledcolumns';
        set(fig_dist{j+1},'Units','normalized');
        set(fig_dist{j+1},'Position',[0.180729166666667,0.159259259259259,0.708854166666667,0.348148148148148]);
        room = 'A108';
        title(tcl,['Room ' room  ' Tmix ' tMix]);
        saveas(fig_dist{j+1},fullfile(path_save,[room '_dist_params_Tmix_' tMix '.fig']));
        saveas(fig_dist{j+1},fullfile(path_save,[room '_dist_params_Tmix_' tMix '.png']));
    end
   clear C80_A108_dist, clear T20_A108_dist, clear EDT_A108_dist, clear EEy_A108_dist;
   clear C80_sJun_dist, clear T20_sJun_dist, clear EDT_sJun_dist, clear EEy_sJun_dist;
    
end






disp ('fin');