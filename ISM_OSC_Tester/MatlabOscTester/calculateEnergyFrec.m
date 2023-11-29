%% Calculates the energy of an impulse response in the frequency domain

% Author: Fabian Arrebola (03/03/2023) 
% contact: areyes@uma.es
% 3DDIANA research group. University of Malaga
% Project: SONICOM
% 
% Copyright (C) 2023 Universidad de Málaga

%Energy in  frequency domain
function [energy]= calculateEnergyFrec (Fs, IR)

Y =  fft(IR);
Ya= abs(Y);
Ye= sum(Ya .^2);
energy= Ye;