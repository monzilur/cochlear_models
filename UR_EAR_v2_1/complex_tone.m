function [pin]=complex_tone(dur, rampdur,f0,ncomponents,filter_type,Wn_freq,include_fundmntl,stimdB,Fs)
%% Parameters - Complex tone (harmonic complex)

%dur is total duration of stimulus (s) (not same as Moore's dur)
%rampdur is duration of on or off ramp (s)
%f0 is fundamental frequency
%ncomponents is the number of components (including the fundamental, whether or not it is ultimately present)
%filter_type: 0=none,1=lowpass,2=highpass,3=bandpass,4=bandreject
%Wn_freq is the cutoff frequency or frequencies of the filter specified.
%include_fundmntl: 1 for include, 0 for omit
%stimdB is the level of the stimulus
%Fs is the sampling freq in Hz

%Other parameters for generating tones
compnt_step = 1; %Ratio between included components: 1 for every harmonic, 2 for every odd harmonic
rand_phase = 0; %Change to 1 if random starting phases are desired for each component of the complex tone
phase = 0; %Default, randomized if desired below

%Allocate time vector
t = (0:(1/Fs):dur); 

%Other parameters and error messages for filters
rectangular_filt = 0; %1=rectangular filter (fir) made through firls with impulse response length 'el'; 0=gradual filter made through fir1 with order=5000.
order = 5000; %order of fir1 filter
el=1024; %length of impulse response for firls
switch length(Wn_freq)
    case 1
        switch filter_type
            case 0
            case 1
            case 2
            case 3
                error('In order to make the requested bandpass filter, Wn_freq must be of length 2')
            case 4
                error('In order to make the requested band-reject filter, Wn_freq must be of length 2')
        end
        fCo = Wn_freq; %Cutoff frequency for high and lowpass filters
        fCo_rel_nyq = fCo/(Fs/2); %Express fCo as a percentage of Nyquist rate (this is the type of input the filter syntax requires)
    case 2
        switch filter_type
            case 0
            case 1
                error('In order to make the requested low-pass filter, input only one frequency for Wn_freq')
            case 2
                error('In order to make the requested high-pass filter, input only one frequency for Wn_freq')
            case 3
            case 4
        end
        Lower = Wn_freq(1); %Cutoff frequencies for bandpass and bandreject filters
        Upper = Wn_freq(2);
        Wn1=Lower/(Fs/2);
        Wn2=Upper/(Fs/2);
end

%% Determine frequencies to generate
int_multiplier = [1:compnt_step:ncomponents]; 
freq_array = int_multiplier*f0;
pin = 0;

%% Omit fundamental if instructed
switch include_fundmntl
    case 0
        freq_array = freq_array(2:end);
    case 1
end

%% Step through each frequency component in the complex tone.
for f = [1:length(freq_array)];
    %Randomly vary the starting phase of each component - default turned off
    switch rand_phase
        case 0
        case 1
            phase = 2*pi * rand(1,1); %random starting phase
    end
    pin = pin + cos(2 * pi * freq_array(f) *t + phase);
end

%% Optional filters to apply to complex tone
switch rectangular_filt
    case 0 %gradually sloping (steepness is determined by filter order)
        switch filter_type
            case 0 %none
            case 1 %lowpass
                b=fir1(order,fCo_rel_nyq,'low');
                pin=filter(b,1,pin);
            case 2 %highpass
                b=fir1(order,fCo_rel_nyq,'high');
                pin=filter(b,1,pin);
            case 3 %bandpass
                b=fir1(order,[Wn1,Wn2],'bandpass');
                pin=filter(b,1,pin);
            case 4 %band reject
                b=fir1(order,[Wn1,Wn2],'stop');
                pin=filter(b,1,pin);
        end
        
    case 1 %rectangular (very steep)
        switch filter_type
            case 0 %none
            case 1 %lowpass
                f = [0 Wn1 Wn1 1];
                m = [1  1   0  0];
                b= firls(el,f,m);
                pin=filter(b,1,pin);
            case 2 %highpass
                f = [0 Wn1 Wn1 1];
                m = [0  0   1  1];
                b= firls(el,f,m);
                pin=filter(b,1,pin);
            case 3 %bandpass
                f = [0 Wn1 Wn1 Wn2 Wn2 1];
                m = [0  0   1   1   0  0];
                b= firls(el,f,m);
                pin=filter(b,1,pin);
            case 4 %band reject
                f = [0 Wn1 Wn1 Wn2 Wn2 1];
                m = [0  0   1   1   0  0];
                b= firls(el,f,m);
                pin=filter(b,1,pin);
        end
end

%% Gate and scale final complex tone
pin = tukeywin(length(pin), 2*rampdur/dur)' .* pin; % apply on/off ramps
pin = 20e-6 * 10.^(stimdB/20) * pin/rms(pin); % scale signal into Pascals