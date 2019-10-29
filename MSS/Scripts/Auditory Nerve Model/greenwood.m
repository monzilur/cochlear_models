function F=greenwood(nchans,f1,f2)
  % Uses Greenwood scale "A cochlear frequency?position function for
  % several species—29 years later"
  A=350;
  a=2.1/18.5;
  k=0.85;
  x=linspace(log10((f1/A)+k)/a,log10((f2/A)+k)/a,nchans);
  F=round(A*(10.^(a*x)-k));
end