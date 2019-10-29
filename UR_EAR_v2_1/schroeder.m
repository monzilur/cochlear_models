function pin = schroeder(dur, rampdur, Cvalue, F0, ncomponents, dB_incr, include_fundmntl, stimdB, Fs)
%% Schroeder phase harmonic complex
% Note that SIGN of the Schroeder phase complex is included in Cvalue
t = (0:(1/Fs):dur); %% time vector
% Omit fundamental if instructed

if include_fundmntl == 1
    first_harm = 1; % include fundamental
else
    first_harm = 2; % exclude fundamental
end
freqs = (first_harm:(first_harm + ncomponents - 1)) * F0;  % describ the freqs here... freq range varies from study to study

%% find harmonic closest to 1100, for masking paradigm
[~,incr_num] = min(abs(freqs - 1100));
incr_num = incr_num;

if dB_incr == -99  % dB_incr is wrt Masker Component (thus 0 dB_incr is a signal at the same level as the Masker, resulting in a scalar of 2 (or a component that is 6 dB higher than other components).
    incr_scalar = 1; % no scaling applied here
else
    incr_scalar = 1 + 10.^(dB_incr/20); % convert dB_incr into a linear scalar (Again: dB_incr = 0 will be a scalar of 2, as desired, consistent with Schr literature)
end
%% Step through each frequency component in the complex tone.
pin = 0; % initialize
for ifreq = 1:length(freqs)
    n = first_harm + ifreq - 1;  % keep track of the HARMONIC NUMBER
    phase = Cvalue * pi * n * (n-1)/ncomponents; % using the version of Schroeder phase in Lauer et al 2006 (pos C value = "positive" Schroeder)
    if ifreq == incr_num
        pin = pin + incr_scalar * cos(2 * pi * freqs(ifreq) * t + phase);    %add the next component
    else
        pin = pin + cos(2 * pi * freqs(ifreq) * t + phase);
    end
end
%% Gate and scale final complex tone
pin = tukeywin(length(pin), 2*rampdur/dur)' .* pin; % ramp
pin = 20e-6 * 10.^(stimdB/20) * pin/rms(pin);% scale signal into Pascals