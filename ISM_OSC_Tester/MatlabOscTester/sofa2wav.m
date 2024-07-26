%% This script extracts from the BRIR (sofa ambisonic file) the wav file 
%% associated with the measured impulse response

% Authors: Fabian Arrebola (02/03/2024) 
% contact: areyesa@uma.es
% 3DDIANA research group. University of Malaga
% Project: SONICOM
% 
% Copyright (C) 2024 Universidad de Málaga

cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources';

% hrtf = SOFAload('HRTF_SADIE_II_D1_44100_24bit_256tap_FIR_SOFA_aligned.sofa');
% data = hrtf.Data.IR;
% plot (squeeze(data(1,1,:)));


%% ROOM
brirMeas = SOFAload('SalaJuntasTeleco_listener1_sourceQuad_2m_48kHz_Omnidirectional_reverb.sofa');
%brirMeas = SOFAload('Sala108_listener1_sourceQuad_2m_48kHz_Omnidirectional_reverb.sofa');
%brirMeas = SOFAload('Sala108_listener1_sourceQuad_2m_48kHz_reverb_adjusted.sofa');
%brirMeas = SOFAload('SalaJuntasTeleco_listener1_sourceQuad_2m_48kHz_reverb_adjusted.sofa');
%%brirMeas = SOFAload('SalaJuntasTeleco_listener1_sourceQuad_2m_44100Hz_reverb_adjusted.sofa');
%% brirMeas = SOFAload('lab138_3_KU100_reverb_120cm_adjusted_44100.sofa');

dataMeas = brirMeas.Data.IR;
data1 = squeeze(dataMeas(3,:,:));
data1 = data1';
Fs1 = brirMeas.Data.SamplingRate; 

dataCrop = data1;

fileName1 = 'sJunBRIR_omni.wav';
%fileName1 = 'sJunBRIR.wav';
%fileName1 = 'A108BRIR_omni.wav';
%fileName1 = 'LabBRIR.wav';
audiowrite(fileName1,dataCrop,Fs1);

% %% SMALL
% brirSMALL = SOFAload('small_Pos1_KU100_reverb_140cm_adjusted_44100.sofa');
% dataSMALL = brirSMALL.Data.IR;
% 
% data2 = squeeze(dataSMALL(1,:,:));
% data2=data2';
% Fs2 = brirSMALL.Data.SamplingRate; 
% 
% dataCrop  = zeros (44032,2);
% %dataDelay = zeros (44032,2)
% dataCrop = data2(1:44032,:);
% %dataDelay(201:44032,:) = data2(1:44032-200,:);
% 
% fileName2 = 'SmallBRIR.wav';
% %audiowrite(fileName2,dataDelay,Fs2);
% audiowrite(fileName2,dataCrop,Fs2);

disp('end');

% hrtf = SOFAload('HRTF_SADIE_II_D1_44100_24bit_256tap_FIR_SOFA_aligned.sofa');
% data = hrtf.Data.IR;
% plot (squeeze(data(1,1,:)));
% 
% brir = SOFAload('brir.sofa');
% dataBRIR = brir.Data.IR;
% figure;
% subplot (3,1,1);
% plot (squeeze(dataBRIR(1,1,:)));
