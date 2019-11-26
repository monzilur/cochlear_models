function [X_ft, t, params] = cochleagram_CARFAC(x,fs,dt, type, varargin)
%[X_ft, t, params] = cochleagram_CARFAC(x,fs,dt, type, varargin)
% This was modified from CARFAC_binaural in CAR_FAC package
%
% Copyright 2012 The CARFAC Authors. All Rights Reserved.
% Author: Richard F. Lyon
%
% This file is part of an implementation of Lyon's cochlear model:
% "Cascade of Asymmetric Resonators with Fast-Acting Compression"
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%     http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.

% Test/demo hacking for carfac matlab stuff, two-channel (binaural) case

% Apply ramp
cosine_ramp = ones(size(x));
ramp_length = 500;
cosine_ramp(end-ramp_length+1:end) = 0.5 + 0.5*cos(pi*[0:1:ramp_length-1]/ramp_length);
cosine_ramp(1:ramp_length) = 0.5 + 0.5*cos(pi*[ramp_length-1:-1:0]/ramp_length);
x = x.* cosine_ramp;

agc_plot_fig_num = 0;

test_signal = x;
n_ears = 1;

CFs= 2^(1.5)* 440 * 2 .^ ((-31:97)/24); %shft = 1.5
params.f_min=CFs(1);
params.f_max=CFs(end-1);
params.n_f=varargin{1};    

ERB_values = [2 8; 4 6; 8 3.5; 16 1.8; 32 0.95; 64 0.48; 128 0.243];
ERB_per_step = ERB_values(ERB_values(:,1)==params.n_f,2);

CF_CAR_params = struct( ...
'velocity_scale', 0.1, ...  % for the velocity nonlinearity
'v_offset', 0.04, ...  % offset gives a quadratic part
'min_zeta', 0.10, ... % minimum damping factor in mid-freq channels
'max_zeta', 0.35, ... % maximum damping factor in mid-freq channels
'first_pole_theta', pi, ... % original value 0.85*pi
'first_pole_freq', params.f_max, ...
'zero_ratio', sqrt(2), ... % how far zero is above pole
'high_f_damping_compression', 0.5, ... % 0 to 1 to compress zeta
'ERB_per_step', ERB_per_step, ... % assume G&M's ERB formula
'min_pole_Hz', params.f_min, ...
'ERB_break_freq', 165.3, ...  % Greenwood map's break freq.
'ERB_Q', 1000/(24.7*4.37));  % Glasberg and Moore's high-cf ratio

CF_struct = CARFAC_Design_MR(n_ears,fs,CF_CAR_params);  % default design

% Run stereo test:
CF_struct.n_ears = n_ears;
%CF_struct = CARFAC_Init(CF_struct, n_ears);
CF_struct = CARFAC_Init(CF_struct);
CF_struct.seglen = floor(dt*1e-3*fs);
test_signal(ceil(length(test_signal)/CF_struct.seglen) * CF_struct.seglen) = 0;

[CF_params, nap_decim, ~] = CARFAC_Run_MR(CF_struct, test_signal, agc_plot_fig_num);

params.CF_params = CF_params;

X_ft = nap_decim';

dt_corrected = CF_struct.seglen/fs;

params.freqs = params.CF_params.pole_freqs;

t = 0:dt_corrected:(size(X_ft,2)-1)*dt_corrected;
end



