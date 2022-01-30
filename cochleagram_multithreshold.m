function [X_ft, t, params, X_ft_multithreshold] = cochleagram_multithreshold(x, fs, dt, type, varargin)
% function [X_ft, t, params, X_ft_multithreshold] = cochleagram_multilevel(x, fs, dt, type, varargin)
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
% X_ft_multithreshold - a multithreshold cochleagram
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
% 
% X_ft = nan(size(params.melbank.x,1), size(spec,2));
% for tt = 1:size(spec,2)
%     X_ft(:,tt)=10.*log10(params.melbank.x*((abs(spec(params.melbank.na:params.melbank.nb,tt))).^2));
% end


% Loop through AN fibertypes
%params.threshold = [0 -20 -40];
params.threshold = [-15 -30 -40];
%params.SAT = [8e-6 2e-6 4e-7];
% params.SAT = [2e-5 8e-6 4e-6]; % v1
params.SAT = [6e-5 3e-5 1e-5]; % v2
% params.SAT = [8e-5 5e-5 3e-5]; % v3
% params.SAT = [1 1 1]*4.6e-5; % v4

for fiberType=1:3
    threshold = params.threshold(fiberType);
    SAT = params.SAT(fiberType);
    modeldata{fiberType} = model_fiber_type(params,spec,threshold,SAT);
end

X_ft_multithreshold = cat(1,modeldata{:});
fiber_percent = [0.15 0.25 0.6]; % ColburnCarney-JARO-2003
%fiber_percent = 0.33*ones(1,3);
X_ft = zeros(size(modeldata{1}));
for ii=1:max(size(modeldata))
    X_ft = X_ft + modeldata{ii}*fiber_percent(ii);
end
end


function modeldata = model_fiber_type(params,spec,threshold,SAT)
    modeldata = nan(size(params.melbank.x,1), size(spec,2));
    for tt = 1:size(spec,2)
        modeldata(:,tt)= max(10.*log10(params.melbank.x*((abs(spec(...
            params.melbank.na:params.melbank.nb,tt))).^2)),threshold) -threshold;
    end
    
    n= 1.77;
    c=1e-4;
    modeldata = hill_function(modeldata,n,c,SAT);
end
