function stim = Noise(dur, rampdur, Low_freq, High_freq, stimdB, Fs)
%Band-limited Gaussian Noise

t = (0:(1/Fs):dur);
gate = tukeywin(length(t), 2*rampdur/dur); %gating function
stim = randn(1,length(t)); % start with wideband gaussian noise

% now limit the bandwidth
B = fir1(5000,[Low_freq/(Fs/2) High_freq/(Fs/2)]); % compute coeff's ; 5000-order FIR filter
stim = conv(stim,B,'same'); % apply the filter

stim = gate' .* stim; %white noise ramped on and off
stim = 20e-6 * 10.^(stimdB/20) * stim/rms(stim); % 20 micropascals * linear scalar

