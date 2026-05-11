

AB= alpha_T20';
absorbData1 = repmat (AB, 6, 1); 

current_folder = 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\AbsorAlfas';
nameFile= 'FiInfAbsorb';
save(fullfile( current_folder,   nameFile), 'absorbData1');