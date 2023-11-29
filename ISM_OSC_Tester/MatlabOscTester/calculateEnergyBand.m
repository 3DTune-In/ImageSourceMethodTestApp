%% Calculates the energy of an impulse response for a given frequency band

% Author: Fabian Arrebola (03/03/2023) 
% contact: areyes@uma.es
% 3DDIANA research group. University of Malaga
% Project: SONICOM
% 
% Copyright (C) 2023 Universidad de Málaga

function [energy]= calculateEnergyBand (Fs, IR, Lo, Hi)

L=length(IR);

Y = fft(IR);
Ya= abs(Y);
Y2= Ya.^2;

P1= zeros (L/2+1, 2);
P1 = Y2(1:L/2+1,:);
P1(2:end-1,:) = 2*P1(2:end-1,:);
P2 = P1(Lo : Hi,:);

Ye= sum(P2);

energy= Ye;