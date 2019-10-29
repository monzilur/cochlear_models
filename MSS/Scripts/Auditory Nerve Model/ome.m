% OME  Performs outer/middle ear filtering
%   output = OME(signal,fs,params) performs outer/middle ear filtering on
%   the input SIGNAL, which has a sampling frequency of FS using the
%   parameters specified in the structure PARAMS. PARAMS is a data
%   structure that must contain the fields:
%     
%     filters: An array of structures specifying the order and cutoff
%              frequencies of N OME filters, which are designed using the
%              built-in Matlab function BUTTER
%        gain: A scalar quantity used to multiply the output of the
%              filtered signal such that it represents stapes velocity.
%
%   The FILTERS data structure must contain the following fields:
%
%       order: The order of the filter
%       locut: The high-pass cutoff point
%       hicut: The low-pass cutoff point (ignored if above the nyquist
%              frequency.
%
%   Mark Steadman
%   09/01/2015
%   
%   marks@ihr.mrc.ac.uk

function output=ome(signal,fs,params)
  if ~isvector(signal)
    error('Multi-channel signals not supported.');
  end
  
  % Design filters
  nyquist=fs/2;
  nFilters=numel(params.filters);
  
  for i=1:nFilters
    filt=params.filters(i);
    if filt.hicut>nyquist
      [b,a]=butter(filt.order,filt.locut/nyquist,'high');
    else
      [b,a]=butter(filt.order,[filt.locut,filt.hicut]/nyquist);
    end
    OMEfilt(i)=dfilt.df1(b,a);%#ok
  end
  OMEfilt=cascade(OMEfilt(:));
  
  % Perform filtering & scale output
  output=filter(OMEfilt,signal)*params.gain;
end