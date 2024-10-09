
%% This script Convert all .mat files located in a folder into .xls files

% Authors: Fabian Arrebola (09/10/2024) 
% contact: areyesa@uma.es
% 3DDIANA research group. University of Malaga
% Project: SONICOM
% 
% Copyright (C) 2024 Universidad de Málaga


folder = 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\AbsorEyring\A108';

% Get list of .mat files in folder
files = dir(fullfile(folder, '*.mat'));
NumF = length(files);

% Get info
for i = 1:NumF
    % Read the .mat file
    currentFile = fullfile(folder, files(i).name);
    data = load (currentFile);
    [~, nameFile, ~] = fileparts(currentFile);
    fileExcel = [nameFile, '.xlsx'];
    fileExcel = [folder '\' fileExcel];
    struct2xls(data, fileExcel);
end

function struct2xls(s, filename)
    fields = fieldnames(s);
    numField =numel(fields);
    for i = 1:numel(fields)
        data = s.(fields{i});
        writematrix(data, filename, 'Sheet', fields{i});
    end
end