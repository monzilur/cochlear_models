function [X_ft,t,params,X_ft_multiFiber] = cochleagram_multiFiber(x,fs,dt,type,varargin)
% [X_ft, t, params, X_ft_multiFiber] = cochleagram_multiFiber(x,fs,dt,type,varargin)
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
% cochleagram_multiLevel(x,fs,5,'log',32,500,22000,100)

    [X_ft,t,params,X_ft_multiFiber] = cochleagram_MSS(x,fs,dt,type,varargin{:});

end