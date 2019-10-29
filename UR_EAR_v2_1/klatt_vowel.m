function stim = klatt_vowel(dur, rampdur, F0, formant_freqs, bw, stimdB, Fs)
%klatt_vowel: Generate Klatt vowel waveform.
%   DUR is the length of the waveform (s)
%   rampdur is the duration of he on/off ramps (s)
%   F0 is the voice pitch (Hz)
%   F is a vector of formant frequencies (Hz)
%   bw is a vector of formant bandwidths
%   Fs is the sample rate (S/s)
%   STIM is the generated waveform

% based on code written by D. Schwarz, douglas.schwarz@rochester.edu

nformants = length(formant_freqs); % number of formants
a = 1;
b = 1;
for i = 1:nformants
    [bi,ai] = klatt1(formant_freqs(i),bw(i),Fs); % generate filter coefficients for each formant resonance
    a = conv(a,ai);
    b = conv(b,bi);
end

npts = floor((dur + 0.125)*Fs); % add 125 ms to stimulus so that onset can be removed (below)
stim = zeros(npts,1);
stim(round(1:(Fs/F0):end)) = 1; % create a series of impulses spaced at 1/F0 (glottal pulse train)
stim = stim - mean(stim);

stim = filter(b,a,stim); % filter the impulse train

% band-limit to 5 kHz (removing high freq harmonics of impulse train)
B = fir1(5000, 5000/(Fs/2),'low'); % compute coeff's for 5000-order FIR filter with 5000 Hz cutoff freq
stim = conv(stim,B,'same'); % apply the filter

stim_npts = dur * Fs;    % desired length of stimulus
stim = stim(end-stim_npts+1:end); % remove onset and only retail desired length
stim = stim' .* tukeywin(length(stim),2*rampdur/dur)'; % apply on/off ramps
stim = 20e-6 * 10.^(stimdB/20) * stim/rms(stim); % Convert to pascal and scale to desired level

function [b,a] = klatt1(form_freq,bw,Fs)
T = 1/Fs;
%bw = 4.8*form_freq/G; % this is now directly passed in
B = 2*exp(-pi*bw*T)*cos(2*pi*form_freq*T);
C = -exp(-2*pi*bw*T);
A = 1 - C - B;
b = A;
a = [1 -B -C];