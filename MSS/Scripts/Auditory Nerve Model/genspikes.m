% GENSPIKE  Performs stochastic spike generation
%   output = GENSPIKES(signal,fs,refractory,nfibres) performs stochastic
%   spike generation based on vesicle release probabilities provided in
%   SIGNAL. Spikes are generated independently for each of NFIBRES auditory
%   nerve fibres for each of the N probability functions provided in the N
%   x M matrix SIGNAL.
%
%   The output is the an N x M x P matrix, where P = nfibres.
%
%   Mark Steadman
%   14/01/2015
%   
%   marks@ihr.mrc.ac.uk

function output=genspikes(signal,fs,refractory,nfibres)
  signal=repmat(signal,1,1,nfibres);
  timesincelast=zeros(size(signal,1),1,nfibres);
  output=false(size(signal));
  dt=1/fs;
  
  for i=1:size(signal,2)
    % stochastically emit vesicle
    ejected=signal(:,i,:)>rand(size(signal,1),1,nfibres);
    
    % apply refractory period
    ejected(timesincelast<refractory)=false;
    timesincelast(ejected)=0;
    
    output(:,i,:)=ejected;
    timesincelast=timesincelast+dt;
  end
end