function stim = generate_single_formant(dur, rampdur, F0, Fp, G, stimdB, Fs)
% Generate_single_formant - Lyzenga & Horst's triangular spectrum (from D. Schwarz code)
%    dur = duration in seconds  (0.25 s)
%    ramdur = 0.025 (s)
%    F0 = fundamental freq. in Hertz  (100 or 200 Hz)
%    Fp = peak frequency of formant in Hertz  (2000 (on harmonic) or 2100 (off-harmonic)
%    stimdB = desired SPL of composite waveform (dB SPL) (65 dB SPL)
%    G = slope of triangle edges in dB/octave (200)
%    Fs = sample rate, samples/sec

min_rel_level = -60; % dB relative to a peak at the overall SPL (components lower in amplitude than this will be excluded)
Pref = 20e-6; % 20 micropascals

% Calculate intercepts at which signal is down by min_rel_level.
F1 = 2.^(min_rel_level/G)*Fp;
F2 = 2.^(-min_rel_level/G)*Fp;
tri_x = log2([F1 Fp F2]);
tri_y = [stimdB + min_rel_level, stimdB, stimdB + min_rel_level];

% Generate time vector.
t = (0:1/Fs:dur)';
t(end) = [];

if F0 > 0    
    % Calculate which harmonics we need.
    harm_num = ceil(F1/F0):floor(F2/F0);
    % Generate vector of amplitudes. sqrt(2) compensates for the fact that SPL
    % is determined from RMS value of pressure waveform; amplitude is sqrt(2) times as great.
    f_harm = harm_num*F0;
elseif F0 == -1
    f_harm = [Fp:-200:F1 Fp:200:F2];
    f_harm = unique(f_harm);
elseif F0 == -2
    f_harm = [Fp-100:-200:F1 Fp-100:200:F2];
    f_harm = unique(f_harm);
end

log2_harm_freqs = log2(f_harm);
SPLs = interp1(tri_x,tri_y,log2_harm_freqs);
amp = sqrt(2)*Pref*10.^(SPLs/20); % This converts dB SPL to peak amplitude in Pascals
sin_matrix = sin(t*(2*pi*f_harm)); % zero phase

% for: Random phase for each trial.
% phase = repmat(2*pi*rand(1,length(f_harm)),length(t),1);
% sin_matrix = sin(t*(2*pi*f_harm) + phase);

%------------------------------------------------
% Multiply each col of sin_matrix by appropriate amplitude, add up the
% columns, and multiply by ramp envelope.
stim = sin_matrix * amp';
stim = Pref * 10.^(stimdB/20) * stim / rms(stim); % scale overall RMS level into desired pascals
stim = stim .* tukeywin(length(stim),2*rampdur/dur); % apply ramp