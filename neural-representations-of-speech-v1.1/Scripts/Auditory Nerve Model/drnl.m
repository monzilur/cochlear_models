% DRNL  Performs drnl filtering
%   output = DRNL(signal,fs,params) performs drnl filtering on the input
%   SIGNAL, which has a sampling frequency of FS using the parameters
%   specified in the structure PARAMS. PARAMS is a data structure that must
%   contain the fields:
%     
%                   a: \
%                   b:  > Compression parameters
%                   c: /
%       nonlinCascade: Number of gammatone filters (nonlinear path)
%           nonlinCFs: CFs of gammatone filters (nonlinear path)
%           nonlinBWs: Bandwidths of gammatone filters (nonlinear path)
%       nonlinLpOrder: Order of lowpass filters (nonlinear path)
%     nonlinLpCascade: Number of lowpass filters (nonlinear path)
%                   g: Linear path gain scalar
%          linCascade: Number of gammatone filters (linear path)
%              linCFs: CFs of gammatone filters (linear path)
%              linBWs: Bandwidths of gammatone filters (linear path)
%          linLpOrder: Order of lowpass filters (linear path)
%        linLpCascade: Number of lowpass filters (linear path)
%
%   Mark Steadman
%   09/01/2015
%   
%   marks@ihr.mrc.ac.uk

function output=drnl(signal,fs,params)
  BFs=params.nonlinCFs;
  output=zeros(numel(BFs),length(signal));
  nyquist=fs/2;
  
  % Design filters
  
  [b,a]=gammatone(params.linCFs,params.linBWs,fs);
  for i=1:numel(BFs)
    % Cascade the gammatone filters
    gtLin(i)=cascade(repmat(dfilt.df1(b(i,:),a(i,:)),1,...
      params.linCascade));%#ok
  end

  [b,a]=gammatone(params.nonlinCFs,params.nonlinBWs,fs);
  for i=1:numel(BFs)
    % Cascade the gammatone filters
    gtNonlin(i)=cascade(repmat(dfilt.df1(b(i,:),a(i,:)),1,...
      params.nonlinCascade));%#ok
  end

  for i=1:numel(params.nonlinCFs)
    % Generate coefficients
    [b,a]=butter(params.linLpOrder,params.linCFs(i)/nyquist);
    % Cascade the filters
    lpLin(i)=...
      cascade(repmat(dfilt.df1(b,a),1,params.linLpCascade));%#ok

    % Generate coefficients
    [b,a]=butter(params.nonlinLpOrder,params.nonlinCFs(i)/nyquist);
    % Cascade the filters
    lpNonlin(i)=...
      cascade(repmat(dfilt.df1(b,a),1,params.nonlinLpCascade));%#ok
  end
  
  % Filter the signal
  
  y=signal;
  for i=1:numel(BFs)
    % linear path
    linOutput=filter(lpLin(i),filter(gtLin(i),signal*params.g(i)));
    
    % nonlinear path (first gammatone cascade)
    nonlinOutput=filter(gtNonlin(i),signal);
    
    % Compression
    thr=exp(log(params.a(i)/params.b(i))/(params.c-1));
    absx=abs(nonlinOutput);
    y(absx<thr)=params.a(i)*nonlinOutput(absx<thr);
    y(absx>=thr)=sign(nonlinOutput(absx>=thr)).*...
      (params.b(i)*absx(absx>=thr).^params.c);
    
    % nonlinear path (second gammatone cascade and lowpass filters)
    nonlinOutput=filter(lpNonlin(i),filter(gtNonlin(i),y));
    
    % Sum the pathways
    output(i,:)=linOutput+nonlinOutput;
  end
end