% CLASSIFY calculates the discriminability of a set of neurograms in
% percent correct using a nearest neighbour classifier with relative
% temporal shifting.
%
% RESULTS=CLASSIFY(NEUROGRAMS,PARAMETERS)
%   Uses the single trial neurograms defined in NEUROGRAMS as the input
%   data. NEUROGRAMS is an M x N x P cell array with each cell containing a
%   single trial neurogram. M is the number of exemplars of each stimulus
%   class (e.g. the number of talkers), N is the number of stimulus classes
%   (e.g. the number of phonemes) and P is the number of repetitions.
% 
%   Each neurogram is itself and M x N matrix, where M is the number of
%   neurons or recording sites and N is the number of temporal bins. see
%   BUILDNEUROGRAMS.m
%
%   PARAMETERS is a data structure containing parameters for the classifier
%   algorithm. The structure must contain the following fields:
%
%     MAX_SHIFT
%       The maximum number of temporal bins that each test neurogram is
%       shifted. The relative shifts go from -MAX_SHIFT to MAX_SHIFT.
%
%     WINDOW_LENGTH
%       The length of the smothing window used to smooth all neurograms in
%       number of temporal bins.
%
%     WINDOW_FUNC
%       A function handle for the function used to create the temporal
%       smoothing window (e.g. @hann).
%
%     VERBOSE
%       A logical value determining whether or not classifier performance
%       information is output to the command window as the algorithm is
%       running.
%
% By Mark A. Steadman

function results=classify(neurograms,parameters)

  % Define experiment properties
  ntalkers=size(neurograms,1);  % Number of talkers
  nclasses=size(neurograms,2);  % Number of consonants
  nreps=size(neurograms,3);     % Number of stim repetitions

  % Initialise output
  results.correct=0;
  results.confusions=zeros(nclasses);
  results.distmat=zeros(ntalkers,nclasses);
  results.guessmat=zeros(ntalkers,nclasses);
  results.shiftmat=zeros(ntalkers,nclasses);
  results=repmat(results,nreps,1);
  shifts=-parameters.max_shift:parameters.max_shift;
  
  % Initialse loop variables
  tocombine=cell(ntalkers,1);
  nsites=size(neurograms{1},1); % Number of fibers / recording sites
  ndim=nsites*(size(neurograms{1},2)-2*parameters.max_shift);
  y=zeros(nclasses,ndim);

  % Smooth the neurograms
  if parameters.window_length
    w=parameters.window_func(parameters.window_length)';
    w=w/sum(w);
    neurograms=cellfun(@(x) convn(x,w,'same'),neurograms,'uni',0);
  end

  for i=1:nreps
    tic;
    repidx=i==1:nreps;
    testset=neurograms(:,:,repidx);
    trainingset=neurograms(:,:,~repidx);

    % Build the training neurograms
    for j=1:nclasses
      for k=1:ntalkers
        tocombine{k}=mean(cat(3,trainingset{k,j,:}),3);
      end
      
      % Combine neurograms creates a template for a phoneme class by
      % averaging across talkers. The optimal relative shift is calcaulated
      % by minimising the distance to the neurogram for the first talker
      % for any relative lag (from -max_shift to max_shift)
      y(j,:)=combineneurograms(tocombine,parameters.max_shift);
    end
    
    % Loop through test neurograms
    for j=1:nclasses
      for k=1:ntalkers
        % Create lagged neurogram - this matrix has the dimensions n by p,
        % where n is the number of lags (from -max_shift to max_shift) and
        % p is the total dimensionality of the neurogram (i.e. number of
        % recording sites by the number of time bins)
        x=lagneurogram(testset{k,j},parameters.max_shift);
        
        % For every template (in the matrix y), find the distance to the
        % closest version of the test neurogram for any lag.
        [idx,d]=knnsearch(y,x,'k',1,'dist','euclidean');
        [mindist,minidx]=min(d);
        n=idx(minidx);
        
        results(i).confusions(n,j)=results(i).confusions(n,j)+1;
        results(i).guessmat(k,j)=n;
        results(i).distmat(k,j)=mindist;
        results(i).shiftmat(k,j)=shifts(minidx);
      end
    end
    
    % Calculate percent correct
    diag=results(i).confusions.*eye(nclasses);
    results(i).correct=100*sum(diag(:))/sum(results(i).confusions(:));

    % Report status
    if parameters.verbose
      disp(['  Rep ',num2str(i),' of ',num2str(nreps), ' took ', ...
        num2str(round(toc)),' seconds. ',...
        'PC=',num2str(results(i).correct)]);
    end
  end
end