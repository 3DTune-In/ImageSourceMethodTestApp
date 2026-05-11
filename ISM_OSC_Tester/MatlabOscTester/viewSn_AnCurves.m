% t = datetime('now','Format','HH:mm:ss.SSS');ylim
% [h,m,s] = hms(t);
% H = int2str (h);
% M = int2str (m);
% S = int2str (s);
% current_folder = pwd;
% nameFile= "SnFile_"+ H +"_"+ M + "_" + S;
% save(fullfile( current_folder,   nameFile), 'Sn'); 

cd 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\SeriesIr';
x=[0:0.05:1]; 
matFiles=dir(['SnFile_*.mat']); 
NumFiles = length(matFiles);
 for i=1:NumFiles
    MatFile=matFiles(i).name;
    load(MatFile);
    figure;
    grid on;
    plot (Sn);
    grid on;
    legend( 'B1','B2','B3','B4', 'B5','B6','B7','B8','B9','Location','southeast');
    title (MatFile);
    pause(0.1);
 end

% for i=1:NumFiles
%     MatFile=matFiles(i).name;
%     load(MatFile);
%     j=9;
%     Sn_5 = Sn (:,j);
%     %hold on;
%     figure;
%     plot (Sn_5);
%     title ("Banda Nº"+j);
% end
%  legend (matFiles(1).name, matFiles(2).name, matFiles(3).name, matFiles(4).name);
%  legend (matFiles(1).name, matFiles(2).name);
 
 grid on;