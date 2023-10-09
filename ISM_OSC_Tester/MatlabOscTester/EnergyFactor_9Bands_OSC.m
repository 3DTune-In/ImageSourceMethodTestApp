

%% MAX ITERATIONS 
ITER_MAX = 41;
EPSILON_OBJ = 0.00001;
%% PRUNING DISTANCES
DpMax=28; DpMin=3;
DpMinFit = 22;                   %% small distance values are not parsed
% DpMax=18; DpMin=3;
% DpMinFit = 10;                   %% small distance values are not parsed
x=[DpMin:1:DpMax];               % Initial and final pruning distance

L=1; R=2;                        % Channel
%% ABSORTIONS
%% Pablo+40 iteraciones
absorbData = [
0.338909689799483	0.259871841453028	0.479960669046509	0.0297859988099942	0.466584244231692	0.600776234389392	0.643694649952930	0.609525467569185	0.777059824182964;
0.338909689799483	0.259871841453028	0.479960669046509	0.0297859988099942	0.466584244231692	0.600776234389392	0.643694649952930	0.609525467569185	0.777059824182964;
0.338909689799483	0.259871841453028	0.479960669046509	0.0297859988099942	0.466584244231692	0.600776234389392	0.643694649952930	0.609525467569185	0.777059824182964;
0.338909689799483	0.259871841453028	0.479960669046509	0.0297859988099942	0.466584244231692	0.600776234389392	0.643694649952930	0.609525467569185	0.777059824182964;
0.400000000000000	0.400000000000000	0.300000000000000	0.200000000000000	0.170000000000000	0.150000000000000	0.100000000000000	0.100000000000000	0.200000000000000;
0.200000000000000	0.200000000000000	0.250000000000000	0.350000000000000	0.500000000000000	0.300000000000000	0.250000000000000	0.400000000000000	0.400000000000000;];

% %% Pablo
% absorbData = [
% 0.18 0.18 0.34	0.42  0.59	0.43	0.83  0.68	0.68;
% 0.18 0.18 0.34	0.42  0.59	0.43	0.83  0.68	0.68;
% 0.18 0.18 0.34	0.42  0.59	0.43	0.83  0.68	0.68;
% 0.18 0.18 0.34	0.42  0.59	0.43	0.83  0.68	0.68;
% 0.40 0.40 0.30  0.20  0.17  0.15    0.10  0.10  0.20;
% 0.20 0.20 0.25  0.35  0.50  0.30    0.25  0.40  0.40;];

formatSlope = "Slope: %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f ";
formatAbsor = "Absor: %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f ";

% absorbData = [
% 0.273770719640980	0.459839482885110	0.376930025779702	0.678683111774911	0.454277859851608	0.438749508816753	0.743301756520415	0.671431054228773	0.695195234887130;
% 0.273770719640980	0.459839482885110	0.376930025779702	0.678683111774911	0.454277859851608	0.438749508816753	0.743301756520415	0.671431054228773	0.695195234887130;
% 0.273770719640980	0.459839482885110	0.376930025779702	0.678683111774911	0.454277859851608	0.438749508816753	0.743301756520415	0.671431054228773	0.695195234887130;
% 0.273770719640980	0.459839482885110	0.376930025779702	0.678683111774911	0.454277859851608	0.438749508816753	0.743301756520415	0.671431054228773	0.695195234887130;
% 0.273770719640980	0.459839482885110	0.376930025779702	0.678683111774911	0.454277859851608	0.438749508816753	0.743301756520415	0.671431054228773	0.695195234887130;
% 0.273770719640980	0.459839482885110	0.376930025779702	0.678683111774911	0.454277859851608	0.438749508816753	0.743301756520415	0.671431054228773	0.695195234887130;
% ];

% absorbData = [
% 0.273770719640980	0.318712325323339	0.376930025779702	0.473766749877195	0.327961993934912	0.318844957942948	0.687702087073435	0.647533206059719	0.695195234887130;
% 0.273770719640980	0.318712325323339	0.376930025779702	0.473766749877195	0.327961993934912	0.318844957942948	0.687702087073435	0.647533206059719	0.695195234887130;
% 0.273770719640980	0.318712325323339	0.376930025779702	0.473766749877195	0.327961993934912	0.318844957942948	0.687702087073435	0.647533206059719	0.695195234887130;
% 0.273770719640980	0.318712325323339	0.376930025779702	0.473766749877195	0.327961993934912	0.318844957942948	0.687702087073435	0.647533206059719	0.695195234887130;
% 0.273770719640980	0.318712325323339	0.376930025779702	0.473766749877195	0.327961993934912	0.318844957942948	0.687702087073435	0.647533206059719	0.695195234887130;
% 0.273770719640980	0.318712325323339	0.376930025779702	0.473766749877195	0.327961993934912	0.318844957942948	0.687702087073435	0.647533206059719	0.695195234887130;
% ];

% absorbData = [
% 0.273770719640980	0.318712325323339	0.376930025779702	0.473766749877195	0.327961993934912	0.318844957942948	0.687702087073435	0.647533206059719	0.695195234887130;
% 0.273770719640980	0.318712325323339	0.376930025779702	0.473766749877195	0.327961993934912	0.318844957942948	0.687702087073435	0.647533206059719	0.695195234887130;
% 0.273770719640980	0.318712325323339	0.376930025779702	0.473766749877195	0.327961993934912	0.318844957942948	0.687702087073435	0.647533206059719	0.695195234887130;
% 0.273770719640980	0.318712325323339	0.376930025779702	0.473766749877195	0.327961993934912	0.318844957942948	0.687702087073435	0.647533206059719	0.695195234887130;
% 0.100000000000000	0.100000000000000	0.150000000000000	0.100000000000000	0.100000000000000	0.0500000000000000	0.200000000000000	0.300000000000000	0.300000000000000;
% 0.300000000000000	0.100000000000000	0.250000000000000	0.250000000000000	0.200000000000000	0.150000000000000	0.200000000000000	0.300000000000000	0.300000000000000;
% ];



% absorbData = [0.10 0.10 0.24 0.32 0.39 0.53 0.38 0.38 0.38;
%               0.10 0.10 0.24 0.32 0.39 0.53 0.38 0.38 0.38;
%               0.10 0.10 0.24 0.32 0.39 0.53 0.38 0.38 0.38;
%               0.10 0.10 0.24 0.32 0.39 0.53 0.38 0.38 0.38;
%               0.10 0.10 0.15 0.10 0.10 0.05 0.20 0.30 0.30;
%               0.30 0.10 0.25 0.25 0.20 0.15 0.20 0.30 0.30;];

%% Open connection to send messages to ISM
ISMPort = 12300;
connectionToISM = InitConnectionToISM(ISMPort);

%% Open OSC server
% https://0110.be/posts/OSC_in_Matlab_on_Windows%2C_Linux_and_Mac_OS_X_using_Java
% https://github.com/hoijui/JavaOSC
listenPort = 12301;
receiver = InitOscServer(listenPort);
[receiver osc_listener] = AddListenerAddress(receiver, '/ready');

%% Send Initial absortions
% fileAbsor=zeros(1,9);
% for j=1:6
%     fileAbsor = absorbData(j,:);
%     SendCoefficientsVectorToISM(connectionToISM, fileAbsor);
% end 

%% Send Initial absortions
walls_absor = zeros(1,54);
absorbDataT = absorbData';
walls_absor = absorbDataT(:);
SendCoefficientsVectorToISM(connectionToISM, walls_absor'); 

%% Waiting msg from ISM
message = WaitingOneOscMessageStringVector(receiver, osc_listener);    
disp(message);



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

%% Working loop
rng('default');
iLoop = 0;
while ( iLoop < ITER_MAX)
    disp(iLoop);
    %% Folder with impulse responses
    %cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\AbsorPX4';
    %cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\AbsorP4';
    cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\SeriesIr';

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
    %% -------figure
    %% BRIR Energy for each band
    E_BandBrir=zeros(NB,2);
    %eSumBands=zeros(1,1); %checksum
    eSumBands=0; %checksum
    for j=1:NB
        %eSumBands = eSumBands+E_BandWin(j,i,:);
        e = calculateEnergyBand(Fs, t_BRIR, Blo(j), Bhi(j))/length(t_BRIR);  %/(Bhi(j)-Blo(j)+1);
        E_BandBrir(j,:) = e;
        eSumBands = eSumBands+E_BandBrir(j,:);
    end
    eSumBands= squeeze(eSumBands);
    %% --------------------------                    % FIGURE 1 -- Total: ISM, Windowed, BRIR-Windowed
 %   figure; hold on;
    eL_Ism  = zeros(NumFiles,L);
    eL_Win  = zeros(NumFiles,L);
    eL_BRIR_W = zeros(NumFiles,L);
    eL_Ism = e_TotalIsm(:,L);   % Ism without direct path
    eL_Win = e_TotalWin(:,L);   % Reverb files (hybrid windowed order 0 with no direct path)
    %eL_Total=e_Total([1:1:length(e_Total)],1);      % TOTAL Ism+Rever sin camino directo

%     plot (x, eL_Ism,'r--*');   %Ism
%     plot (x, eL_Win,'g--o');   % Windowed
%     %plot (x,eL_Total,'b--+'); % Total
%     grid;

    eL_BRIR_W(:,L) = eBRIR_L*ones(length(NumFiles))-eL_Win;
%     plot (x, eL_BRIR_W,'k--x');
%     %ylim([0.0 0.8]);
%     xlabel('Distance (m)');
%     ylabel('Energy');
%     title('Total Energy vs Pruning Distance');
%     legend('E-Ism',  'E-win','EBRIR-E-win',  'Location','northwest');
    %% -----------------------------                 % FIGURE 2 -- Total Factor
    figure;
    Factor = sqrt (eL_Ism ./ eL_BRIR_W);
    plot (x, Factor,'b--*');
    %ylim([0.0 1.5]);
    xlabel('Distance (m)');
    ylabel('Factor');
    title('Factor (total) vs Pruning Distance');
    legend('SQRT(e_TotalIsm/(eBRIR-e_Totalwin))', 'Location','southeast');
    grid;
    %% -----------------------------                 % FIGURE 3 -- Partial: ISM, Windowed, BRIR-Windowed
%    figure; hold on;
    for j=1:NB
%        subplot(NB,3,3*j-2);
%        y=  E_BandIsm(j,:,L);
%        plot (x,y,'r--.');   %Ism
%        legend('e-BandIsm', 'Location','northwest');
%        ylim([0.0 0.01*j]);    grid;

%         subplot(NB,3,3*j-1);
%         y= E_BandWin(j,:,L);
%         plot (x,y,'g--.');   % Windowed
%         legend('e-BandWin', 'Location','northeast');
%         ylim([0.0 0.01*j]);    grid;

%        subplot(NB,3,3*j);
        eBand=E_BandBrir(j,L);
        y= E_BandWin(j,:,L);
        E_BandBrir_Win(j,:,L)=eBand(1,L)*ones(1, length(NumFiles))-y;
%         plot (x, E_BandBrir_Win(j,:,L) ,'b--.');   % Brir-Windowed
%         legend('e-Brir-Win', 'Location','southeast');
%         ylim([0.0 0.01*j]);    grid;
    end
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
    ylim([0.0 2.5]); grid;
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
        Ff=factorBand(j, NumFiles-(DpMax-DpMinFit) : NumFiles, L);  % from DpMinFit meters to the end
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
    ylim([0.0 2.5]);
    xlabel('Distance (m)');  ylabel('Factor');
    legend( leg, 'Location','northwest'); grid;
    title('CURVE FIT (9B)- Factor per Band vs Pruning Distance');
    hold off;


    %% -----------------------------------------------------------------
    %% Extrac slopes to send to ISM
    alfa = 0.5;
    %epsilon = 0.00001;
    epsilon = EPSILON_OBJ;
    slopes=zeros(1,9);
    for j=1:NB
        slopes(1,j) = gofpArray(j).p1;
        slopeB = slopes (1,j);
        if abs (slopeB)  > epsilon
            % for k=1:4    %excluding ceil and floor
             for k=1:4
                newAbsor = absorbData (k,j) + slopeB*alfa; 
                if newAbsor > 0.0 && newAbsor < 1.0
                    absorbData (k,j) = newAbsor;
                elseif newAbsor < 0.0
                    absorbData (k,j) = 0.05;
                elseif newAbsor > 1.0
                    absorbData (k,j) = 0.95;
                end
            end 
        end
    end 
    %% Send slopes to ISM
    % SendCoefficientsVectorToISM(connectionToISM, slopes);

    %% Send points to ISM
%     points=zeros(1,9);
%     for j=1:NB
%         points(1,j) = gofpArray(j).p2;
%     end 
%     SendCoefficientsVectorToISM(connectionToISM, points);

    %% Send new absortions
    absorbDataT = absorbData';
    walls_absor = absorbDataT(:);
    SendCoefficientsVectorToISM(connectionToISM, walls_absor'); 

    vSlope = sprintf(formatSlope,slopes);
    disp(vSlope);
    vAbsor = sprintf(formatAbsor,absorbData(1,:));
    disp(vAbsor);

    message = WaitingOneOscMessageStringVector(receiver, osc_listener);    
    %disp(message);
        
    % pause (1)
%% ------------------------------
    b = mod( iLoop , 10 ) ;
    if (b==0)
        % actual folder
        current_folder = pwd;
        % new folder
        new_folder = num2str(iLoop);
        mkdir( current_folder, new_folder);
        % save slopes and absortions
        nameFile= 'FiInfSlopes';
        save(fullfile( current_folder,   nameFile), 'slopes');
        nameFile= 'FiInfAbsorb';
        save(fullfile( current_folder,   nameFile), 'absorbData');

        % copy files
        copyfile(fullfile( current_folder,'BR*'), new_folder);
        copyfile(fullfile( current_folder,'wIr*'), new_folder);
        copyfile(fullfile( current_folder,'iIr*'), new_folder);
        copyfile(fullfile( current_folder,'FiInf*'), new_folder);
    end
%% -------------------------------

    if (iLoop<ITER_MAX-1)
        close all;
    end
    iLoop=iLoop+1;
end

% Close, doesn't work properly
CloseOscServer(receiver, osc_listener);




%% Open a UDP connection with a OSC server
function connectionToISM = InitConnectionToISM(port)
    connectionToISM = udp('127.0.0.1',port);
    fopen(connectionToISM);   
end

%% Send float vector to the OSC server (ISM)
function SendCoefficientsVectorToISM(u, coefVector)
    m = repmat('f',1,length(coefVector));
    oscsend(u,'/coefficients',m, coefVector);    
end

%% Send a signal to the OSC server (ISM)
function SendImpulseToISM()
    %oscsend(u,'/3DTI-OSC/v1/source1/anechoic/nearfield','s','false');
    oscsend(u,'/play','N', "");
end

%% 
function receiver = InitOscServer(port)
    cd('C:/Repos/of_v0.11.2_vs2017_release/ImageSourceMethodTestApp/ISM_OSC_Tester/MatlabOscTester')
    %version -java
    disp('Waiting OSC message');
    javaaddpath('javaosctomatlab.jar');    
    %javaclasspath    
    import com.illposed.osc.*;    
    import java.lang.String       
    receiver =  OSCPortIn(port);
%     osc_method = String('/ready');
%     osc_listener = MatlabOSCListener();
%     receiver.addListener(osc_method,osc_listener);
end

%%
function [receiver osc_listener] = AddListenerAddress(receiver, address) 
    import com.illposed.osc.*;    
    import java.lang.String    
    osc_method = String(address);
    osc_listener = MatlabOSCListener();
    receiver.addListener(osc_method,osc_listener);
end

%%
function message = WaitingOneOscMessageDoubleVector(receiver, osc_listener)
    import com.illposed.osc.*;    
    receiver.startListening();
    while true            
        arguments = osc_listener.getMessageArgumentsAsDouble();
        if ~isempty(arguments) == 1
             message = double(arguments);
             receiver.stopListening();
            break;
        end
    end
end
%%
function message = WaitingOneOscMessageStringVector(receiver, osc_listener)
    import com.illposed.osc.*;     
    receiver.startListening();
    while true           
        arguments = osc_listener.getMessageArgumentsAsString();
        if ~isempty(arguments) == 1             
            message = string(arguments);
            receiver.stopListening();
            break;
        end
    end
end
%% 
function message = WaitingOneOscMessageStructVector(receiver, osc_listener)
    import com.illposed.osc.*;     
    receiver.startListening();
    while true            
        arguments = osc_listener.getMessageArguments();        
        if ~isempty(arguments) == 1   
             message = struct(arguments);
             receiver.stopListening();
            break;
        end
    end
end

%% This doesn't work very well, I think
function CloseOscServer(receiver, osc_listener)
    import com.illposed.osc.*;         
    receiver.stopListening();
    receiver.close();
    receiver = 0;
    clear receiver;
    clear osc_listener;
    javarmpath('javaosctomatlab.jar');
    clear java;
end
