addpath(genpath('~/Dropbox/Codes/cochlear_models/'))
addpath(genpath(pwd))
% Generates auditory nerve responses to a set of stimuli
outdir=pwd;
wavfile='~/Dropbox/Codes/cochlear_models/natural_sound_clip.wav';
% Read the stimulus
[x,fs]=audioread(wavfile);

% Run the model
dbSPL=70;
%BFs=round(greenwood(100,100,5000));
%BFs=2000;
BFs = logspace(log10(508),log10(19912),16);
dt = 4;
paramnames={'GP_LSR','GP_MSR','GP_HSR'};
fiber_percent = [15 25 60]; % ColburnCarney-JARO-2003
for ii=1:numel(paramnames)
  nreps=fiber_percent(ii); 
  modeldata{ii}=runexperiment(x,fs,dt,dbSPL,BFs,nreps,paramnames{ii});
end

output=runmodel(setleveldb(x,dbSPL),fs,BFs,1,paramnames{1});

[X_ft_meddis,~,~,X_ft_meddis_AN] = cochleagram_meddis_IHC(x,fs,dt,'log',16);
X_ft_spec = cochleagram_spec_log(x,fs,dt,'log',16);

X_ft_AN = zeros(size(modeldata{1}));
fiber_thresholds = [0 15;10 30;25 45]; % ColburnCarney-JARO-2003
for ii=1:max(size(modeldata))
    X_ft_AN = X_ft_AN + modeldata{ii}*diff(fiber_thresholds(ii,:))/range(modeldata{ii}(:)) + fiber_thresholds(ii,1);
end
% The problem is that I don't know where or how this process may happen.
% So it is better to resort to a simpler process to generate cochleagram
% based on the mean firing rates of the auditory nerves

for ii=1:2
    subplot(5,2,ii)
    plot(x)
    xlim([0 fs])
    title('Waveform')
end

field_names = {'bm','ihc','syn'};
an_fiber_types = {'LSR','MSR','HSR'};
for ii=1:3
    subplot(5,2,2*ii+1)
    X_ft = output.(field_names{ii});
    imagesc(resample(X_ft',floor(dt*1e3),fs)');
    %xlim([0 1000*length(x)/(4*fs)])
    axis xy
    title(['Sumner ',field_names{ii}])
    
    subplot(5,2,2*ii+2)
    imagesc(modeldata{ii})
    xlim([0 1000*length(x)/(4*fs)])
    axis xy
    title(['Sumner AN ',an_fiber_types{ii}])
    
end

subplot(5,2,9)
imagesc(X_ft_meddis)
axis xy
xlim([0 1000*length(x)/(4*fs)])
title('Meddis IHC')

subplot(5,2,10)
imagesc(X_ft_spec)
axis xy
xlim([0 1000*length(x)/(4*fs)])
title('Spec-log')

function mean_psth=runexperiment(x,fs,dt,dbSPL,BFs,nreps,modelparams)
  x=setleveldb(x,dbSPL); % In uPascals
  % Run the model
  output=runmodel(x,fs,BFs,nreps,modelparams);
  
  % Populate the data structure
  spiketimes=anoutput2spiketimes(output.spikes,fs);
  edges = 0:dt*1e-3:1.2*length(x)/fs;
  for jj=1:numel(BFs)
    for ii = 1:nreps  
        psthdata(ii,:) = histc(spiketimes{ii,jj},edges);
    end
    mean_psth(jj,:) = mean(psthdata,1);
  end
end

function X_ft=runIHC(x,fs,dt,dbSPL,BFs,modelparams)
  x=setleveldb(x,dbSPL); % In uPascals
  % Run the model
  output=runmodel(x,fs,BFs,1,modelparams);
  
  X_ft = resample(output.ihc',floor(dt*1e3),fs)';
end
    