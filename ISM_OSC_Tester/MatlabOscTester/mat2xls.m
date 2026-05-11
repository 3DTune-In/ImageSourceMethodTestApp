

folder = 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder\sJun EYY 0-5PP 1pc';

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
        if isstruct(data)
            struct2xls(data, filename); % Llamada recursiva para estructuras anidadas
        else
            writematrix(data, filename, 'Sheet', fields{i});
        end
    end

end