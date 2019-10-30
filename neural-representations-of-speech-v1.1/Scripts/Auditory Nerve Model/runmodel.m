function output=runmodel(signal,fs,BFs,nfibres,paramname)
  refractory=0.75e-3; % refractory period
  
  % Load parameters
  paramfun=str2func(strcat('loadparams_',paramname));
  paramfun(BFs);
  
  % Outer/middle ear filtering
  output.ome=ome(signal,fs,params.OME);
  
  % Basilar membrane
  output.bm=drnl(output.ome,fs,params.DRNL);
  
  % Inner hair cell
  output.ihc=ihc(output.bm,fs,params.IHC);
  
  % Synapse (deterministic output)
  output.syn=synapse(output.ihc,fs,params.synapse);

  % stochastic spike generation (75ms refractory period);
  output.spikes=genspikes(output.syn,fs,refractory,nfibres);

end