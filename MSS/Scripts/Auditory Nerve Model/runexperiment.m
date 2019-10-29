function spkdata=runexperiment(wavlist,dbSPL,wavparams,BFs,nreps,modelparams)

nsets=numel(wavlist);
spkdata=createSPKtemplate('NA',nsets,nreps);
spkdata.parameter_names=fieldnames(wavparams);
spkdata=repmat(spkdata,numel(BFs),1);
stimgrid=cell2mat(struct2cell(wavparams')');

for i=1:numel(wavlist)
  
  % Read the stimulus
  [sig,fs]=audioread(wavlist{i});
  sig=setleveldb(sig,dbSPL); % In uPascals
  
  % Run the model
  [~,name]=fileparts(wavlist{i});
  display(['Processing ' name]);
  output=runmodel(sig,fs,BFs,nreps,modelparams);
  
  % Populate the data structure
  spiketimes=anoutput2spiketimes(output.spikes,fs);
  
  for j=1:numel(BFs)
    spkdata(j).sets(i).stimulus.values=sig;
    spkdata(j).sets(i).stimulus.fs=fs;
    spkdata(j).sets(i).parameter_values=stimgrid(i,:);
    spkdata(j).sets(i).sweeps=spiketimes(:,j);
  end
end