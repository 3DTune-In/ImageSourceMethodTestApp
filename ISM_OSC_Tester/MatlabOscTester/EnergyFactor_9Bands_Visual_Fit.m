%% This script displays and renders the results associated with the 
%% behavior of the ISM+Convolution hybrid system of the 3DTI toolkit.

%% As input parameters are taken:
%% a) N impulse responses obtained by the ISM with a sufficiently high 
%%    reflection order (i*files)
%% b) N impulse responses obtained by convolution and windowing (w*.wav files)
%% c) the BRIR of the room to be simulated (BRIR.wav IR obtained by 
%%    convolution and windowing with a pruning distance of 1 meter).
%% N = DpMax-DpMin+1;
%% DpMin = Initial pruning distance
%% DpMax = Final pruning distance
%% DpMinFit = first distance value to carry out the process of fitting the 
%% slopes of the energy factors

%cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\DpMinFitresources\IR\H_20230116'
%cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\IR\P_20230207AbsorLowW20ms'

%cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\LabRectanOr15'
%cd 'D:\3DTI_of_v0.11.2_vs2017_release\of_v0.11.2_vs2017_release\METODO_IMAGENES\vstudio';

%Folder with impulse responses
%cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\AbsorP5';
%% cd 'C:\Repos\HIBRIDO PRUEBAS\DpMax_35 DpMin_3 DpMinFit_18 4iter_100\100';
%% cd 'C:\Repos\HIBRIDO PRUEBAS\DpMax_34 DpMin_3 DpMinFit 25_walls_6_it10\12';
%cd 'C:\Repos\HIBRIDO PRUEBAS\DpMax_36 DpMin_3 DpMinFit_25 iter_18\18';
cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\SeriesIr\20';
%cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\DpMax_36 DpMin_3 DpMinFit_25 iter_21\4'
%cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\DpMax_30 DpMin_15 DpMinFit_18'
%cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\DpMax_28 DpMin_3 DpMinFit_16_alfa_05\40';
%% PRUNING DISTANCES
DpMax=14; DpMin=2;
DpMinFit = 9;                   %% small distance values are not parsed
%DpMax=40; DpMin=10;

x=[DpMin:1:DpMax];               % Initial and final pruning distance

L=1; R=2;                        % Channel

%%   BANDS
%    62,5    125     250      500      1000       2000       4000       8000       16000
% B =[44 88; 89 176; 177 353; 354 707; 708 1414; 1415 2828; 2829 5657; 5658 11314; 11315 22016;];
% 
% Blo=[ 1    89      177      354      708       1415       2829       5658        11315       ];
% Bhi=[  88     176      353      707      1414       2828       5657       11314        22016 ];

%%   9 BANDS
NB=9;
B =[44 88; 89 176; 177 353; 354 707; 708 1414; 1415 2828; 2829 5657; 5658 11314; 11315 22016;];
Blo=[ 1    89      177      354      708       1415       2829       5658        11315       ];
Bhi=[  88     176      353      707      1414       2828       5657       11314        22016 ];


%% FILES with Impulse Response in de folder
iFiles=dir(['i*.wav']);   % Ism files without direct path
wFiles=dir(['w*.wav']);   % Reverb files (hybrid windowed order 0 with no direct path)
% tFiles=dir(['t*.wav']); % Total (Reverb + Ism) files
NumFiles = length(iFiles);

%% Delimitation of the number of files depending on the pruning distances to be studied
if (NumFiles>(DpMax-DpMin+1))
  NumFiles = DpMax-DpMin+1;
end

%% Read file with BRIR
BRIRFile=dir(['BRIR*.wav']);  %BRIR obtained with a pruning distance of 1 meter
AudioFile=BRIRFile.name;
[t_BRIR,Fs] = audioread(AudioFile);

%f_BRIR= SSA_Spectrum(Fs,t_BRIR,0);
%%%%%%%%%%%%%%%%
e_BRIR= calculateEnergy(t_BRIR);
%%%%%%% PARSEVAL RELATION --> e_BRIR (in time) == E_BRIR (in frec)
E_BRIR= calculateEnergyFrec(Fs, t_BRIR)/length(t_BRIR); 
eBRIR_L= e_BRIR(L); eBRIR_R= e_BRIR(R);
%% --------------
%% Total Energy in time domain
e_TotalIsm=zeros(NumFiles,2);              
e_TotalWin=zeros(NumFiles,2);   
e_Total=zeros(NumFiles,2);
%% Energy per band in frequency domain
E_BandIsm =zeros(NB,NumFiles,2);            
E_BandWin=zeros(NB,NumFiles,2); 
E_BandBrir_Win=zeros(NB,NumFiles,2);        %BRIR-Win

%% Calculate total and partial energies
for i=1:NumFiles
     %%%%  Ism files -------------------------------------
     iAudioFile=iFiles(i).name; 
     [ir_Ism,Fs] = audioread(iAudioFile);
     e= calculateEnergy(ir_Ism);
     e_TotalIsm(i,:)= e;
     % PARSEVAL RELATION --> e_TotalIsm (in time) == E_TotalIsm (in frec) 
     E_TotalIsm= calculateEnergyFrec(Fs, ir_Ism)/length(ir_Ism); 
     E_TotalIsm2= calculateEnergyBand(Fs, ir_Ism, Blo(1), Bhi(NB))/length(ir_Ism);                            
     %eSumBandsI=zeros(1,2);  
     eSumBandsI=0; %checksum
     for j=1:NB
        e = calculateEnergyBand(Fs, ir_Ism, Blo(j), Bhi(j)) / length(ir_Ism);  %(Bhi(j)-Blo(j)+1);  
        E_BandIsm(j,i,:) = e;
        eSumBandsI = eSumBandsI+E_BandIsm(j,i,:);
     end
     eSumBandsI= squeeze(eSumBandsI);
     %%%%  Windowed files -------------------------------
     wAudioFile=wFiles(i).name; 
     [ir_Win,Fs] = audioread(wAudioFile);
     e = calculateEnergy(ir_Win);
     e_TotalWin(i,:)= e;
     %% PARSEVAL RELATION --> e_Totalwin (in time) == E_TotalWin (in frec) 
     E_TotalWin= calculateEnergyFrec(Fs, ir_Win)/length(ir_Win); 
     E_TotalWin2= calculateEnergyBand(Fs, ir_Win, Blo(1), Bhi(NB))/length(ir_Ism); %(Bhi(NB)-Blo(1)+1); 
     %eSumBandsW=zeros(1,2); %checksum
     eSumBandsW=0; %checksum
     for j=1:NB
        e = calculateEnergyBand(Fs, ir_Win, Blo(j), Bhi(j))/length(ir_Win); %/(Bhi(j)-Blo(j)+1); 
        E_BandWin(j,i,:) = e;
        eSumBandsW= eSumBandsW+E_BandWin(j,i,:);
     end
     eSumBandsW= squeeze(eSumBandsW);
end
%% -------
%% BRIR Energy for each band
E_BandBrir=zeros(NB,2);
%eSumBands=zeros(1,1); %checksum
eSumBands=0; %checksum
for j=1:NB
    %eSumBands = eSumBands+E_BandWin(j,i,:);
    e = calculateEnergyBand(Fs, t_BRIR, Blo(j), Bhi(j))/length(t_BRIR);  %/(Bhi(j)-receiver.stopListening();Blo(j)+1);
    E_BandBrir(j,:) = e;
    eSumBands = eSumBands+E_BandBrir(j,:);
end
eSumBands= squeeze(eSumBands);
%% --------------------------                    % FIGURE 1 -- Total: ISM, Windowed, BRIR-Windowed
figure; hold on;                                 
eL_Ism  = zeros(NumFiles,L);
eL_Win  = zeros(NumFiles,L);
eL_BRIR_W = zeros(NumFiles,L);
eL_Ism = e_TotalIsm(:,L);   % Ism without direct path
eL_Win = e_TotalWin(:,L);   % Reverb files (hybrid windowed order 0 with no direct path)
%eL_Total=e_Total([1:1:length(e_Total)],1);      % TOTAL Ism+Rever sin camino directo

plot (x, eL_Ism,'r--*');   %Ism
plot (x, eL_Win,'g--o');   % Windowed
%plot (x,eL_Total,'b--+'); % Total
grid;

eL_BRIR_W(:,L) = eBRIR_L*ones(length(NumFiles))-eL_Win;
plot (x, eL_BRIR_W,'k--x');
%ylim([0.0 0.8]);
xlabel('Distance (m)');  
ylabel('Energy'); 
title('Total Energy vs Pruning Distance');  
legend('E-Ism',  'E-win','EBRIR-E-win',  'Location','northwest');
%% -----------------------------                 % FIGURE 2 -- Total Factor
figure;                                          
Factor = sqrt (eL_Ism ./ eL_BRIR_W);
plot (x, Factor,'b--*');
ylim([0.0 1.2]);
xlabel('Distance (m)');  
ylabel('Factor'); 
title('Factor (total) vs Pruning Distance');  
legend('SQRT(e_TotalIsm/(eBRIR-e_Totalwin))', 'Location','southeast');
grid;
%% -----------------------------                 % FIGURE 3 -- Partial: ISM, Windowed, BRIR-Windowed
figure; hold on;                                 
for j=1:NB
    subplot(NB,3,3*j-2);
    y=  E_BandIsm(j,:,L);
    plot (x,y,'r--.');   %Ism
    legend('e-BandIsm', 'Location','northwest');
    ylim([0.0 0.01*j]);    grid;

    subplot(NB,3,3*j-1);
    y= E_BandWin(j,:,L);
    plot (x,y,'g--.');   % Windowed
    legend('e-BandWin', 'Location','northeast');
    ylim([0.0 0.01*j]);    grid;

    subplot(NB,3,3*j);
    eBand=E_BandBrir(j,L);
    y= E_BandWin(j,:,L);
    E_BandBrir_Win(j,:,L)=eBand(1,L)*ones(1, length(NumFiles))-y;
    plot (x, E_BandBrir_Win(j,:,L) ,'b--.');   % Brir-Windowed
    legend('e-Brir-Win', 'Location','southeast');
    ylim([0.0 0.01*j]);    grid;
end
% %% color map
% c= [0.3333, 0.0 ,0.5; 0.6667, 0, 0.5; 1.0000, 0, 0.5; 1.0000, 0.3333, 0.5; 1.0000, 0.6667,0.5;
%     1.0000, 0.5000, 0;  1.0000, 0.0000, 0.5000; 0.0000, 0.3333, 1.0000; 0.0000, 0.6667, 0.5000];
% colormap(c);
%% -----------------------------                  % FIGURE 4 -- Factor per Band
figure; hold on;                                  
factorBand =zeros(NB, NumFiles,2);
for j=1:NB
    eBand=E_BandBrir(j,L);
    y= E_BandWin(j,:,L);
    E_BandBrir_Win(j,:,L)=eBand(1,L)*ones(1, length(NumFiles))-y;
    factorBand(j,:,L) = sqrt(E_BandIsm (j,:,L) ./ E_BandBrir_Win(j,:,L)); 
    plot (x, factorBand(j,:,L),"LineWidth",1.5);   % ,'color', [c(j,1) c(j,2) c(j,3)]
end
grid;
ylim([0.0 3.5]);
xlabel('Distance (m)');  ylabel('Factor'); 
legend( 'B1','B2','B3','B4', 'B5','B6','B7','B8','B9','Location','northeast');
title('Factor per Band vs Pruning Distance');  

%% -----------------------------
%% Curve Fitting with "curveFitter"
% xf=[DpMinFit:1:DpMax]; % from 10 meters to the end
% for j=1:NB
%    Ff=factorBand(j, NumFiles-(DpMax-DpMinFit) : NumFiles, L);  % from 10 meters to the end
% % %P1 = P2(1:L/2+1);
%    curveFitter(xf,Ff);
% end
% %hold off;

%% Curve Fitting                                   % FIGURE 5 -- Fit for each Band     
xf=[DpMinFit:1:DpMax]; % from 10 meters to the end
figure; hold on;                                     
leg = {'B1', 'a1','B2', 'a2','B3','a3','B4','a4','B5', 'a5','B6','a6','B7','a7','B8','a8','B9','a9'};

%fitObj= cfit.empty(0,NB); % Create empty array of specified class cfit
%cfitData = struct(cfit);
%cfitArray = repmat (cfitData, 1, NB);

gof = struct([]);                                   % Create empty struct
gofplus = struct('gof', gof , 'p1', 0, 'p2', 0);    % Create struct to load data per band
gofpArray = repmat (gofplus, 1, NB);                % Array of structures to store information for each band

for j=1:NB
   Ff=factorBand(j, NumFiles-(DpMax-DpMinFit) : NumFiles, L);  % from 10 meters to the end
   xft=xf'; Fft= Ff'; % transpose
      % [fitObj, gof] = fit(xft,Fft,'poly1');
   [fitObj, gofplus.gof] = fit(xft,Fft,'poly1');
      % cfitArray(j) = struct(fitObj);
   gofpArray(j).gof = gofplus.gof;
   gofpArray(j).p1  = fitObj.p1;
   gofpArray(j).p2  = fitObj.p2;
      % disp(fitObj)  % disp(cfitArray(j)); 
      % fitObj.p1;    % cfitArray(j).coeffValues(1,1);
   p=plot(fitObj, xft,Fft, '--o');
   p(2,1).Color = 'b'; p(1,1).LineWidth=1.5;
end   
ylim([0.0 3.5]);
xlabel('Distance (m)');  ylabel('Factor'); 
legend( leg, 'Location','northwest'); grid;
title('CURVE FIT (9B)- Factor per Band vs Pruning Distance'); 
%hold off;

%  % actual dir
%  current_folder = pwd;
%  % new folder
%  iloop=1;
%  new_folder = num2str(iloop);
%  mkdir( current_folder, new_folder);
% 
%  nameFile= 'slopesFile';
%  save(fullfile( current_folder,   nameFile), 'Blo');
%  nameFile= 'absorbFile';
%  save(fullfile( current_folder,   nameFile), 'Bhi');
% 
%     % copy files
%  copyfile(fullfile( current_folder,'*'), new_folder);