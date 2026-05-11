cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources';


%% sofa_reverb140cm_quad_reverb_adjusted.sofa_v1.sofa
brirLAB = SOFAload('2_KU100_reverb_120cm_original_meas_44100.sofa');
%brirLAB = SOFAload('BRIR_CR1_KU_MICS_L.sofa');
dataLAB = brirLAB.Data.IR;
subplot (2,1,1);
plot (squeeze(dataLAB(3,1,:)));
data= squeeze(dataLAB(3,:,:));

fileName = 'LabBRIR.wav';
file= fopen(fileName, 'w');
fprintf(file, '%f', data);
fclose (file);

%% sofa_reverb140cm_quad_reverb.sofa
brirSMALL = SOFAload('sofa_reverb140cm_quad_reverb_44100.sofa');
%brirSMALL = SOFAload('DRIR_CR1_VSA_110OSC_R.sofa'); 
dataSMALL = brirSMALL.Data.IR;
subplot (2,1,2);
plot (squeeze(dataSMALL(1,1,:)), 'r');
data= squeeze(dataSAMLL(1,:,:));

fileName = 'SmallBRIR.wav';
file= fopen(fileName, 'w');
fprintf(file, '%f', data);
fclose (file);

disp('end');

% hrtf = SOFAload('hrtf.sofa');
% data = hrtf.Data.IR;
% plot (squeeze(data(1,1,:)));
% 
% brir = SOFAload('brir.sofa');
% dataBRIR = brir.Data.IR;
% figure;
% subplot (3,1,1);
% plot (squeeze(dataBRIR(1,1,:)));
