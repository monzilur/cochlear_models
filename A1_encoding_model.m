function [v_hat, y_hat, X_ft, t] = A1_encoding_model(fitted_parameters, ...
    x,fs,dt, type, numChannels)
% [v_hat, y_hat, X_ft] = A1_encoding_model(fitted_parameters, ...
%    x,fs,dt, type, numChannels)
% fitted_parameters.cochlear_model : function handle to produce a cochleagram
% fitted_parameters.kernel : linear weights fitted to tensorized cochleagram and
% neuron's response
% fitted_parameters.nonlinear_model : a sigmoid fit of the output of linear
% model to neuron's response
%
% Author: Monzilur Rahman
% Year: 2018

if ~exist('type','var')
    type = 'log';
end

if ~exist('numChannels','var')
    numChannels = 16;
end

[X_ft,t,~] = fitted_parameters.cochlear_model(x,fs,dt,type,numChannels);
X_ft_normalized = (X_ft - mean(X_ft(:))) / std(X_ft(:));

h = size(fitted_parameters.kernel.k_fh,2);
X_fht = tensorize_mod(X_ft_normalized,h);

y_hat = kernelconv_standard(X_fht,fitted_parameters.kernel);
v_hat = lnmodel(fitted_parameters.nonlinear_params,y_hat);

end