function [X_ft, t, params] = cochleagram_WSR(x, fs, dt, type, varargin)
% function [X_ft, t, params] = cochleagram_WSR(x, fs, dt, type, varargin)
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

% set number of frequency channels
if size(varargin,2)>0
    params.n_f = varargin{1};
else
    params.n_f = 34;
end

frmlen = dt; % frame length in ms
tc = 8; % time-constant of leaky integration
fac = 1; % non-linear factor, in a value of -1, it turns into a half-wave rectifier
shft = 1.5; % shifter by # of octaves, sets frequencies between 508Hz to 20K

params.frmlen=frmlen;
params.tc=tc;
params.fac=fac;
params.shft=shft;

CFs= 2^shft* 440 * 2 .^ ((-31:97)/24);

x_t = resample(x,round(16000*2^shft),fs);

X_ft = (wav2aud(x_t, [frmlen tc fac shft]))';

t=0:frmlen:(size(X_ft,2)-1)*frmlen;
t=t/1000;

selected_channels = floor(linspace(1,length(CFs)-1,params.n_f));

X_ft=X_ft(selected_channels,:);

params.freqs = CFs(selected_channels);