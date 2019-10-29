function [X_ft, t, params] = cochleagram_LS(x, fs, dt, type, varargin)
% function [X_ft, t, params] = cochleagram_LS(x, fs, dt, type, varargin)
%
% NOTE: this function has been copied from benlib and has not been altered!
%
% calculate log-frequency-spaced or cat-erb-spaced cochleagram
% of input sound.
%
% input params:
% x -- the sound
% fs -- sample rate in Hz
% dt -- desired time bin size in ms
% type -- 'log' or 'cat-erb'
% varargin -- additional parameters, currently f_min, f_max, n_f
%
% output:
% X_ft -- the cochleagram
% t -- times at which cochleagram is measured
% params -- parameters used to make the cochleagram
%
% e.g.
% 1/2-octave spacing between 500 and 1600Hz, 10ms time window:
% [X_ft, t, params] = cochleagram(rand(10000,1), 44100, 10, 'log', 500, 16000, 11)

if strcmp(type, 'log')
  if isempty(varargin)
    params.f_min = 500;
    params.f_max = 22627;
    params.n_f = 34;		
%   %%%%%%%%%%%% PLEASE NOTE: For the SHEnC data, we can only go up to 24kHz as the sound were sampled with 48kHz.
%   By setting the values like this, we make sure that the upper 28 of the 34 frequency channels cover exactly the
%   same frequencies as the lower 28 channels in the Comp data
  else
    CFs= 2^(1.5)* 440 * 2 .^ ((-31:97)/24); %shft = 1.5
    params.f_min=CFs(1);
    params.f_max=CFs(end-1);
    params.n_f=varargin{1};      
	%[params.f_min, params.f_max, params.n_f] = varargin{:};
  end
  
  freqs = logspace(log10(params.f_min),log10(params.f_max),params.n_f);
  
elseif strcmp(type, 'cat-erb')
  if isempty(varargin)
    params.f_min = 1000;
    params.f_max = 32000;
    params.n_f = 23;
  else
	[params.f_min, params.f_max, params.n_f] = varargin{:};
  end
  mflh=[params.f_min params.f_max];
  mflh=frq2erbcat(mflh);
  melrng=mflh*(-1:2:1)';          % mel range
  melinc=melrng/(param.n_f-1);
  
  freqs=mflh+(-1:2:1)*melinc;
end

%earQ=4; % 4,8,16 respectively for 29, 60 and 121 channels
%earQ = K * stepfactor * params.n_f; % earQ/stepfactor = numChannels;
% For stepfactor 0.5 (50% overlap of channels) and 29 frequency channels earQ = 4
% earQ stepfactor table: numChannels, earQ, stepfactor
numChannel_list = [2 4 8 16 32 64 128];
earQ_list = [1 1 2 2 2 4 8];
stepfactor_list = [0.5 0.25 0.5 0.25 0.125 0.125 0.125];
earQ = earQ_list(numChannel_list==params.n_f);
stepfactor = stepfactor_list(numChannel_list==params.n_f);

df = floor(dt*fs/1000);

[X_ft,CenterFreqs, gains, earQ]=LyonPassiveEar_original(x,fs,df,earQ,stepfactor);
X_ft = flip(X_ft,1);
CenterFreqs = fliplr(CenterFreqs);

ind_fmin = find(min(abs(freqs(1)-CenterFreqs))==abs(freqs(1)-CenterFreqs));
ind_fmax = find(min(abs(freqs(end)-CenterFreqs))==abs(freqs(end)-CenterFreqs));
selected_channels = floor(linspace(ind_fmin,ind_fmax,params.n_f));

X_ft = X_ft(selected_channels,:);

dt_corrected = df/fs;

t = 0:dt_corrected:dt_corrected*(size(X_ft,2)-1);

params.earQ=earQ;
params.stepfactor=stepfactor;
params.freqs=CenterFreqs(selected_channels);
params.gains=gains;