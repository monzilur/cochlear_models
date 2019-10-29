function [pin_mod pin_unmod] = CMR_BW2(s_dur, m_dur, s_rampdur,m_rampdur, freq, bw,bw_mod,No,tone_level,fs)

lbw = freq - bw/2;
hbw = freq + bw/2;

% chech negative and Nyquist freq
if lbw<1
    lbw = 1;
end
if hbw >fs/2
    hbw = fs/2;
end

%% Generate, filter, and scale noise
m_npts = m_dur*fs;
s_npts = s_dur*fs;
sig_delay = (m_npts-s_npts)/2;
m_ramp_npts = m_rampdur*fs;
s_ramp_npts = s_rampdur*fs;
m_gate = hannfl(m_npts,m_ramp_npts);
s_gate = hannfl(s_npts,s_ramp_npts);

% tone
t = 0:1/fs:s_dur-1/fs;
signal = sin(2*pi*t*freq + 2*pi*rand).*(s_gate'); 
signal = signal/rms(signal)*10^(tone_level/20)*20e-6;

sc = 20e-6*10^((No+10*log10(bw))/20); %Noise input as spectrum level
noise = bpnoise(m_npts, 0, 10000, fs);
% unmod masker
masker1 = real( ifft( scut( fft(noise), lbw, hbw, fs)));                           % bandpass Gaussian noise
masker1 = masker1 .* m_gate;                                                % add fall\rise ramps
masker1 = masker1/rms(masker1)*sc;
pin_unmod = masker1' +[zeros(1,sig_delay),signal,zeros(1,sig_delay)];
% mod masker
LPmodulator = bpnoise( m_npts, 0, bw_mod, fs);                                  % lowpass modulator (0 to BW_mod)
masker2 = LPmodulator .* noise;                                                   % multiply with modulator
masker2 = real( ifft( scut( fft( masker2), lbw, hbw, fs)));      % restrict noise spectrum to desired BW
masker2 = masker2 .* m_gate;                                                % add fall\rise ramps
masker2 = masker2/rms(masker2)*sc;
pin_mod = masker2' +[zeros(1,sig_delay),signal,zeros(1,sig_delay)];

end

%% %%%%%%%%%%%%%%% subfunctions %%%%%%%%%%%%%%%%%%%%%%%%
function out = bpnoise(len,flow,fhigh,fs)
% create narrowband noise with bandwidth from flow to fhigh
out = real(ifft(scut(fft(randn(len,1)),flow,fhigh,fs)));
out = out/(norm(out,2)/sqrt(len));
end

function cut = scut(in,flow,fhigh,fs)
% zero-out unwanted frequency
len = length(in);
flow = round(flow*len/fs);
fhigh = round(fhigh*len/fs);
cut = zeros(len,1);
cut(flow+1:fhigh+1) = in(flow+1:fhigh+1);
% HACK: if lowpass ( flow = 0) index would be greater than len (len +1)
if flow == 0
	flow = 1;
end
cut(len-fhigh+1:len-flow+1) = in(len-fhigh+1:len-flow+1);
end

function h = hannfl(len,h1len,h2len)
% raised cos for ramping
% len - total length of the stimuli
% h1len, h2len - length of beginning ramp and ending ramp

if nargin<3
    h2len = h1len;
end
h = ones(len,1);
h(1:h1len)=(1-cos(pi/h1len*[0:h1len-1]))/2;
h(end-h2len+1:end)=(1+cos(pi/h2len*[1:h2len]))/2;
end
