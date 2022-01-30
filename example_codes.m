% The usage for producing cochleagram is same for all models
% Example:
[x,fs] = audioread('soundfile.wav');
n_F = 32; % number of frequency channels : this is an optional parameter, 
% default 34
min_F = 500; % Hz : this is an optional parameter, default 500
max_F = 22000; % Hz : this an optional parameter, default 19.9
bin_size = 5; % ms
% 'log' indicates log spacing of frequency channels
[X_ft, t, params] = cochleagram_spec_power(x,fs,5,'log',n_F,min_F,max_F);

% Only exception is WSR model. For which min_F and max_F are fixed.
[X_ft, t, params] = cochleagram_spec_power(x,fs,5,'log',n_F);

% It is also possible to produce multiFiber versions of the BEZ and MSS model 
% useing  cochleagram_BEZ and cochleagram_MSS functions.
% The usage is as follows.
% Example:
% Single fiber output = > X_ft
% Multi fiber output => X_ft_multiFiber
% For BEZ model:
[X_ft, t, params, X_ft_multiFiber] = cochleagram_BEZ(x,fs,5,'log',32,500,22000);
% For MSS model
[X_ft, t, params, X_ft_multiFiber] = cochleagram_MSS(x,fs,5,'log',32,500,22000);
