function [X_ft, t, params] = cochleagram_spec_power(x, fs, dt, type, varargin)
% function [X_ft, t, params] = cochleagram_spec_power(x, fs, dt, type, varargin)
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
% varargin -- additional parameters: n_f, f_min, f_max
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

if ~exist('type','var')
    type = 'log';
end

params.fs = fs;
params.threshold = -70;

if strcmp(type, 'log')
    
  params.nfft_mult = 4;
  params.meltype = 'lusc';

elseif strcmp(type, 'cat-erb')

  params.nfft_mult = 1;
  params.meltype = 'kusc';

end

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

% get actual dt (which is an integer number of samples)
dt_sec_nominal = dt/1000;
dt_bins = round(dt_sec_nominal*params.fs);
params.dt_sec = dt_bins/params.fs;

% get window, overlap sizes
t_window_bins = dt_bins * 2;
params.t_window_sec = t_window_bins/params.fs;
t_overlap_bins = t_window_bins - dt_bins;

[melbank.x, melbank.mc, melbank.na, melbank.nb] =  melbankbw(params.n_f, ...
    t_window_bins*params.nfft_mult, params.fs, params.f_min/params.fs, ...
    params.f_max/params.fs, params.meltype);        
if any(sum(melbank.x')==0)
	error('some melbank filters have no coefficients; increase nfft_mult');
end

params.melbank = melbank;

params.freqs = 10.^params.melbank.mc;

[spec, freqs, t] = spectrogram(x, t_window_bins, t_overlap_bins, ...
    t_window_bins*params.nfft_mult, params.fs);

X_ft = nan(size(params.melbank.x,1), size(spec,2));
for tt = 1:size(spec,2)
    %before_threshold(:,tt) = 10.*log10(params.melbank.x*((abs(spec(params.melbank.na:params.melbank.nb,tt))).^2));
    X_ft(:,tt)=max(10.*log10(params.melbank.x*((abs(spec(params.melbank.na:params.melbank.nb,tt))).^2)),params.threshold);
end
%plot(before_threshold(:))