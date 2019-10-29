function X_fht = tensorize_mod(X_ft, n_h)
% function X_fht = tensorize_mod(X_ft, n_h, lag)
%
% Add a history dimension to a 2D stimulus grid
% FIXME -- pad with nan instead?
%
% Inputs:
%  X_ft -- stimulus, freq x time
%  n_h -- number of history steps
%  lag -- minimum lag
% 
% Outputs:
%  X_fht -- stimulus, freq x history x time

n_f = size(X_ft, 1);
n_t = size(X_ft, 2);

n_start=1;
n_end=n_h;
for i=1:n_t-n_h+1
X_fht(:,1:n_h,i)=X_ft(:,n_start:n_end);
n_start=n_start+1;
n_end=n_end+1;
end

end
