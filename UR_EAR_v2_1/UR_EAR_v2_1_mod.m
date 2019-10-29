addpath(genpath('~/Dropbox/MR_lib'))
% Parameter names & defaults for each stimulus.
% To add a stimulus parameter, fill in the first unused quote with the name
% of the parameter. The handle of the edit box with the value in it will be
% stimEditText(n,m), where n is the index of the stimulus and m is the index
% of the parameter.
% Note that (arbitrarily) each stimulus has up to 6 parameters that can be varied.
% The variable plot_type specifies linear (0) or log (1) axes for plots
Which_AN = 2;
Which_IC =1;
Fs = 100e3;
RsFs = 10000;  %Resample rate for time_freq surface plots
colors = ['g', 'b', 'r']; % colors for plots & labels of each stimulus condition

% IC model parameters
if Which_IC == 1  % SFIE model
    %'IC Models (Nelson & Carney, 2004;           Carney et al, 2015),    BMF(Hz) ='

    BMF = 100; % initial default when switching to SFIE model
    ICparamEdit.String = num2str(BMF);
    BMF = str2double(char(ICparamEdit.String));
    M = [];
    Delta = []; % not applicable for this model
    
elseif Which_IC == 2  % AN_ModFilt model
    %Mod Filter (Mao et al, 2013), BMF(Hz) ='
    BMF = 100; % initial default when switching to AN_modfilt model
    ICparamEdit.String = num2str(BMF);
    BMF = str2double(char(ICparamEdit.String));
    M = [];
    Delta = [];

elseif Which_IC==3 
    M = 30; % initial default when switching to EI_Krips&Furst model
    Delta = 100e-6;
    ICparamEdit.String = num2str(M);
    ICparam2Edit.String = num2str(Delta);
    M = str2double(char(ICparamEdit.String));
    Delta = str2double(char(ICparam2Edit.String));
    BMF = [];  % not applicable for this model
end

% Stimulus preparation
%Wav File   (Note: stimulus duration is computed from file, and no on/off ramp is applied.)
add_LTASS_noise = 0;  SNR = 0; % Note that tukeywin is applied after noise is added (no tukeywin was used for 'plain' speech)
nconditions = 1; % response to first wavfile (if other input filename was left blank by user, this will be only stimulus)
wavfile1 = 'ap_ltass.wav'; % file name of the stimulus
[stim_temp, Fs_wav] = audioread(wavfile1);
rms_stim = sqrt(mean(stim_temp.^2));
stimdB = rms2db(rms_stim);
[p,q] = rat(Fs/Fs_wav,0.0001);% find two integers whose ratio matches the desired change in sampling rate
Condition.stimulus = resample(stim_temp',p,q);% resample signal to have sampling rate required for AN model
Condition.stimulus = 20e-6 * power(10,(stimdB/20)) * Condition.stimulus/rms(Condition.stimulus); % scale stim to have an rms = 1, then scale to desired dB SPL in Pascals.

if add_LTASS_noise == 1                    % Make wideband LTASS noise (100 Hz - 6 kHz)
  disp('Adding LTASS noise with SNR = 0');
  ltass_SPL = stimdB - SNR;               
  ltass_noise = ltass_noise0(Fs,ltass_SPL,length(Condition.stimulus),1); % note: function modified to handle Fs = 100kHz
  ltass_ramp = 0.010;
  ltass_dur = length(Condition.stimulus)/Fs;
  gate = tukeywin(length(ltass_noise), 2*ltass_ramp/ltass_dur); %gating function 
  ltass_noise = ltass_noise .* gate;
  Condition.stimulus = Condition.stimulus + ltass_noise';      
end
clear stim_temp

% Model parameters
minCF  = 200;
maxCF = 20000;
CF_num = 20;
fiber_num = 3; % Number of fibers in each CF
CF_range = [minCF, maxCF];
dbloss1= 0;  % Hearing loss in decibels, to determine Cohc and Cihc for model
dbloss2= 0;  %   using function from Bruce and Zilany models, as in Bruce et al 2018 code
dbloss3= 0;
dbloss4= 0;
dbloss5= 0;
dbloss6= 0;
dbloss7= 0;
ag_dbloss=[dbloss1,dbloss2,dbloss3,dbloss4,dbloss5,dbloss6,dbloss7];
ag_fs = [125 250 500 1e3 2e3 4e3 8e3];  % audiometric frequencies

% Model Selection and Parameters
% Number of stimulus repetitions (only 1 rep is needed if probability of 
% firing is displayed - more reps needed for looking at spike times)

fiberType = 2;      % AN fiber type. (1 = low SR, 2 = medium SR, 3 = high SR)
implnt = 0;         % 0 = approximate model, 1=exact powerlaw implementation(See Zilany etal., 2009)
noiseType = 1;      % 0 for fixed fGn (1 for variable fGn) - this is the 'noise' associated with spontaneous activity of AN fibers - see Zilany et al., 2009. "0" lets you "freeze" it.
species = 1;% 1=cat; 2=human AN model parameters (with Shera tuning sharpness)
CFs = logspace(log10(CF_range(1)),log10(CF_range(2)),CF_num); % set range and resolution of CFs here
if Which_IC == 1
    BMF = str2double(char(ICparamEdit.String));
elseif Which_IC == 2
    BMF = str2double(char(ICparamEdit.String));
elseif Which_IC == 3
    M= str2double(char(ICparamEdit.String));
    Delta= str2double(char(ICparam2Edit.String));
    BMF = str2double(char(ICparamEdit.String));
end

dbloss = interp1(ag_fs,ag_dbloss,CFs,'linear','extrap');
[cohc_vals,cihc_vals,OHC_Loss]=fitaudiogram2(CFs,dbloss,species);
if cohc_vals(1) == 0
    cohc_vals(1) = 1; % for a very low CF, a "0" may be returned by Bruce et al fit audiogram, but this is a bad default. Set it to 1 here.
end
if cihc_vals(1) == 0
    cihc_vals(1) = 1; % for a very low CF, a "0" may be returned, but this is a bad default. Set it to 1 here.
end

% Check for NaN in stimulus - this prevents NaN from being passed into .mex files and causing MATLAB to close
if sum(isnan(Condition.stimulus))>0
    error('One or more fields of the UR_EAR input were left blank or completed incorrectly.')
end

% Set up and RUN the simulation
% Loop through conditions
nrep=1;
for iicondition = 1% One or Two stimulus conditions

    dur = length( Condition(iicondition).stimulus)/Fs;             % duration of waveform in sec
    onset_num = 1;  % 1st point that will be included in analyzed response  (allows exclusion of onset response, e.g. to omit 1st 50 ms, use 0.050*Fs;)

    % Loop through CFs (within nconditions loop)
    for  n = 1:length(CFs)               

        CF = CFs(n); % CF in Hz;                
        cohc = cohc_vals(n); cihc = cihc_vals(n); % LHC - fix - need to grab one value of cohc, cihc for each CF

        switch  Which_AN
            case 1

                % Using ANModel_2014 (2-step process)
                vihc = model_IHC( Condition(iicondition).stimulus,CF,nrep,1/Fs,dur*1.2,cohc,cihc,species);
                %                [vihc,bm] = model_IHC_BM( Condition(iicondition).stimulus,CF,nrep,1/Fs,dur*1.2,cohc,cihc,species); % use vrsion of model_IHC that returns BM response (ChirpFilter only)
                [an_sout,~,~] = model_Synapse(vihc,CF,nrep,1/Fs,fiberType,noiseType,implnt); % an_sout is the auditory-nerve synapse output - a rate vs. time function that could be used to drive a spike generator
                Condition(iicondition).AN_average(n) = mean(an_sout(onset_num:end)); % save mean rates for a plot of population AN response
                %    Condition(iicondition).BM_population(iCF,:) = resample(bm,RsFs,Fs);  % save synapse output waveform into a matrix (load waves into matrix so they'll show up properly in imagesc)
                Condition(iicondition).VIHC_population(n,:) = resample(vihc,RsFs,Fs);  % save synapse output waveform into a matrix (load waves into matrix so they'll show up properly in imagesc)
                Condition(iicondition).an_sout_population(n,:) = resample(an_sout,RsFs,Fs);  % save synapse output waveform into a matrix (load waves into matrix so they'll show up properly in imagesc)

            case 2

                vihc = model_IHC_BEZ2018( Condition(iicondition).stimulus,CF,nrep,1/Fs,dur*1.2,cohc,cihc,species);
                [psth,neurogram_ft] = generate_neurogram_UREAR2(Condition(iicondition).stimulus,Fs,species,ag_fs,ag_dbloss,CF_num,dur,n,fiber_num,CF_range,fiberType);

                an_sout=(100000*psth)/fiber_num;

                Condition(iicondition).AN_average(n) = sum(psth(onset_num:end))/(dur*fiber_num);

                Condition(iicondition).an_sout_population(n,:) = resample(an_sout,RsFs,Fs);
                Condition(iicondition).an_sout_population_plot(n,:) = neurogram_ft;
                Condition(iicondition).VIHC_population(n,:) = resample(vihc,RsFs,Fs);  % save synapse output waveform into
        end
        switch Which_IC
            case 1 %Monaural SFIE

                [ic_sout_BE,ic_sout_BS,cn_sout_contra] = SFIE_BE_BS_BMF(an_sout,BMF,Fs);
                Condition(iicondition).cn_sout_contra(n,:) = cn_sout_contra;
                Condition(iicondition).cn_sout_avg(n) = mean(cn_sout_contra(onset_num:end));
                Condition(iicondition).average_ic_sout_BE(n) = mean(ic_sout_BE(onset_num:end)); % averages the bandpass response
                Condition(iicondition).BE_sout_population(n,:) = resample(ic_sout_BE,RsFs,Fs);
                Condition(iicondition).average_ic_sout_BS(n) = mean(ic_sout_BS(onset_num:end));

            case 2 %Monaural Simple F ilter                      

                ic_sout_BE = unitgain_bpFilter(an_sout,BMF,Fs);  % Now, call NEW unitgain BP filter to simulate bandpass IC cell with all BMF's

                Condition(iicondition).average_ic_sout_BE(n) = mean(ic_sout_BE(onset_num:end)); % averages the bandpass response over the stimulus duration
                Condition(iicondition).BE_sout_population(n,:) = resample(ic_sout_BE,RsFs,Fs);

            case 3 % EI model from Krips & Furst

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                an_sout1 = an_sout;% from above - AN response at excitatory CF
                lcf1 = CF * 2^(-1/6);
                hcf1 = CF * 2^(1/6);
                C=linspace(lcf1,hcf1,M);

                CF_2= CF * 1.1;
                lcf2 =  CF_2 * 2^(-1/6);
                hcf2 =  CF_2 * 2^(1/6);
                C2=linspace(lcf2,hcf2,M);
                vihc = model_IHC( Condition(iicondition).stimulus,CF_2,nrep,1/Fs,dur*1.2,cohc,cihc,species);
                [an_sout2,~,~] = model_Synapse(vihc, CF_2,nrep,1/Fs,fiberType,noiseType,implnt); % an_sout is the auditory-nerve
                delays1 = linspace(0,2e-3,M);
                delays2 = linspace(0,3.5e-3,M);

                parfor n_inh = 1:M


                    inh1_delay(n_inh) = delays1(n_inh); % (M/1000*i);% sec; delay of the inhibitory signal (1ms>>200Hz BMF; 2ms>>100Hz BMF; 3 ms >> 80Hz BMF for Delta = 500 ms)
                    n_inh1_delay(n_inh) = floor(inh1_delay(n_inh)*Fs); % # of points in inhibitory delay
                    inh2_delay(n_inh) = delays2(n_inh); % (M/1000*i);% sec; delay of the inhibitory signal (1ms>>200Hz BMF; 2ms>>100Hz BMF; 3 ms >> 80Hz BMF for Delta = 500 ms)
                    n_inh2_delay(n_inh) = floor(inh2_delay(n_inh)*Fs); % # of points in inhibitory delay




                    CF1 = C(n_inh);  % shift inhibition to higher CF, a la Heeringa & van Dijk, and Ken's results in budgie
                    vihc = model_IHC( Condition(iicondition).stimulus,CF1,nrep,1/Fs,dur*1.2,cohc,cihc,species);
                    [an_inh1,~,~] = model_Synapse(vihc,CF1,nrep,1/Fs,fiberType,noiseType,implnt); % an_sout is the auditory-nerve synapse output - a rate vs. time function that could be used to drive a spike generator


                    CF2 = C2(n_inh);  % shift inhibition to higher CF, a la Heeringa & van Dijk, and Ken's results in budgie
                    vihc = model_IHC( Condition(iicondition).stimulus,CF2,nrep,1/Fs,dur*1.2,cohc,cihc,species);
                    [an_inh2,~,~] = model_Synapse(vihc,CF2,nrep,1/Fs,fiberType,noiseType,implnt); % an_sout is the auditory-nerve synapse output - a rate vs. time function that could be used to drive a spike generator

                    if iicondition==1

                        lambda_1 = an_inh1;
                        lambda_I11{n_inh} = [zeros(1,n_inh1_delay(n_inh)) lambda_1(1:(end-n_inh1_delay(n_inh)))];
                        lambda_2  =an_inh2;
                        lambda_I21{n_inh} = [zeros(1,n_inh2_delay(n_inh)) lambda_2(1:(end-n_inh2_delay(n_inh)))];

                    else

                        lambda_1 = an_inh1;
                        lambda_I12{n_inh} = [zeros(1,n_inh1_delay(n_inh)) lambda_1(1:(end-n_inh1_delay(n_inh)))];
                        lambda_2  =an_inh2;
                        lambda_I22{n_inh} = [zeros(1,n_inh2_delay(n_inh)) lambda_2(1:(end-n_inh2_delay(n_inh)))];
                    end


                end


                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


                if iicondition==1

                    an_sout_E = EI_KF_CD(an_sout1, lambda_I11,an_sout2,lambda_I21,Fs,M,Delta);

                else
                    an_sout_E = EI_KF_CD(an_sout1,lambda_I12,an_sout2,lambda_I22,Fs,M,Delta);
                end
                Condition(iicondition).average_ic_sout_BE(n) = mean( an_sout_E(onset_num:end));

                Condition(iicondition).BE_sout_population(n,:) = resample(an_sout_E,RsFs,Fs);


        end
    end % END OF CF LOOP
end  % end of nconditions loop


% Plotting
fig1 = figure(1013);
set_figure_size(fig1,[0 0 30 20]);

% Stimulus Plot 1: Stimulus Waveform - Toggle between responses to two STIMULI
subplot(3,3,1)
cla('reset') % clear previous plot and axis labels
stim_plot = 1; % this will always be "1" when nconditions = 1
plot((0:(length(Condition(stim_plot).stimulus)-1))/Fs,Condition(stim_plot).stimulus,'k');
% plot stim #1 as initial plot
title('Stimulus Waveform')
xlim([0,(length(Condition(stim_plot).stimulus)-1)/Fs]) %BNM 7/25/16
ylabel('Amplitude (Pa)')
xlabel('Time (sec)')

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot 2: Spectrogram of stimulus - Toggle between responses to two STIMULI

subplot(3,3,2)
cla('reset') % clear previous plot and axis labels
[sg,Ftmp,Ttmp] = spectrogram(Condition(stim_plot).stimulus,hanning(1000),[],2000,Fs); % 50% overlap (using even #'s to avoid "beating" with F0 for speech)
spec_image = pcolor(Ttmp,Ftmp,abs(sg));
shading('interp')
title('Spectrogram')
ylim([0.9*CF_range(1) 1.1*CF_range(2)]);
ylim([0 1000]);
set(spec_image,'HitTest','off'); %Hit Test must be turned off for button down function to work
ylabel('Frequency (Hz)')
% set(gca,'TickDir','out','XtickLabel',[])
caxis([0 25]) % selected based on 65 dB SPL speech
xlim([0,(length(Condition(stim_plot).stimulus)-1)/Fs]) %BNM 7/25/16
 
% Plot 3: Spectrum of stimulus in CF range - Toggle between two STIMULI       
subplot(3,3,3)
cla('reset')
m = length(Condition(stim_plot).stimulus);
nfft = pow2(nextpow2(m));  % Find next power of 2
spectrum_plot = 20* log10(abs(2*fft(Condition(stim_plot).stimulus,nfft)/m/20e-6)); % see: http://12000.org/my_notes/on_scaling_factor_for_ftt_in_matlab/.
%spectrum_plot = 20*log10(abs(fft(Condition(stim_plot).stimulus)/numel(Condition(stim_plot).stimulus)/20e-6)); % this normalization was missing in v1.0
specplot_max = -inf; % intialize
for icond = 1:nconditions  % use overall max (across nconditions) value for upper limit of ylim
    specplot_max = max(specplot_max, max(20* log10(abs( fft(Condition(stim_plot).stimulus,nfft)/nfft/20e-6))));
end
fres = Fs/nfft; % freq resolution = 1/Dur
semilogx(fres*(0:nfft-1),spectrum_plot,'HitTest','off','color',colors(stim_plot));
    %               semilogx(spectrum_plot_CF_range,fres*(0:nfft-1),spectrum_plot,'HitTest','off','color','k','linewidth',2); % black line, for figure
xlim([CF_range(1) CF_range(2)])
ylim([(specplot_max - 40), specplot_max+10]) % plot 50 dB worth of spectral magnitudes
title('Spectrum over CF range')
ylabel('Magnitude (dB SPL)')
xlabel('Frequency (Hz)')
set(gca, 'XTick',[100 200 500 1000 2000 5000 10000]); % only labels within CF range will be used
        
% Plot 3: VIHC Response - Time-Freq plot - Toggle between responses to two STIMULI
subplot(3,3,4)
cla('reset')
vihc_clicks_stim = 1;
data=Condition(vihc_clicks_stim).VIHC_population(:,floor(0.01*RsFs):floor(dur*RsFs));
plotcolor = pcolor((1:length(data))/RsFs,CFs,data);
title('VIHC')
shading('interp')
caxis([-.005 0.015]); % based on 75 dB SPL speech
set(gca,'view',[0 90])
ylabel('IHC BF (Hz)')
c2=colorbar;  % set up and position the color bar for spike rate
title(c2,'mV');

% Plot 4: AN Response - Time-Freq plot - Toggle between responses to two STIMULI
subplot(3,3,5);
cla('reset')
an_clicks_stim = 1;

if Which_AN==1
%      data=Condition(an_clicks_stim).an_sout_population(:,floor(0.01*RsFs):floor(dur*RsFs));
    data=Condition(an_clicks_stim).an_sout_population;  %LHC  9/20/18

    plotcolor = pcolor((1:length(data))/RsFs,CFs,data);
    plotcolor.HitTest = 'off';
end
if Which_AN==2
    data=Condition(an_clicks_stim).an_sout_population_plot(:,floor(0.01*Fs/16):floor(dur*Fs/16));
    plotcolor = pcolor((1:length(data))*16/Fs,CFs,data);
    plotcolor.HitTest = 'off';
    %      imagesc(t_ft,CFs,data);

end
shading('interp')
title('AN')
set(gca,'view',[0 90])
axis square
ylabel('AN BF (Hz)')
set(gca,'TickDir','out')
xlabel('Time (sec)')
c2=colorbar;  % set up and position the color bar for spike rate
title(c2,'spikes/sec');

% Plot 5: IC BE Response - Time-Freq plot - Toggle between responses to two STIMULI      
subplot(3,3,6); % include this so that even on 1st iteration it will use the correct axes
cla('reset')
ic_clicks_stim = 1;  % scroll through the # of possible condition plots
data = Condition(ic_clicks_stim).BE_sout_population;
pcolor((0:length(data)-1)/RsFs,CFs,data);
shading('interp')
title('IC')
set(gca,'view',[0 90])
axis square
set(gca,'TickDir','out')
ylabel('IC BF (Hz)')
xlabel('Time (sec)')
xlim([((dur/2) - 0.025) ((dur/2) + 0.025)]) % plot 50 ms window, in middle of stimulus waveform
c4 = colorbar;
title(c4,'spikes/sec');
        
% Plot 6: Average AN Model Response %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

subplot(3,3,7)
cla('reset')
semilogx(CFs, Condition(iicondition).AN_average,'linewidth',2,'color',colors(iicondition)) % log axes
xlim([CF_range(1) CF_range(2)]);
ylim([0,350]) % fix rate (sp/sec) axis to allow comparisons
set(gca, 'XTick',[100 200 500 1000 2000 5000 10000]); % only labels within CF range will be used
title('AN Average Response')
xlabel('AN BF (Hz)')
ylabel('Average Rate (sp/sec)')

% Plot 7: Average CN Response
subplot(3,3,8)
cla('reset')
semilogx(CFs, Condition(1).cn_sout_avg,'linewidth',2,'color',colors(iicondition))
title('CN Average Response')
xlabel('CN BF (Hz)')
ylabel('Average Rate (sp/sec)')
xlim([CF_range(1) CF_range(2)]);
set(gca, 'XTick',[100 200 500 1000 2000 5000 10000]); % only labels within CF range will be used

% FINAL PLOT: AVERAGE BE/BS IC RESPONSE - plot average rates for population of IC BE model cells (Toggles to BS cells for SFIE model)
subplot(3,3,9)
if Which_IC == 1  % SFIE model - plot toggles between BE and BS model responses
    semilogx(CFs, Condition(iicondition).average_ic_sout_BE,'linewidth',2,'color',colors(iicondition),'HitTest', 'off')
    title('Avg. IC Rate: Band-Enhanced')
    xlabel('IC BF (Hz)')
    ylabel('Average Rate (sp/sec)')
    xlim([CF_range(1) CF_range(2)]);
    set(gca, 'XTick',[100 200 500 1000 2000 5000 10000]); % only labels within CF range will be used
    max_rate = max(Condition.average_ic_sout_BE); % intialize
    ylim([0 (1.1 * max_rate)]);
elseif which_IC == 2 % AN_ModFilt model (models only Band-Enhanced cells)
    semilogx(IC_response_avg,CFs, Condition(iicondition).average_ic_sout_BE,...
               'linewidth',2,'color',colors(iicondition),'HitTest', 'off')
    title(['Avg. IC Rate: Band-Enhanced (BMF=' num2str(BMF) ' Hz)'])
    xlabel('IC BF (Hz)')
    ylabel('Average Rate (sp/sec)')
    xlim([CF_range(1) CF_range(2)]);
    set(gca, 'XTick',[100 200 500 1000 2000 5000 10000]); % only labels within CF range will be used
    YL = ylim;
    ylim([0, YL(2)]);  % force rate axis to have 0 sp/sec as minimum
end
    
% to write out some data for additional analysis - Plot a single CF using quick_model_plot.m (simple-minded, but effective!)
save('UR_EAR_model_mod_data.mat','CFs','Condition');