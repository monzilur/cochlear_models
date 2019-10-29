function stim = FM_Tone(dur, rampdur, signalfreq, params, stimdB, Fs)
% Sinusoidally frequency modulated Tone
% mod-freq is in Hz
% Df_percentage is the modulation excursion in % of signal freq

fm = params(1);
Df_percentage = params(2);

phi_all = [0 pi 1.5*pi];

randomize_phase = 0;
switch randomize_phase
    case 0 % fixed phase
        phi = phi_all(3);
    case 1 % random phase <<< Note that this will be randomized across INTERVALs
        phi = phi_all(randi([1 2],1,1));
end

t = (0:(1/Fs):dur); % time array
gate = tukeywin(length(t),2*rampdur/dur); %gating function

Df = signalfreq * Df_percentage/100; % Df is in Hz now, the freq 'excursion'
Modulator = (Df/fm)* sin(2*pi*fm*t + phi);

stim = sin(2*pi*signalfreq*t + Modulator);

stim = gate' .* stim;
stim = 20e-6 * 10.^(stimdB/20) * stim/rms(stim); % scale to pascals

