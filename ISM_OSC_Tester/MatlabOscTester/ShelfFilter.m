%% shelvFilt = shelvingFilter(gain,slope,cutoffFreq,type)
 shelvFiltLP = shelvingFilter  (-30,1,62.5*sqrt(2),"lowpass");
 %shelvFiltHP = shelvingFilter  (-30,1,16000/sqrt(2),"highpass");
 visualize(shelvFiltLP); 
 %visualize (shelvFiltHP);