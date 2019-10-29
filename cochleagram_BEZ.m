function [X_ft, t, params, X_ft_composite] = cochleagram_BEZ(x,fs,dt,type,varargin)
% c[X_ft, t, params, X_ft_composite] = cochleagram_BEZ(x,fs,dt,type,varargin)
% This function was edited from UR_EAR_v2_1 by Carney lab

Fs = 100e3;
RsFs = floor(1000/dt);  %Resample rate for time_freq surface plots

if ~exist('type','var')
    type = 'log';
end

% set frequencies
if size(varargin,2)>0
    param.n_f = varargin{1};
else
    minCF  = 500;
    maxCF = 19.9;
    param.n_f = 34;
end

WSR_CFs= 2^(1.5)* 440 * 2 .^ ((-31:97)/24);
minCF = WSR_CFs(1);
maxCF = WSR_CFs(end-1);

if type == 'log'
    CFs = logspace(log10(minCF),log10(maxCF),param.n_f); % set range and resolution of CFs here
end

% Stimulus preparation
% Apply ramp
cosine_ramp = ones(size(x));
ramp_length = 500;
cosine_ramp(end-ramp_length+1:end) = 0.5 + 0.5*cos(pi*[0:1:ramp_length-1]/ramp_length);
cosine_ramp(1:ramp_length) = 0.5 + 0.5*cos(pi*[ramp_length-1:-1:0]/ramp_length);
x = x.* cosine_ramp;

%Wav File   (Note: stimulus duration is computed from file, and no on/off ramp is applied.)
add_LTASS_noise = 0;  SNR = 0; % Note that tukeywin is applied after noise is added (no tukeywin was used for 'plain' speech)
stimdB = 70;
[p,q] = rat(Fs/fs,0.0001);% find two integers whose ratio matches the desired change in sampling rate
stimulus = resample(x',p,q);% resample signal to have sampling rate required for AN model
stimulus = 20e-6 * power(10,(stimdB/20)) * stimulus/rms(stimulus); % scale stim to have an rms = 1, then scale to desired dB SPL in Pascals.

if add_LTASS_noise == 1                    % Make wideband LTASS noise (100 Hz - 6 kHz)
  disp('Adding LTASS noise with SNR = 0');
  ltass_SPL = stimdB - SNR;               
  ltass_noise = ltass_noise0(Fs,ltass_SPL,length(stimulus),1); % note: function modified to handle Fs = 100kHz
  ltass_ramp = 0.010;
  ltass_dur = length(stimulus)/Fs;
  gate = tukeywin(length(ltass_noise), 2*ltass_ramp/ltass_dur); %gating function 
  ltass_noise = ltass_noise .* gate;
  stimulus = stimulus + ltass_noise';      
end

% Model Selection and Parameters
fiber_num = 10; % Number of fibers in each CF
species = 1;% 1=cat; 2=human AN model parameters (with Shera tuning sharpness)

% Check for NaN in stimulus - this prevents NaN from being passed into .mex files and causing MATLAB to close
if sum(isnan(stimulus))>0
    error('One or more fields of the UR_EAR input were left blank or completed incorrectly.')
end

% Set up and RUN the simulation
dur = length(stimulus)/Fs;             % duration of waveform in sec
onset_num = 1;  % 1st point that will be included in analyzed response  (allows exclusion of onset response, e.g. to omit 1st 50 ms, use 0.050*Fs;)

% Loop through AN fibertypes
for fiberType=1:3
    [AN_output,~] = generate_neurogram_UREAR2_MR(stimulus,Fs,RsFs,species,CFs,dur,fiber_num,fiberType);
    modeldata{fiberType} = AN_output.an_sout_population(:,1:ceil(dur*RsFs));
    %X_ft = AN_output.an_sout_population;
end

X_ft_composite = cat(1,modeldata{:});
fiber_percent = [0.15 0.25 0.6]; % ColburnCarney-JARO-2003

X_ft = zeros(size(modeldata{1}));
for ii=1:max(size(modeldata))
    X_ft = X_ft + modeldata{ii}*fiber_percent(ii);
end

t = (0:size(X_ft,2)-1)/RsFs;

params.freqs = CFs;
params.dur =  dur;

end