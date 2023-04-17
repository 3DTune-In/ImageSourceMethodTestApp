%Energy per band 
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