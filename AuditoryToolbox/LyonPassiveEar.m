function [y,CenterFreqs, gains, EarQ]=LyonPassiveEar(x,sr,df,freqs,stepfactor,...
    differ,agcf,taufactor)
% [y,CenterFreqs, gains]=LyonPassiveEar(x,sr,df,freqs,stepfactor,...
%    differ,agcf,taufactor)
%
% Changes
% Zeroed out the preemphasis channels before doing the AGC.  This is needed
% so that cochlear inversion is possible (since we don't have those channels,
% we can't invert their gain.)..... Malcolm 6/26/95

% (c) 1998 Interval Research Corporation  

if nargin < 4
	fprintf('Syntax: y=LyonPassiveEar(x,sr,df,stepfactor, freqs, differ,agcf,taufactor)\n');
	fprintf(' The input, sample_rate, decimation and frequency channel parameters are mandatory.\n');
	return;
end

if ~exist('stepfactor','var')
    stepfactor = 0.25;
end
if ~exist('differ','var')
    differ=1;
end
if ~exist('agcf','var')
    agcf=1;
end
if ~exist('taufactor','var')
    taufactor=3;
end

topf = max(freqs);
lowf = min(freqs);
NumChannels = length(freqs);

[earFilters,CenterFreqs, gains, EarQ] = DesignLyonFilters(sr, topf,lowf,...
    NumChannels, stepfactor);

nSamples = length(x);
nOutputSamples = floor(nSamples/df);
[nChannels filterWidth] = size(earFilters);

sosOutput = zeros(nChannels, df);
sosState = zeros(nChannels, 2);
agcState = zeros(nChannels, 4);
y = zeros(nChannels, nOutputSamples);

decEps = EpsilonFromTauFS(df/sr*taufactor,sr);
decState = zeros(nChannels, 2);
decFilt = SetGain([0 0 1 -2*(1-decEps) (1-decEps)^2], 1, 0, sr);

eps1 = EpsilonFromTauFS(.64,sr);
eps2 = EpsilonFromTauFS(.16,sr);
eps3 = EpsilonFromTauFS(.04,sr);
eps4 = EpsilonFromTauFS(.01,sr);

tar1 = .0032;
tar2 = .0016;
tar3 = .0008;
tar4 = .0004;

if 0
	fprintf('df=%g, earq=%g, stepfactor=%g, differ=%g\n',df,earQ,stepfactor,differ);
	fprintf('agcf=%g, taufactor=%g\n', agcf, taufactor);
	[tar1 tar2 tar3 tar4; eps1 eps2 eps3 eps4]
end

for i=0:nOutputSamples-1
	[sosOutput sosState]= soscascade(x(i*df+1:i*df+df), earFilters, ...  
				sosState);
	output = max(0, sosOutput);		%% Half Wave Rectify
	output(1) = 0;					%% Test Hack to make inversion easier.
	output(2) = 0;
	if agcf > 0
		[output agcState] = agc(output, [tar1 tar2 tar3 tar4; ...
				eps1 eps2 eps3 eps4], ...
				agcState);
	end

	if differ > 0
		output = [output(1,:);output(1:nChannels-1,:) - ...
					output(2:nChannels,:)];
		output = max(0, output);
	end

	if df > 1
		[output decState] = sosfilters(output, decFilt, decState);
	end
	y(:,i+1) = output(:,df);
end

%y = min(y,2*tar4);
y=y(3:nChannels,:);