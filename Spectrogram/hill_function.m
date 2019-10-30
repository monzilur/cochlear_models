function y=hill_function(x,n,c,SAT)
% y=hill_function(x,n,c)
if ~exist('n','var')
    n=1.77;
end
if ~exist('c','var')
    c=1e-2;
end
if ~exist('SAT','var')
    SAT=0.16;
end
    x_to_n = (c*x).^n;
    y=x_to_n./(SAT+x_to_n);
end