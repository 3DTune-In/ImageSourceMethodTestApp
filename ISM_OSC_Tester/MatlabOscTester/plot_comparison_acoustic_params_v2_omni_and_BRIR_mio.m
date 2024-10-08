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
close all;

%% Config
path_general = 'C:\Users\Fabian\OneDrive - Universidad de Málaga\3DIANA\Temas de Investigación\Metodo Imagenes HYBRID\';

% Reference BRIR measured 
path_reference_BRIR = fullfile(path_general, '2024_03_04_Medidas_aula108_salaJuntasTeleco\raw_measures');

%% Hybrid (ISM+conv) BRIR and absorption coefficients of OurAdjustment
%% OurAdjustment name pattern: room name (A108, sJun)-L#-S# with L=Listener position and S=Source position
name_room = 'sJun'; %'A108'; %'sJun';  
if isequal(name_room,'A108')
    name_path_room_hybrid = 'Aula108';
    name_path_room_meas = 'Sala108';
elseif isequal(name_room,'sJun')
    name_path_room_hybrid = 'SalaJuntas';
    name_path_room_meas = 'SalaJuntasTeleco';
end
%path_load_alpha_OurAdjustment_BRIR = fullfile(path_general, ['2024_07_11_SimulacionPosicionesBRIR_' name_path_room_hybrid '_AjusteOMNI']); 
%path_load_alpha_OurAdjustment_BRIR = fullfile(path_general, ['2024_09_18_SimulacionPosicionesBRIR_' name_path_room_hybrid '_AjusteOMNI']); 
path_load_alpha_OurAdjustment_BRIR = fullfile(path_general, ['2024_10_02_SimulacionPosicionesBRIR_' name_path_room_hybrid '_OMNI_EEy20']); 

%% Hybrid (ISM+conv) Omni with OurAdjustment
%path_OurAdjustment_Omni = fullfile(path_general, ['2024_07_24_SimulacionPosicionesOmni_' name_path_room_hybrid '_AjusteOMNI']);
%path_OurAdjustment_Omni = fullfile(path_general, ['2024_09_18_SimulacionPosicionesOmni_' name_path_room_hybrid '_AjusteOMNI']);
path_OurAdjustment_Omni = fullfile(path_general, ['2024_10_02_SimulacionPosicionesOmni_' name_path_room_hybrid '_OMNI_EEy20']);
%path_OurAdjustment_Omni = fullfile(path_general, ['2024_07_26_SimulacionPosicionesOmni_' name_path_room_hybrid '_AjusteOMNI_EDT']); 
%path_OurAdjustment_Omni = fullfile(path_general, ['2024_07_30_SimulacionPosicionesOmni_' name_path_room_hybrid '_AjusteOMNI_C80']); 

%% Hybrid (ISM+conv) BRIR with TEyring
%path_TEyring_BRIR = fullfile(path_general, ['2024_07_17_SimulacionPosicionesBRIR_' name_path_room_hybrid '_AjusteTeyring']);
path_TEyring_BRIR = fullfile(path_general, ['2024_09_18_SimulacionPosicionesBRIR_' name_path_room_hybrid '_AjusteTeyring']);

%% Hybrid (ISM+conv) Omni with TEyring
% path_TEyring_Omni = fullfile(path_general, ['2024_07_24_SimulacionPosicionesOmni_' name_path_room_hybrid '_AjusteTeyring']);
path_TEyring_Omni = fullfile(path_general, ['2024_09_18_SimulacionPosicionesOmni_' name_path_room_hybrid '_AjusteTeyring']);

% For absorption coefficient values
path_load_acoustic_params_omni = fullfile(path_general, '2024_03_04_Medidas_aula108_salaJuntasTeleco\Acoustic_parameters');
name_meas_acoustic_params_omni = [name_path_room_meas '_listener1_source-front2m_IR_AcousticParams.mat'];

% Indexes of Listener and Source positions
ind_listener =  [1,1,1,1,2,3,4,5];
ind_source =    [1,2,3,4,2,2,2,2];
table_meas = table;

% Channel to plot
channel_to_plot = 4; %3; % 1=L, 2=R, 3=BRIR average, 4=RIR omni (theres also the omni measurement which will be plot as reference)
% Band to plot
band_to_plot = [65 16000]; %[250 4000];  

% Range of plots (this is in relation with band_to plot -> xlim)
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
ylim_alpha = [0.05 0.4]; % absorption coefficients

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
elseif channel_to_plot == 4
    name_extra_path_save = 'RIR omni';
end
path_save = fullfile(path_general, '2024_07_17_coef_absorcion_Teyring_Acoustic_Params', ['Acoustic_parameters_v2_omni_and_BRIR_' num2str(band_to_plot(1)) '-' num2str(band_to_plot(2)) 'Hz'], name_extra_path_save); % 'BRIR_L'); % 'BRIR_R'); %average_BRIR/');

%% Load data
% Absorption coefficients from OurAdjustment method and TEyring (with omni measurement)
alpha_OurAdjustment = load(fullfile(path_load_alpha_OurAdjustment_BRIR, [name_room '-L1-S1'],'FiInfAbsorb.mat'));
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

        [brir_hybrid_our_BRIR{ind_pos}, fs_hybrid_our_BRIR] = audioread(fullfile(path_load_alpha_OurAdjustment_BRIR,[name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))], [name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos)) '-HYB.wav']));
        [brir_hybrid_our_Omni{ind_pos}, fs_hybrid_our_Omni] = audioread(fullfile(path_OurAdjustment_Omni,[name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))], [name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos)) '-HYB.wav']));

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

        brir_hybrid_our_BRIR{ind_pos} = audioread(fullfile(path_load_alpha_OurAdjustment_BRIR,[name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))], [name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos)) '-HYB.wav']));
        brir_hybrid_our_Omni{ind_pos} = audioread(fullfile(path_OurAdjustment_Omni,[name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))], [name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos)) '-HYB.wav']));

        brir_hybrid_TEyring_BRIR{ind_pos} = audioread(fullfile(path_TEyring_BRIR,[name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))], [name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos)) '-HYB.wav']));
        brir_hybrid_TEyring_Omni{ind_pos} = audioread(fullfile(path_TEyring_Omni,[name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))], [name_room '-L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos)) '-HYB.wav']));

    end

    table_meas.listener(ind_pos) = ind_listener(ind_pos); % table with redundant info about index of measurement
    table_meas.source(ind_pos) = ind_source(ind_pos);

    %%% Adjustment of level and length of all audio signals (NOT NECESSARY,
    %%% ita toolbox accurately takes these details into account by normalising and trimming IR in relation to the noise level)
    brir_reference{ind_pos} = level_factor.level_factor_D1SADIEII_to_raw * brir_reference{ind_pos};     % Level scale factor

    length_limit = min([size(brir_reference{ind_pos},1),size(brir_hybrid_our_BRIR{ind_pos},1),size(brir_hybrid_TEyring_BRIR{ind_pos},1),size(brir_hybrid_our_Omni{ind_pos},1),size(brir_hybrid_TEyring_Omni{ind_pos},1)]); % Equal lenght for all audio signals
    brir_reference{ind_pos} = brir_reference{ind_pos}(1:length_limit,:);
    brir_hybrid_our_BRIR{ind_pos} = brir_hybrid_our_BRIR{ind_pos}(1:length_limit,:);
    brir_hybrid_our_Omni{ind_pos} = brir_hybrid_our_Omni{ind_pos}(1:length_limit,:);
    brir_hybrid_TEyring_BRIR{ind_pos} = brir_hybrid_TEyring_BRIR{ind_pos}(1:length_limit,:);
    brir_hybrid_TEyring_Omni{ind_pos} = brir_hybrid_TEyring_Omni{ind_pos}(1:length_limit,:);
    %%%

    % Generate average mono channel from binaural signals 
    brir_reference{ind_pos}(:,4) = brir_reference{ind_pos}(:,3); % rearrange channel position of rir omni from channel 3 to 4
    brir_reference{ind_pos}(:,3) =  mean(brir_reference{ind_pos}(:,1:2),2);           % (column 3 is mono average from brir)
    brir_hybrid_our_BRIR{ind_pos}(:,3) =  mean(brir_hybrid_our_BRIR{ind_pos}(:,1:2),2);         % (column 3 is mono average from brir)
    brir_hybrid_TEyring_BRIR{ind_pos}(:,3) =  mean(brir_hybrid_TEyring_BRIR{ind_pos}(:,1:2),2); % (column 3 is mono average from brir)

    % Collect all IR in a single variable: 'BRIR Left';'BRIR Right';'mono average BRIR';'RIR omni'
    brir_hybrid_our{ind_pos} = [brir_hybrid_our_BRIR{ind_pos}, brir_hybrid_our_Omni{ind_pos}(:,1)];
    brir_hybrid_TEyring{ind_pos} = [brir_hybrid_TEyring_BRIR{ind_pos}, brir_hybrid_TEyring_Omni{ind_pos}(:,1)];

end

%% Create ITA-audio objects to feed the toolbox functions
for ind_pos=1:size(ind_listener,2)
    %Create empty audio objects
    itaObj_reference{ind_pos} = itaAudio;
    itaObj_hybrid_our{ind_pos} = itaAudio;
    itaObj_hybrid_TEyring{ind_pos} = itaAudio;
    % Set comment for entire audio object
    itaObj_reference{ind_pos}.comment = ['Reference BRIR and omni RIR measurement of ' name_room  ' position L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))];
    itaObj_hybrid_our{ind_pos}.comment = ['Hybrid BRIR and omni RIR with OurAdjustment method simulation of ' name_room  ' position L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))];
    itaObj_hybrid_TEyring{ind_pos}.comment = ['Hybrid BRIR and omni RIR with TEyring method simulation of ' name_room  ' position L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))];
    % Set sampling rate
    itaObj_reference{ind_pos}.samplingRate = metadata_reference.fs;
    itaObj_hybrid_our{ind_pos}.samplingRate = fs_hybrid_our_BRIR;
    itaObj_hybrid_TEyring{ind_pos}.samplingRate = fs_hybrid_TEyring_BRIR;
    % Set the time data
    itaObj_reference{ind_pos}.time = brir_reference{ind_pos};
    itaObj_hybrid_our{ind_pos}.time = brir_hybrid_our{ind_pos};
    itaObj_hybrid_TEyring{ind_pos}.time = brir_hybrid_TEyring{ind_pos};
    % Channel names 
    itaObj_reference{ind_pos}.channelNames = {'BRIR Left';'BRIR Right';'mono average BRIR';'RIR omni'};
    itaObj_hybrid_our{ind_pos}.channelNames = {'BRIR Left';'BRIR Right';'mono average BRIR';'RIR omni'};
    itaObj_hybrid_TEyring{ind_pos}.channelNames = {'BRIR Left';'BRIR Right';'mono average BRIR';'RIR omni'};
    % Change the length of the audio track
    itaObj_reference{ind_pos}.trackLength = size(brir_reference{ind_pos},1)/metadata_reference.fs;
    itaObj_hybrid_our{ind_pos}.trackLength = size(brir_hybrid_our{ind_pos},1)/fs_hybrid_our_BRIR;
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

    [raResults_hybrid_our{ind_pos}, filteredSignal_hybrid_our{ind_pos}] = ita_roomacoustics(itaObj_hybrid_our{ind_pos}, 'freqRange',freqRange, 'bandsPerOctave',bandsPerOctave,...
        'T20', 'C50','C80', 'D50', 'EDT'); % short list
    raResultsIACC_hybrid_our{ind_pos} = ita_roomacoustics_IACC(itaObj_hybrid_our{ind_pos}, 'freqRange',freqRange, 'bandsPerOctave',bandsPerOctave);
    disp(['Hybrid OurAdjustment Position L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))]);

    [raResults_hybrid_TEyring{ind_pos}, filteredSignal_hybrid_TEyring{ind_pos}] = ita_roomacoustics(itaObj_hybrid_TEyring{ind_pos}, 'freqRange',freqRange, 'bandsPerOctave',bandsPerOctave,...
        'T20', 'C50','C80', 'D50', 'EDT'); % short list
    raResultsIACC_hybrid_TEyring{ind_pos} = ita_roomacoustics_IACC(itaObj_hybrid_TEyring{ind_pos}, 'freqRange',freqRange, 'bandsPerOctave',bandsPerOctave);
    disp(['Hybrid TEyring Position L' num2str(ind_listener(ind_pos)) '-S' num2str(ind_source(ind_pos))]);

end

%% Arrange data for easy plots

% if channel_to_plot==3 % itaObj cannot store empty channels, then average BRIR channel is different for reference measurements
%     channel_to_plot_ref = 4;
% else
%     channel_to_plot_ref = channel_to_plot;
% end

for ind_pos=1:size(ind_listener,2)

      T20{ind_pos}(:,1) = raResults_reference{ind_pos}.T20.freqData(:,4);                      % Reference omni measured
      T20{ind_pos}(:,2) = raResults_hybrid_our{ind_pos}.T20.freqData(:,channel_to_plot);       % Hybrid OurAdjustment
      T20{ind_pos}(:,3) = raResults_hybrid_TEyring{ind_pos}.T20.freqData(:,channel_to_plot);   % Hybrid TEyring
%       T20{ind_pos}(:,4) = raResults_reference{ind_pos}.T20.freqData(:,channel_to_plot_ref);    % Reference average BRIR measured
      T20_fc{ind_pos}(:,1) = raResults_reference{ind_pos}.T20.freqVector;                   % central f octave bands
      T20_fc{ind_pos}(:,2) = raResults_hybrid_our{ind_pos}.T20.freqVector;
      T20_fc{ind_pos}(:,3) = raResults_hybrid_TEyring{ind_pos}.T20.freqVector;
%       T20_fc{ind_pos}(:,4) = raResults_reference{ind_pos}.T20.freqVector; 

      EDT{ind_pos}(:,1) = raResults_reference{ind_pos}.EDT.freqData(:,4);                      % Reference omni measured
      EDT{ind_pos}(:,2) = raResults_hybrid_our{ind_pos}.EDT.freqData(:,channel_to_plot);       % Hybrid OurAdjustment
      EDT{ind_pos}(:,3) = raResults_hybrid_TEyring{ind_pos}.EDT.freqData(:,channel_to_plot);   % Hybrid TEyring
%       EDT{ind_pos}(:,4) = raResults_reference{ind_pos}.EDT.freqData(:,channel_to_plot_ref);    % Reference average BRIR measured
      EDT_fc{ind_pos}(:,1) = raResults_reference{ind_pos}.EDT.freqVector;                   % central f octave bands
      EDT_fc{ind_pos}(:,2) = raResults_hybrid_our{ind_pos}.EDT.freqVector;
      EDT_fc{ind_pos}(:,3) = raResults_hybrid_TEyring{ind_pos}.EDT.freqVector;
%       EDT_fc{ind_pos}(:,4) = raResults_reference{ind_pos}.EDT.freqVector;

      C50{ind_pos}(:,1) = raResults_reference{ind_pos}.C50.freqData(:,4);                      % Reference omni measured
      C50{ind_pos}(:,2) = raResults_hybrid_our{ind_pos}.C50.freqData(:,channel_to_plot);       % Hybrid OurAdjustment
      C50{ind_pos}(:,3) = raResults_hybrid_TEyring{ind_pos}.C50.freqData(:,channel_to_plot);   % Hybrid TEyring
%       C50{ind_pos}(:,4) = raResults_reference{ind_pos}.C50.freqData(:,channel_to_plot_ref);    % Reference average BRIR measured
      C50_fc{ind_pos}(:,1) = raResults_reference{ind_pos}.C50.freqVector;                   % central f octave bands
      C50_fc{ind_pos}(:,2) = raResults_hybrid_our{ind_pos}.C50.freqVector;
      C50_fc{ind_pos}(:,3) = raResults_hybrid_TEyring{ind_pos}.C50.freqVector;
%       C50_fc{ind_pos}(:,4) = raResults_reference{ind_pos}.C50.freqVector;

      C80{ind_pos}(:,1) = raResults_reference{ind_pos}.C80.freqData(:,4);                      % Reference omni measured
      C80{ind_pos}(:,2) = raResults_hybrid_our{ind_pos}.C80.freqData(:,channel_to_plot);       % Hybrid OurAdjustment
      C80{ind_pos}(:,3) = raResults_hybrid_TEyring{ind_pos}.C80.freqData(:,channel_to_plot);   % Hybrid TEyring
%       C80{ind_pos}(:,4) = raResults_reference{ind_pos}.C80.freqData(:,channel_to_plot_ref);    % Reference average BRIR measured
      C80_fc{ind_pos}(:,1) = raResults_reference{ind_pos}.C80.freqVector;                   % central f octave bands
      C80_fc{ind_pos}(:,2) = raResults_hybrid_our{ind_pos}.C80.freqVector;
      C80_fc{ind_pos}(:,3) = raResults_hybrid_TEyring{ind_pos}.C80.freqVector;
%       C80_fc{ind_pos}(:,4) = raResults_reference{ind_pos}.C80.freqVector; 

      D50{ind_pos}(:,1) = raResults_reference{ind_pos}.D50.freqData(:,4);                      % Reference omni measured
      D50{ind_pos}(:,2) = raResults_hybrid_our{ind_pos}.D50.freqData(:,channel_to_plot);       % Hybrid OurAdjustment
      D50{ind_pos}(:,3) = raResults_hybrid_TEyring{ind_pos}.D50.freqData(:,channel_to_plot);   % Hybrid TEyring
%       D50{ind_pos}(:,4) = raResults_reference{ind_pos}.D50.freqData(:,channel_to_plot_ref);    % Reference average BRIR measured
      D50_fc{ind_pos}(:,1) = raResults_reference{ind_pos}.D50.freqVector;                   % central f octave bands
      D50_fc{ind_pos}(:,2) = raResults_hybrid_our{ind_pos}.D50.freqVector;
      D50_fc{ind_pos}(:,3) = raResults_hybrid_TEyring{ind_pos}.D50.freqVector;
%       D50_fc{ind_pos}(:,4) = raResults_reference{ind_pos}.D50.freqVector; 

      IACC_early{ind_pos}(:,1) = raResultsIACC_reference{ind_pos}.IACC_early.freqData;             % Reference BRIR measured
      IACC_early{ind_pos}(:,2) = raResultsIACC_hybrid_our{ind_pos}.IACC_early.freqData;            % Hybrid OurAdjustment BRIR
      IACC_early{ind_pos}(:,3) = raResultsIACC_hybrid_TEyring{ind_pos}.IACC_early.freqData;        % Hybrid TEyring BRIR
      IACC_early{ind_pos}(:,4) = raResultsIACC_reference{ind_pos}.IACC_early.freqData;             % Reference BRIR measured (idem channel 1)
      IACC_early_fc{ind_pos}(:,1) = raResultsIACC_reference{ind_pos}.IACC_early.freqVector;     % central f octave bands
      IACC_early_fc{ind_pos}(:,2) = raResultsIACC_hybrid_our{ind_pos}.IACC_early.freqVector;
      IACC_early_fc{ind_pos}(:,3) = raResultsIACC_hybrid_TEyring{ind_pos}.IACC_early.freqVector;
      IACC_early_fc{ind_pos}(:,4) = raResultsIACC_reference{ind_pos}.IACC_early.freqVector; 

      IACC_late{ind_pos}(:,1) = raResultsIACC_reference{ind_pos}.IACC_late.freqData;             % Reference BRIR measured
      IACC_late{ind_pos}(:,2) = raResultsIACC_hybrid_our{ind_pos}.IACC_late.freqData;            % Hybrid OurAdjustment BRIR
      IACC_late{ind_pos}(:,3) = raResultsIACC_hybrid_TEyring{ind_pos}.IACC_late.freqData;        % Hybrid TEyring BRIR
      IACC_late{ind_pos}(:,4) = raResultsIACC_reference{ind_pos}.IACC_late.freqData;             % Reference BRIR measured (idem channel 1)
      IACC_late_fc{ind_pos}(:,1) = raResultsIACC_reference{ind_pos}.IACC_late.freqVector;     % central f octave bands
      IACC_late_fc{ind_pos}(:,2) = raResultsIACC_hybrid_our{ind_pos}.IACC_late.freqVector;
      IACC_late_fc{ind_pos}(:,3) = raResultsIACC_hybrid_TEyring{ind_pos}.IACC_late.freqVector;
      IACC_late_fc{ind_pos}(:,4) = raResultsIACC_reference{ind_pos}.IACC_late.freqVector; 

      IACC_fullTime{ind_pos}(:,1) = raResultsIACC_reference{ind_pos}.IACC_fullTime.freqData;             % Reference BRIR measured
      IACC_fullTime{ind_pos}(:,2) = raResultsIACC_hybrid_our{ind_pos}.IACC_fullTime.freqData;            % Hybrid OurAdjustment BRIR
      IACC_fullTime{ind_pos}(:,3) = raResultsIACC_hybrid_TEyring{ind_pos}.IACC_fullTime.freqData;        % Hybrid TEyring BRIR
      IACC_fullTime{ind_pos}(:,4) = raResultsIACC_reference{ind_pos}.IACC_fullTime.freqData;             % Reference BRIR measured (idem channel 1)
      IACC_fullTime_fc{ind_pos}(:,1) = raResultsIACC_reference{ind_pos}.IACC_fullTime.freqVector;     % central f octave bands
      IACC_fullTime_fc{ind_pos}(:,2) = raResultsIACC_hybrid_our{ind_pos}.IACC_fullTime.freqVector;
      IACC_fullTime_fc{ind_pos}(:,3) = raResultsIACC_hybrid_TEyring{ind_pos}.IACC_fullTime.freqVector;
      IACC_fullTime_fc{ind_pos}(:,4) = raResultsIACC_reference{ind_pos}.IACC_fullTime.freqVector; 

end

% Add JND for each magnitude from Reference omni measurement
%%% JND of ISO 3382-1:2009 are questioned and values seem to depend on the sound content. 
%%% Some studies call to revise these JND and apply different values and
%%% conditions. See DelSolarDorrego2022 and its bibliography
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

    %%%%%% Is this correct? CHECK -> It seems is correct, is what the norm 
    %%%%%% norma ISO 3382-1:2009 says, but seems that ITA-toolbox gives % values 
    %%%%%% and the norm gives two decimal values (0,05)
    D50{ind_pos}(:,5) = D50{ind_pos}(:,1)+0.05*100; % +0.05  (1 JND)
    D50{ind_pos}(:,6) = D50{ind_pos}(:,1)-0.05*100; % -0.05 (1 JND)
    D50_fc{ind_pos}(:,5) = D50_fc{ind_pos}(:,1);
    D50_fc{ind_pos}(:,6) = D50_fc{ind_pos}(:,1);

    IACC_early{ind_pos}(:,5) = IACC_early{ind_pos}(:,1)+0.075; % +0.075  (1 JND)
    IACC_early{ind_pos}(:,6) = IACC_early{ind_pos}(:,1)-0.075; % -0.075 (1 JND)
    IACC_early_fc{ind_pos}(:,5) = IACC_early_fc{ind_pos}(:,1);
    IACC_early_fc{ind_pos}(:,6) = IACC_early_fc{ind_pos}(:,1);

    IACC_late{ind_pos}(:,5) = IACC_late{ind_pos}(:,1)+0.075; % +0.075  (1 JND)
    IACC_late{ind_pos}(:,6) = IACC_late{ind_pos}(:,1)-0.075; % -0.075 (1 JND)
    IACC_late_fc{ind_pos}(:,5) = IACC_late_fc{ind_pos}(:,1);
    IACC_late_fc{ind_pos}(:,6) = IACC_late_fc{ind_pos}(:,1);

    IACC_fullTime{ind_pos}(:,5) = IACC_fullTime{ind_pos}(:,1)+0.075; % +0.075  (1 JND)
    IACC_fullTime{ind_pos}(:,6) = IACC_fullTime{ind_pos}(:,1)-0.075; % -0.075 (1 JND)
    IACC_fullTime_fc{ind_pos}(:,5) = IACC_fullTime_fc{ind_pos}(:,1);
    IACC_fullTime_fc{ind_pos}(:,6) = IACC_fullTime_fc{ind_pos}(:,1);
end

% Arrange channel to plot names
legend_names = {'Reference omni'; ...
    strcat("Hybrid OurAdjustment ", string(raResults_hybrid_our{1}.EDT.channelNames(channel_to_plot))); ...
    strcat("Hybrid TEyring ", raResults_hybrid_TEyring{1}.EDT.channelNames(channel_to_plot)); ...
%     strcat("Reference ", raResults_reference{1}.EDT.channelNames(channel_to_plot)); ...
    'ref+JND';'ref-JND'; 'Calibration reference omni'};

legend_names_IACC = {'Reference BRIR'; 'Hybrid OurAdjustment BRIR'; 'Hybrid TEyring BRIR'; ...
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
semilogx(param_meas_omni.fc_octaves, alpha_OurAdjustment.absorbData1(1,:))
hold on;
semilogx(param_meas_omni.fc_octaves, param_meas_omni.alpha.alpha_T20)
xlabel('freq (Hz)'); grid on
ylim(ylim_alpha); % xlim(band_to_plot); 
title([name_room ' absorption coefficients \alpha'])
legend('\alpha from Our Adjustment','\alpha from T_{Eyring}', 'Location','northwest')

% newcolors = [0 0 0; 0 0.4470 0.7410; 0.8500 0.3250 0.0980; 0.9290 0.6940 0.1250; 0.7 0.7 0.7; 0.7 0.7 0.7; 0 0 0];
newcolors = [0 0 0; 0 0.4470 0.7410; 0.8500 0.3250 0.0980; 0.7 0.7 0.7; 0.7 0.7 0.7; 0 0 0];

for ind_pos=1:size(ind_listener,2)

    fig_acoustic{ind_pos} = figure;
    tcl = tiledlayout(2,3,"TileSpacing","compact"); 

    nexttile(1);
    semilogx(T20_fc{ind_pos}(:,1:3), T20{ind_pos}(:,1:3));
    hold on; semilogx(T20_fc{ind_pos}(:,5:6), T20{ind_pos}(:,5:6));
    hold on; semilogx(T20_fc{1}(:,1), T20{1}(:,1),'--'); % calibration position reference omni measured
    colororder(newcolors);
    grid on, xlabel('freq (Hz)'); ylabel('T20 (s)')
    xlim(band_to_plot); ylim(ylim_T);
    title('T20'); % legend(legend_names); 

    nexttile(2);
    semilogx(EDT_fc{ind_pos}(:,1:3), EDT{ind_pos}(:,1:3)); 
    hold on; semilogx(EDT_fc{ind_pos}(:,5:6), EDT{ind_pos}(:,5:6));
    hold on; semilogx(EDT_fc{1}(:,1), EDT{1}(:,1),'--'); % calibration position reference omni measured
    colororder(newcolors);
    grid on, xlabel('freq (Hz)'); ylabel('EDT (s)')
    xlim(band_to_plot); ylim(ylim_T);
    title('EDT'); %legend(legend_names, 'Location','eastoutside');

    ax_tile3 = nexttile(3); %%% ESTO ES SOLO PARA LA LEYENDA EN LA POSICIÓN 3.
    ax_tile3.Visible = "off";

    nexttile(4);
    semilogx(C50_fc{ind_pos}(:,1:3), C50{ind_pos}(:,1:3)); 
    hold on; semilogx(C50_fc{ind_pos}(:,5:6), C50{ind_pos}(:,5:6)); 
    hold on; semilogx(C50_fc{1}(:,1), C50{1}(:,1),'--'); % calibration position reference omni measured
    colororder(newcolors);
    grid on, xlabel('freq (Hz)'); ylabel('C50 (dB)')
    xlim(band_to_plot); ylim(ylim_C);
    title('C50'); % legend(legend_names); 

    nexttile(5);
    semilogx(C80_fc{ind_pos}(:,1:3), C80{ind_pos}(:,1:3)); 
    hold on; semilogx(C80_fc{ind_pos}(:,5:6), C80{ind_pos}(:,5:6));
    hold on; semilogx(C80_fc{1}(:,1), C80{1}(:,1),'--'); % calibration position reference omni measured
    colororder(newcolors);
    grid on, xlabel('freq (Hz)'); ylabel('C80 (dB)')
    xlim(band_to_plot); ylim(ylim_C);
    title('C80'); % legend(legend_names);

    nexttile(6);
    semilogx(D50_fc{ind_pos}(:,1:3), D50{ind_pos}(:,1:3)); 
    hold on; semilogx(D50_fc{ind_pos}(:,5:6), D50{ind_pos}(:,5:6)); 
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
newcolors_IACC = [0 0 0; 0 0.4470 0.7410; 0.8500 0.3250 0.0980; 0.7 0.7 0.7; 0.7 0.7 0.7; 0 0 0];

for ind_pos=1:size(ind_listener,2)

    fig_iacc{ind_pos} = figure;
    tcl = tiledlayout(1,3,"TileSpacing","compact"); 

    nexttile(1);
    semilogx(IACC_early_fc{ind_pos}(:,1:3), IACC_early{ind_pos}(:,1:3));
    hold on; semilogx(IACC_early_fc{ind_pos}(:,5:6), IACC_early{ind_pos}(:,5:6));
    hold on; semilogx(IACC_early_fc{1}(:,4), IACC_early{1}(:,4),'--'); % calibration position reference BRIR measured
    colororder(newcolors_IACC);
    grid on, xlabel('freq (Hz)'); ylabel('IACC')
    xlim(band_to_plot); ylim([0 1])
    title('IACC early'); % legend(legend_names); 

    nexttile(2);
    semilogx(IACC_late_fc{ind_pos}(:,1:3), IACC_late{ind_pos}(:,1:3));
    hold on; semilogx(IACC_late_fc{ind_pos}(:,5:6), IACC_late{ind_pos}(:,5:6));
    hold on; semilogx(IACC_late_fc{1}(:,4), IACC_late{1}(:,4),'--'); % calibration position reference BRIR measured
    colororder(newcolors_IACC);
    grid on, xlabel('freq (Hz)'); ylabel('IACC')
    xlim(band_to_plot); ylim([0 1])
    title('IACC late'); % legend(legend_names); 

    nexttile(3);
    semilogx(IACC_fullTime_fc{ind_pos}(:,1:3), IACC_fullTime{ind_pos}(:,1:3));
    hold on; semilogx(IACC_fullTime_fc{ind_pos}(:,5:6), IACC_fullTime{ind_pos}(:,5:6)); 
    hold on; semilogx(IACC_fullTime_fc{1}(:,4), IACC_fullTime{1}(:,4),'--'); % calibration position reference BRIR measured
    colororder(newcolors_IACC);
    grid on, xlabel('freq (Hz)'); ylabel('IACC')
    xlim(band_to_plot); ylim([0 1])
    title('IACC full time'); % legend(legend_names);
    hl_IACC = legend(legend_names_IACC, 'Location','eastoutside');

    set(fig_iacc{ind_pos},'Units','normalized');
    set(fig_iacc{ind_pos},'Position',[0.180729166666667,0.159259259259259,0.708854166666667,0.348148148148148]);

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