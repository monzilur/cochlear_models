function sweeps=anoutput2spiketimes(output,fs)

  nsites=size(output,1); 
  nreps=size(output,3);
  sweeps=cell(nreps,nsites);
  
  for i=1:nsites
    for j=1:nreps
      times=find(output(i,:,j))/fs;
      sweeps{j,i}=times;
    end
  end
end