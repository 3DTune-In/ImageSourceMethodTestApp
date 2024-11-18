

clear all;
close all;
sInFolder = 'C:\Users\FABIAN\OneDrive - Universidad de Málaga\3DIANA\Temas de Investigación\Metodo Imagenes HYBRID\2024_10_28_Acoustic_parameter_evaluation_TABLES'
% Conversion
eFolders = dir(fullfile(sInFolder,'Ac*'));
for j=1:length(eFolders)
    folder= [sInFolder '\' eFolders(j).name];
    eFiles=dir(fullfile(folder,'*.mat'));
    for i=1:length(eFiles)
        sMatFile=fullfile(folder,eFiles(i).name);
        name = eFiles(i).name;
        load (sMatFile);
        room = name(1:4);    param = name(6:8);   tmix = name (end-5:end-4);
        if isequal(param,'C80')
            %C80p (:,:) = Err_C80rs_t;     
            C80p (:,:) = Tab_C80_t; 
            if isequal(room,'A108')        C80_A108cell{j} = C80p; Tab_C80_A108 = Tab_C80;
            elseif isequal(room,'sJun')    C80_sJuncell{j} = C80p; Tab_C80_sJun = Tab_C80;
            end
        elseif isequal(param,'EEy')
            %EEyp (:,:) = Err_EEyrs_t;      
            EEyp (:,:) = Tab_EEy_t;      
            if isequal(room,'A108')        EEy_A108cell{j} = EEyp; Tab_EEy_A108 = Tab_EEy;
            elseif isequal(room,'sJun')    EEy_sJuncell{j} = EEyp; Tab_EEy_sJun = Tab_EEy;
            end
        elseif isequal(param,'T20')
            %T20p (:,:) = Err_T20rs_t;      
            T20p (:,:) = Tab_T20_t;      
            if isequal(room,'A108')        T20_A108cell{j} = T20p; Tab_T20_A108 = Tab_T20;
            elseif isequal(room,'sJun')    T20_sJuncell{j} = T20p; Tab_T20_sJun = Tab_T20;
            end
        elseif isequal(param,'EDT')
            %EDTp (:,:) = Err_EDTrs_t;   
            EDTp (:,:) = Tab_EDT_t; 
            if isequal(room,'A108')        EDT_A108cell{j} = EDTp; Tab_EDT_A108 = Tab_EDT;
            elseif isequal(room,'sJun')    EDT_sJuncell{j} = EDTp; Tab_EDT_sJun = Tab_EDT;
            end
        else 
            param = name(6:11);
            if isequal(param,'IACC_e')
                %IACC_ep (:,:) = Err_IACC_early_rs_t; 
                IACC_ep (:,:) = Tab_IACC_early_t; 
                if isequal(room,'A108')                   IACC_e_A108cell{j} = IACC_ep;
                elseif isequal(room,'sJun')               IACC_e_sJuncell{j} = IACC_ep;
                end
            end
        end      
    end
end

% Cell 3 is empty, so it is deleted
C80_A108cell {3} = C80_A108cell {4};
EEy_A108cell {3} = EEy_A108cell {4};
T20_A108cell {3} = T20_A108cell {4};
EDT_A108cell {3} = EDT_A108cell {4};
IACC_e_A108cell {3} = IACC_e_A108cell {4};

% defines the size of the arrays
C80_A108    = zeros (size(C80p,1), size(C80p,2)*3); C80_sJun = zeros (size(C80p,1), size(C80p,2)*3);
EEy_A108    = zeros (size(EEyp,1), size(EEyp,2)*3); EEy_sJun = zeros (size(EEyp,1), size(EEyp,2)*3);
T20_A108    = zeros (size(T20p,1), size(T20p,2)*3); T20_sJun = zeros (size(T20p,1), size(T20p,2)*3);
EDT_A108    = zeros (size(EDTp,1), size(EDTp,2)*3); EDT_sJun = zeros (size(EDTp,1), size(EDTp,2)*3);
IACC_e_A108 = zeros (size(IACC_ep,1), size(IACC_ep,2)*3); IACC_e_sJun = zeros (size(IACC_ep,1), size(IACC_ep,2)*3);

% Stores the data of the different Tmix values ​​in a single matrix
for i=1:3
    w = size(C80p,2);
    C80_sJun( : , [(i-1)*w + 1  : (i-1)*w + w]) = C80_sJuncell{i}(:,:);
    C80_A108( : , [(i-1)*w + 1  : (i-1)*w + w]) = C80_A108cell{j}(:,:);
    T20_sJun( : , [(i-1)*w + 1  : (i-1)*w + w]) = T20_sJuncell{i}(:,:);
    T20_A108( : , [(i-1)*w + 1  : (i-1)*w + w]) = T20_A108cell{j}(:,:);
    EDT_sJun( : , [(i-1)*w + 1  : (i-1)*w + w]) = EDT_sJuncell{i}(:,:);
    EDT_A108( : , [(i-1)*w + 1  : (i-1)*w + w]) = EDT_A108cell{j}(:,:);
    IACC_e_sJun( : , [(i-1)*w + 1  : (i-1)*w + w]) = IACC_e_sJuncell{i}(:,:);
    IACC_e_A108( : , [(i-1)*w + 1  : (i-1)*w + w]) = IACC_e_A108cell{j}(:,:);
    %w= w-1;
    w=w-2;
    EEy_sJun( : , [(i-1)*w + 1  : (i-1)*w + w]) = EEy_sJuncell{i}(:,:);
    EEy_A108( : , [(i-1)*w + 1  : (i-1)*w + w]) = EEy_A108cell{j}(:,:);
end



% figure; plot(C80_sJun); title ('C80 sJun');
% figure; plot(T20_sJun); title ('T20 sJun');
% figure; plot(EEy_sJun); title ('EEy sJun');
% figure; plot(IACC_e_sJun);title ('IACC_e sJun');
% figure; plot(C80_A108); title ('C80 A108');
% figure; plot(T20_A108); title ('T20 A108');
% figure; plot(EEy_A108); title ('EEy A108');
% %figure; plot(IACC_e_A108);title ('IACC_e A108');