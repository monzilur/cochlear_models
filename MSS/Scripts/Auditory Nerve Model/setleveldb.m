function y=setleveldb(x,leveldBSPL)

  % Convert the value in dB to one in pascals
  upascals=10.^(leveldBSPL/20)*20;

  % Determine the current RMS value of the signal
  rmsVal=rms(x);

  % set the RMS value of the signal to be equal to the value in pascals
  multiplier=upascals/rmsVal;
  y=x*multiplier;
end