function stim = Noise_in_Notched_Noise(dur,rampdur,db_target,db_increment,Fs)

% dur is total duration of stimulus (s)
% rampdur is duration of on or off ramp (s)
% db_target is the spectrum level (No, dB SPL) of the entire target noise.
% db_increment is the increment of the target noise. (So, dB)
%     >> if db_increment == -99, then the standard stimulus is created (i.e. no
%     increment.)
% Masker noise has spectrum level 10 dB higher than spectrum level of target_standard.
% Threshold plotted by Viemeister is So/No (dB), or So(dB) - No(dB)
% Fs is sampling rate

% %Create vector of time values and then generate masker noise
% t = 0:(1/Fs):dur;
% %% Generate low-freq band of masker noise
% Low_freq =   100;
% High_freq = 6000;
% tmp = randn(1,length(t)); % start with wideband gaussian noise, then limit the bandwidth
% B = fir1(5000,[Low_freq/(Fs/2) High_freq/(Fs/2)]); % compute coeff's ; 5000-order FIR filter
% notched_noise = conv(tmp,B,'same'); % apply the filter
% clear tmp;
%
%  %% Generate and add high-freq band of masker noise
%  Low_freq =  14000;
%  High_freq = 20000;
%  tmp = randn(1,length(t)); % start with wideband gaussian noise, then limit the bandwidth
%  B = fir1(5000,[Low_freq/(Fs/2) High_freq/(Fs/2)]); % compute coeff's ; 5000-order FIR filter
%  notched_noise = notched_noise + conv(tmp,B,'same'); % apply the filter
%  clear tmp;
%
% %% Generate target noise
% Low_freq =   6000;
% High_freq = 14000;
% tmp = randn(1,length(t)); % start with wideband gaussian noise
% % now limit the bandwidth
% B = fir1(5000,[Low_freq/(Fs/2) High_freq/(Fs/2)]); % compute coeff's ; 5000-order FIR filter
% target_noise = conv(tmp,B,'same'); % apply the filter
% clear tmp;
flank_increment = 10;  % 10 dB to match Viemeister
if db_increment == -inf
    standard = gen_noiseband(dur,100,6000,(db_target + flank_increment),Fs) + ... % flanking bands are 10 dB higher than standard target level
        gen_noiseband(dur,6000,14000,(db_target),Fs) + ...
        gen_noiseband(dur,14000,20000,(db_target + flank_increment),Fs);
    standard = standard.* (tukeywin(npts,(2*rampdur)/dur))';
    stim = standard;
    
else
    
    test =     gen_noiseband(dur,100,6000,(db_target + flank_increment),Fs) + ... % flanking bands are 10 dB higher than standard target level
        gen_noiseband(dur,6000,14000,(db_target + db_increment),Fs) + ...
        gen_noiseband(dur,14000,20000,(db_target + flank_increment),Fs);
    test =     test.* (tukeywin(npts,(2*rampdur)/dur))';
    stim = test;
    
end

    function noiseband_wave = gen_noiseband(dur, Flo, Fhi, No, Fs)
        % generate noiseband and scale to spectrum level of No (dB SPL)
        % Flo and Fhi are in Hz
        npts = dur * Fs;
        noiseband_wave = randn(1,npts); % start with wideband gaussian noise, then limit the bandwidth
        B = fir1(5000,[Flo/(Fs/2) Fhi/(Fs/2)]); % compute coeff's ; 5000-order FIR filter
        noiseband_wave = conv(noiseband_wave,B,'same'); % apply the filter
        noise_level = No + 10*log10(Fhi - Flo); % dB SPL RMS for desired No for specified bandwidth
        scalar = 20e-6 * 10^(noise_level/20); % linear scalar to achieve desired level
        noiseband_wave = scalar * noiseband_wave/rms(noiseband_wave);
    end

end
