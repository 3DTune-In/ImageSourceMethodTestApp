

%% Path
addpath('C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\ISM_OSC_Tester\MatlabOscTester'); 

%% Info to show: Error or Absorption
info = 'Error';     % 'Error' --'Absor'
%numValAbsor = 10;   %  Num samples


%% Folder with data
%nameFolder='\Adj sJun-C80-DirPath';
%nameFolder='\Adj sJun-EEY-DirPath';
%nameFolder='\2024_10_01 EYY EDT C80 C50\sJun C80 0-5PP  28 Average';
nameFolder='\Adj sJun-EDT-DirPath';

lastCharacter = nameFolder(end);
if isstrprop(lastCharacter, 'digit')
    variableBand= str2mat(lastCharacter); 
    band = str2num(variableBand);
    trueBand= true;
    %x=[0:1/numValAbsor:1];
elseif isstrprop(lastCharacter, 'alpha')
    band= 5; 
    trueBand= false;
    %x=[0:1:80];
else

end

resourcesFolder = 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\workFolder';
workFolder = strcat(resourcesFolder,nameFolder);
cd (workFolder);

files = dir(workFolder);
fileErr = false;
fileSn = false;
fileDau = false;
for i = 1:length(files)
     fileName = files(i).name;
     if startsWith(fileName, 'ErrFil')
         fileErr = true;
     elseif startsWith(fileName, 'DauFil')
         fileDau = true;
     elseif startsWith(fileName, 'SnFil')
         fileSn = true;
     else
     end
end 

if info == 'Absor'
    ErrPerBand=dir(['AnFile*.mat'])
    fileName=ErrPerBand.name;
elseif info == 'Error'
    if fileSn
        ErrPerBand=dir(['SnFile*.mat'])
    elseif fileDau
        ErrPerBand=dir(['DauFile*.mat'])
    elseif fileErr
        ErrPerBand=dir(['ErrFile*.mat'])
    end
    fileName=ErrPerBand.name;
end

load(fileName);
legend_names= {'62.5 Hz'; '125 Hz'; '250 Hz'; '500 Hz';'1 KHz'; '2 KHz'; '4 KHz';'8 KHz';'16 KHz'};

figure; hold on;
if ( isstrprop(lastCharacter, 'alpha')) 
    if (info == 'Error') & (fileSn ==true)
         ErrVsAbs = Sn;
         x=[1:1:length(Sn(:,1))];
    elseif (info == 'Error') & (fileDau==true)
         ErrVsAbs = Dau;
         x=[1:1:length(Dau(:,1))];
    elseif info == 'Absor'
         ErrVsAbs = An;
         x=[1:1:length(An(:,1))];
    elseif (info == 'Error') & (fileErr ==true)
         ErrVsAbs = Sn;
         x=[1:1:length(Sn(:,1))];
    end
else
    x=[1:1:length(ErrVsAbs(:,1))];
end

for i=1:9
    if isstrprop(lastCharacter, 'digit')
        if i == (band )
            plot (x, ErrVsAbs(:, i), 'b--o', 'LineWidth', 1);
        elseif i == (band-1) || i == (band+1)
            plot (x, ErrVsAbs(:, i), 'LineWidth', 1.5);
        else
            plot (x, ErrVsAbs(:, i));
        end
    else
            plot (x, ErrVsAbs(:, i));
    end

end
if (isstrprop(lastCharacter, 'digit'))
    title([ nameFolder(2:end-1) 'Error Vs Absorption Band Nº ' num2str(variableBand) ] );
    xlabel('Absoption');
else
    title([info ' Evolution ' nameFolder(2:end)]);
    xlabel('Iteration');
end 
legend(legend_names); 
legend('Location','southeast');

if info == 'Error' 
    ylabel ('Error');
    if trueBand ylim([-0.9 0.9]);
end
else 
    ylabel( 'Absorption');
end


grid;
disp('end');