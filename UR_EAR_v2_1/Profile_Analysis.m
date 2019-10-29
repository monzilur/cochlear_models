function waveform = Profile_Analysis(dur, rampdur, ncomponents, dB_incr, stim_dB, Fs)
% This function produces a vector of log-spaced components based on Lentz (JASA 2005)
%Variables:
% dur = duration in sec  (e.g. 0.5 sec)
% ncomponents is # of components in stimulus (spaced between 200 & 5000 Hz)
% dB_incr = 20*log(Delta_A/A), where A is the amplitude of the standard component at 1000 Hz
% ramp_time: onset/offset in seconds
% stim_dB = overall stimulus level in dB SPL (both inetervals are scaled to same dB SPL)
% Fs = sampling rate (Hz)

npts = dur * Fs; % # pts in stimulus
t = (0:(npts-1))/Fs; % time vector

freq_array = logspace(log10(200),log10(5000),ncomponents); %column vector of n equally spaced compenents in the frequency range 200 to 5000Hz
waveform = 0;  % initialize variable

for f = freq_array  % step through each frequency component in the complex
    phase = 2*pi * rand(1,1); %Randomly vary the starting phase of each component
    if mod(f,4) ~= 0     %rounding each component to the nearest 4Hz (see Lentz, 2005)
        freq =  4*(ceil(f/4));
    else
        freq = f;
    end
    % Note that the increment is a tone added in phase to the component at 1000 Hz
    incr_size = 10.^(dB_incr/20); % convert increment from dB into a linear scalar  (if dB_incr = 0, incr_size = 1 and the amplitude at 1000 Hz is doubled)
    
    %Adding components with or without incr
    if freq == 1000
        waveform = waveform + (1 + incr_size) * cos(2 * pi * freq * t + phase);
    else
        waveform = waveform + cos(2 * pi * freq * t + phase);
    end
end

waveform = tukeywin(npts, 2*rampdur/dur)' .* waveform; % gate
waveform = 20e-6 * 10.^(stim_dB/20) * waveform/rms(waveform);% convert signal into Pascals