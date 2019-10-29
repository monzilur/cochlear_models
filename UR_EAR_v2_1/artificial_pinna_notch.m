function stimulus = artificial_pinna_notch(dur, rampdur, fcenter, stimdB, Fs)
    %Function to create single, simple artificial pinna first notch (FN)
    %using bandwidth estimated from human HRTFs
    
    npts = floor(dur*Fs);
    stimulus = randn(1,npts); % start with wideband noise

    %add artifical 'pinna' notch at freq = fcenter (currently a monaural stimulus)
    Wo = fcenter/(Fs/2); % notch freq normalized by Nyquist rate
    BW = (fcenter/6.)/(Fs/2); % set notch width = 1/10 of notch freq; normalize by Nyquist rate
    Ab = abs(10*log10(0.5)); % 3-dB width is the default for interpretation of BW
    [b,a] = secondorderNotch(Wo,BW,Ab);
    stimulus = filter(b,a,stimulus);

    % now limit the overall bandwidth to 2 octaves (bounded by 100 Hz & 19 kHz)
    lo_fr = max(100., fcenter / 2); % limit low freq edge of noise to 100 Hz
    hi_fr = min(fcenter * 2, 19000.); % limit the upper frequency cutoff to 19000 
    [bb,aa] = butter(4,[lo_fr/(Fs/2) hi_fr/(Fs/2)]); % compute coeff's for an 8th order (2 * 4th order) butterworth filter
    stimulus = filter(bb,aa,stimulus); % apply the filter

    %window stimulus & scale into pascals
    gate = tukeywin(npts,2*rampdur/dur); %raised cosine ramps
    stimulus = stimulus .*gate'; %gate stimulus
    stimulus = 20e-6 * power(10,(stimdB/20)) * stimulus/rms(stimulus);
    
    function [num,den] = secondorderNotch(Wo,BW,Ab)
    % Design a 2nd-order notch digital filter.
    % Inputs are normalized by pi.
    BW = BW*pi;
    Wo = Wo*pi;
    Gb   = 10^(-Ab/20);
    beta = (sqrt(1-Gb.^2)/Gb)*tan(BW/2);
    gain = 1/(1+beta);
    num  = gain*[1 -2*cos(Wo) 1];
    den  = [1 -2*gain*cos(Wo) (2*gain-1)];
    end
end