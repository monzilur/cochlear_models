function [B,A] = get_alpha_norm(tau, fs, t)
% GET_ALPHA_NORM  Returns filter coefficients for a normalized alpha function
%
% Returns z-transform coefficients for a function of:
%
%                           y(t) = t*e^(-t/tau)
%
% The resulting coefficents can then be used in filter().  This version
% normalizes the alpha function so that the area from 0 to t is equal
% to 1.
%
%  Written by Mike Anzalone 3/2004

a = exp(-1/(fs*tau));
% norm = zeros(length(t));
norm = 1 ./(tau^2 .* (exp(-t/tau) .* (-t/tau-1) + 1));

B = [0 a];
A = [1 -2*a a^2] * fs * 1 ./norm;

