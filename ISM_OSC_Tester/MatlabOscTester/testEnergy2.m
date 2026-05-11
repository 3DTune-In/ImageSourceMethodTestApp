cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder';

% BRIRFile=dir(['BRIR*.wav']);  %BRIR obtained with a pruning distance of 1 meter
% AudioFile=BRIRFile.name;
% [BRIR,Fs] = audioread(AudioFile);
      
%[Ism_L,Fs] = audioread('ISM_DpMax.wav');
%[Ism,Fs] = audioread('iIrRO40DP30W02.wav');

iFiles=dir(['iIrR*.wav']);   % Ism files without direct path
NumFiles = length(iFiles);

for i=1:NumFiles
   
   iAudioFile=iFiles(i).name; 
   [Ism,Fs] = audioread(iAudioFile);

   vMaxL = max (Ism(:,1));
   vMaxR = max (Ism(:,2));
   vMax = max (vMaxL, vMaxR);

   %e_BRIR= calculateEnergy(BRIR);
   e_ISM = calculateEnergy(Ism);

   figure;
   subplot(2,1,1); plot (Ism(1:15000, 1));
   text = iAudioFile + "_L   e="+ num2str(e_ISM(1));
   title(text);
   ylim([-vMax vMax]);

   subplot(2,1,2); plot (Ism(1:15000, 2));
   text = iAudioFile + "_R   e="+ num2str(e_ISM(2));
   title(text);
   ylim([-vMax vMax]);

end
%pause;
disp('end'); 

