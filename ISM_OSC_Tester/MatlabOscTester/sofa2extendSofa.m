
%% Extends the length of impulse responses in a .sofa file if the specified 
%% length is greater than the length initial impulse response by adding 
%% samples that are random noise.
%% If the specified length is less tan initial length, trims the initial 
%% impulse response by removing the samples located at the end.

% Authors: Fabian Arrebola (16/12/2024) 
% contact: areyesa@uma.es
% 3DDIANA research group. University of Malaga
% Project: SONICOM
% 
% Copyright (C) 2024 Universidad de Málaga

addpath ('C:\Users\FABIAN\Documents\MATLAB\SOFAtoolbox');
SOFAstart;

close all; clear all;

cd 'C:\Repos\of_v0.12.0_vs_release\ImageSourceMethodTestApp\bin\data\resources';
path_save = 'C:\Repos\of_v0.12.0_vs_release\ImageSourceMethodTestApp\bin\data\resources';

%% Total duration in seconds
totalDuration = 12;  % In seconds

%% ROOM
sofaName = 'Sala108_listener1_sourceQuad_2m_48kHz_reverb_adjusted.sofa';
brirInitial = SOFAload(sofaName);
fileName2 = 'A108BRIR_reverb_adjusted.wav';

version = ['_extended_' num2str(totalDuration)];

% hrtf = SOFAload('HRTF_SADIE_II_D1_44100_24bit_256tap_FIR_SOFA_aligned.sofa');
% data = hrtf.Data.IR;
% plot (squeeze(data(1,1,:)));
% SOFAplotHRTF(brirInitial, 'EtcMedian'  );fileName2
% 'EtcHorizontal'  Energy-Time Curve (ETC) in the horizontal plane (+/- THR)
% 'EtcMedian'      ETC in the median plane (+/- THR)
% 'MagHorizontal'  Magnitude spectra in the horizontal plane (+/- THR)
% 'MagMedian'      Magnitude spectra in the median plane (+/- THR)
% 'MagSagittal'    Magnitude spectra in a sagittal plane specified by OFFSET +/- THR
% 'MagSpectrum'    A single magnitude spectrum for given direction(s) DIR in COLOR
% 'ITDhorizontal'  Interaural time delays (ITDs) in the horizontal plane (Matlab only)

dataInital = brirInitial.Data.IR;
data1c = squeeze(dataInital(3,:,:));
data1c = data1c';
Fs = brirInitial.Data.SamplingRate; 
figure; plot (data1c); grid on; title([fileName2 ' Original']); %xlim([0 2000]);

secondsIRfromFile = size(dataInital,3)/Fs;
timesExtend = totalDuration/secondsIRfromFile;
if timesExtend < 1
   samplesToCopy = floor(secondsIRfromFile*Fs*timesExtend);
else
   samplesToCopy = size(dataInital,3);
end

% create new matrix with new dimensions (extension or reduction)
dataExtend = zeros (size(dataInital,1), size(dataInital,2),floor(timesExtend*size(dataInital,3)));

% If the duration to be generated is greater than the duration of the initial IR
%dataExtend (:,:, [1:size(dataInital,3)] ) = dataInital (:,:,[1:end]); 

% copy original data into dataExtend
dataExtend (:,:, [1:samplesToCopy] ) = dataInital (:,:,[1:samplesToCopy]);

% create random data 
matrixExtend = (rand ( size(dataInital,1), size(dataInital,2),floor(timesExtend*size(dataInital,3)) ) -0.5) *2 /100000;

% adds random data to dataExtend
dataExtend (:, :, [size(dataInital,3): size(dataExtend,3)]) = matrixExtend (:, :, [size(dataInital,3): size(dataExtend,3)]);

% plot frontal impulse response
data1c = squeeze(dataExtend(3,:,:));  % frontal impulse response
data1c = data1c';
figure; plot (data1c); grid on; title([fileName2 ' Extend']); %xlim([0 2000]);

% create an object from a copy of the original object
brirExtend = brirInitial;
% Resize (adjusts the size to the new dimensions)
brirExtend.Data.IR = resize (brirExtend.Data.IR, [size(dataInital,1), size(dataInital,2),floor(timesExtend*size(dataInital,3))] );
% Copy dataExtend
brirExtend.Data.IR = dataExtend;
brirExtend = SOFAupdateDimensions(brirExtend); % update sofa to new dimensions

% % plot new frontal impulse responde
% dataInital = brirExtend.Data.IR;
% data1c = squeeze(dataInital(3,:,:));
% data1c = data1c';
% Fs = brirExtend.Data.SamplingRate; 
% figure; plot (data1c); grid on; title( [fileName2 ' from object']); %xlim([0 2000]);

% save file .sofa
brirExtend = SOFAsave(fullfile(path_save,[sofaName(1:end-5), version, '.sofa']),brirExtend);

disp('end');

