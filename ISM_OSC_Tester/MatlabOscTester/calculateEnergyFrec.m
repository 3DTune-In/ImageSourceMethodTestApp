%Energy in  frequency domain
function [energy]= calculateEnergyFrec (Fs, IR)

Y =  fft(IR);
Ya= abs(Y);
Ye= sum(Ya .^2);
energy= Ye;