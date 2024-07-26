% Compare and plot of Acoustic Parameters and Reverberation Time
% 
% Three different cases:
% - Reference: real measurement (binaural)
% - Hybrid (ISM+conv) binaural with Our Adjustment 
% - Hybrid (ISM+conv) binaural with TEyring adjustment
%
% Also comparison between absorption coefficients (alpha) obtained through:
% - Our Adjustment method
% - TEyring formula
% both using an omnidirectional measurement in the seame reference point
% (Listener 1 position)
%
% Complement to hybrid reverberation method ISM+conv
% Acoustic Parameters come from ITA-Toolbox 
% 
% 17/07/2024 Pablo Gutierrez-Parera
% Universidad de Malaga

clear;
%close all;

%% Config
path_general = 'C:\Users\Fabian\OneDrive - Universidad de Málaga\3DIANA\Temas de Investigación\Metodo Imagenes HYBRID\';

% Reference BRIR measured 
path_reference_BRIR = fullfile(path_general, '2024_03_04_Medidas_aula108_salaJuntasTeleco\raw_measures');

% Hybrid (ISM+conv) BRIR and absorption coefficients of OurAdjustment
% OurAdjustment name pattern: room name (A108, sJun)-L#-S# with L=Listener position and S=Source position
name_room = 'A108'    %'A108'; % 'sJun';  
if isequal(name_room,'A108')
    name_path_room_hybrid = 'Aula108';
    name_path_room_meas = 'Sala108';
elseif isequal(name_room,'sJun')
    name_path_room_hybrid = 'SalaJuntas';
    name_path_room_meas = 'SalaJuntasTeleco';
end
%path_load_alpha_OurAdjustment = fullfil     e(path_general, ['2024_07_11_SimulacionPosiciones_' name_path_room_hybrid '_AjusteOMNI']); 
path_load_alpha_OurAdjustment = fullfile(path_general, ['2024_07_11_SimulacionPosicionesBRIR_' name_path_room_hybrid '_AjusteOMNI']); 
%path_load_alpha_OurAdjustment = fullfile(path_general, ['2024_07_24_SimulacionPosicionesOmni_' name_path_room_hybrid '_AjusteOMNI']); 

% Hybrid (ISM+conv) BRIR with TEyring
%path_TEyring_BRIR = fullfile(path_general, ['2024_07_17_SimulacionPosiciones_' name_path_room_hybrid '_AjusteTeyring']);
path_TEyring_BRIR = fullfile(path_general, ['2024_07_17_SimulacionPosicionesBRIR_' name_path_room_hybrid '_AjusteTeyring']);
%path_TEyring_BRIR = fullfile(path_general, ['2024_07_24_SimulacionPosicionesOmni_' name_path_room_hybrid '_AjusteTeyring']);

% For absorption coefficient values
path_load_acoustic_params_omni = fullfile(path_general, '2024_03_04_Medidas_aula108_salaJuntasTeleco\Acoustic_parameters');
name_meas_acoustic_params_omni = [name_path_room_meas '_listener1_source-front2m_IR_AcousticParams.mat'];

% Indexes of Listener and Source positions
ind_listener =  [1,1,1,1,2,3,4,5];
ind_source =    [1,2,3,4,2,2,2,2];
table_meas = table;

% Channel to plot
channel_to_plot = 3; %3; % 1=L, 2=R, 3=BRIR average (theres also the omni measurement which will be plot as reference)
% Band to plot
band_to_plot = [65 16000]; % [250 4000]; 

% Level scale factor
path_levelfactor = 'C:\Users\Fabian\OneDrive - Universidad de Málaga\3DIANA\Temas de Investigación\Metodo Imagenes HYBRID\2024_03_04_Medidas_aula108_salaJuntasTeleco';
name_levelfactor = ['level_factor_D1SADIEII_to_' name_room '_raw.mat'];

save_figs = 0;
if channel_to_plot == 1
    name_extra_path_save = 'BRIR_L';
elseif channel_to_plot == 2
    name_extra_path_save = 'BRIR_R';
elseif channel_to_plot == 3
    name_extra_path_save = 'average_BRIR';
end
path_save = fullfile(path_general, '2024_07_17_coef_absorcion_Teyring_Acoustic_Params', ['Acoustic_parameters_' num2str(band_to_plot(1)) '-' num2str(band_to_plot(2)) 'Hz'], name_extra_path_save); % 'BRIR_L'); % 'BRIR_R'); %average_BRIR/');

%% Load data
% Absorption coefficients from OurAdjustment method and TEyring (with omni measurement)
alpha_OurAdjustment = load(fullfile(path_load_alpha_OurAdjustment, [name_room '-L1-S1'],'FiInfAbsorb.mat'));
param_meas_omni = load(fullfile(path_load_acoustic_params_omni,name_meas_acoustic_params_omni));

% Level factor correction
level_factor = load(fullfile(path_levelfactor,name_levelfactor));

% RIRs to be compared
for ind_pos=1:size(ind_listener,2)
    if ind_source(ind_pos)==1 % additional control over source 1 position name
        name_extra_raw_meas = '-front2m';
    else
        name_extra_raw_meas = num2str(ind_source(ind_pos));
    end

    if ind_pos==1 % load pos=1 and check fs
        brir_reference_intermediate = load(fullfile(path_reference_BRIR, [name_path_room_meas '_listener' num2str(ind_listener(ind_pos)) '_source' name_extra_raw_meas '_IR.mat']));
        brir_reference{ind_pos} = brir_reference_intermediate.IR;
        metadata_reference = load(fullfile(path_reference_BRIR, [name_path_room_meas '_listener' num2str(ind_listener(ind_pos)) '_source' name_extra_raw_meas '_sweepmetadata.mat']));

        [brir_hybrid_our{ind_pos}, fs_hybrid_our] = audioread(fullfile(path_load_alpha_OurAdjustment,[name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))], [name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos)) '-HYB.wav']));

        [brir_hybrid_TEyring{ind_pos}, fs_hybrid_TEyring] = audioread(fullfile(path_TEyring_BRIR,[name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))], [name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos)) '-HYB.wav']));

        % check fs
        if isequal(metadata_reference.fs, fs_hybrid_our, fs_hybrid_TEyring)
            fs=fs_hybrid_our;
        else
            error('fs mismatch between simulations and measurements')
        end

   else
        brir_reference_intermediate = load(fullfile(path_reference_BRIR, [name_path_room_meas '_listener' num2str(ind_listener(ind_pos)) '_source' name_extra_raw_meas '_IR.mat']));
        brir_reference{ind_pos} = brir_reference_intermediate.IR;

        brir_hybrid_our{ind_pos} = audioread(fullfile(path_load_alpha_OurAdjustment,[name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))], [name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos)) '-HYB.wav']));

        brir_hybrid_TEyring{ind_pos} = audioread(fullfile(path_TEyring_BRIR,[name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))], [name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos)) '-HYB.wav']));
    end

    table_meas.listener(ind_pos) = ind_listener(ind_pos); % table with redundant info about index of measurement
    table_meas.source(ind_pos) = ind_source(ind_pos);

    %%% Adjustment of level and length of all audio signals (NOT NECESSARY,
    %%% ita toolbox accurately takes these details into account by normalising and trimming IR in relation to the noise level)
    brir_reference{ind_pos} = level_factor.level_factor_D1SADIEII_to_raw * brir_reference{ind_pos};     % Level scale factor

    length_limit = min([size(brir_reference{ind_pos},1),size(brir_hybrid_our{ind_pos},1),size(brir_hybrid_TEyring{ind_pos},1)]); % Equal lenght for all audio signals
    brir_reference{ind_pos} = brir_reference{ind_pos}(1:length_limit,:);
    brir_hybrid_our{ind_pos} = brir_hybrid_our{ind_pos}(1:length_limit,:);
    brir_hybrid_TEyring{ind_pos} = brir_hybrid_TEyring{ind_pos}(1:length_limit,:);
    %%%

    % Generate average mono channel from binaural signals 
    brir_reference{ind_pos}(:,4) =  mean(brir_reference{ind_pos}(:,1:2),2);           % (column 4 is mono average from brir)
    brir_hybrid_our{ind_pos}(:,3) =  mean(brir_hybrid_our{ind_pos}(:,1:2),2);         % (column 3 is mono average from brir)
    brir_hybrid_TEyring{ind_pos}(:,3) =  mean(brir_hybrid_TEyring{ind_pos}(:,1:2),2); % (column 3 is mono average from brir)

end

%% Create ITA-audio objects to feed the toolbox functions
for ind_pos=1:size(ind_listener,2)
    %% Create empty audio objects
    itaObj_reference{ind_pos} = itaAudio;
    itaObj_hybrid_our{ind_pos} = itaAudio;
    itaObj_hybrid_TEyring{ind_pos} = itaAudio;
    % Set comment for entire audio object
    itaObj_reference{ind_pos}.comment = ['Reference BRIR and omni RIR measurement of ' name_room  ' position L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))];
    itaObj_hybrid_our{ind_pos}.comment = ['Hybrid BRIR with OurAdjustment method simulation of ' name_room  ' position L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))];
    itaObj_hybrid_TEyring{ind_pos}.comment = ['Hybrid BRIR with TEyring method simulation of ' name_room  ' position L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))];
    %% Set sampling rate
    itaObj_reference{ind_pos}.samplingRate = metadata_reference.fs;
    itaObj_hybrid_our{ind_pos}.samplingRate = fs_hybrid_our;
    itaObj_hybrid_TEyring{ind_pos}.samplingRate = fs_hybrid_TEyring;
    %% Set the time data
    itaObj_reference{ind_pos}.time = brir_reference{ind_pos};
    itaObj_hybrid_our{ind_pos}.time = brir_hybrid_our{ind_pos};
    itaObj_hybrid_TEyring{ind_pos}.time = brir_hybrid_TEyring{ind_pos};
    %% Channel names 
    itaObj_reference{ind_pos}.channelNames = {'BRIR L';'BRIR R';'RIR omni';'mono average BRIR'};
    itaObj_hybrid_our{ind_pos}.channelNames = {'BRIR L';'BRIR R';'mono average BRIR'};
    itaObj_hybrid_TEyring{ind_pos}.channelNames = {'BRIR L';'BRIR R';'mono average BRIR'};
    %% Change the length of the audio track
    itaObj_reference{ind_pos}.trackLength = size(brir_reference{ind_pos},1)/metadata_reference.fs;
    itaObj_hybrid_our{ind_pos}.trackLength = size(brir_hybrid_our{ind_pos},1)/fs_hybrid_our;
    itaObj_hybrid_TEyring{ind_pos}.trackLength = size(brir_hybrid_TEyring{ind_pos},1)/fs_hybrid_TEyring;
end

%% Compute acoustic parameters
% T20, (T30?)
% C50, C80
% D50
% EDT
freqRange = [50 20000];
bandsPerOctave = 1;

 disp('Computed acoustic parameters:');
for ind_pos=1:size(ind_listener,2)
    [raResults_reference{ind_pos}, filteredSignal_reference{ind_pos}] = ita_roomacoustics(itaObj_reference{ind_pos}, 'freqRange',freqRange, 'bandsPerOctave',bandsPerOctave,...
        'T20', 'C50','C80', 'D50', 'EDT'); % short list
    %        'T20','T30','T60','T_Huszty','T_Lundeby', 'C50','C80', 'D50', 'EDT', 'Intersection_Time_Lundeby'); % long list
       disp(['Reference measured Position L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))]);

    [raResults_hybrid_our{ind_pos}, filteredSignal_hybrid_our{ind_pos}] = ita_roomacoustics(itaObj_hybrid_our{ind_pos}, 'freqRange',freqRange, 'bandsPerOctave',bandsPerOctave,...
        'T20', 'C50','C80', 'D50', 'EDT'); % short list
    disp(['Hybrid OurAdjustment Position L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))]);

    [raResults_hybrid_TEyring{ind_pos}, filteredSignal_hybrid_TEyring{ind_pos}] = ita_roomacoustics(itaObj_hybrid_TEyring{ind_pos}, 'freqRange',freqRange, 'bandsPerOctave',bandsPerOctave,...
        'T20', 'C50','C80', 'D50', 'EDT'); % short list
    disp(['Hybrid TEyring Position L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))]);

end

%% Arrange data for easy plots

if channel_to_plot==3 % itaObj cannot store empty channels, then average BRIR channel is different for reference measurements
    channel_to_plot_ref = 4;
else
    channel_to_plot_ref = channel_to_plot;
end

for ind_pos=1:size(ind_listener,2)

      T20{ind_pos}(:,1) = raResults_reference{ind_pos}.T20.freqData(:,3);                      % Reference omni measured
      T20{ind_pos}(:,2) = raResults_hybrid_our{ind_pos}.T20.freqData(:,channel_to_plot);       % Hybrid OurAdjustment
      T20{ind_pos}(:,3) = raResults_hybrid_TEyring{ind_pos}.T20.freqData(:,channel_to_plot);   % Hybrid TEyring
      T20{ind_pos}(:,4) = raResults_reference{ind_pos}.T20.freqData(:,channel_to_plot_ref);    % Reference average BRIR measured
      T20_fc{ind_pos}(:,1) = raResults_reference{ind_pos}.T20.freqVector;                   % central f octave bands
      T20_fc{ind_pos}(:,2) = raResults_hybrid_our{ind_pos}.T20.freqVector;
      T20_fc{ind_pos}(:,3) = raResults_hybrid_TEyring{ind_pos}.T20.freqVector;
      T20_fc{ind_pos}(:,4) = raResults_reference{ind_pos}.T20.freqVector; 

      EDT{ind_pos}(:,1) = raResults_reference{ind_pos}.EDT.freqData(:,3);                      % Reference omni measured
      EDT{ind_pos}(:,2) = raResults_hybrid_our{ind_pos}.EDT.freqData(:,channel_to_plot);       % Hybrid OurAdjustment
      EDT{ind_pos}(:,3) = raResults_hybrid_TEyring{ind_pos}.EDT.freqData(:,channel_to_plot);   % Hybrid TEyring
      EDT{ind_pos}(:,4) = raResults_reference{ind_pos}.EDT.freqData(:,channel_to_plot_ref);    % Reference average BRIR measured
      EDT_fc{ind_pos}(:,1) = raResults_reference{ind_pos}.EDT.freqVector;                   % central f octave bands
      EDT_fc{ind_pos}(:,2) = raResults_hybrid_our{ind_pos}.EDT.freqVector;
      EDT_fc{ind_pos}(:,3) = raResults_hybrid_TEyring{ind_pos}.EDT.freqVector;
      EDT_fc{ind_pos}(:,4) = raResults_reference{ind_pos}.EDT.freqVector;

      C50{ind_pos}(:,1) = raResults_reference{ind_pos}.C50.freqData(:,3);                      % Reference omni measured
      C50{ind_pos}(:,2) = raResults_hybrid_our{ind_pos}.C50.freqData(:,channel_to_plot);       % Hybrid OurAdjustment
      C50{ind_pos}(:,3) = raResults_hybrid_TEyring{ind_pos}.C50.freqData(:,channel_to_plot);   % Hybrid TEyring
      C50{ind_pos}(:,4) = raResults_reference{ind_pos}.C50.freqData(:,channel_to_plot_ref);    % Reference average BRIR measured
      C50_fc{ind_pos}(:,1) = raResults_reference{ind_pos}.C50.freqVector;                   % central f octave bands
      C50_fc{ind_pos}(:,2) = raResults_hybrid_our{ind_pos}.C50.freqVector;
      C50_fc{ind_pos}(:,3) = raResults_hybrid_TEyring{ind_pos}.C50.freqVector;
      C50_fc{ind_pos}(:,4) = raResults_reference{ind_pos}.C50.freqVector;

      C80{ind_pos}(:,1) = raResults_reference{ind_pos}.C80.freqData(:,3);                      % Reference omni measured
      C80{ind_pos}(:,2) = raResults_hybrid_our{ind_pos}.C80.freqData(:,channel_to_plot);       % Hybrid OurAdjustment
      C80{ind_pos}(:,3) = raResults_hybrid_TEyring{ind_pos}.C80.freqData(:,channel_to_plot);   % Hybrid TEyring
      C80{ind_pos}(:,4) = raResults_reference{ind_pos}.C80.freqData(:,channel_to_plot_ref);    % Reference average BRIR measured
      C80_fc{ind_pos}(:,1) = raResults_reference{ind_pos}.C80.freqVector;                   % central f octave bands
      C80_fc{ind_pos}(:,2) = raResults_hybrid_our{ind_pos}.C80.freqVector;
      C80_fc{ind_pos}(:,3) = raResults_hybrid_TEyring{ind_pos}.C80.freqVector;
      C80_fc{ind_pos}(:,4) = raResults_reference{ind_pos}.C80.freqVector; 

      D50{ind_pos}(:,1) = raResults_reference{ind_pos}.D50.freqData(:,3);                      % Reference omni measured
      D50{ind_pos}(:,2) = raResults_hybrid_our{ind_pos}.D50.freqData(:,channel_to_plot);       % Hybrid OurAdjustment
      D50{ind_pos}(:,3) = raResults_hybrid_TEyring{ind_pos}.D50.freqData(:,channel_to_plot);   % Hybrid TEyring
      D50{ind_pos}(:,4) = raResults_reference{ind_pos}.D50.freqData(:,channel_to_plot_ref);    % Reference average BRIR measured
      D50_fc{ind_pos}(:,1) = raResults_reference{ind_pos}.D50.freqVector;                   % central f octave bands
      D50_fc{ind_pos}(:,2) = raResults_hybrid_our{ind_pos}.D50.freqVector;
      D50_fc{ind_pos}(:,3) = raResults_hybrid_TEyring{ind_pos}.D50.freqVector;
      D50_fc{ind_pos}(:,4) = raResults_reference{ind_pos}.D50.freqVector; 

end

% Add JND for each magnitude from Reference omni measurement
for ind_pos=1:size(ind_listener,2)
    T20{ind_pos}(:,5) = 1.05*T20{ind_pos}(:,1); % +5% (1 JND)
    T20{ind_pos}(:,6) = 0.95*T20{ind_pos}(:,1); % -5% (1 JND)
    T20_fc{ind_pos}(:,5) = T20_fc{ind_pos}(:,1);
    T20_fc{ind_pos}(:,6) = T20_fc{ind_pos}(:,1);

    EDT{ind_pos}(:,5) = 1.05*EDT{ind_pos}(:,1); % +5% (1 JND)
    EDT{ind_pos}(:,6) = 0.95*EDT{ind_pos}(:,1); % -5% (1 JND)
    EDT_fc{ind_pos}(:,5) = EDT_fc{ind_pos}(:,1);
    EDT_fc{ind_pos}(:,6) = EDT_fc{ind_pos}(:,1);

    C50{ind_pos}(:,5) = C50{ind_pos}(:,1)+1; % +1dB (1 JND)
    C50{ind_pos}(:,6) = C50{ind_pos}(:,1)-1; % -1dB (1 JND)
    C50_fc{ind_pos}(:,5) = C50_fc{ind_pos}(:,1);
    C50_fc{ind_pos}(:,6) = C50_fc{ind_pos}(:,1);

    C80{ind_pos}(:,5) = C80{ind_pos}(:,1)+1; % +1dB (1 JND)
    C80{ind_pos}(:,6) = C80{ind_pos}(:,1)-1; % -1dB (1 JND)
    C80_fc{ind_pos}(:,5) = C80_fc{ind_pos}(:,1);
    C80_fc{ind_pos}(:,6) = C80_fc{ind_pos}(:,1);

    %%%%%% ¿ESTO ES CORRECTO? COMPROBAR -> Parece que sí, es lo que dice la norma ISO 3382-1:2009
    D50{ind_pos}(:,5) = D50{ind_pos}(:,1)+0.05; % +0.05  (1 JND)
    D50{ind_pos}(:,6) = D50{ind_pos}(:,1)-0.05; % -0.05 (1 JND)
    D50_fc{ind_pos}(:,5) = D50_fc{ind_pos}(:,1);
    D50_fc{ind_pos}(:,6) = D50_fc{ind_pos}(:,1);
end

% Arrange channel to plot names
legend_names = {'Reference omni'; ...
    strcat("Hybrid OurAdjustment ", string(raResults_hybrid_our{1}.EDT.channelNames(channel_to_plot))); ...
    strcat("Hybrid TEyring ", raResults_hybrid_TEyring{1}.EDT.channelNames(channel_to_plot)); ...
    strcat("Reference ", raResults_reference{1}.EDT.channelNames(channel_to_plot_ref)); 'ref+JND';'ref-JND'};

%% Plot acoustic parameters for each Listener-Source position

% % plot absorption coefficients (alpha). All theorical alpha from TEyring
% fig_alpha_all = figure;
% semilogx(param_meas.fc_octaves, param_meas.alpha{:,:})
% hold on;
% semilogx(param_meas.fc_octaves, alpha_OurAdjustment.absorbData1(1,:))
% xlabel('freq (Hz)'); grid on
% title([name_room ' absorption coefficients \alpha'])
% legend('\alpha from T_{20}','\alpha from T_{30}','\alpha from T_{60}','\alpha from T_{Huszty}','\alpha from T_{Lundeby}', '\alpha from Our Adjustment','Location','northwest')

% plot absorption coefficients (alpha). Only alpha T20 
fig_alpha = figure;
semilogx(param_meas_omni.fc_octaves, param_meas_omni.alpha.alpha_T20)
hold on;
semilogx(param_meas_omni.fc_octaves, alpha_OurAdjustment.absorbData1(1,:))
xlabel('freq (Hz)'); grid on
title([name_room ' absorption coefficients \alpha'])
legend('\alpha from T_{Eyring}', '\alpha from Our Adjustment','Location','northwest')

newcolors = [0 0 0; 0 0.4470 0.7410; 0.8500 0.3250 0.0980; 0.9290 0.6940 0.1250; 0.7 0.7 0.7; 0.7 0.7 0.7];

for ind_pos=1:size(ind_listener,2)

    fig_acoustic{ind_pos} = figure;
    tcl = tiledlayout(2,3,"TileSpacing","compact"); %%%%% AÑADIR 'COMPACT' 

    nexttile(1);
    semilogx(T20_fc{ind_pos}, T20{ind_pos}); colororder(newcolors);
    grid on, xlabel('freq (Hz)'); ylabel('T20 (s)')
    xlim(band_to_plot);
    title('T20'); % legend(legend_names); 

    nexttile(2);
    semilogx(EDT_fc{ind_pos}, EDT{ind_pos}); colororder(newcolors);
    grid on, xlabel('freq (Hz)'); ylabel('EDT (s)')
    xlim(band_to_plot);
    title('EDT'); %legend(legend_names, 'Location','eastoutside');


    ax_tile3 = nexttile(3); %%% ESTO ES SOLO PARA LA LEYENDA EN LA POSICIÓN 3. ARREGLAR
    ax_tile3.Visible = "off";

    nexttile(4);
    semilogx(C50_fc{ind_pos}, C50{ind_pos}); colororder(newcolors);
    grid on, xlabel('freq (Hz)'); ylabel('C50 (dB)')
    xlim(band_to_plot);
    title('C50'); % legend(legend_names); 

    nexttile(5);
    semilogx(C80_fc{ind_pos}, C80{ind_pos}); colororder(newcolors);
    grid on, xlabel('freq (Hz)'); ylabel('C80 (dB)')
    xlim(band_to_plot);
    title('C80'); % legend(legend_names);

    nexttile(6);
    semilogx(D50_fc{ind_pos}, D50{ind_pos}); colororder(newcolors);
    grid on, xlabel('freq (Hz)'); ylabel('D50')
    xlim(band_to_plot);
    title('D50'); % legend(legend_names); 

    set(fig_acoustic{ind_pos},'Units','normalized');
    set(fig_acoustic{ind_pos},'Position',[0.224479166666667,0.159259259259259,0.605208333333333,0.670370370370371]);

    hl = legend(legend_names); 
    oldLegendPos=get(hl,'Position');
    newLegendPos=get(ax_tile3,'Position');
%     set(hl,'Position',[newLegendPos(1) newLegendPos(2) oldLegendPos(3) oldLegendPos(4)])
    set(hl,'Position',[0.672887738111667,0.671764995599537,0.242685019892998,0.14157458168367])

    title(tcl,['Room ' name_room  ' position L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))])

end

%% Save figures
if save_figs
    % absorption coefficients figure
    saveas(fig_alpha,fullfile(path_save,[name_room '_alpha_OurAdjustment_and_Teyring.fig']));
    saveas(fig_alpha,fullfile(path_save,[name_room '_alpha_OurAdjustment_and_Teyring.png']));

    % acoustic parameters Listener-Source positions figures
    for ind_pos=1:size(ind_listener,2)
        saveas(fig_acoustic{ind_pos},fullfile(path_save,[name_room  '_AcousticParams_L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos)) '.fig'])); % '_channel_' string(raResults_hybrid_our{1}.EDT.channelNames(channel_to_plot)) '.fig']));
        saveas(fig_acoustic{ind_pos},fullfile(path_save,[name_room  '_AcousticParams_L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos)) '.png']));
    end
end