%% PRUNING DISTANCES
DpMax=30; DpMin=2;
DpMinFit = 20;                   %% small distance values are not parsed

%% Folder with impulse responses
%% cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\SeriesIr';
cd 'C:\Repos\HIBRIDO PRUEBAS\New LAB 32 2 20'
%delete *.wav;

%% SAVE Configuration parameters for ISM simulation
RefOrd=20; 
W_Slope=2;                       % Value for energy adjustment
RGain_dB = 24;
RGain = db2mag(RGain_dB);
save ('ParamsISM.mat','RefOrd', 'DpMax','W_Slope','RGain_dB');
%% SAVE PRUNING DISTANCES
save ('DistanceRange.mat','DpMax', 'DpMin','DpMinFit');