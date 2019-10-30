function output=runmodel_prob(signal,fs,BFs,paramname)
  
  % Load parameters
  paramfun=str2func(strcat('loadparams_',paramname));
  paramfun(BFs);
  
  % Outer/middle ear filtering
  output=ome(signal,fs,params.OME);
  
  % Basilar membrane
  output=drnl(output,fs,params.DRNL);
  
  % Inner hair cell
  output=ihc(output,fs,params.IHC);
  
  % Synapse (deterministic output)
  output=synapse(output,fs,params.synapse);
end