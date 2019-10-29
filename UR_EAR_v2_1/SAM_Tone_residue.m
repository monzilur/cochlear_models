function stim = SAM_Tone_residue(dur, rampdur, carrier_freq, mod_freq, mod_depth, stimdB, Fs,shift)
% Generate the two types of modulated stimuli used by Schouten for residue
% pitch; shift = amount of shift of the 3 tones in the original SAM tone

t = (0:(1/Fs):dur); % time array 
gate = tukeywin(length(t),2*rampdur/dur); %gating function
%if mod_depth ~= -99
    m = 10.^(mod_depth/20); % convert from dB into a linear scalar for modulation depth
%else 
%    m = 0; % unmodulated case
%end
if shift == 0
   stim = (1. + m * sin(2 * pi * (mod_freq) * t))/2 .* sin(2 * pi * carrier_freq * t);  % Harmonic SAM (if params are chosen properly)
else
   stim = (1. + m * sin(2 * pi * mod_freq * t))/2 .* sin(2 * pi * (carrier_freq + shift) * t);    % shifted SAM
end
stim = gate' .* stim; 
stim = 20e-6 * 10.^(stimdB/20) * stim/rms(stim); % scale to pascals
