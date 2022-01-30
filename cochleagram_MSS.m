function [X_ft,t,params,X_ft_multiFiber] = cochleagram_MSS(x,fs,dt,type,varargin)
% [X_ft, t, params, X_ft_multiFiber] = cochleagram_MSS(x,fs,dt,type,varargin)
% This function uses neural-represntations-of-speech-v1.1 toolbox
% Author: Monzilur Rahman
% Year: 2018
% ===================================================
% input params:
% x -- the sound
% fs -- sample rate in Hz
% dt -- desired time bin size in ms
% type -- 'log'
% varargin -- additional parameters: n_f, f_min, f_max
%
% Default values: 
% - number of frequency channels = 34
% - f_min = 500
% - f_max = 19900
% - fiber number per channel = 200
% output:
% X_ft -- the cochleagram
% t -- times at which cochleagram is measured
% params -- parameters used to make the cochleagram
% X_ft_multiFiber -- multiFiber cochleagram output

% ===================================================
% Example:
% [x,fs] = audioread('soundfile.wav')
% cochleagram_MSS(x,fs,5,'log',32,500,22000,100)

if ~exist('type','var')
    type = 'log';
end

dbSPL=70;

% set frequencies
if size(varargin,2)>0
    params.n_f = varargin{1};
else
    params.n_f = 34;
end

if size(varargin,2)>2
    params.f_min = varargin{2};
    params.f_max = varargin{3};
else
    WSR_CFs= 2^(1.5)* 440 * 2 .^ ((-31:97)/24);
    params.f_min = WSR_CFs(1); % 500 Hz
    params.f_max = WSR_CFs(end-1); % 19900 Hz
end

if type == 'log'
    CFs = logspace(log10(params.f_min),log10(params.f_max),params.n_f); % set range and resolution of CFs here
end

paramnames={'GP_LSR','GP_MSR','GP_HSR'};

if max(size(varargin))>3
    nreps = varargin{4};
else
    nreps=20; % Number of fibers per centre frequency
end
  
% Run the model
for ii=1:numel(paramnames)
  [modeldata{ii},t] = runexperiment(x,fs,dt,dbSPL,CFs,nreps,paramnames{ii});
end

X_ft_multiFiber = cat(1,modeldata{:});
fiber_percent = [0.15 0.25 0.6]; % ColburnCarney-JARO-2003

X_ft = zeros(size(modeldata{1}));
for ii=1:max(size(modeldata))
    X_ft = X_ft + modeldata{ii}*fiber_percent(ii);
end

params.freqs = CFs;

end

function [mean_psth,edges]=runexperiment(x,fs,dt,dbSPL,CFs,nreps,modelparams)
  x=setleveldb(x,dbSPL); % In uPascals
  % Run the model
  output=runmodel(x,fs,CFs,nreps,modelparams);
  
  % Populate the data structure
  spiketimes=anoutput2spiketimes(output.spikes,fs);
  edges = 0:dt*1e-3:length(x)/fs;
  for jj=1:numel(CFs)
    for ii = 1:nreps  
        psthdata(ii,:) = histc(spiketimes{ii,jj},edges);
    end
    mean_psth(jj,:) = mean(psthdata,1);
  end
end
    