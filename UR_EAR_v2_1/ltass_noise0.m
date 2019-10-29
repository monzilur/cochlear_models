function noise = ltass_noise0(fs,SPL,varargin)

%%%% Can't handle model's Fs = 100,000 !! (LHC)
% Put in a 'fix' below

%ltass_noise0: Generate a vector of LTASS noise.
% Syntax:
%   NOISE = ltass_noise0(FS,SPL,N,M)
% where FS is the sample rate (S/s), SPL is the desired SPL of the noise, N
% and M are the number of rows and columns respectively of the noise
% matrix.  NOISE is a matrix of LTASS noise with the desired SPL and size.

% Author: Doug Schwarz
% Email: douglas.schwarz@rochester.edu

% $Date: 2014-12-16 13:44:27 -0500 (Tue, 16 Dec 2014) $
% $Revision: 1086 $

required_length = varargin{1};  % save this value for check at bottom
upsample_flag = 0;
if fs > 50000
    upsample_flag = 1;
    fs = fs/2; % reduce sampling rate to let this run, then upsample below
    varargin{1} = floor(varargin{1}/2); % must correct # of points for the new sampleing rate
end

fn = fs/2;

Pref = 20e-6; % reference pressure in pascals
desired_rms = Pref*10.^(SPL/20);

% LTASS noise magnitude specification.
M_dB = [30 38.6 54.4 57.7 56.8 60.2 60.3 59.0 62.1 62.1 60.5 56.8 53.7 ...
	53.0 52.0 48.7 48.1 46.8 45.6 44.5 44.3 43.7 43.4  41.3  40.7 30].';
f = [0 80   100  125  160  200  250  315  400 500  630  800  1000 ...
	1250 1600 2000 2500 3150 4000 5000 6300 8000 10000 12500 16000 25e3].';

% Build a filter with freq. response equal to the LTASS specification.
use = f > 0 & f < fn;
f2 = [0;f(use);fn];
M_dB2 = interp1(f,M_dB,f2);
M2 = 10.^(M_dB2/20);
b0 = fir2(5000,f2/fn,M2);

% Apply filter to white noise.
noise = conv(randn(varargin{:}),b0,'same');

% Scale noise to desired SPL.
noise = noise*(desired_rms/rms(noise));
if upsample_flag ==1
    noise = resample(noise,2,1);
end
if length(noise ) ~= required_length
    noise = [noise' zeros(1,required_length - length(noise))]'; % add zeros at end of noise to get correct length
end