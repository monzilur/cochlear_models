function [stim1, stim2] = Forward_masking_tones(mask_dur, mask_ramp, probe_dur, probe_level, mask_freq, probe_freq, delay, stimdB,Fs)
% Condition(1) = Masker + probe; Condition(2) = Masker only
% probe_ramp set at 50% of probe_dur

% Create masker tone
t_mask = (0:(1/Fs):mask_dur); % time array 
mask =  sin(2 * pi * mask_freq * t_mask);
mask_gate = tukeywin(length(t_mask),2*mask_ramp/mask_dur); %gating function
mask = mask_gate' .* mask; 
mask = 20e-6 * 10.^(stimdB/20) * mask/rms(mask); % scale to pascals

% Create probe tone
t_probe = (0:(1/Fs):probe_dur); % time array 
probe =  sin(2 * pi *probe_freq * t_probe);
probe_gate = tukeywin(length(t_probe),1); % 2*probe_ramp/probe_dur); %gating function  << probe ramp fixed at 50% of dur
probe = probe_gate' .* probe; 
probe = 20e-6 * 10.^(probe_level/20) * probe/rms(probe); % scale to pascals

delay_pts = zeros(1,round(delay*Fs));

stim1 = [mask delay_pts probe];
stim2 = [mask delay_pts zeros(1,length(probe))];

% figure
% subplot(2,1,1)
% plot(length(stim1)/Fs,stim1)
% subplot(2,1,2)
% plot(length(stim1)/Fs,stim2)