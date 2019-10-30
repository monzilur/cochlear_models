function spkdata=createSPKtemplate(fname,nsets,nreps)

[~,fname,fext]=fileparts(fname);
spkdata.original_filename=[fname,fext];
spkdata.trode='';
spkdata.unit=0;
spkdata.parameter_names={'stimID'};
spkdata.sets=repmat(struct(...
   'parameter_values', 0,...
   'stimulus',[],...
   'sweeps', {cell(nreps,1)}),nsets,1);
end