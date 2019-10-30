% BUILDNEUROGRAMS converts a list of .mat files contain data using the SPK
% data structure into a set of neurograms.
%
% Y=BUILDNEUROGRAMS(FILELIST,BINSIZE,DURATION)
%   Takes in input set of .mat data files utilising the SPK data structure
%   and builds neurograms assuming that the stimulus class (i.e. phoneme)
%   is indicated by the parameter name consonantID and the exemplar index
%   is indicated by the parameter name speakerID.
%
%   The neurograms are M x N matrices where M = NUMEL(FILELIST) and N in
%   the number of bins. The number of bins is derived from DURATION, the
%   maximum duration of each stimulus, and BINSIZE, the binsize used to
%   calculate the single trial PSTHS
%
%   Y is an M x N x P cell array whereby M is the number of exemplars of
%   each stimulus class (e.g. the number of talkers), N is the number of
%   stimulus classes (e.g. the number of phonemes) and P is the number of
%   repetitions.
%
% By Mark A. Steadman

function neurograms=buildneurograms(filelist,binsize,duration)
 
  % Read in all the spike data
  data=cellfun(@load, filelist);
  spkdata=cat(1,data.spkdata);
  
  % Extract the stim information for each sweep in spkdata
  stimgrids=arrayfun(@(x) cat(1,x.sets.parameter_values),spkdata,'uni',0);
  talkerid=find(ismember(spkdata(1).parameter_names,'speakerID'));
  tokenid=find(ismember(spkdata(1).parameter_names,'consonantID'));
  talkers=unique(stimgrids{1}(:,talkerid));
  tokens=unique(stimgrids{1}(:,tokenid));
  
  % Initialise output array
  nsites=numel(filelist);
  ntalkers=numel(talkers);
  ntokens=numel(tokens);
  nreps=min(arrayfun(@(y) min(arrayfun(@(x) numel(x.sweeps),y.sets)),spkdata));
  neurograms=cell(ntalkers,ntokens,nreps);
  
  % Define PSTH bin edges
  edges=0:binsize:duration;
  
  % Main loop
  for i=1:ntalkers
    for j=1:ntokens
      for k=1:nreps
        for m=1:nsites
          idx=ismember(stimgrids{m}(:,[talkerid,tokenid]),...
            [talkers(i),tokens(j)],'rows');
          psth=histcounts(spkdata(m).sets(idx).sweeps{k},edges);
          neurograms{i,j,k}(m,:)=psth;
        end
      end
    end
  end
end