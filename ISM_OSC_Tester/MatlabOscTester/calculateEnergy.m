%% Calculates the energy of an impulse response in the time domain

% Author: Fabian Arrebola (03/03/2023) 
% contact: areyes@uma.es
% 3DDIANA research group. University of Malaga
% Project: SONICOM
% 
% Copyright (C) 2023 Universidad de Málaga

function [energy] = calculateEnergy(yIR)

v=rms(yIR);
v2=v.^2;   
v3=v2.*length(yIR);
energy=v3;