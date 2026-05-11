%% This script contains the formulation associated with the 
%% coefficient calculation process for Peak and Shelving filters. 

% Authors: Fabian Arrebola (16/05/2024) 
% contact: areyesa@uma.es
% 3DDIANA research group. University of Malaga
% Project: SONICOM
% 
% Copyright (C) 2024 Universidad de Málaga


classdef calculateShelCoef
    methods (Static)  

        function [b0,b1,b2,a0, a1,a2] = LowP (Fs,Fc, Q, gain)
            A = sqrt(gain);
            w0 = 2 * pi * Fc / Fs;
            beta = sqrt(A)/Q;
           
            b0 =    A*( (A+1) - (A-1)*cos(w0) + beta*sin(w0));
            b1 =  2*A*( (A-1) - (A+1)*cos(w0));
            b2 =    A*( (A+1) - (A-1)*cos(w0) - beta*sin(w0));
            a0 =        (A+1) + (A-1)*cos(w0) + beta*sin(w0);
            a1 =   -2*( (A-1) + (A+1)*cos(w0));
            a2 =        (A+1) + (A-1)*cos(w0) - beta*sin(w0);

            b2 =b2/a0; b1 =b1/a0; b0 =b0/a0;
            a2 =a2/a0; a1 =a1/a0; 
            a0=1;
        end

        function [b0,b1,b2, a0, a1,a2] = HighP (Fs,Fc, Q, gain)
           
            A = sqrt(gain);
            w0 = 2 * pi * Fc / Fs;
            beta = sqrt(A)/Q;
           
            b0 =    A*( (A+1) + (A-1)*cos(w0) + beta*sin(w0));      
            b1 = -2*A*( (A-1) + (A+1)*cos(w0));
            b2 =    A*( (A+1) + (A-1)*cos(w0) - beta*sin(w0));
            a0 =        (A+1) - (A-1)*cos(w0) + beta*sin(w0);
            a1 =   +2*( (A-1) - (A+1)*cos(w0));
            a2 =        (A+1) - (A-1)*cos(w0) - beta*sin(w0);

            b2 =b2/a0; b1 =b1/a0; b0 =b0/a0;
            a2 =a2/a0; a1 =a1/a0; 
            a0=1;
        end

%         function [b0,b1,b2,a0,a1,a2] = BandP(Fs, Fcen, Q, gain)
%             A = sqrt(gain);
%             w0 = 2 * pi * Fcen / Fs;
%             alfa = sin(w0)/(2*Q);
%             b0 = 1 + alfa*A   ;
%             b1 = -2 * cos(w0) ;
%             b2 = 1 - alfa/A   ;
%             a0 = 1 + alfa/A   ;
%             a1 = -2 * cos(w0) ;
%             a2 = 1 - alfa/A    ;
% 
%             b2 =b2/a0; b1 =b1/a0; b0 =b0/a0;
%             a2 =a2/a0; a1 =a1/a0; a0=1;
%         end

        function [b0,b1,b2,a0,a1,a2] = BandP_Valimak(Fs, Fcen, Q, G)
            A = sqrt(G);
            %Bw = (Fcen/(Fs/2))/Q;
            wc = 2 * pi * Fcen / Fs;
            Bw = wc/Q;
            beta = 2*A*cos(wc);

            b0 = A + G * tan(Bw/2)  ;
            b1 = -2 * A* cos(wc) ;
            b2 = A - G * tan(Bw/2)   ;
            a0 = A +     tan(Bw/2)   ;
            a1 = -2 * A* cos(wc) ;
            a2 = A -     tan(Bw/2)   ;

            b2 =b2/a0; b1 =b1/a0; b0 =b0/a0;
            a2 =a2/a0; a1 =a1/a0; a0=1;
        end
    end

end