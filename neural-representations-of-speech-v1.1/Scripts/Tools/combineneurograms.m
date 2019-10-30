% COMBINENEUROGRAMS combines multiple neurograms together by finding the
% relative temporal shifts that minimise the Euclidean distance between
% them and then averaging.
%
% Y=COMBINENEUROGRAMS(X,MAXSHIFT)
%   Combines the neurgrams in the cell array X using maximum relative
%   temporal shift MAXSHIFT. The first element in X is used as a temporal
%   anchor and other neurograms are shifted relative to it such that the
%   Euclidean distances between them are minimised. The output is a single
%   neurogram, Y, which represents the averaged, shifted input neurograms.
%
% By Mark A. Steadman

function y=combineneurograms(x,maxshift)
  nrows=size(x{1},1);
  ncols=size(x{1},2);
  nsamples=ncols-2*maxshift; % Number of cols in the output
  
  % Define start and end indices of "anchor" neurogram
  idx1=maxshift+1;
  idx2=idx1+nsamples-1;
  
  % Initialise variables
  N=numel(x);
  y=cell(N,1);
  dist=zeros(N,1);
  
  for i=1:N
    idx=i==1:N;
    anchor=reshape(x{idx}(:,idx1:idx2)',nrows*nsamples,1)';
    
    % Create time-lagged versions of other neurograms
    shifted=cellfun(@(x) lagneurogram(x,maxshift),x(~idx),'uni',0);
    y{i}=anchor;
    
    % Add optimally shifted neurograms to the anchor
    for j=1:numel(shifted)
      [idx,d]=knnsearch(shifted{j},anchor);
      dist(i)=dist(i)+d;
      y{i}=y{i}+shifted{j}(idx,:);
    end
  end
  
  % Select the output where the minimum shifting was necessary
  idx=find(dist==min(dist),1);  
  y=y{idx}/numel(x);
end