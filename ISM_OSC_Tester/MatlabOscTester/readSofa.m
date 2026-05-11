% Ruta del archivo .sofa

% sofaFile = 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\Sala108_listener1_sourceQuad_2m_44100Hz_reverb_adjusted.sofa';
% sofaFile = 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\lab138_3_KU100_reverb_120cm_adjusted_44100.sofa';
sofaFile = 'C:\Repos\of_v0.11.2_vs2017_release\ImageSourceMethodTestApp\bin\data\resources\SalaJuntasTeleco_listener1_sourceQuad_2m_44100Hz_reverb_adjusted.sofa';


% Cargar el archivo .sofa
sofaData = SOFAload(sofaFile);

% Acceder a los metadatos y atributos
dimensions = sofaData.API.Dimensions;

% Acceder a los datos de la respuesta al impulso (IR)
irData = sofaData.Data.IR;

% Obtener la información de los altavoces (source)
sourcePositions = sofaData.SourcePosition;


% Obtener la información de los receptores (receiver)
receiverPositions = sofaData.ReceiverPosition;

% Obtener los datos de la respuesta al impulso (IR)
NumIRs= length (sourcePositions(:,3));

maxTot=0;
for i=1:NumIRs
    irDataValues(:,:) = irData(i,:,:);
    absIr = abs(irDataValues);
    maxIr = max(absIr,[], [1 2]);
    if maxIr> maxTot
        maxTot=maxIr;
    end
end

for i=1:NumIRs
    irDataValues(:,:) = irData(i,:,:);
    % Visualizar los datos de la respuesta al impulso
    figure;
    %plot(irDataValues(1,:));
    subplot 211,plot(irDataValues(1,:));
    title('Respuesta al impulso L', i );
    ylim([-maxTot maxTot]);
    subplot 212,plot(irDataValues(2,:));
    title('Respuesta al impulso R', i);
    ylim([-maxTot maxTot]);
end


disp('fin');