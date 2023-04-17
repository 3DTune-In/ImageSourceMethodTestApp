%Energy in  time domain
function [energy] = calculateEnergy(yIR)

v=rms(yIR);
v2=v.^2;   
v3=v2.*length(yIR);
energy=v3;