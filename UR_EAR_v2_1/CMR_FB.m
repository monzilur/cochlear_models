function [pin_comod, pin_codev] = CMR_FB(dur, rampdur, freq, No,tone_level,bw,Fs)

% Generate central band of noise, centered on tone
npts = dur * Fs;
lbw = freq - bw/2;
hbw = freq + bw/2;
%% Generate, filter, and scale noise
noise_c = randn(npts,1);
B = fir1(5000,[lbw/(Fs/2),hbw/(Fs/2)]); % order of 5000
noise_c = conv(noise_c,B,'same');
sc = 20e-6*10^((No+10*log10(bw))/20); %Noise input as spectrum level
noise_c = sc * noise_c /rms(noise_c);  % normalize to RMS=1 and then scale to desired level in Pascals

% Generate lower flank band of noise, centered at tone - 2*bw
lbw = freq - 2*bw - bw/2;
hbw = freq - 2*bw + bw/2;
%% Generate, filter, and scale noise
noise_L = randn(npts,1);
B = fir1(5000,[lbw/(Fs/2),hbw/(Fs/2)]); % order of 5000
noise_L = conv(noise_L,B,'same');
sc = 20e-6*10^((No+10*log10(bw))/20); %Noise input as spectrum level
noise_L = sc * noise_L /rms(noise_L);  % normalize to RMS=1 and then scale to desired level in Pascals

% Generate upper flank band of noise, centered at tone + 2*bw
lbw = freq + 2*bw - bw/2;
hbw = freq + 2*bw + bw/2;
%% Generate, filter, and scale noise
noise_U = randn(npts,1);
B = fir1(5000,[lbw/(Fs/2),hbw/(Fs/2)]); % order of 5000
noise_U = conv(noise_U,B,'same');
sc = 20e-6*10^((No+10*log10(bw))/20); %Noise input as spectrum level
noise_U = sc * noise_U /rms(noise_U);  % normalize to RMS=1 and then scale to desired level in Pascals

t = 0:(1/Fs):(dur-(1/Fs));
noise_comod = 2*(noise_c .* cos(2*pi*(2*bw)*t)'); % generate 2 identical flanking bands by modulating at 2*bw, then correct for 6 dB atten

%Tone
sc_s = 20e-6*10.^(tone_level/20);
tone = sc_s*sqrt(2)*sin(2*pi*freq*t);

pin_comod = (noise_c' + noise_comod' + tone) .* (tukeywin(npts,(2*rampdur)/dur))';
pin_codev = (noise_c' + noise_L' + noise_U' + tone) .*   (tukeywin(npts,(2*rampdur)/dur))';
end
