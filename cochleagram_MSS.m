function [X_ft,t,params,X_ft_composite] = cochleagram_MSS(x,fs,dt,type,varargin)
% function [X_ft,t,params] = cochleagram_MSS(x,fs,dt,type,varargin)
%
% Author: Monzilur Rahman
% Year: 2018
if ~exist('type','var')
    type = 'log';
end

dbSPL=70;
CFs= 2^(1.5)* 440 * 2 .^ ((-31:97)/24); %shft = 1.5
params.f_min=CFs(1);
params.f_max=CFs(end-1);
params.n_f = varargin{1};
params.fs = fs;

if type == 'log'
    BFs = logspace(log10(params.f_min),log10(params.f_max),params.n_f);
end

paramnames={'GP_LSR','GP_MSR','GP_HSR'};
nreps=20; % Number of fibers per centre frequency
  
% Run the model
for ii=1:numel(paramnames)
  [modeldata{ii},t] = runexperiment(x,fs,dt,dbSPL,BFs,nreps,paramnames{ii});
end

X_ft_composite = cat(1,modeldata{:});
fiber_percent = [0.15 0.25 0.6]; % ColburnCarney-JARO-2003

X_ft = zeros(size(modeldata{1}));
for ii=1:max(size(modeldata))
    X_ft = X_ft + modeldata{ii}*fiber_percent(ii);
end

params.freqs = BFs;

end

function [mean_psth,edges]=runexperiment(x,fs,dt,dbSPL,BFs,nreps,modelparams)
  x=setleveldb(x,dbSPL); % In uPascals
  % Run the model
  output=runmodel(x,fs,BFs,nreps,modelparams);
  
  % Populate the data structure
  spiketimes=anoutput2spiketimes(output.spikes,fs);
  edges = 0:dt*1e-3:length(x)/fs;
  for jj=1:numel(BFs)
    for ii = 1:nreps  
        psthdata(ii,:) = histc(spiketimes{ii,jj},edges);
    end
    mean_psth(jj,:) = mean(psthdata,1);
  end
end
    