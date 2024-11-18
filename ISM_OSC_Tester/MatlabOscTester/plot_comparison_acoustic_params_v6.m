% Compare and plot of Acoustic Parameters and Reverberation Time
% 
% Four different cases:
% - Reference: real measurement (omni and binaural)
% - Hybrid (ISM+conv) binaural with Our Adjustment (EEy)
% - Hybrid (ISM+conv) binaural with TEyring adjustment
% - Hybrid (ISM+conv) binaural with Our Adjustment (C80)
%
% Also comparison between absorption coefficients (alpha) obtained through:
% - Our Adjustment method
% - TEyring formula
% both using an omnidirectional measurement in the same reference point
% (Listener 1 position)
%
% v3: includes figure with Our Adjustement acoustic parameter -> "Zona Media
% de IR" or "Hybrid-to-Measurement Early Reflection Factor acoustic parameter (Mxy)"
%
% v4: adapts to the new nomenclature of folders and cases:
%       adjustment of alpha values with EEy, C80, TEyring parameters 
%
% Complement to hybrid reverberation method ISM+conv
% Acoustic Parameters come from ITA-Toolbox 
% 
% 17/07/2024 Pablo Gutierrez-Parera
% Universidad de Malaga

%% --------------------------------------- 
%% v6: Generates the .MAT files with the data necessary to subsequently calculate 
%% average values ​​of the 8 positions and Figure of Merit (FOM) --> distance
%% for each parameter (C80, EDY, T20, EEy) within a Tmix value
%% A108_C80_tmix.mat <-- 'Err_C80a_t', 'Err_C80r_t', 'Err_C80rs_t', 'Tab_C80_t', 'Tab_C80', 'Err_C80rs'
%% .......
%% sJun_EDT_tmix.mat <-- 'Err_EDTa_t', 'Err_EDTr_t', 'Err_EDTrs_t', 'Tab_EDT_t', 'Tab_EDT', 'Err_EDTrs');
%%
%% Code --> from line 670 to the end
%%
%% 28/10/2024 Fabian Arrebola 
%% Universidad de Malaga
%% ---------------------------------------

clear;
close all;

%% Config
path_general = 'C:\Users\Fabian\OneDrive - Universidad de Málaga\3DIANA\Temas de Investigación\Metodo Imagenes HYBRID\';
path_general2 = 'C:\Repos\'

% Reference BRIR measured 
path_reference_BRIR = fullfile(path_general, '2024_03_04_Medidas_aula108_salaJuntasTeleco\raw_measures');

% Hybrid (ISM+conv) BRIR and absorption coefficients of OurAdjustment
% OurAdjustment name pattern: room name (A108, sJun)-L#-S# with L=Listener position and S=Source position
name_room =  'A108'; %'A108';  'sJun';     
if isequal(name_room,'A108')
    name_path_room_hybrid = 'Aula108';
    name_path_room_meas = 'Sala108';
elseif isequal(name_room,'sJun')
    name_path_room_hybrid = 'SalaJuntas';
    name_path_room_meas = 'SalaJuntasTeleco';
end

date_folder = '2024_10_21';
tmix = 40; % [IN METERS!] point of mix between ISM and reverb tail (convolution)

% Hybrid (ISM+conv) BRIR with OurAdjustment
% path_OurAdjustment_BRIR = fullfile(path_general, ['2024_07_11_SimulacionPosicionesBRIR_' name_path_room_hybrid '_AjusteOMNI']); 
% path_OurAdjustment_BRIR = fullfile(path_general, ['2024_09_18_SimulacionPosicionesBRIR_' name_path_room_hybrid '_AjusteOMNI']); 
path_OurAdjustment_BRIR_EEy = fullfile(path_general, [date_folder '_P_BRIR_' name_room '_EEY_' num2str(tmix)]);
path_OurAdjustment_BRIR_C80 = fullfile(path_general, [date_folder '_P_BRIR_' name_room '_C80_' num2str(tmix)]);
% Hybrid (ISM+conv) Omni with OurAdjustment (and absorption coefficients)
% path_alpha_OurAdjustment_Omni = fullfile(path_general, ['2024_07_24_SimulacionPosicionesOmni_' name_path_room_hybrid '_AjusteOMNI']); 
% path_alpha_OurAdjustment_Omni = fullfile(path_general, ['2024_07_30_SimulacionPosicionesOmni_' name_path_room_hybrid '_AjusteOMNI_C80']); 
% path_alpha_OurAdjustment_Omni = fullfile(path_general, ['2024_07_26_SimulacionPosicionesOmni_' name_path_room_hybrid '_AjusteOMNI_EDT']); 
path_alpha_OurAdjustment_Omni_EEy = fullfile(path_general, [date_folder '_P_Omni_' name_room '_EEY_' num2str(tmix)]);
path_alpha_OurAdjustment_Omni_C80 = fullfile(path_general, [date_folder '_P_Omni_' name_room '_C80_' num2str(tmix)]);

% Hybrid (ISM+conv) BRIR with TEyring
% path_TEyring_BRIR = fullfile(path_general, ['2024_07_17_SimulacionPosicionesBRIR_' name_path_room_hybrid '_AjusteTeyring']);
path_TEyring_BRIR = fullfile(path_general, [date_folder '_P_BRIR_' name_room '_Eyring_' num2str(tmix)]);
% Hybrid (ISM+conv) Omni with TEyring
% path_TEyring_Omni = fullfile(path_general, ['2024_07_24_SimulacionPosicionesOmni_' name_path_room_hybrid '_AjusteTeyring']);
path_TEyring_Omni = fullfile(path_general, [date_folder '_P_Omni_' name_room '_Eyring_' num2str(tmix)]);

% For absorption coefficient values
path_load_acoustic_params_omni = fullfile(path_general, '2024_03_04_Medidas_aula108_salaJuntasTeleco\Acoustic_parameters');
name_meas_acoustic_params_omni = [name_path_room_meas '_listener1_source-front2m_IR_AcousticParams.mat'];

plot_IACC = 0; % plot Interaural Cross-Correlation between BRIR L-R channels
plot_EEy = 1; % compute and plot Our Adjustment acoustic parameter -> Hybrid-to-Measurement Early Energy factor acoustic parameter (EEy)

% Indexes of Listener and Source positions
ind_listener =  [1,1,1,1,2,3,4,5];
ind_source =    [1,2,3,4,2,2,2,2];
table_meas = table;

% Channel to plot
channel_to_plot = 4; %3; % 1=L, 2=R, 3=BRIR average, 4=RIR omni (theres also the omni measurement which will be plot as reference)
% Band to plot
band_to_plot = [250 4000]; %[65 16000];  

% Range of plots (this is in relation with band_to_plot -> xlim)
if strcmp(name_room,'A108')
    if isequal(band_to_plot, [65 16000])
        ylim_T = [0 2]; % Time seconds
        ylim_C = [-10 20]; % Clarity dB
    elseif isequal(band_to_plot, [250 4000])
        ylim_T = [0.6 1.8]; % Time seconds
        ylim_C = [-6 12]; % Clarity dB
    end
elseif strcmp(name_room,'sJun')
    if isequal(band_to_plot, [65 16000])
        ylim_T = [0 2]; % Time seconds
        ylim_C = [-10 25]; % Clarity dB
    elseif isequal(band_to_plot, [250 4000])
        ylim_T = [0 1.2]; % Time seconds
        ylim_C = [-5 20]; % Clarity dB
    end
end
ylim_D = [0 100]; % Definition %
ylim_alpha = [0 0.4]; %[0.05 0.4]; % absorption coefficients

% Level scale factor
path_levelfactor = 'C:\Users\Fabian\OneDrive - Universidad de Málaga\3DIANA\Temas de Investigación\Metodo Imagenes HYBRID\2024_03_04_Medidas_aula108_salaJuntasTeleco';
name_levelfactor = ['level_factor_D1SADIEII_to_' name_room '_raw.mat'];

save_figs = 1;
if channel_to_plot == 1
    name_extra_path_save = 'BRIR_L';
elseif channel_to_plot == 2
    name_extra_path_save = 'BRIR_R';
elseif channel_to_plot == 3
    name_extra_path_save = 'average_BRIR';
elseif channel_to_plot == 4
    name_extra_path_save = ['_tmix' num2str(tmix) 'm']; %'_EDT_pruebasFabian'; %''; %'RIR omni';
end
path_save = fullfile(path_general2, '2024_10_17_Evaluation_Acoustic_Params', ['Acoustic_parameters_v4_' num2str(band_to_plot(1)) '-' num2str(band_to_plot(2)) 'Hz', name_extra_path_save]); % 'BRIR_L'); % 'BRIR_R'); %average_BRIR/');

%% Load data
% Absorption coefficients from OurAdjustment method and TEyring (with omni measurement)
alpha_OurAdjustment_EEy = load(fullfile(path_alpha_OurAdjustment_Omni_EEy, [name_room '-L1-S1'],'FiInfAbsorb.mat')); % for alpha with OurAdjustment EEy
alpha_OurAdjustment_C80 = load(fullfile(path_alpha_OurAdjustment_Omni_C80, [name_room '-L1-S1'],'FiInfAbsorb.mat')); % for alpha with OurAdjustment C80
param_meas_omni = load(fullfile(path_load_acoustic_params_omni,name_meas_acoustic_params_omni)); % for alpha with TEyring

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

        [brir_hybrid_our_BRIR_EEy{ind_pos}, fs_hybrid_our_BRIR] = audioread(fullfile(path_OurAdjustment_BRIR_EEy,[name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))], [name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos)) '-HYB.wav']));
        [brir_hybrid_our_Omni_EEy{ind_pos}, fs_hybrid_our_Omni] = audioread(fullfile(path_alpha_OurAdjustment_Omni_EEy,[name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))], [name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos)) '-HYB.wav']));

        [brir_hybrid_our_BRIR_C80{ind_pos}, fs_hybrid_our_BRIR] = audioread(fullfile(path_OurAdjustment_BRIR_C80,[name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))], [name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos)) '-HYB.wav']));
        [brir_hybrid_our_Omni_C80{ind_pos}, fs_hybrid_our_Omni] = audioread(fullfile(path_alpha_OurAdjustment_Omni_C80,[name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))], [name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos)) '-HYB.wav']));

        [brir_hybrid_TEyring_BRIR{ind_pos}, fs_hybrid_TEyring_BRIR] = audioread(fullfile(path_TEyring_BRIR,[name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))], [name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos)) '-HYB.wav']));
        [brir_hybrid_TEyring_Omni{ind_pos}, fs_hybrid_TEyring_Omni] = audioread(fullfile(path_TEyring_Omni,[name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))], [name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos)) '-HYB.wav']));

        % check fs
        if isequal(metadata_reference.fs, fs_hybrid_our_BRIR, fs_hybrid_TEyring_BRIR, fs_hybrid_our_Omni, fs_hybrid_TEyring_Omni)
            fs=fs_hybrid_our_BRIR;
        else
            error('fs mismatch between simulations and measurements')
        end

   else
        brir_reference_intermediate = load(fullfile(path_reference_BRIR, [name_path_room_meas '_listener' num2str(ind_listener(ind_pos)) '_source' name_extra_raw_meas '_IR.mat']));
        brir_reference{ind_pos} = brir_reference_intermediate.IR;

        brir_hybrid_our_BRIR_EEy{ind_pos} = audioread(fullfile(path_OurAdjustment_BRIR_EEy,[name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))], [name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos)) '-HYB.wav']));
        brir_hybrid_our_Omni_EEy{ind_pos} = audioread(fullfile(path_alpha_OurAdjustment_Omni_EEy,[name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))], [name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos)) '-HYB.wav']));

        [brir_hybrid_our_BRIR_C80{ind_pos}, fs_hybrid_our_BRIR] = audioread(fullfile(path_OurAdjustment_BRIR_C80,[name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))], [name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos)) '-HYB.wav']));
        [brir_hybrid_our_Omni_C80{ind_pos}, fs_hybrid_our_Omni] = audioread(fullfile(path_alpha_OurAdjustment_Omni_C80,[name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))], [name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos)) '-HYB.wav']));

        brir_hybrid_TEyring_BRIR{ind_pos} = audioread(fullfile(path_TEyring_BRIR,[name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))], [name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos)) '-HYB.wav']));
        brir_hybrid_TEyring_Omni{ind_pos} = audioread(fullfile(path_TEyring_Omni,[name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))], [name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos)) '-HYB.wav']));

    end

    table_meas.listener(ind_pos) = ind_listener(ind_pos); % table with redundant info about index of measurement
    table_meas.source(ind_pos) = ind_source(ind_pos);

    %%% Adjustment of level and length of all audio signals (NOT NECESSARY,
    %%% ita toolbox accurately takes these details into account by normalising and trimming IR in relation to the noise level)
    brir_reference{ind_pos} = level_factor.level_factor_D1SADIEII_to_raw * brir_reference{ind_pos};     % Level scale factor

    length_limit = min([size(brir_reference{ind_pos},1),size(brir_hybrid_our_BRIR_EEy{ind_pos},1),size(brir_hybrid_TEyring_BRIR{ind_pos},1),size(brir_hybrid_our_Omni_EEy{ind_pos},1),size(brir_hybrid_TEyring_Omni{ind_pos},1)]); % Equal lenght for all audio signals
    brir_reference{ind_pos} = brir_reference{ind_pos}(1:length_limit,:);
    brir_hybrid_our_BRIR_EEy{ind_pos} = brir_hybrid_our_BRIR_EEy{ind_pos}(1:length_limit,:);
    brir_hybrid_our_Omni_EEy{ind_pos} = brir_hybrid_our_Omni_EEy{ind_pos}(1:length_limit,:);
    brir_hybrid_our_BRIR_C80{ind_pos} = brir_hybrid_our_BRIR_C80{ind_pos}(1:length_limit,:);
    brir_hybrid_our_Omni_C80{ind_pos} = brir_hybrid_our_Omni_C80{ind_pos}(1:length_limit,:);
    brir_hybrid_TEyring_BRIR{ind_pos} = brir_hybrid_TEyring_BRIR{ind_pos}(1:length_limit,:);
    brir_hybrid_TEyring_Omni{ind_pos} = brir_hybrid_TEyring_Omni{ind_pos}(1:length_limit,:);
    %%%

    % Generate average mono channel from binaural signals 
    brir_reference{ind_pos}(:,4) = brir_reference{ind_pos}(:,3); % rearrange channel position of rir omni from channel 3 to 4
    brir_reference{ind_pos}(:,3) =  mean(brir_reference{ind_pos}(:,1:2),2);           % (column 3 is mono average from brir)
    brir_hybrid_our_BRIR_EEy{ind_pos}(:,3) =  mean(brir_hybrid_our_BRIR_EEy{ind_pos}(:,1:2),2);         % (column 3 is mono average from brir)
    brir_hybrid_our_BRIR_C80{ind_pos}(:,3) =  mean(brir_hybrid_our_BRIR_C80{ind_pos}(:,1:2),2);         % (column 3 is mono average from brir)
    brir_hybrid_TEyring_BRIR{ind_pos}(:,3) =  mean(brir_hybrid_TEyring_BRIR{ind_pos}(:,1:2),2); % (column 3 is mono average from brir)

    % Collect all IR in a single variable: 'BRIR Left';'BRIR Right';'mono average BRIR';'RIR omni'
    brir_hybrid_our_EEy{ind_pos} = [brir_hybrid_our_BRIR_EEy{ind_pos}, brir_hybrid_our_Omni_EEy{ind_pos}(:,1)];
    brir_hybrid_our_C80{ind_pos} = [brir_hybrid_our_BRIR_C80{ind_pos}, brir_hybrid_our_Omni_C80{ind_pos}(:,1)];
    brir_hybrid_TEyring{ind_pos} = [brir_hybrid_TEyring_BRIR{ind_pos}, brir_hybrid_TEyring_Omni{ind_pos}(:,1)];

end

%% Create ITA-audio objects to feed the toolbox functions
for ind_pos=1:size(ind_listener,2)
    %Create empty audio objects
    itaObj_reference{ind_pos} = itaAudio;
    itaObj_hybrid_our_EEy{ind_pos} = itaAudio;
        itaObj_hybrid_our_C80{ind_pos} = itaAudio;
    itaObj_hybrid_TEyring{ind_pos} = itaAudio;
    % Set comment for entire audio object
    itaObj_reference{ind_pos}.comment = ['Reference BRIR and omni RIR measurement of ' name_room  ' position L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))];
    itaObj_hybrid_our_EEy{ind_pos}.comment = ['Hybrid BRIR and omni RIR with OurAdjustment EEy method simulation of ' name_room  ' position L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))];
        itaObj_hybrid_our_C80{ind_pos}.comment = ['Hybrid BRIR and omni RIR with OurAdjustment C80 method simulation of ' name_room  ' position L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))];
    itaObj_hybrid_TEyring{ind_pos}.comment = ['Hybrid BRIR and omni RIR with TEyring method simulation of ' name_room  ' position L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))];
    % Set sampling rate
    itaObj_reference{ind_pos}.samplingRate = metadata_reference.fs;
    itaObj_hybrid_our_EEy{ind_pos}.samplingRate = fs_hybrid_our_BRIR;
        itaObj_hybrid_our_C80{ind_pos}.samplingRate = fs_hybrid_our_BRIR;
    itaObj_hybrid_TEyring{ind_pos}.samplingRate = fs_hybrid_TEyring_BRIR;
    % Set the time data
    itaObj_reference{ind_pos}.time = brir_reference{ind_pos};
    itaObj_hybrid_our_EEy{ind_pos}.time = brir_hybrid_our_EEy{ind_pos};
        itaObj_hybrid_our_C80{ind_pos}.time = brir_hybrid_our_C80{ind_pos};
    itaObj_hybrid_TEyring{ind_pos}.time = brir_hybrid_TEyring{ind_pos};
    % Channel names 
    itaObj_reference{ind_pos}.channelNames = {'BRIR Left';'BRIR Right';'mono average BRIR';'RIR omni'};
    itaObj_hybrid_our_EEy{ind_pos}.channelNames = {'BRIR Left';'BRIR Right';'mono average BRIR';'RIR omni'};
        itaObj_hybrid_our_C80{ind_pos}.channelNames = {'BRIR Left';'BRIR Right';'mono average BRIR';'RIR omni'};
    itaObj_hybrid_TEyring{ind_pos}.channelNames = {'BRIR Left';'BRIR Right';'mono average BRIR';'RIR omni'};
    % Change the length of the audio track
    itaObj_reference{ind_pos}.trackLength = size(brir_reference{ind_pos},1)/metadata_reference.fs;
    itaObj_hybrid_our_EEy{ind_pos}.trackLength = size(brir_hybrid_our_EEy{ind_pos},1)/fs_hybrid_our_BRIR;
        itaObj_hybrid_our_C80{ind_pos}.trackLength = size(brir_hybrid_our_C80{ind_pos},1)/fs_hybrid_our_BRIR;
    itaObj_hybrid_TEyring{ind_pos}.trackLength = size(brir_hybrid_TEyring{ind_pos},1)/fs_hybrid_TEyring_BRIR;
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
    raResultsIACC_reference{ind_pos} = ita_roomacoustics_IACC(itaObj_reference{ind_pos}, 'freqRange',freqRange, 'bandsPerOctave',bandsPerOctave);
    disp(['Reference measured Position L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))]);

    [raResults_hybrid_our_EEy{ind_pos}, filteredSignal_hybrid_our_EEy{ind_pos}] = ita_roomacoustics(itaObj_hybrid_our_EEy{ind_pos}, 'freqRange',freqRange, 'bandsPerOctave',bandsPerOctave,...
        'T20', 'C50','C80', 'D50', 'EDT'); % short list
    raResultsIACC_hybrid_our_EEy{ind_pos} = ita_roomacoustics_IACC(itaObj_hybrid_our_EEy{ind_pos}, 'freqRange',freqRange, 'bandsPerOctave',bandsPerOctave);
    disp(['Hybrid OurAdjustment EEy Position L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))]);

    [raResults_hybrid_our_C80{ind_pos}, filteredSignal_hybrid_our_C80{ind_pos}] = ita_roomacoustics(itaObj_hybrid_our_C80{ind_pos}, 'freqRange',freqRange, 'bandsPerOctave',bandsPerOctave,...
        'T20', 'C50','C80', 'D50', 'EDT'); % short list
    raResultsIACC_hybrid_our_C80{ind_pos} = ita_roomacoustics_IACC(itaObj_hybrid_our_C80{ind_pos}, 'freqRange',freqRange, 'bandsPerOctave',bandsPerOctave);
    disp(['Hybrid OurAdjustment C80 Position L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))]);

    [raResults_hybrid_TEyring{ind_pos}, filteredSignal_hybrid_TEyring{ind_pos}] = ita_roomacoustics(itaObj_hybrid_TEyring{ind_pos}, 'freqRange',freqRange, 'bandsPerOctave',bandsPerOctave,...
        'T20', 'C50','C80', 'D50', 'EDT'); % short list
    raResultsIACC_hybrid_TEyring{ind_pos} = ita_roomacoustics_IACC(itaObj_hybrid_TEyring{ind_pos}, 'freqRange',freqRange, 'bandsPerOctave',bandsPerOctave);
    disp(['Hybrid TEyring Position L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))]);

end

%% Compute Our Adjustment acoustic parameter -> Hybrid-to-Measurement Early Reflection Factor acoustic parameter (Mxy) 
if plot_EEy

    ir_reference = filteredSignal_reference{1}(4,1).time; % IR on reference calibration position
    for ind_pos=1:size(ind_listener,2)

        % Time range to compute the Mxy parameter
        t_ini= 100/fs;  % 2.1 ms
        t_end= (tmix-2.7)/343; % 40 meters   (20-2.7)/343; % 20 meters
        % Central frequencies of each octave band
        freqVector = raResults_reference{ind_pos}.T20.freqVector;
        % Impulse responses to compute the Mxy
        ir_meas = filteredSignal_reference{ind_pos}(4,1).time;
        ir_hybrid_our_EEy = filteredSignal_hybrid_our_EEy{ind_pos}(4,1).time;
        ir_hybrid_our_C80 = filteredSignal_hybrid_our_C80{ind_pos}(4,1).time;
        ir_hybrid_TEyring = filteredSignal_hybrid_TEyring{ind_pos}(3,1).time;

        % Compute the Mxy parameter
        EEy{ind_pos}(:,1) = compute_Mxy_acoustic_parameter(ir_reference, ir_meas, t_ini, t_end, fs)';    % IR reference vs measurement
        EEy{ind_pos}(:,2) = compute_Mxy_acoustic_parameter(ir_hybrid_our_EEy, ir_meas, t_ini, t_end, fs)';   % IR hybrid our adjustment EEy vs measurement
        EEy{ind_pos}(:,3) = compute_Mxy_acoustic_parameter(ir_hybrid_TEyring, ir_meas, t_ini, t_end, fs)';   % IR hybrid TEyring vs measurement
        EEy{ind_pos}(:,4) = compute_Mxy_acoustic_parameter(ir_hybrid_our_C80, ir_meas, t_ini, t_end, fs)';   % IR hybrid our adjustment C80 vs measurement

    end
end

%% Plot Mxy parameter
if plot_EEy

    legend_names = {'Reference omni'; ...
        strcat("Hybrid OurAdjustment EEy ", string(raResults_hybrid_our_EEy{1}.T20.channelNames(channel_to_plot))); ...
        strcat("Hybrid TEyring ", raResults_hybrid_TEyring{1}.T20.channelNames(channel_to_plot)); ...
                strcat("Hybrid OurAdjustment C80 ", string(raResults_hybrid_our_C80{1}.T20.channelNames(channel_to_plot))); ...
        'Calibration reference omni'};
    newcolors = [0 0 0; 0 0.4470 0.7410; 0.8500 0.3250 0.0980; 0.93,0.69,0.13; 0 0 0];

    fig_EEy=figure;
    tcl = tiledlayout(2,5,"TileSpacing","compact");
    for ind_pos=1:size(ind_listener,2)

        nexttile(ind_pos);
        semilogx(freqVector, EEy{ind_pos});
        hold on; semilogx(freqVector, EEy{1}(:,1),'--'); % calibration position reference omni measured
        colororder(newcolors);
        grid on, xlabel('freq (Hz)'); ylabel('EEy')
        xlim(band_to_plot); ylim([0 2.5]);
        title(['Room ' name_room  ' position L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))])

    end

    set(fig_EEy,'Units','normalized');
    set(fig_EEy,'Position',[0.1046875,0.207407407407407,0.81875,0.67037037037037]);

    hl = legend(legend_names);
%     oldLegendPos=get(hl,'Position');
%     newLegendPos=get(ax_tile,'Position');
    set(hl,'Position',[0.601899918725523,0.250453501724626,0.136132312431439,0.090469610789863])

%     title(tcl,'Mxy')
end

%% Arrange data for easy plots

% if channel_to_plot==3 % itaObj cannot store empty channels, then average BRIR channel is different for reference measurements
%     channel_to_plot_ref = 4;
% else
%     channel_to_plot_ref = channel_to_plot;
% end

for ind_pos=1:size(ind_listener,2)

      T20{ind_pos}(:,1) = raResults_reference{ind_pos}.T20.freqData(:,4);                      % Reference omni measured
      T20{ind_pos}(:,2) = raResults_hybrid_our_EEy{ind_pos}.T20.freqData(:,channel_to_plot);       % Hybrid OurAdjustment EEy
      T20{ind_pos}(:,3) = raResults_hybrid_TEyring{ind_pos}.T20.freqData(:,channel_to_plot);   % Hybrid TEyring
       T20{ind_pos}(:,4) = raResults_hybrid_our_C80{ind_pos}.T20.freqData(:,channel_to_plot);     % Hybrid OurAdjustment C80
      T20_fc{ind_pos}(:,1) = raResults_reference{ind_pos}.T20.freqVector;                   % central f octave bands
      T20_fc{ind_pos}(:,2) = raResults_hybrid_our_EEy{ind_pos}.T20.freqVector;
      T20_fc{ind_pos}(:,3) = raResults_hybrid_TEyring{ind_pos}.T20.freqVector;
       T20_fc{ind_pos}(:,4) = raResults_hybrid_our_C80{ind_pos}.T20.freqVector; 

      EDT{ind_pos}(:,1) = raResults_reference{ind_pos}.EDT.freqData(:,4);                      % Reference omni measured
      EDT{ind_pos}(:,2) = raResults_hybrid_our_EEy{ind_pos}.EDT.freqData(:,channel_to_plot);       % Hybrid OurAdjustment EEy
      EDT{ind_pos}(:,3) = raResults_hybrid_TEyring{ind_pos}.EDT.freqData(:,channel_to_plot);   % Hybrid TEyring
       EDT{ind_pos}(:,4) = raResults_hybrid_our_C80{ind_pos}.EDT.freqData(:,channel_to_plot);       % Hybrid OurAdjustment C80
      EDT_fc{ind_pos}(:,1) = raResults_reference{ind_pos}.EDT.freqVector;                   % central f octave bands
      EDT_fc{ind_pos}(:,2) = raResults_hybrid_our_EEy{ind_pos}.EDT.freqVector;
      EDT_fc{ind_pos}(:,3) = raResults_hybrid_TEyring{ind_pos}.EDT.freqVector;
       EDT_fc{ind_pos}(:,4) = raResults_hybrid_our_C80{ind_pos}.EDT.freqVector;

      C50{ind_pos}(:,1) = raResults_reference{ind_pos}.C50.freqData(:,4);                      % Reference omni measured
      C50{ind_pos}(:,2) = raResults_hybrid_our_EEy{ind_pos}.C50.freqData(:,channel_to_plot);       % Hybrid OurAdjustment EEy
      C50{ind_pos}(:,3) = raResults_hybrid_TEyring{ind_pos}.C50.freqData(:,channel_to_plot);   % Hybrid TEyring
       C50{ind_pos}(:,4) = raResults_hybrid_our_C80{ind_pos}.C50.freqData(:,channel_to_plot);       % Hybrid OurAdjustment C80
      C50_fc{ind_pos}(:,1) = raResults_reference{ind_pos}.C50.freqVector;                   % central f octave bands
      C50_fc{ind_pos}(:,2) = raResults_hybrid_our_EEy{ind_pos}.C50.freqVector;
      C50_fc{ind_pos}(:,3) = raResults_hybrid_TEyring{ind_pos}.C50.freqVector;
       C50_fc{ind_pos}(:,4) = raResults_hybrid_our_C80{ind_pos}.C50.freqVector;

      C80{ind_pos}(:,1) = raResults_reference{ind_pos}.C80.freqData(:,4);                      % Reference omni measured
      C80{ind_pos}(:,2) = raResults_hybrid_our_EEy{ind_pos}.C80.freqData(:,channel_to_plot);       % Hybrid OurAdjustment EEy
      C80{ind_pos}(:,3) = raResults_hybrid_TEyring{ind_pos}.C80.freqData(:,channel_to_plot);   % Hybrid TEyring
       C80{ind_pos}(:,4) = raResults_hybrid_our_C80{ind_pos}.C80.freqData(:,channel_to_plot);       % Hybrid OurAdjustment C80
      C80_fc{ind_pos}(:,1) = raResults_reference{ind_pos}.C80.freqVector;                   % central f octave bands
      C80_fc{ind_pos}(:,2) = raResults_hybrid_our_EEy{ind_pos}.C80.freqVector;
      C80_fc{ind_pos}(:,3) = raResults_hybrid_TEyring{ind_pos}.C80.freqVector;
       C80_fc{ind_pos}(:,4) = raResults_hybrid_our_C80{ind_pos}.C80.freqVector; 

      D50{ind_pos}(:,1) = raResults_reference{ind_pos}.D50.freqData(:,4);                      % Reference omni measured
      D50{ind_pos}(:,2) = raResults_hybrid_our_EEy{ind_pos}.D50.freqData(:,channel_to_plot);       % Hybrid OurAdjustment EEy
      D50{ind_pos}(:,3) = raResults_hybrid_TEyring{ind_pos}.D50.freqData(:,channel_to_plot);   % Hybrid TEyring
       D50{ind_pos}(:,4) = raResults_hybrid_our_C80{ind_pos}.D50.freqData(:,channel_to_plot);       % Hybrid OurAdjustment C80
      D50_fc{ind_pos}(:,1) = raResults_reference{ind_pos}.D50.freqVector;                   % central f octave bands
      D50_fc{ind_pos}(:,2) = raResults_hybrid_our_EEy{ind_pos}.D50.freqVector;
      D50_fc{ind_pos}(:,3) = raResults_hybrid_TEyring{ind_pos}.D50.freqVector;
       D50_fc{ind_pos}(:,4) = raResults_hybrid_our_C80{ind_pos}.D50.freqVector; 

      IACC_early{ind_pos}(:,1) = raResultsIACC_reference{ind_pos}.IACC_early.freqData;             % Reference BRIR measured
      IACC_early{ind_pos}(:,2) = raResultsIACC_hybrid_our_EEy{ind_pos}.IACC_early.freqData;            % Hybrid OurAdjustment BRIR EEy
      IACC_early{ind_pos}(:,3) = raResultsIACC_hybrid_TEyring{ind_pos}.IACC_early.freqData;        % Hybrid TEyring BRIR
       IACC_early{ind_pos}(:,4) = raResultsIACC_hybrid_our_C80{ind_pos}.IACC_early.freqData;            % Hybrid OurAdjustment BRIR C80
      IACC_early_fc{ind_pos}(:,1) = raResultsIACC_reference{ind_pos}.IACC_early.freqVector;     % central f octave bands
      IACC_early_fc{ind_pos}(:,2) = raResultsIACC_hybrid_our_EEy{ind_pos}.IACC_early.freqVector;
      IACC_early_fc{ind_pos}(:,3) = raResultsIACC_hybrid_TEyring{ind_pos}.IACC_early.freqVector;
       IACC_early_fc{ind_pos}(:,4) = raResultsIACC_hybrid_our_C80{ind_pos}.IACC_early.freqVector; 

      IACC_late{ind_pos}(:,1) = raResultsIACC_reference{ind_pos}.IACC_late.freqData;             % Reference BRIR measured
      IACC_late{ind_pos}(:,2) = raResultsIACC_hybrid_our_EEy{ind_pos}.IACC_late.freqData;            % Hybrid OurAdjustment BRIR EEy
      IACC_late{ind_pos}(:,3) = raResultsIACC_hybrid_TEyring{ind_pos}.IACC_late.freqData;        % Hybrid TEyring BRIR
       IACC_late{ind_pos}(:,4) = raResultsIACC_hybrid_our_C80{ind_pos}.IACC_late.freqData;            % Hybrid OurAdjustment BRIR C80
      IACC_late_fc{ind_pos}(:,1) = raResultsIACC_reference{ind_pos}.IACC_late.freqVector;     % central f octave bands
      IACC_late_fc{ind_pos}(:,2) = raResultsIACC_hybrid_our_EEy{ind_pos}.IACC_late.freqVector;
      IACC_late_fc{ind_pos}(:,3) = raResultsIACC_hybrid_TEyring{ind_pos}.IACC_late.freqVector;
       IACC_late_fc{ind_pos}(:,4) = raResultsIACC_hybrid_our_C80{ind_pos}.IACC_late.freqVector; 

      IACC_fullTime{ind_pos}(:,1) = raResultsIACC_reference{ind_pos}.IACC_fullTime.freqData;             % Reference BRIR measured
      IACC_fullTime{ind_pos}(:,2) = raResultsIACC_hybrid_our_EEy{ind_pos}.IACC_fullTime.freqData;            % Hybrid OurAdjustment BRIR EEy
      IACC_fullTime{ind_pos}(:,3) = raResultsIACC_hybrid_TEyring{ind_pos}.IACC_fullTime.freqData;        % Hybrid TEyring BRIR
       IACC_fullTime{ind_pos}(:,4) = raResultsIACC_hybrid_our_C80{ind_pos}.IACC_fullTime.freqData;            % Hybrid OurAdjustment BRIR C80
      IACC_fullTime_fc{ind_pos}(:,1) = raResultsIACC_reference{ind_pos}.IACC_fullTime.freqVector;     % central f octave bands
      IACC_fullTime_fc{ind_pos}(:,2) = raResultsIACC_hybrid_our_EEy{ind_pos}.IACC_fullTime.freqVector;
      IACC_fullTime_fc{ind_pos}(:,3) = raResultsIACC_hybrid_TEyring{ind_pos}.IACC_fullTime.freqVector;
       IACC_fullTime_fc{ind_pos}(:,4) = raResultsIACC_hybrid_our_C80{ind_pos}.IACC_fullTime.freqVector;
end




% Add JND for each magnitude from Reference omni measurement
%%% JND of ISO 3382-1:2009 are questioned and values seem to depend on the sound content. 
%%% Some studies call to revise these JND and apply different values and
%%% conditions. See DelSolarDorrego2022 and its bibliography
jnd_pos = [5 6];
for ind_pos=1:size(ind_listener,2)
    T20{ind_pos}(:,jnd_pos(1)) = 1.05*T20{ind_pos}(:,1); % +5% (1 JND)
    T20{ind_pos}(:,jnd_pos(2)) = 0.95*T20{ind_pos}(:,1); % -5% (1 JND)
    T20_fc{ind_pos}(:,jnd_pos(1)) = T20_fc{ind_pos}(:,1);
    T20_fc{ind_pos}(:,jnd_pos(2)) = T20_fc{ind_pos}(:,1);

    EDT{ind_pos}(:,jnd_pos(1)) = 1.05*EDT{ind_pos}(:,1); % +5% (1 JND)
    EDT{ind_pos}(:,jnd_pos(2)) = 0.95*EDT{ind_pos}(:,1); % -5% (1 JND)
    EDT_fc{ind_pos}(:,jnd_pos(1)) = EDT_fc{ind_pos}(:,1);
    EDT_fc{ind_pos}(:,jnd_pos(2)) = EDT_fc{ind_pos}(:,1);

    C50{ind_pos}(:,jnd_pos(1)) = C50{ind_pos}(:,1)+1; % +1dB (1 JND)
    C50{ind_pos}(:,jnd_pos(2)) = C50{ind_pos}(:,1)-1; % -1dB (1 JND)
    C50_fc{ind_pos}(:,jnd_pos(1)) = C50_fc{ind_pos}(:,1);
    C50_fc{ind_pos}(:,jnd_pos(2)) = C50_fc{ind_pos}(:,1);

    C80{ind_pos}(:,jnd_pos(1)) = C80{ind_pos}(:,1)+1; % +1dB (1 JND)
    C80{ind_pos}(:,jnd_pos(2)) = C80{ind_pos}(:,1)-1; % -1dB (1 JND)
    C80_fc{ind_pos}(:,jnd_pos(1)) = C80_fc{ind_pos}(:,1);
    C80_fc{ind_pos}(:,jnd_pos(2)) = C80_fc{ind_pos}(:,1);

    %%%%%% Is this correct? CHECK -> It seems is correct, is what the norm 
    %%%%%% norma ISO 3382-1:2009 says, but seems that ITA-toolbox gives % values 
    %%%%%% and the norm gives two decimal values (0,05)
    D50{ind_pos}(:,jnd_pos(1)) = D50{ind_pos}(:,1)+0.05*100; % +0.05  (1 JND)
    D50{ind_pos}(:,jnd_pos(2)) = D50{ind_pos}(:,1)-0.05*100; % -0.05 (1 JND)
    D50_fc{ind_pos}(:,jnd_pos(1)) = D50_fc{ind_pos}(:,1);
    D50_fc{ind_pos}(:,jnd_pos(2)) = D50_fc{ind_pos}(:,1);

    IACC_early{ind_pos}(:,jnd_pos(1)) = IACC_early{ind_pos}(:,1)+0.075; % +0.075  (1 JND)
    IACC_early{ind_pos}(:,jnd_pos(2)) = IACC_early{ind_pos}(:,1)-0.075; % -0.075 (1 JND)
    IACC_early_fc{ind_pos}(:,jnd_pos(1)) = IACC_early_fc{ind_pos}(:,1);
    IACC_early_fc{ind_pos}(:,jnd_pos(2)) = IACC_early_fc{ind_pos}(:,1);

    IACC_late{ind_pos}(:,jnd_pos(1)) = IACC_late{ind_pos}(:,1)+0.075; % +0.075  (1 JND)
    IACC_late{ind_pos}(:,jnd_pos(2)) = IACC_late{ind_pos}(:,1)-0.075; % -0.075 (1 JND)
    IACC_late_fc{ind_pos}(:,jnd_pos(1)) = IACC_late_fc{ind_pos}(:,1);
    IACC_late_fc{ind_pos}(:,jnd_pos(2)) = IACC_late_fc{ind_pos}(:,1);

    IACC_fullTime{ind_pos}(:,jnd_pos(1)) = IACC_fullTime{ind_pos}(:,1)+0.075; % +0.075  (1 JND)
    IACC_fullTime{ind_pos}(:,jnd_pos(2)) = IACC_fullTime{ind_pos}(:,1)-0.075; % -0.075 (1 JND)
    IACC_fullTime_fc{ind_pos}(:,jnd_pos(1)) = IACC_fullTime_fc{ind_pos}(:,1);
    IACC_fullTime_fc{ind_pos}(:,jnd_pos(2)) = IACC_fullTime_fc{ind_pos}(:,1);
end

% Arrange channel to plot names
legend_names = {'Reference omni'; ...
    strcat("Hybrid OurAdjustment EEy ", string(raResults_hybrid_our_EEy{1}.EDT.channelNames(channel_to_plot))); ...
    strcat("Hybrid TEyring ", raResults_hybrid_TEyring{1}.EDT.channelNames(channel_to_plot)); ...
    strcat("Hybrid OurAdjustment C80 ", string(raResults_hybrid_our_C80{1}.EDT.channelNames(channel_to_plot))); ...
%     strcat("Reference ", raResults_reference{1}.EDT.channelNames(channel_to_plot)); ...
    'ref+JND';'ref-JND'; 'Calibration reference omni'};

legend_names_IACC = {'Reference BRIR'; 'Hybrid OurAdjustment BRIR EEy'; 'Hybrid TEyring BRIR'; 'Hybrid OurAdjustment BRIR C80'; ...
    'ref+JND';'ref-JND'; 'Calibration reference BRIR'};

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
semilogx(param_meas_omni.fc_octaves, alpha_OurAdjustment_EEy.absorbData1(1,:))
hold on;
semilogx(param_meas_omni.fc_octaves, param_meas_omni.alpha.alpha_T20)
hold on;
semilogx(param_meas_omni.fc_octaves, alpha_OurAdjustment_C80.absorbData1(1,:))
xlabel('freq (Hz)'); grid on
ylim(ylim_alpha); % xlim(band_to_plot); 
title([name_room ' absorption coefficients \alpha'])
legend('\alpha from Our Adjustment EEy','\alpha from T_{Eyring}','\alpha from Our Adjustment EEy', 'Location','northwest')

% newcolors = [0 0 0; 0 0.4470 0.7410; 0.8500 0.3250 0.0980; 0.9290 0.6940 0.1250; 0.7 0.7 0.7; 0.7 0.7 0.7; 0 0 0];
newcolors = [0 0 0; 0 0.4470 0.7410; 0.8500 0.3250 0.0980; 0.93,0.69,0.13; 0.7 0.7 0.7; 0.7 0.7 0.7; 0 0 0];

for ind_pos=1:size(ind_listener,2)

    fig_acoustic{ind_pos} = figure;
    tcl = tiledlayout(2,3,"TileSpacing","compact"); 

    nexttile(1);
    semilogx(T20_fc{ind_pos}, T20{ind_pos});
%     semilogx(T20_fc{ind_pos}(:,1:3), T20{ind_pos}(:,1:3));
%     hold on; semilogx(T20_fc{ind_pos}(:,5:6), T20{ind_pos}(:,5:6));
    hold on; semilogx(T20_fc{1}(:,1), T20{1}(:,1),'--'); % calibration position reference omni measured
    colororder(newcolors);
    grid on, xlabel('freq (Hz)'); ylabel('T20 (s)')
    xlim(band_to_plot); ylim(ylim_T);
    title('T20'); % legend(legend_names); 

    nexttile(2);
        semilogx(EDT_fc{ind_pos}, EDT{ind_pos});
%     semilogx(EDT_fc{ind_pos}(:,1:3), EDT{ind_pos}(:,1:3)); 
%     hold on; semilogx(EDT_fc{ind_pos}(:,5:6), EDT{ind_pos}(:,5:6));
    hold on; semilogx(EDT_fc{1}(:,1), EDT{1}(:,1),'--'); % calibration position reference omni measured
    colororder(newcolors);
    grid on, xlabel('freq (Hz)'); ylabel('EDT (s)')
    xlim(band_to_plot); ylim(ylim_T);
    title('EDT'); %legend(legend_names, 'Location','eastoutside');

    ax_tile3 = nexttile(3); %%% ESTO ES SOLO PARA LA LEYENDA EN LA POSICIÓN 3.
    ax_tile3.Visible = "off";

    nexttile(4);
    semilogx(C50_fc{ind_pos}, C50{ind_pos});
%     semilogx(C50_fc{ind_pos}(:,1:3), C50{ind_pos}(:,1:3));
%     hold on; semilogx(C50_fc{ind_pos}(:,5:6), C50{ind_pos}(:,5:6)); 
    hold on; semilogx(C50_fc{1}(:,1), C50{1}(:,1),'--'); % calibration position reference omni measured
    colororder(newcolors);
    grid on, xlabel('freq (Hz)'); ylabel('C50 (dB)')
    xlim(band_to_plot); ylim(ylim_C);
    title('C50'); % legend(legend_names); 

    nexttile(5);
    semilogx(C80_fc{ind_pos}, C80{ind_pos});
%     semilogx(C80_fc{ind_pos}(:,1:3), C80{ind_pos}(:,1:3));
%     hold on; semilogx(C80_fc{ind_pos}(:,5:6), C80{ind_pos}(:,5:6));
    hold on; semilogx(C80_fc{1}(:,1), C80{1}(:,1),'--'); % calibration position reference omni measured
    colororder(newcolors);
    grid on, xlabel('freq (Hz)'); ylabel('C80 (dB)')
    xlim(band_to_plot); ylim(ylim_C);
    title('C80'); % legend(legend_names);

    nexttile(6);
    semilogx(D50_fc{ind_pos}, D50{ind_pos});
%     semilogx(D50_fc{ind_pos}(:,1:3), D50{ind_pos}(:,1:3)); 
%     hold on; semilogx(D50_fc{ind_pos}(:,5:6), D50{ind_pos}(:,5:6)); 
    hold on; semilogx(D50_fc{1}(:,1), D50{1}(:,1),'--'); % calibration position reference omni measured
    colororder(newcolors);
    grid on, xlabel('freq (Hz)'); ylabel('D50 (%)')
    xlim(band_to_plot); ylim(ylim_D);
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

%% Plot Interaural Cross Correlation IACC for each Listener-Source position
if plot_IACC

    newcolors_IACC = [0 0 0; 0 0.4470 0.7410; 0.8500 0.3250 0.0980; 0.93,0.69,0.13; 0.7 0.7 0.7; 0.7 0.7 0.7; 0 0 0];

    for ind_pos=1:size(ind_listener,2)

        fig_iacc{ind_pos} = figure;
        tcl = tiledlayout(1,3,"TileSpacing","compact");

        nexttile(1);
        semilogx(IACC_early_fc{ind_pos}, IACC_early{ind_pos});
%         semilogx(IACC_early_fc{ind_pos}(:,1:3), IACC_early{ind_pos}(:,1:3));
%         hold on; semilogx(IACC_early_fc{ind_pos}(:,5:6), IACC_early{ind_pos}(:,5:6));
        hold on; semilogx(IACC_early_fc{1}(:,1), IACC_early{1}(:,1),'--'); % calibration position reference BRIR measured
        colororder(newcolors_IACC);
        grid on, xlabel('freq (Hz)'); ylabel('IACC')
        xlim(band_to_plot); ylim([0 1])
        title('IACC early'); % legend(legend_names);

        nexttile(2);
        semilogx(IACC_late_fc{ind_pos}, IACC_late{ind_pos});
%         semilogx(IACC_late_fc{ind_pos}(:,1:3), IACC_late{ind_pos}(:,1:3));
%         hold on; semilogx(IACC_late_fc{ind_pos}(:,5:6), IACC_late{ind_pos}(:,5:6));
        hold on; semilogx(IACC_late_fc{1}(:,1), IACC_late{1}(:,1),'--'); % calibration position reference BRIR measured
        colororder(newcolors_IACC);
        grid on, xlabel('freq (Hz)'); ylabel('IACC')
        xlim(band_to_plot); ylim([0 1])
        title('IACC late'); % legend(legend_names);

        nexttile(3);
        semilogx(IACC_fullTime_fc{ind_pos}, IACC_fullTime{ind_pos});
%         semilogx(IACC_fullTime_fc{ind_pos}(:,1:3), IACC_fullTime{ind_pos}(:,1:3));
%         hold on; semilogx(IACC_fullTime_fc{ind_pos}(:,5:6), IACC_fullTime{ind_pos}(:,5:6));
        hold on; semilogx(IACC_fullTime_fc{1}(:,1), IACC_fullTime{1}(:,1),'--'); % calibration position reference BRIR measured
        colororder(newcolors_IACC);
        grid on, xlabel('freq (Hz)'); ylabel('IACC')
        xlim(band_to_plot); ylim([0 1])
        title('IACC full time'); % legend(legend_names);
        hl_IACC = legend(legend_names_IACC, 'Location','eastoutside');

        set(fig_iacc{ind_pos},'Units','normalized');
        set(fig_iacc{ind_pos},'Position',[0.180729166666667,0.159259259259259,0.708854166666667,0.348148148148148]);

        title(tcl,['Room ' name_room  ' position L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))])

    end
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

    if plot_IACC % interaural cross-correlation Listener-Source positions figures
        for ind_pos=1:size(ind_listener,2)
            saveas(fig_iacc{ind_pos},fullfile(path_save,[name_room  '_IACC_L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos)) '.fig']));
            saveas(fig_iacc{ind_pos},fullfile(path_save,[name_room  '_IACC_L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos)) '.png']));
        end
    end
% end
% 
% %%
% if save_figs
    if plot_EEy
        saveas(fig_EEy,fullfile(path_save,[name_room  '_EEy.fig']));
        saveas(fig_EEy,fullfile(path_save,[name_room  '_EEy.png']));
    end
end

%% ---------------------------------------
%% Generate Mat and Xlsx files with tables
%% ---------------------------------------

for ind_pos=1:size(ind_listener,2)
    %% Col order: -- Ref -- Our_EEy -- TEyring -- Our_C80  -- [jnd1]-- [jnd2] --> [optional]
    EEy{ind_pos}(:, [3, 4]) = EEy{ind_pos}(:, [4, 3]);                        % swap cols 3 4
    %% Col order: -- Ref -- Our_EEy -- Our_C80 -- TEyring  -- [jnd1]-- [jnd2] --> [optional]
    
    %% 9frec x Nc x 8 pos <-- 9xNc
    Tab_EEy(: , : ,ind_pos) = EEy{ind_pos}; 
    % 9xNc
    Tab_EEyCell(: , : ) = EEy{ind_pos};
    p=ind_pos; pi=1+(p-1)*9; pf=pi+8;
    %% 72xNc
    Tab_EEy_t([pi:pf] , : ) = Tab_EEyCell(: , : );

    Err_EEya  (: , : ,ind_pos) = abs(EEy{ind_pos}(: , :) - EEy{ind_pos}(:, 1));     % absolute error
    Err_EEyr  (: , : ,ind_pos) = abs(EEy{ind_pos}(: , :) ./ EEy{ind_pos}(:, 1) -1); % relative error
    Err_EEyrs (: , : ,ind_pos) = Err_EEyr(: , 1:4 ,ind_pos);                        % relative short error
    Err_EEya_t ([pi:pf] , : )  = abs(EEy{ind_pos}(: , :) - EEy{ind_pos}(:, 1));     % absolute error
    Err_EEyr_t ([pi:pf] , : )  = abs(EEy{ind_pos}(: , :) ./ EEy{ind_pos}(:, 1) -1); % relative error
    Err_EEyrs_t([pi:pf] , : )  = Err_EEyr(: , 1:4 ,ind_pos);                        % relative short error
    %% T20 --------------------------------------
    T20{ind_pos}(:, [3, 4]) = T20{ind_pos}(:, [4, 3]);                              % swap cols 3 4
    Tab_T20   (: , : ,ind_pos) = T20{ind_pos};
    Err_T20a  (: , : ,ind_pos) = abs(T20{ind_pos}(: , :) - T20{ind_pos}(:, 1));     % absolute error
    Err_T20r  (: , : ,ind_pos) = abs(T20{ind_pos}(: , :) ./ T20{ind_pos}(:, 1) -1); % relative error
    Err_T20rs (: , : ,ind_pos) = Err_T20r(: , 1:5 ,ind_pos);                        % relative short error
    % 72xNc
    Tab_T20_t  ([pi:pf] , : ) = T20{ind_pos};
    Err_T20a_t ([pi:pf] , : ) = abs(T20{ind_pos}(: , :) - T20{ind_pos}(:, 1));     % absolute error
    Err_T20r_t ([pi:pf] , : ) = abs(T20{ind_pos}(: , :) ./ T20{ind_pos}(:, 1) -1); % relative error
    Err_T20rs_t([pi:pf] , : ) = Err_T20r(: , 1:5 ,ind_pos);                       % relative short error
    %% EDT --------------------------------------
    EDT{ind_pos}(:, [3, 4]) = EDT{ind_pos}(:, [4, 3]);                            % swap cols 3 4
    Tab_EDT  (: , : ,ind_pos) = EDT{ind_pos};
    Err_EDTa (: , : ,ind_pos) = abs(EDT{ind_pos}(: , :) - EDT{ind_pos}(:, 1));
    Err_EDTr (: , : ,ind_pos) = abs(EDT{ind_pos}(: , :) ./ EDT{ind_pos}(:, 1) -1);
    Err_EDTrs(: , : ,ind_pos) = Err_EDTr(: , 1:5 ,ind_pos);
    Tab_EDT_t  ([pi:pf] , : ) = EDT{ind_pos};
    Err_EDTa_t ([pi:pf] , : ) = abs(EDT{ind_pos}(: , :) - EDT{ind_pos}(:, 1));
    Err_EDTr_t ([pi:pf] , : ) = abs(EDT{ind_pos}(: , :) ./ EDT{ind_pos}(:, 1) -1);
    Err_EDTrs_t([pi:pf] , : ) = Err_EDTr(: , 1:5 ,ind_pos);
    %% C80 --------------------------------------
    C80{ind_pos}(:, [3, 4]) = C80{ind_pos}(:, [4, 3]);                            % swap cols 3 4
    Tab_C80(: , : ,ind_pos) = C80{ind_pos};
    Err_C80a(: , : ,ind_pos) = abs(C80{ind_pos}(: , :) - C80{ind_pos}(:, 1));
    Err_C80r(: , : ,ind_pos) = abs(C80{ind_pos}(: , :) ./ C80{ind_pos}(:, 1) -1);
    Err_C80rs(: , : ,ind_pos) = Err_C80r(: , 1:5 ,ind_pos);
    Tab_C80_t  ([pi:pf] , : ) = C80{ind_pos};
    Err_C80a_t ([pi:pf] , : ) = abs(C80{ind_pos}(: , :) - C80{ind_pos}(:, 1));
    Err_C80r_t ([pi:pf] , : ) = abs(C80{ind_pos}(: , :) ./ C80{ind_pos}(:, 1) -1);
    Err_C80rs_t([pi:pf] , : ) = Err_C80r(: , 1:5 ,ind_pos);
    %% IACC_early --------------------------------------   
    IACC_early{ind_pos}(:, [3, 4]) = IACC_early{ind_pos}(:, [4, 3]);              % swap cols 3 4
    Tab_IACC_early(: , : ,ind_pos) = IACC_early{ind_pos};
    Err_IACC_early_a(: , : ,ind_pos) = abs(IACC_early{ind_pos}(: , :) - IACC_early{ind_pos}(:, 1));
    Err_IACC_early_r(: , : ,ind_pos) = abs(IACC_early{ind_pos}(: , :) ./ IACC_early{ind_pos}(:, 1) -1);
    Err_IACC_early_rs(: , : ,ind_pos) = Err_IACC_early_r(: , 1:5 ,ind_pos);
    % IACC_early{ind_pos}(:, [3, 4]) = IACC_early{ind_pos}(:, [4, 3]);              % swap cols 3 4
    Tab_IACC_early_t([pi:pf] , : )= IACC_early{ind_pos};
    Err_IACC_early_a_t([pi:pf] , : ) = abs(IACC_early{ind_pos}(: , :) - IACC_early{ind_pos}(:, 1));
    Err_IACC_early_r_t([pi:pf] , : ) = abs(IACC_early{ind_pos}(: , :) ./ IACC_early{ind_pos}(:, 1) -1);
    Err_IACC_early_rs_t([pi:pf] , : ) = Err_IACC_early_r(: , 1:5 ,ind_pos);
    %% IACC_late --------------------------------------
    IACC_late{ind_pos}(:, [3, 4]) = IACC_late{ind_pos}(:, [4, 3]);                % swap cols 3 4
    Tab_IACC_late(: , : ,ind_pos) = IACC_late{ind_pos};
    Err_IACC_late_a(: , : ,ind_pos) = abs(IACC_late{ind_pos}(: , :) - IACC_late{ind_pos}(:, 1));
    Err_IACC_late_r(: , : ,ind_pos) = abs(IACC_late{ind_pos}(: , :) ./ IACC_late{ind_pos}(:, 1) -1);
    Err_IACC_late_rs(: , : ,ind_pos) = Err_IACC_late_r(: , 1:5 ,ind_pos);
    %% IACC_fullTime --------------------------------------
    IACC_fullTime{ind_pos}(:, [3, 4]) = IACC_fullTime{ind_pos}(:, [4, 3]);        % swap cols 3 4
    Tab_IACC_fullTime(: , : ,ind_pos) = IACC_fullTime{ind_pos};
    Err_IACC_fullTime_a(: , : ,ind_pos) = abs(IACC_fullTime{ind_pos}(: , :) - IACC_fullTime{ind_pos}(:, 1));
    Err_IACC_fullTime_r(: , : ,ind_pos) = abs(IACC_fullTime{ind_pos}(: , :) ./ IACC_fullTime{ind_pos}(:, 1) -1);
    Err_IACC_fullTime_rs(: , : ,ind_pos) = Err_IACC_fullTime_r(: , 1:5 ,ind_pos);
end
nameFile= [name_room '_EEy_tmix' num2str(tmix)  '.mat'];
save(fullfile( path_save,   nameFile), 'Err_EEya_t', 'Err_EEyr_t', 'Err_EEyrs_t', 'Tab_EEy_t', 'Tab_EEy' , 'Err_EEyrs');

nameFile= [name_room '_T20_tmix' num2str(tmix)  '.mat'];
save(fullfile( path_save,   nameFile), 'Err_T20a_t', 'Err_T20r_t', 'Err_T20rs_t', 'Tab_T20_t', 'Tab_T20', 'Err_T20rs');

nameFile= [name_room '_C80_tmix' num2str(tmix)  '.mat'];
save(fullfile( path_save,   nameFile), 'Err_C80a_t', 'Err_C80r_t', 'Err_C80rs_t', 'Tab_C80_t', 'Tab_C80', 'Err_C80rs');

nameFile= [name_room '_EDT_tmix' num2str(tmix)  '.mat'];
save(fullfile( path_save,   nameFile), 'Err_EDTa_t', 'Err_EDTr_t', 'Err_EDTrs_t', 'Tab_EDT_t', 'Tab_EDT', 'Err_EDTrs');

nameFile= [name_room '_IACC_early_tmix' num2str(tmix)  '.mat'];
save(fullfile( path_save,   nameFile), 'Err_IACC_early_a_t', 'Err_IACC_early_r_t', 'Err_IACC_early_rs_t', 'Tab_IACC_early_t', 'Tab_IACC_early')

nameFile= [name_room '_IACC_late_tmix' num2str(tmix)  '.mat'];
save(fullfile( path_save,   nameFile), 'Err_IACC_late_a', 'Err_IACC_late_r', 'Err_IACC_late_rs', 'Tab_IACC_late');

nameFile= [name_room '_IACC_fullTime_tmix' num2str(tmix)  '.mat'];
save(fullfile( path_save,   nameFile), 'Err_IACC_fullTime_a', 'Err_IACC_fullTime_r', 'Err_IACC_fullTime_rs', 'Tab_IACC_fullTime');