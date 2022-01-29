function [X_ft, t, params] = cochleagram_spec_log(x, fs, dt, type, varargin)
% function [X_ft, t, params] = cochleagram_spec_log(x, fs, dt, type, varargin)
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
%
% Author: Monzilur Rahman
% Year: 2018

params.fs = fs;
params.threshold = -50;

if strcmp(type, 'log')
  if isempty(varargin)
%     params.f_min = 1000;
    params.f_min = 500;
%     params.f_max = 32000;
    params.f_max = 22627;
%     params.n_f = 31;
    params.n_f = 34;
    %%%%%%%%%%%% PLEASE NOTE: For the SHEnC data, 
    % we can only go up to 24kHz as the sound were sampled with 48kHz. By 
    % setting the values like this, we make sure that the upper 28 of 
    % the 34 frequency channels cover exactly the same frequencies as the 
    % lower 28 channels in the Comp data
  else
    if max(size(varargin)) == 1
        CFs= 2^(1.5)* 440 * 2 .^ ((-31:97)/24); %shft = 1.5
        params.f_min=CFs(1);
        params.f_max=CFs(end-1);
        params.n_f=varargin{1};
    else
        params.f_min=varargin{2};
        params.f_max=varargin{3};
        params.n_f=varargin{1};
    end
	%[params.f_min, params.f_max, params.n_f] = varargin{:};
  end

  params.nfft_mult = 4;
  params.meltype = 'lusc';

elseif strcmp(type, 'cat-erb')
  if isempty(varargin)
    params.f_min = 1000;
    params.f_max = 32000;
    params.n_f = 23;
  else
	[params.f_min, params.f_max, params.n_f] = varargin{:};
  end

  params.nfft_mult = 1;
  params.meltype = 'kusc';

end

% get actual dt (which is an integer number of samples)
dt_sec_nominal = dt/1000;
dt_bins = round(dt_sec_nominal*params.fs);
params.dt_sec = dt_bins/params.fs;

% get window, overlap sizes
t_window_bins = dt_bins * 2;
params.t_window_sec = t_window_bins/params.fs;
t_overlap_bins = t_window_bins - dt_bins;

[melbank.x, melbank.mc, melbank.na, melbank.nb] =  melbankbw(params.n_f,...
    t_window_bins*params.nfft_mult, params.fs, params.f_min/params.fs,...
    params.f_max/params.fs, params.meltype);        
if any(sum(melbank.x')==0)
	error('some melbank filters have no coefficients; increase nfft_mult');
end

params.melbank = melbank;

params.freqs = 10.^params.melbank.mc;

[spec, freqs, t] = spectrogram(x, t_window_bins, t_overlap_bins,...
    t_window_bins*params.nfft_mult, params.fs);

X_ft = nan(size(params.melbank.x,1), size(spec,2));
for tt = 1:size(spec,2)
    X_ft(:,tt)=max(20.*log10(params.melbank.x*abs(spec(...
        params.melbank.na:params.melbank.nb,tt))), params.threshold);
end
