function kernel = elnet_fht_gaussian(X_fht, y_t, regularization,lambda)
% function kernel = elnet_fht_gaussian(X_fht, y_t, regularization,lambda)
% 
% BASED on benlib's elnet_fht, but strongly modified
%
% Elastic net kernel estimation using glmnet
% X_fht -- fxhxt "tensorised" stimulus
% y_t   -- 1xt response vector
% regularization -- 'lasso' or 'ridge' (elastic net currently not implemented)
%
% last edited by: Oliver Schoppe, 13 April 2015

% load parameters

% set parameters
if strcmp(regularization, 'lasso')
  alpha = 1;
elseif strcmp(regularization, 'ridge')
  alpha = 0.01; % minimum "reliable" value for glmnet
else
	error('Unknown regularization method.');
end
options = glmnetSet;
options.alpha = alpha;
%options.nlambda = 1;
options.lambda = lambda;

% get data into format expected by glmnet.m
[n_f, n_h, n_t] = size(X_fht);
X_t_fh = reshape(X_fht, n_f*n_h, n_t)';
y_t = y_t(:);

% get kernels for given values of lambda and alpha
result = glmnet(X_t_fh, y_t, 'gaussian', options);

% save model fit in kernel structure and return
kernel.c = result.a0;
kernel.k_fh = reshape(result.beta(:), n_f, n_h);
kernel.alpha = alpha;
kernel.lambda = lambda;

end

