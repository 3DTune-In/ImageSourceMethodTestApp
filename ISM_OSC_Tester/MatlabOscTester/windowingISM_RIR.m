function [y2w]= windowingISM_RIR (Fs, IR, maxDistSL, slope, ismOrRir)

% Author: Fabian Arrebola (17/10/2023) 
% contact: areyes@uma.es
% 3DDIANA research group. University of Malaga
% Project: SONICOM
% 
% Copyright (C) 2023 Universidad de Málaga


y=IR;
Vs=340;          % v=e/t -->  e=v*t --> t=e/v

DistMargin = Vs*slope/1000;
Ly = length(y());
windowIsmRIR = ones(1,Ly);

dist1= maxDistSL- DistMargin*0.5;
dist2= maxDistSL+ DistMargin*0.5;
t1= dist1/Vs; t2 = dist2/Vs;
N1= floor(t1* Fs); N2= ceil (t2*Fs);

Nc= ceil(slope * Fs/1000);
Nt= N1+Nc+(Ly-N2)+1;

if ismOrRir
    for n=N1:N2-1
        windowIsmRIR(n)=0.5-0.5*cos(pi*(n-(N1+Nc*0.5)-Nc*0.5)/Nc);
    end

    for n=N2:Ly
        windowIsmRIR(n)=0;
    end
else
    for n=N1:N2-1
        windowIsmRIR(n)=0.5 + 0.5*cos(pi*(n-(N1+Nc*0.5)-Nc*0.5)/Nc);
    end

    for n=1:N1-1
        windowIsmRIR(n)=0;
    end

end


y2w = y;
for i=1:Ly
    y2w(i,1)= y(i,1)*windowIsmRIR(i);
    y2w(i,2)= y(i,2)*windowIsmRIR(i);
end
% plot (y2w);
% disp(DistMargin);

