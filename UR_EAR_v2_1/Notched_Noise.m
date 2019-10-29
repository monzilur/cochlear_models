function Final_stim = Notched_Noise(dur,rampdur,cf,delta,bw,db_noise,db_tone,Fs)

%dur is total duration of stimulus (s) (not same as Moore's dur)
%rampdur is duration of on or off ramp (s)
%cf is frequency of tone (center frequency of the stimulus)
%delta is the distance (in Hz) from the center frequency of the stimulus to the inner edges of the noise, divided by the center frequency of the noise. Delta may either be a scalar (for notches that are symmetrical around the tone) or a two-element vector (for notches that are asymmetrical around the tone).
%bw is the bandwidth of each band of noise in Hz, divided by the center frequency of the stimulus. 
%db_noise is the overall level (RMS dB SPL) of the entire (2 bands of) noise - NOT the spectrum level.
%db_tone - tone levels (dB SPL)
%Fs is sampling rate

el=1024; %Length of impulse response using firls.

%% Alert user if delta and bandwidth combination is too large.
if max(delta)+bw >= 1 %Works for one and two element deltas (symmetrical and asymmetrical notches)
    error('Unsuccessful - delta+bw must be less than 1, otherwise the first three elements of f are 0 (triplet, not just duplicate f points), and that causes issues because f specifies frequency points where the amplitude of the filter changes.')
end

%Create vector of time values and then generate noise
t = (0:(1/Fs):dur); %vector of time values
noise_pre_filter = randn(size(t)); %generate noise

%Generate tone
nn_tone=sin(cf*2*pi*t);

%% Filter the noise to create a notch
%%%%%%% FIRLS FILTER %%%%%%%
switch length(delta)
    case 1 %%%%%%% DELTA is a single value, WIDTH OF NOTCH IS SAME ON BOTH SIDES, SYMMETRICAL NOTCH %%%%%%%
        %Determine points on the frequency axis where changes in the filter should occur
        b1l = (cf*(1-delta-bw)*2)/Fs;  %Point on the frequency axis (as a percentage of maximum frequency (Nyq rate) where lower band (Band1) lower edge is desired to occur.
        b1h = (cf*(1-delta)*2)/Fs;    %Lower band (Band1) high edge
        b2l = (cf*(1+delta)*2)/Fs;    %Upper band (Band2) lower edge
        b2h = (cf*(1+delta+bw)*2)/Fs; %Upper band (Band 2) high edge
             
        %Describe frequency-amplitude characteristics of filter, like above make separate cases for no notch vs. a notch
        if delta==0
            f = [0 b1l b1l b2h b2h 1];
            m = [0  0   1   1   0  0];
        else
            f = [0 b1l b1l b1h b1h b2l b2l b2h b2h 1]; %IF b1l is 0, there are not just duplicate points but three frequency points that are the same - duplicates are allowed, triplets are not
            m = [0  0   1   1   0   0   1   1   0  0];
        end
        
        %Make filter and filter noise
        b= firls(el,f,m);
        noise_post_filter=filter(b,1,noise_pre_filter);
        
    case 2 %%%%%%% Two DELTAS, WIDTH OF NOTCH IS NOT EQUAL ON BOTH SIDES, ASYMMETRICAL NOTCH %%%%%%%
        %Determine points on the frequency axis where changes in the filter should occur
        b1l = (cf*(1-delta(1)-bw)*2)/Fs;  %Point on the frequency axis (as a percentage of maximum frequency (Nyq rate) where lower band (Band1) lower edge is desired to occur.
        b1h = (cf*(1-delta(1))*2)/Fs;    %Lower band (Band1) high edge
        b2l = (cf*(1+delta(2))*2)/Fs;    %Upper band (Band2) lower edge
        b2h = (cf*(1+delta(2)+bw)*2)/Fs; %Upper band (Band 2) high edge
        
        %Describe frequency-amplitude characteristics of filter, like above make separate cases for no notch vs. a notch
        if delta(1)==0 && delta(2)==0 %For example, if input (perhaps a for loop) is formatted for asymmetrical notches but no notch is desired
            f = [0 b1l b1l b2h b2h 1];
            m = [0  0   1   1   0  0];
        else
            f = [0 b1l b1l b1h b1h b2l b2l b2h b2h 1];
            m = [0  0   1   1   0   0   1   1   0  0];
        end
        
        %Make filter and filter noise
        b= firls(el,f,m);
        noise_post_filter=filter(b,1,noise_pre_filter);
end

%% Scale Noise & tone, then add
Scaled_noise = 20e-6 * 10.^(db_noise/20) * noise_post_filter/rms(noise_post_filter);
Scaled_tone = 20e-6 * 10.^(db_tone/20) * nn_tone/rms(nn_tone);

%% Add Tone to Noise
Ungated_stim=Scaled_noise + Scaled_tone;

%% Gate
t1 = tukeywin((Fs*dur)+1,2*rampdur/dur);
Final_stim=t1'.*Ungated_stim;