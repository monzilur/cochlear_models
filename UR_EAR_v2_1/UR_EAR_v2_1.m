function UR_EAR_v2_1
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%   UR_EAR_v2_0  (8/10/18)  %%%%%%%%%%%%%%%%%%%%%%%%%%
%  Version of UE_Ear updated and extended by Afagh Farhadi at University of
%  Rochester.  With input from the Carney lab and Hannah Nichols from
%  Louisiana Tech (REU student).
%%  v2_1 (9/20/18 LHC) 
%  Fixed bugs in re-sampling and LTASS noise addition (optional) for
%  *.wav inputs. Fixed assignment of cohc, cihc based on audiogram values.
%% %%%%%%%%%%%%%%%%%%%%%%%% LHC - v1_0 (9/23/16) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% First "release" version of code tool developed by UR Research Assistants
% Natalia Galant, Braden Maxwell, Danika Teverovsky, Thomas Varner, Langchen Fan
% in the Carney lab at the University of Rochester, Depts of BME & Neuroscience
%   Presented at ARO 2016
% See User_Manual.pdf and Readme.txt files for more info
% Send queries to Laurel.Carney@Rochester.edu
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Initial default parameters for GUI
Which_IC = 2; % This sets initial default as the AN_ModFilt model (Mao et al., 2016)

if Which_IC == 1 || 2
    ICparamEdit.String = num2str(100);  %  Set BMF value for SFIE model or AN_Modfilt model
elseif Which_IC == 3
    ICparamEdit.String = num2str(30);
    ICparam2Edit.String = num2str(100e-6);
end

Which_AN = 1; % This sets initial default as (Zilany et al., 2014)

initial_stimulus = 1;  % select default stimulus type to #1, which is *.wav file
cfRange = [200 3000]; % set a 'generic' default range of CFs; this can be updated on GUI
rng('default'); % added to accommodate older versions of Matlab, in cases for which rng has previously been run
rng('shuffle'); % seed the random number generator using time of day
%% %%%%%%%%% Set up Panels and Axes for plots %%%%%%%%%%%%%%%%%%%%%%%%%
% Set up (large) main panel in GUI
mainFig = figure('Position',[25,50,1250,850]);
InputPanel = uipanel('Position',[0 0 0.25 1],'Title','Stimulus Detail',...
    'Parent',mainFig,'Units','normalized','FontSize',11,'Visible','on');

% Set up panel for Response plots
outputPanel = uipanel('Visible','on','Parent',mainFig,'units',...
    'normalized','position',[0.26,0,0.74,1]);

outputPanel2 = uipanel(outputPanel,'Visible','off','units',...
    'normalized','position',[0,0,1,1]);

% Normalized- First column of plots - Stimulus - (used 'Normalized' units to allow re-sizing of figure on various screens)
stim_waveform_axes = axes('Units', 'normalized', 'Visible', 'off','position',[70/950,750/900,200/950,185/900],'Parent', outputPanel);
spectrogram_plot = axes('Units', 'normalized', 'Visible', 'off','position',[70/950,350/900,200/950,185/900],'Parent', outputPanel);
spectrum_plot_CF_range = axes('Units', 'normalized', 'Visible', 'off','position',[70/950,75/900,200/950,185/900],'Parent', outputPanel);
align([stim_waveform_axes,spectrogram_plot,spectrum_plot_CF_range], 'top','fixed',50);

% Normalized- Middle 2 plots - time-freq plots
AN_response_time = axes('Units', 'normalized', 'Visible', 'off','position',[((345/950)-.015),((450/900)-.015),(250/950)*.85,(230/900)*.85],'Parent', outputPanel); %1=distace from left edge 2=distance from bottom
IC_response_time = axes('Units', 'normalized', 'Visible', 'off','position',[((345/950)-.015),((150/900))-.015,(250/950)*.85,(230/900)*.85],'Parent', outputPanel);

% Last column of plots - Average rates
AN_response_avg = axes('Units', 'normalized', 'Visible', 'off','position',[670/950,800/900,250/950,165/900],'Parent', outputPanel);
CN_response_avg = axes('Units', 'normalized', 'Visible', 'off','position',[670/950,375/900,250/950,165/900],'Parent', outputPanel);
IC_response_avg = axes('Units', 'normalized', 'Visible', 'off','position',[670/950,100/900,250/950,165/900],'Parent', outputPanel);
align([AN_response_avg,CN_response_avg,IC_response_avg], 'top','fixed',50);

% Normalized- wide plots for panel2
stim_waveform_axes_wide = axes('Units', 'normalized', 'Visible', 'off','position',[70/950,350/900,800/950,100/900],'Parent', outputPanel2);
spectrogram_plot_wide = axes('Units', 'normalized', 'Visible', 'off','position',  [70/950,320/900,800/950,100/900],'Parent', outputPanel2);
VIHC_response_time = axes('Units', 'normalized', 'Visible', 'off','position',     [70/950,250/900,800/950,100/900],'Parent', outputPanel2); %1=distace from left edge 2=distance from bottom
AN_response_time_wide = axes('Units', 'normalized', 'Visible', 'off','position',  [70/950,150/900,800/950,100/900],'Parent', outputPanel2); %1=distace from left edge 2=distance from bottom
IC_response_time_wide = axes('Units', 'normalized', 'Visible', 'off','position',  [70/950,80/900,800/950,100/900],'Parent', outputPanel2);
align([stim_waveform_axes_wide,spectrogram_plot_wide,VIHC_response_time,AN_response_time_wide,IC_response_time_wide], 'top','fixed',40);

%% Set up main stimulusDetailPanel - GUI inputs related to stimuli
% Types of Stimuli: Modify this, and every line marked with "STIM", to add a new stimulus
stimTypeOptions = {'Wavefile','Noise Band','Notched Noise','Tone in Noise',...
    'Profile Analysis','Pinna Cues','SAM Tone','Complex Tone','Single Formant',...
    'Double Formant', 'Schroeder Phase', 'Noise-in-Notched Noise', 'Fm Tone','Forward Masking','CMR_BW','CMR_FB'};

numOptions = length(stimTypeOptions);

stimDetailPanel = uipanel('Parent',InputPanel,...
    'Units','normalized','Position',[0.05 0.85 0.9 0.15],'FontSize',11,'Visible','on');

stimTypeMenu = uicontrol(stimDetailPanel,'Style','popupmenu',...
    'BackgroundColor','white','String',stimTypeOptions,...
    'Units','normalized','Position',[0.05 0.85 0.4 0.08],...
    'Callback',{@stimTypeMenuCallback},'Visible','on');

stimEditPositions = [0.9 0.83 0.76 0.69 0.62 0.55 0.48 0.41 0.34]; % positions of 9 parameter Edit boxes

%% Checkboxes for each stimulus type
% You must add a component to each of these arrays if you add a new stimulus
stimCheckBoxVisible1 = [0 0 0 1 0 0 0 1 0 0 1 0 0 0 0 0]; % Indicate whether to include "toggle" check boxes, see below. STIM
stimCheckBoxVisible2 = [0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0]; % STIM
stimCheckBoxText1 = {'','','',  'Wideband (100-10kHz)',      '','','','Include Fundamental','','','Include Fundamental','','','','',''}; % STIM
stimCheckBoxText2 = {'','','','Narrowband (1/3-octave BW)','','','',       '',              '','','','','','','',''}; % STIM
stimCheckBoxCallback1 = {{} {} {} {@stimBoxCallback,4,2} {} {} {} {} {} {} {} {} {} {} {} {} {} {}}; % STIM
stimCheckBoxCallback2 = {{} {} {} {@stimBoxCallback,4,1} {} {} {} {} {} {} {} {} {} {} {} {} {} {}}; % STIM

%% Parameter names & defaults for each stimulus.
% To add a stimulus parameter, fill in the first unused quote with the name
% of the parameter. The handle of the edit box with the value in it will be
% stimEditText(n,m), where n is the index of the stimulus and m is the index
% of the parameter.
% Note that (arbitrarily) each stimulus has up to 6 parameters that can be varied.
% The variable plot_type specifies linear (0) or log (1) axes for plots

Fs = 100e3;  % Modeling sampling rate in Hz (must be 100, 200 or 500 kHz for AN model):

%Wave File
stimEditText{1} = {'File Name 1:','File Name 2:','','','','','','',''}; % sets labels of each textbox
defaultStimEdit{1} = {'m06ae.wav',  'm06iy.wav',    '','','','','','',''}; % sets defaults for each textbox (two vowel tokens from Hillenbrand 1995 database)
plot_type(1) = 1; % log axes for plots

%Band-limited Noise (useful for Edge Pitch (Klein & Hartmann, 1981))
stimEditText{2} = {'Duration (s)','Ramp Dur (s)','Low Freq Cutoff (Hz)','High Freq Cutoff (Hz)','','','','',''};
defaultStimEdit{2} = {'0.5',         '0.020',         '100',         '800',      '','','','',''};
plot_type(2) = 1; % log axes for plots

%Notched Noise (Patterson 1976)
stimEditText{3} = {'Duration (s)','Ramp Dur (s)','Center Freq (Hz)', 'Delta(=CF*Notchwidth/2)','Bandwidth/CF','Tone Level (dB SPL)','',''}; % delta = (1/2 Notch width) * CF
defaultStimEdit{3} = {'0.6',           '0.1',       '1500',                '0.1',           '0.8',        '50'}; % 50 dB SPL tone should be ~threshold for these params.
plot_type(3) = 1; % log axes for plots

%Tone in Noise  (After Es/No is input, the SNR is calculated & displayed)
stimEditText{4} = {'Duration (s)','Ramp Dur (s)','Tone Freq (Hz)','Noise Spec Level (dB)','Es/No(dB):','SNR:','','',''}; % SNR is not an input - just displayed here
defaultStimEdit{4} = {'0.3',          '.010',        '500',              '40',               '15',       '','','',''}; % 15 dB is ~2-3 dB above threshold for NB (12.3) and WB (11.3) from Evilsizer et al.
plot_type(4) = 1; % log axes for plots

%Profile Analysis
stimEditText{5} = {'Duration (s)','Ramp Dur (s)','# Components (Odd #)','Increment (20Log((DelA)/A) dB)','','','','',''};
defaultStimEdit{5} = {'0.5',         '0.010',           '11',               '-2',        '','','','',''};
plot_type(5) = 1; % log axes for plots

%Pinna Cues - artifical pinna cue (spectral notch)
stimEditText{6} = {'Duration (s)','Ramp Dur (s)','Notch Freq(Hz) *Adjust CFs!*','','','','','',''};
defaultStimEdit{6} = {'0.5',       '0.010',        '7000',         '','','','','',''};
plot_type(6) = 1; % log axes for plots

% SAM Tone
stimEditText{7} = {'Duration (s)','Ramp Dur (s)','Carrier Freq (Hz)','Mod Freq (Hz)','Mod Depth (dB)','','','',''};
defaultStimEdit{7} = {'0.5',         '0.010',         '1500',           '100',               '0',     '','','',''};
plot_type(7) = 1; % log axes for plots

%Harmonic Complex Tone
stimEditText{8} = {'Duration (s)','Ramp Dur (s)','F0 (Hz)','# Components','Filter Type','','','',''};
defaultStimEdit{8} = {'0.5',           '0.1',        '200',       '15',         '',       '','','',''};
plot_type(8) = 0; % linear axes for plots

%Single Formant (Triangular spectrum)
stimEditText{9} = {'Duration (s)','Ramp Dur (s)','Frequency (Hz)','F0 (Hz)','G (Spec Slope, dB/oct)','','','',''};
defaultStimEdit{9} = {'0.3',         '0.025',       '2000',        '200',        '200',               '','','',''};
plot_type(9) = 0; % linear axes for plots

%Double Formant
stimEditText{10} = {'Duration (s)','Ramp Dur (s)','F0 (Hz)','Formant Freqs (Hz)','Bandwidths (Hz)','','','',''};
defaultStimEdit{10} = {'0.5',          '0.025',    '200',       '[500 2100]',         '[70 90]',   '','','',''};
plot_type(10) = 0; % linear axes for plots

%Schroeder Phase Complex Tone
stimEditText{11} = {'Duration (s)','Ramp Dur (s)','F0 (Hz)','# Components','C Value','','','',''};
defaultStimEdit{11} = {'0.1',        '0.025',        '100',       '30',       '1',    '','','',''};
plot_type(11) = 0; % linear axes for plots

%Noise in Notched Noise (Viemeister 1983)
stimEditText{12} = {'Duration (s)','Ramp Dur (s)', 'Target Noise Spec Level (dB SPL)','Increment (dB)','','','','',''};
defaultStimEdit{12} = {'0.2',           '0.01',            '20',                          '5',         '','','','',''};
plot_type(12) = 1; % log axes for plots

% FM Tone
stimEditText{13} = {'Duration (s)','Ramp Dur (s)','Center Freq (Hz)','C1:Fm&Df[Hz %]','C2:Fm&Df[Hz %]','','','',''}; % Excursion is freq range of Fm
defaultStimEdit{13} = {'0.65',         '0.010',         '1000',           '[5 13.9]',      '[5 20]',     '','','',''};
plot_type(13) = 1; % log axes for plots

% Forward Masking
stimEditText{14} = {'Masker Dur (s)', 'Masker Ramp (s)','Probe [Dur Level]','Masker Freq (Hz)','Probe Freq (Hz)','Delay (s)','','',''};
defaultStimEdit{14} = {'0.200',         '0.004',         '[0.016 40]',       '2000',             '2000',      '0.010','','',''};
plot_type(14) = 1; % log axes for plots

% CMR Band-widening
stimEditText{15} = {'Tone Dur (s)','Tone Ramp Dur (s)','Tone Freq (Hz)','Tone(dB SPL):',...
    'Noise BW','Noise Spec Level (dB)','Noise Dur (s)', 'Noise Ramp Dur(s)','Mod BW (LP)'};
defaultStimEdit{15} = {'0.3', '.05','1000','65', '400','30','0.6','0.01','50'};
plot_type(15) = 1; % log axes for plots

% CMR Flanking Bands
stimEditText{16} = {'Duration (s)','Ramp Dur (s)','Tone Freq (Hz)','Noise Spec Level (dB)','Tone(dB SPL):','Flank BW','','',''};
defaultStimEdit{16} = {'0.3',          '.010',        '1000',              '40',               '65',       '100','','',''};
plot_type(16) = 1; % log axes for plots

soundLevelPanel = cell(numOptions,1); % initialize dimensions of these cell arrays
stimParamPanel =  cell(numOptions,1);
soundLevelEdit =  cell(numOptions,1);

%% set up soundLevelPanel and stimParamPanel for each stimlus type
for i1 = 1:numOptions
    soundLevelPanel{i1} = uipanel('Title','Sound Level',...
        'Parent',stimDetailPanel,'Units','normalized','Position',...
        [0.05 0.1 0.9 0.6],'FontSize',10,'Visible','off');
    stimParamPanel{i1} = uipanel('Title',...
        ['Stimulus Parameters: ',stimTypeOptions{i1}],'Parent',InputPanel,'Units',...
        'normalized','Position',[0.05 0.5 0.9 0.35],'FontSize',11,'Visible','off');
    
    if (i1 ~= 3) && (i1 ~= 4)
        uicontrol(soundLevelPanel{i1},'Style','text','String',...
            'Sound Level (dB SPL):','FontSize',9,'Units','normalized','Position',...
            [0,0.2,0.9,0.3]); % Text next to Sound Level Edit box on GUI
    elseif i1 == 3 || i1 == 12 % Notched-Noise stimulus
        uicontrol(soundLevelPanel{i1},'Style','text','String',...
            'Noise Level (dB SPL):','FontSize',9,'Units','normalized','Position',...
            [0,0.2,0.9,0.3]); % Text next to Sound Level Edit box on GUI
    elseif i1 == 4 || i1 == 12 % TIN or Noise-in-Notched-Noise (this input is not used for TIN)
        uicontrol(soundLevelPanel{i1},'Style','text','String',...
            ' not used >> ','FontSize',9,'Units','normalized','Position',...
            [0,0.2,0.9,0.3]); % Text next to Sound Level Edit box on GUI
    end
    
    if i1 == 4 || i1 == 12 || i1 == 15 || i1 == 16  % for TIN or Noise-in-Notched-Noise (this variable not used, so blank out the string that is displayed)
        soundLevelEdit{i1} = uicontrol(soundLevelPanel{i1},'Style','edit','String','',...
            'BackgroundColor','white','Units','normalized','Position',[0.75,0.2,0.15,0.3]);
    elseif i1 == 6 % for Pinna Cues, 40 dB SPL is the initial default
        soundLevelEdit{i1} = uicontrol(soundLevelPanel{i1},'Style','edit','String','40',...
            'BackgroundColor','white','Units','normalized','Position',[0.75,0.2,0.15,0.3]);
    else % for all other stimuli, 65 dB SPL is the initial default
        soundLevelEdit{i1} = uicontrol(soundLevelPanel{i1},'Style','edit','String','65',...
            'BackgroundColor','white','Units','normalized','Position',[0.75,0.2,0.15,0.3]);
    end
end
soundLevelPanel{initial_stimulus}.Visible = 'on'; % Display the initial stimulus panel (specified above)
stimParamPanel{initial_stimulus}.Visible = 'on';

%% set up stimParamPanel components
num_params = 9;  % arbitrarily set this to 6 to accomodate parameters for all stimuli in initial set
%    If num_params is increased, make sure to enter another default, or [], for each stimulus (above)
stimParamEdit = cell(numOptions,num_params); % edit boxes for various parameters
stimCheckBox = cell(numOptions,2); % the checkboxes come in pairs
for k = 1:numOptions  % this loops through all stimulus types
    for n = 1:num_params %list of possible parameters
        if k ~=15 && n > 6 % only run 9 param box for CMR -LF 7/2/18
            continue
        end
        thisText = stimEditText{k}{n};
        if ~isempty(thisText)
            thisVisible = 'on';
        else
            thisVisible = 'off';
        end
        
        thisDefault = defaultStimEdit{k}{n};
        
        stimParamEdit{k,n} = uicontrol(stimParamPanel{k},'Style','edit',...
            'String',thisDefault,'BackgroundColor','white','FontSize',8,'Units',...
            'normalized','Position',[0.75,stimEditPositions(n),0.22,...
            0.05],'Visible',thisVisible);
        
        uicontrol(stimParamPanel{k},'Style','text','String',...
            thisText,'FontSize',8,'Units','normalized','Position',...
            [0.01,stimEditPositions(n),0.72,0.05],'Visible','on');
        
        stimCheckBox{k,1} = uicontrol(stimParamPanel{k},'Style','checkbox','Units','normalized',...
            'Position',[0.15,0.45,0.7,0.1],'String',stimCheckBoxText1{k},'Value',1,'Callback',...
            stimCheckBoxCallback1{k},'Visible',boolToOnOff(stimCheckBoxVisible1(k)));
        
        stimCheckBox{k,2} = uicontrol(stimParamPanel{k},'Style','checkbox','Units','normalized',...
            'Position',[0.15,0.35,0.7,0.1],'String',stimCheckBoxText2{k},'Value',0,'Callback',...
            stimCheckBoxCallback2{k},'Visible',boolToOnOff(stimCheckBoxVisible2(k)));
        
        if k == 4 % for Tone-in-Noise stimulus (user inputs Es/No and then SNR is computed & displayed)
            if n == 6
                stimParamEdit{k,n}.Style = 'text';
                SNR_display_callback([],[]) %callback function unique to tone in noise
            else
                stimParamEdit{k,n}.Callback = @SNR_display_callback;
            end
        end
    end
end

    function SNR_display_callback(~,~)   % nested function to compute SNR for a give EsNo for Tone-in-Noise
        if stimCheckBox{4,1}.Value  %Tone in noise is the 4th stimulus
            wideband_yn = 1; % for Wideband noise (matching physiological stimulus)
        else
            wideband_yn = 0; %For Narrowband noise
        end
        No = str2double(stimParamEdit{4,4}.String); % Noise spectrum level, dB SPL
        EsNo = str2double(stimParamEdit{4,5}.String); % Es/No (see Evilsizer et al.)
        dur = str2double(stimParamEdit{4,1}.String); % dur in sec, for Es/No to SNR calc
        rampdur = str2double(stimParamEdit{4,2}.String);
        freq = str2double(stimParamEdit{4,3}.String);
        bin_mode = 1; %Monaural
        SNR_calc = 1; %At this point in UR_EAR, the TIN function will be run solely for the purpose of calculating SNR.
        TINstruct = TIN(dur,rampdur,freq,No,EsNo,bin_mode,wideband_yn,Fs,SNR_calc);
        value = TINstruct.SNR;
        stimParamEdit{4,6}.String = num2str(round(value));
    end

% Special inputs to allow filtering of Complex Tone (Harmonic complex)
filterOptions = {'None','Lowpass','Highpass','Bandpass','Bandreject'}; % for Harmonic complexes
complexToneMenu = uicontrol(stimParamPanel{8},'Style','popupmenu',...
    'BackgroundColor','white','String',filterOptions,...
    'Units','normalized','Position',[0.74 0.58 0.25 0.1],...
    'Callback',{@filterTypeCallback},'Visible','on');
complexFiltEdit = uicontrol(stimParamPanel{8},'Style','edit',... % optional filter for harmonic complexes
    'String',thisDefault,'BackgroundColor','white','Units',...
    'normalized','Position',[0.7,0.35,0.25,0.1],...
    'Visible','off');
complexFilttxt = uicontrol(stimParamPanel{8},'Style','text','String',...
    'Wn','FontSize',10,'Units','normalized','Position',...
    [0.1,0.35,0.55,0.07],'Visible','off');

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% GUI inputs for Model options - set parameters that are common to all models
modelParamPanel = uipanel('Title',...
    'Model Parameters','Parent',InputPanel,'Units','normalized','FontSize',11,...
    'Visible','on','Position',[0.05 0.08 0.9 0.5]);

uicontrol(modelParamPanel,'Style','text','String',...
    'IC:','FontSize',10,'Units','normalized','Position',...
    [0.02,0.88,0.1,0.1],'FontWeight','bold');  % IC Model text on GUI

uicontrol(modelParamPanel,'Style','text','String',...
    'AN:','FontSize',10,'Units','normalized','Position',...
    [0.02,0.7,0.1,0.1],'FontWeight','bold');  % AN Model text on GUI

modelTypeOptions = {'SFIE Model','AN ModFilt Model','EI_Krips&Furst'}; % when adding an IC model, add it here
modelTypePopUp = uicontrol(modelParamPanel,'Style','popupmenu','String',...
    modelTypeOptions,'Units','normalized','Value',Which_IC,'Position',...
    [0.15,0.9,0.4,0.08],'Callback',{@modelTypePopUpCallback});
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ANmodelTypeOptions = {'Zilany, Bruce & Carney 2014','Bruce, Erfani & Zilany 2018'};
ANmodelTypePopUp = uicontrol(modelParamPanel,'Style','popupmenu','String',...
    ANmodelTypeOptions,'Units','normalized','value',Which_AN,'Position',...
    [0.15,0.72,0.7,0.08],'Callback',{@ANmodelTypePopUpCallback});


h4=uicontrol(modelParamPanel,'Style','text','String','Number of fibers in each CF =',...
    'FontSize',8,'Units','normalized','Position',[0.02,0.61,0.6,0.1],'Visible','on');

nrEdit = uicontrol(modelParamPanel,'Style','edit','String','1',...
    'BackgroundColor','white','Units','normalized','Position',[0.7,0.66,0.15,0.07],'Visible','on');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Hearing Loss GUI %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

uicontrol(modelParamPanel,'Style','text','String',...
    'Audiogram  (dbHL)  : ','FontSize',8,'Units','normalized','Position',...
    [0.01,0.53,0.48,0.1]);  % OHC input text on GUI


OHCEdit = uicontrol(modelParamPanel,'Style','edit','String','0',...
    'BackgroundColor','white','Units','normalized','Position',[0.49,0.58,0.07,0.07]);
OHCEdit2 = uicontrol(modelParamPanel,'Style','edit','String','0',...
    'BackgroundColor','white','Units','normalized','Position',[0.56,0.58,0.07,0.07]);
OHCEdit3 = uicontrol(modelParamPanel,'Style','edit','String','0',...
    'BackgroundColor','white','Units','normalized','Position',[0.63,0.58,0.07,0.07]);
OHCEdit4 = uicontrol(modelParamPanel,'Style','edit','String','0',...
    'BackgroundColor','white','Units','normalized','Position',[0.70,0.58,0.07,0.07]);
OHCEdit5 = uicontrol(modelParamPanel,'Style','edit','String','0',...
    'BackgroundColor','white','Units','normalized','Position',[0.77,0.58,0.07,0.07]);
OHCEdit6 = uicontrol(modelParamPanel,'Style','edit','String','0',...
    'BackgroundColor','white','Units','normalized','Position',[0.84,0.58,0.07,0.07]);
OHCEdit7 = uicontrol(modelParamPanel,'Style','edit','String','0',...
    'BackgroundColor','white','Units','normalized','Position',[0.91,0.58,0.07,0.07]);

uicontrol(modelParamPanel,'Style','text','String',...
    'Frequencies  : ','FontSize',8,'Units','normalized','Position',...
    [0.01,0.47,0.48,0.1]);  % OHC input text on GUI

uicontrol(modelParamPanel,'FontSize',6.5,'Style','text','String','125',...
    'Units','normalized','Position',[0.50,0.53,0.06,0.04]);
uicontrol(modelParamPanel,'FontSize',6.5,'style','text','String','250',...
    'Units','normalized','Position',[0.57,0.53,0.06,0.04]);
uicontrol(modelParamPanel,'FontSize',6.5,'Style','text','String','500',...
    'Units','normalized','Position',[0.64,0.53,0.06,0.04]);
uicontrol(modelParamPanel,'FontSize',6.5,'Style','text','String','1e3',...
    'Units','normalized','Position',[0.71,0.53,0.06,0.04]);
uicontrol(modelParamPanel,'FontSize',6.5,'Style','text','String','2e3',...
    'Units','normalized','Position',[0.775,0.53,0.06,0.04]);
uicontrol(modelParamPanel,'FontSize',6.5,'Style','text','String','4e3',...
    'Units','normalized','Position',[0.845,0.53,0.06,0.04]);
uicontrol(modelParamPanel,'FontSize',6.5,'Style','text','String','8e3',...
    'Units','normalized','Position',[0.915,0.53,0.06,0.04]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CF Range GUI %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
uicontrol(modelParamPanel,'Style','text','String',...
    'CF Range (Hz):','FontSize',8,'Units','normalized','Position',...
    [0.04,0.39,0.6,0.1]); % CF Range text for GUI
CFEditLo = uicontrol(modelParamPanel,'Style','edit','String',num2str(cfRange(1)),...
    'BackgroundColor','white','Units','normalized','Position',[0.55,0.44,0.15,0.07]);
uicontrol(modelParamPanel,'Style','text','String',...
    'to','FontSize',8,'Units','normalized','Position',...
    [0.72,0.39,0.05,0.1]); % "To" text on GUI
CFEditHi = uicontrol(modelParamPanel,'Style','edit','String',num2str(cfRange(2)),...
    'BackgroundColor','white','Units','normalized','Position',[0.79,0.44,0.15,0.07]);
uicontrol(modelParamPanel,'Style','text','String',...
    'Number of Cfs=','FontSize',8,'Units','normalized','Position',...
    [0.05,0.3,0.6,0.1]); % Number of Fibers text on GUI
numFibersEdit = uicontrol(modelParamPanel,'Style','edit','String','50',...
    'BackgroundColor','white','Units','normalized','Position',[0.55,0.35,0.15,0.07]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   others   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

uicontrol(modelParamPanel,'Style','text','String',...
    'Species (AN)','FontSize',8,'Units','normalized','Position',...
    [0.03,0.23,0.6,0.1]); % Species text on GUI
speciesTypePopup = uicontrol(modelParamPanel,'Style','popupmenu','String',...
    {'Cat','Human (Shera tuning)'},'Units','normalized','Position',[0.5,0.27,0.4,0.07],'Value',2); % DEFAULT VALUE SET TO 2 (Human)

uicontrol(modelParamPanel,'Style','text','String',...`
    'Spont rate (AN)','FontSize',8,'Units','normalized','Position',...
    [0.05,0.16,0.6,0.1]); % Spont rate text on GUI
spontTypePopup = uicontrol(modelParamPanel,'Style','popupmenu','String',...
    {'Low','Med','High'},'Units','normalized','Position',[0.55,0.2,0.3,0.07],'Value',3); % DEFAULT VALUE SET TO 3 (High spont)

Displayoption = uicontrol(modelParamPanel,'Style','checkbox','Units','normalized',...
    'Position',[0.2,0.13,0.3,0.07],'String',{'Wide Display'},'Value',0,'Callback',@widedisplay); % checkbox to pull up wide display

uicontrol(modelParamPanel,'Style','text','String',...`                                  % Text - CF (Hz) for AN & IC PSTH's
    'CF (Hz) for AN & IC PSTHs:','FontSize',8,'Units','normalized','Position',...
    [0.01,0.003,0.6,0.1]);

Quickplot = uicontrol(modelParamPanel,'Style','pushbutton','String',...                 % Button to pull up AN & IC PSTH's
    {'Quickplot'},'Units','normalized','Position',[0.76,0.044,0.2,0.07],'Callback',@quickplot);

PSTH_CFedit = uicontrol(modelParamPanel,'Style','edit','String',...                     % edit CF for AN & IC PSTH's
    {'500'},'Units','normalized','Position',[0.57,0.044,0.15,0.07]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

modelTypePopUpCallback([],[]); %% Grab parameters specific to type of IC model selected

    function modelTypePopUpCallback(~,~)
        % allow user to select IC model from examples in Nelson & Carrey 2004, Fig. 8
        IC_model_just_changed = 0; % this allows past values to be retained
        if Which_IC ~= modelTypePopUp.Value
            IC_model_just_changed = 1; % flag that model type has changed
        end
        Which_IC = modelTypePopUp.Value;
        if Which_IC == 1  % SFIE model
            h2.Visible = 'off';
            h3.Visible = 'off';
            ICparam2Edit.Visible = 'off';
            h32.Visible = 'off';
            h1=  uicontrol(modelParamPanel,'Style','text','String','IC Models (Nelson & Carney, 2004;           Carney et al, 2015),    BMF(Hz) =',...
                'FontSize',8,'Units','normalized','Position',[0.02,0.82,0.75,0.1]);
            
            if IC_model_just_changed % use last value, unless model type has just been changed
                BMF = 100; % initial default when switching to SFIE model
                ICparamEdit.String = num2str(BMF);
            end
            
            BMF = str2double(char(ICparamEdit.String));
            ICparamEdit = uicontrol(modelParamPanel,'Style','edit','String',BMF,...
                'BackgroundColor','white','Units','normalized','Position',[0.79,0.85,0.15,0.07]);
            M = [];
            Delta = []; % not applicable for this model
        elseif Which_IC == 2  % AN_ModFilt model
            
            h1.Visible = 'off';
            h3.Visible = 'off';
            ICparam2Edit.Visible = 'off';
            h32.Visible = 'off';
            h2= uicontrol(modelParamPanel,'Style','text','String','Mod Filter (Mao et al, 2013), BMF(Hz) =',...
                'FontSize',8,'Units','normalized','Position',[0.02,0.82,0.75,0.07]);
            
            if IC_model_just_changed % use last value, unless model type has just been changed
                
                BMF = 100; % initial default when switching to AN_modfilt model
                ICparamEdit.String = num2str(BMF);
            end
            BMF = str2double(char(ICparamEdit.String));
            ICparamEdit = uicontrol(modelParamPanel,'Style','edit','String',BMF,...
                'BackgroundColor','white','Units','normalized','Position',[0.79,0.85,0.15,0.07]);
            
            M = [];
            Delta = [];
            
        elseif Which_IC==3
            h2.Visible = 'off';
            h1.Visible = 'off';
            h3= uicontrol(modelParamPanel,'Style','text','String','# inhibitory inputs',...
                'FontSize',7,'Units','normalized','Position',[0.02,0.8,1.2,0.1]);
            
            h32= uicontrol(modelParamPanel,'Style','text','String','sec coincidence window',...
                'FontSize',7,'Units','normalized','Position',[0,0.8,0.27,0.1]);           
            
            if IC_model_just_changed % use last value, unless model type has just been changed
                
                M = 30; % initial default when switching to EI_Krips&Furst model
                Delta = 100e-6;
                ICparamEdit.String = num2str(M);
                ICparam2Edit.String = num2str(Delta);
            end
            M = str2double(char(ICparamEdit.String));
            Delta = str2double(char(ICparam2Edit.String));
            ICparamEdit = uicontrol(modelParamPanel,'Style','edit','String',M,...
                'BackgroundColor','white','Units','normalized','Position',[0.79,0.85,0.15,0.07]);  % Initial default is 30 for M
            ICparam2Edit = uicontrol(modelParamPanel,'Style','edit','String',Delta,...
                'BackgroundColor','white','Units','normalized','Position',[0.29,0.85,0.15,0.07]);  % Initial default is 30 for M
            BMF = [];  % not applicable for this model
        end
    end
if Which_IC ~= 3
    h3.Visible = 'off';
    ICparam2Edit.Visible = 'off';
    h32.Visible = 'off';
end
if Which_IC ~= 2
    h2.Visible = 'off';
end
if Which_IC ~= 1
    h1.Visible = 'off';
end

ANmodelTypePopUpCallback([],[]);%% Grab parameters specific to type of AN model selected

    function ANmodelTypePopUpCallback(~,~)   
         AN_model_just_changed = 0; % this allows past values to be retained
        if Which_AN ~= modelTypePopUp.Value
            AN_model_just_changed = 1; % flag that model type has changed
        end
  Which_AN = ANmodelTypePopUp.Value;
  
  
  
  if Which_AN==1
    nrEdit.Visible='off';
    h4.Visible='off';
else
h4=uicontrol(modelParamPanel,'Style','text','String','Number of fibers in each CF =',...
    'FontSize',8,'Units','normalized','Position',[0.02,0.66,0.6,0.06],'Visible','on');

nrEdit = uicontrol(modelParamPanel,'Style','edit','String','1',...
    'BackgroundColor','white','Units','normalized','Position',[0.7,0.66,0.15,0.07],'Visible','on');

end
     
            
            
            
    end



%% Set up OK and CLOSE pushbuttons on lower left side of main panel
uicontrol(InputPanel,'Style','pushbutton', 'String','OK','BackgroundColor',...
    'white','FontSize',12,'Units','normalized','Position',[0.03 0.02 0.45 0.05],...
    'Callback',{@okButtonCallback}); % "OK"

uicontrol(InputPanel,'Style','pushbutton','String','Close','BackgroundColor',...
    'white','FontSize',12,'Units','normalized','Position',[0.52 0.02 0.45 0.05],...
    'Callback',{@closeButtonCallback}); % "CLOSE"

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Useful Nested Functions
    function hideAllExcept(handeCell,idx)
        for j = 1:numOptions
            handeCell{j}.Visible = 'off';
        end
        handeCell{idx}.Visible = 'on';
    end

    function output = boolToOnOff(bool)
        if bool == 0
            output = 'off';
        elseif bool == 1
            output = 'on';
        end
    end

    function idx = getVisibleIdx()
        idx = 0;
        for el = 1:numOptions
            if strcmp(stimParamPanel{el}.Visible,'on')
                idx = el;
                return
            end
        end
    end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%  CALLBACKS  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function okButtonCallback(~,~)  % Create stimuli and then run the model
        %% Clear old stimuli & Create new Stimuli
        
        if Displayoption.Value==1
            outputPanel2.Visible ='on';
        else
            outputPanel2.Visible ='off';
        end
        
        stimIdx = getVisibleIdx; % Read stimulus type from GUI
        stimdB = str2double(soundLevelEdit{stimIdx}.String);  % overall RMS level in dB SPL; This field is common for MOST stimuli - can read it in here
        
        if stimIdx > 1   % for all but stimulus type 1 read in dur & rampdur (dur is computed from wavfle for stim type 1)
            dur = str2double(stimParamEdit{stimIdx,1}.String);  % dur (sec); This field is common for all stimuli - can read it in here
            rampdur = str2double(stimParamEdit{stimIdx,2}.String);  % on/off ramp duration (sec); This field is common for all stimuli - can read it in here
        end
        
        strings = ['   ';'   '];
        title1 = cellstr(strings);  % Stimulus titles on GUI
        
        switch stimIdx
            % STIM: Each switch case is for a stimulus type, and defines input parameters
            % by calling items from the gui, and then calls a function to create waveform.
            % Case "n" is a template for a new stimulus; increment the value of "n" for new stim.
            % If your new stimus is a wavfile, the gui does not need to be edited (just use case 1).
            
            case 1 %Wav File   (Note: stimulus duration is computed from file, and no on/off ramp is applied.)
                % Add LTASS noise (add this option to GUI)
                add_LTASS_noise = 0;  SNR = 0; % Note that tukeywin is applied after noise is added (no tukeywin was used for 'plain' speech)
                title1{1} = (stimParamEdit{stimIdx,1}.String); % Filenames will be displayed on Output GUI
                title1{2} = (stimParamEdit{stimIdx,2}.String);
                nconditions = 1; % response to first wavfile (if other input filename was left blank by user, this will be only stimulus)
                wavfile1 = stimParamEdit{stimIdx,1}.String;
                [stim_temp, Fs_wav] = audioread(wavfile1);
                [p,q] = rat(Fs/Fs_wav,0.0001);% find two integers whose ratio matches the desired change in sampling rate
                Condition(1).stimulus = resample(stim_temp',p,q);% resample signal to have sampling rate required for AN model
                Condition(1).stimulus = 20e-6 * power(10,(stimdB/20)) * Condition(1).stimulus/rms(Condition(1).stimulus); % scale stim to have an rms = 1, then scale to desired dB SPL in Pascals.
               
                if add_LTASS_noise == 1                    % Make wideband LTASS noise (100 Hz - 6 kHz)
                  disp('Adding LTASS noise with SNR = 0');
                  ltass_SPL = stimdB - SNR;               
                  ltass_noise = ltass_noise0(Fs,ltass_SPL,length(Condition(1).stimulus),1); % note: function modified to handle Fs = 100kHz
                  ltass_ramp = 0.010;
                  ltass_dur = length(Condition(1).stimulus)/Fs;
                  gate = tukeywin(length(ltass_noise), 2*ltass_ramp/ltass_dur); %gating function 
                  ltass_noise = ltass_noise .* gate;
                  Condition(1).stimulus = Condition(1).stimulus + ltass_noise';      
                end
                clear stim_temp
                if isempty(stimParamEdit{stimIdx,2}.String) == false % for case when 2nd filename is entered
                    nconditions = 2; % responses to two wavefiles will be compared (two file names were input by user)
                    wavfile2 = stimParamEdit{stimIdx,2}.String;
                    [stim_temp, Fs_wav] = audioread(wavfile2);% read in wav file and it's sampling rate
                    [p,q] = rat(Fs/Fs_wav,0.0001);% find two integers whose ratio matches the desired change in sampling rate
                    Condition(2).stimulus = resample(stim_temp',p,q);% resample signal to have sampling rate required for AN model
                    Condition(2).stimulus = 20e-6 * power(10,(stimdB/20)) * Condition(2).stimulus/rms(Condition(2).stimulus); % scale stim to have an rms = 1, then scale to desired dB SPL in Pascals.
                    
                    if add_LTASS_noise == 1                    % Make wideband LTASS noise (100 Hz - 6 kHz)
                        disp('Adding LTASS noise with SNR = 0');
                        ltass_SPL = stimdB - SNR;
                        ltass_noise = ltass_noise0(Fs,ltass_SPL,length(Condition(1).stimulus),1); % note: function modified to handle Fs = 100kHz
                        ltass_ramp = 0.010;
                        ltass_dur = length(Condition(1).stimulus)/Fs;
                        gate = tukeywin(length(ltass_noise), 2*ltass_ramp/ltass_dur); %gating function
                        ltass_noise = ltass_noise .* gate;
                        Condition(2).stimulus = Condition(2).stimulus + ltass_noise';
                    end
                   clear stim_temp
                end
                
            case 2   % stimulus 2 = Noise Band; Edge Pitch
                nconditions = 1; % response to only 1 stimulus
                Low_freq = str2double(stimParamEdit{stimIdx,3}.String);
                High_freq = str2double(stimParamEdit{stimIdx,4}.String);
                Condition(1).stimulus = Noise(dur,rampdur,Low_freq,High_freq,stimdB,Fs);
                
            case 3   % stimulus 3 = Notched Noise
                nconditions = 2; % compare responses to 2 stimuli
                cf =      str2double(stimParamEdit{stimIdx,3}.String); % Hz; center freq of stimulus (not neuron's CF)
                delta =   str2double(stimParamEdit{stimIdx,4}.String); % UNITS (Notch width/2)/CF
                bw =      str2double(stimParamEdit{stimIdx,5}.String); % Hz for each noise band
                db_tone = str2double(stimParamEdit{stimIdx,6}.String); % dB SPL
                db_noise = str2double(soundLevelEdit{stimIdx}.String); % UNITS - overall RMS level (dB SPL)
                Condition(1).stimulus = Notched_Noise(dur,rampdur,cf,delta,bw,db_noise,  -99,  Fs); % No tone (-99 dB SPL)
                Condition(2).stimulus = Notched_Noise(dur,rampdur,cf,delta,bw,db_noise,db_tone,Fs); % Masker plus tone
                
            case 4   % stimulus 4 = TIN (Tone in Noise)
                nconditions = 2; % compare responses to 2 stimuli
                freq = str2double(stimParamEdit{stimIdx,3}.String);
                No= str2double(stimParamEdit{stimIdx,4}.String); % Noise masker spectrum level (dB SPL / Hz)
                Es_No = str2double(stimParamEdit{stimIdx,5}.String); % Tone level (E/No) ( see Evilsizer et al 2001 )
                SNR = str2double(stimParamEdit{stimIdx,6}.String); % This is calculate and displayed
                %                 if get(handles.binaural, 'Value') == true
                %                   bin_mode = 2; % 'bin_mode' = binaural mode >> Stay Tuned for Binaural version!
                %                 elseif get(handles.binaural, 'Value') == false
                %                   bin_mode = 1;
                %                 end
                bin_mode = 1; % for monaural stimulus, bin_mode = 1
                
                if stimCheckBox{stimIdx,1}.Value == 1
                    wideband_yn = 1; % wideband "yes no" flag
                else
                    wideband_yn = 0;
                end
                SNR_calc = 0; %At this point in the function, the TIN function will be run to generate a TIN stimulus, not just to calculate SNR.
                TINstruct = TIN(dur, rampdur, freq, No,Es_No,bin_mode,wideband_yn,Fs,SNR_calc); % call function to create stimuli
                switch bin_mode
                    case 1
                        Condition(1).stimulus = TINstruct.pin_N; % noise alone
                        Condition(2).stimulus = TINstruct.pin_TIN; % tone-plus-Noise
                        clear TINstruct
                    case 2
                        disp('Binaural TIN is not yet functional');
                        return
                end
                
            case 5    % stimulus 5 = Profile Analysis (see Lentz 2005)
                nconditions = 2; % compare responses to 2 stimuli
                ncomponents = str2double(stimParamEdit{stimIdx,3}.String);
                dB_incr = str2double(stimParamEdit{stimIdx,4}.String);
                Condition(1).stimulus = Profile_Analysis(dur,rampdur, ncomponents,   -99,     stimdB,Fs); % "-99 dB" is the unincremented spectrum
                Condition(2).stimulus = Profile_Analysis(dur,rampdur ,ncomponents, dB_incr, stimdB,Fs);
                
            case 6   % stimulus 6 = Pinna Cues
                nconditions = 1;
                fcenter = str2double(stimParamEdit{stimIdx,3}.String);
                Condition(1).stimulus = artificial_pinna_notch(dur, rampdur, fcenter, stimdB, Fs);
                
            case 7   % stimulus 8 = SAM Tone
                nconditions = 2;
                carrier_freq = str2double(stimParamEdit{stimIdx,3}.String);
                mod_freq = str2double(stimParamEdit{stimIdx,4}.String);
                mod_depth = str2double(stimParamEdit{stimIdx,5}.String);
                Condition(1).stimulus = SAM_Tone(dur, rampdur,carrier_freq,mod_freq,  -99,    stimdB,Fs); % unmodulated tone
                Condition(2).stimulus = SAM_Tone(dur, rampdur,carrier_freq,mod_freq,mod_depth,stimdB,Fs);
%                Condition(1).stimulus = SAM_Tone_residue(dur, rampdur,carrier_freq,mod_freq,mod_depth,stimdB,Fs,0); % SAM tone (choose harmonics)
%                Condition(2).stimulus = SAM_Tone_residue(dur, rampdur,carrier_freq,mod_freq,mod_depth,stimdB,Fs,40); % shifted SAM tone
                
            case 8 %Complex Tone
                nconditions = 1; % display response to only 1 stimulus
                f0 = str2double(stimParamEdit{stimIdx,3}.String);
                ncomponents = str2double(stimParamEdit{stimIdx,4}.String);
                filter_type = complexToneMenu.Value - 1;
                Wn_freq = str2num(complexFiltEdit.String); %  str2num handles vector inputs
                include_fundmntl = stimCheckBox{stimIdx,1}.Value;
                Condition(1).stimulus = complex_tone(dur, rampdur, f0,ncomponents,filter_type,Wn_freq,include_fundmntl,stimdB,Fs);
                
            case 9  % Single Formant - Lyzenga & Horst's triangular spectrum
                nconditions = 1; % display response to only 1 stimulus
                Fp = str2double(stimParamEdit{stimIdx,3}.String); % Peak Freq of spectral envelope (Hz)
                F0 = str2double(stimParamEdit{stimIdx,4}.String); % Fundamental freq (Hz)
                G = str2double(stimParamEdit{stimIdx,5}.String); % spectral slope (dB/oct)
                Condition(1).stimulus = generate_single_formant(dur, rampdur, F0, Fp, G, stimdB, Fs)';
                
            case 10   % Double Formant Klatt vowel
                nconditions = 1; % display response to only 1 stimulus
                F0 = str2double(stimParamEdit{stimIdx,3}.String); % Fundamental freq (Hz)
                formant_freqs = str2num(stimParamEdit{stimIdx,4}.String); % Vector of formant freqs (Hz)
                BWs = str2num(stimParamEdit{stimIdx,5}.String); % Vector of bandwidths for the formants (Hz)
                Condition(1).stimulus = klatt_vowel(dur, rampdur, F0, formant_freqs, BWs, stimdB, Fs);
                
            case 11 % Schroeder Phase Complex Tone
                nconditions = 2; % display response to 2 stimuli
                f0 = str2double(stimParamEdit{stimIdx,3}.String);
                ncomponents = str2double(stimParamEdit{stimIdx,4}.String);
                include_fundmntl = stimCheckBox{stimIdx,1}.Value;
                Cvalue = str2double(stimParamEdit{stimIdx,5}.String);
                dB_incr = -99; % This variable can be used for Schroeder masking simulations; turn it "off" for now
                SchrSign = +1;
                Condition(1).stimulus = schroeder(dur, rampdur, SchrSign*Cvalue, f0, ncomponents, dB_incr, include_fundmntl, stimdB, Fs);
                SchrSign = -1;
                Condition(2).stimulus = schroeder(dur, rampdur, SchrSign*Cvalue, f0, ncomponents, dB_incr, include_fundmntl, stimdB, Fs);
                
            case 12   % stimulus 12 = Noise-in-Notched Noise (Viemeister 1983)
                nconditions = 2; % compare responses to 2 stimuli
                % cf =      str2double(stimParamEdit{stimIdx,3}.String); % Hz; center freq of stimulus (not neuron's CF)
                %  delta =   str2double(stimParamEdit{stimIdx,4}.String); % UNITS (Notch width/2)/CF
                %  bw =      str2double(stimParamEdit{stimIdx,5}.String); % Hz for each noise band
                db_target_No = str2double(stimParamEdit{stimIdx,3}.String); % dB SPL spectrum level for standard target noise
                db_increment_So = str2double(stimParamEdit{stimIdx,4}.String); % dB increment for test target noise
                Condition(1).stimulus = Noise_in_Notched_Noise(dur,rampdur,db_target_No,-inf,Fs); % standard - target noise with No spectrum level
                Condition(2).stimulus = Noise_in_Notched_Noise(dur,rampdur,db_target_No,db_increment_So,Fs); % test - target noise with No+So spectrum level
                %   Condition(1).stimulus = Noise_in_Notched_Noise(dur,rampdur,cf,delta,bw,db_noise,  -inf,  Fs); % No target (-99 dB SPL)
                %   Condition(2).stimulus = Noise_in_Notched_Noise(dur,rampdur,cf,delta,bw,db_noise,db_target,Fs); % Masker plus target
                
            case 13   % stimulus 13 = FM Tone
                nconditions = 2;
                signalfreq = str2double(stimParamEdit{stimIdx,3}.String);
                C1_params = str2num(stimParamEdit{stimIdx,4}.String); % use str2num for vector inputs
                C2_params = str2num(stimParamEdit{stimIdx,5}.String);
                Condition(1).stimulus = FM_Tone(dur, rampdur,signalfreq,C1_params,stimdB,Fs);
                Condition(2).stimulus = FM_Tone(dur, rampdur,signalfreq,C2_params,stimdB,Fs);
                
            case 14   % stimulus 14 = Forward Masking
                nconditions = 2;
                % Param 1 = dur for all stimuli;  Param 2 = ramp >> use these for the masker
                mask_dur = dur; % read in as stimParamEdit{stimIdx,1}.String  above
                mask_ramp = rampdur; % read in as stimParamEdit{stimIdx,2}.String  above
                tmp = str2num(stimParamEdit{stimIdx,3}.String); % use str2num to read in a vector
                probe_dur = tmp(1);
                probe_level = tmp(2);
                mask_freq = str2double(stimParamEdit{stimIdx,4}.String);
                probe_freq = str2double(stimParamEdit{stimIdx,5}.String);
                delay = str2double(stimParamEdit{stimIdx,6}.String);
                [stim1, stim2] = Forward_masking_tones(mask_dur, mask_ramp, probe_dur, probe_level, mask_freq, probe_freq, delay, stimdB,Fs); % Condition(1) = Masker + probe; Condition(2) = Masker only
                Condition(1).stimulus = stim1;
                Condition(2).stimulus = stim2;
                
            case 15   % stimulus 15 = CMR Band widening
                nconditions = 2; % compare responses to 2 stimuli
                s_dur = str2double(stimParamEdit{stimIdx,1}.String);
                s_rampdur = str2double(stimParamEdit{stimIdx,2}.String);
                freq = str2double(stimParamEdit{stimIdx,3}.String);
                m_dur = str2double(stimParamEdit{stimIdx,7}.String);
                m_rampdur = str2double(stimParamEdit{stimIdx,8}.String);
                No= str2double(stimParamEdit{stimIdx,6}.String); % Noise masker spectrum level (dB SPL / Hz)
                tone_level = str2double(stimParamEdit{stimIdx,4}.String); % Tone level (E/No) ( see Evilsizer et al 2001 )
                bw = str2double(stimParamEdit{stimIdx,5}.String); % This is calculate and displayed
                bw_mod = str2double(stimParamEdit{stimIdx,9}.String);
                [stim1, stim2] = CMR_BW2(s_dur, m_dur, s_rampdur,m_rampdur, freq, bw,bw_mod,No,tone_level,Fs); % call function to create stimuli
                Condition(1).stimulus = stim1; % mod noise plus tone
                Condition(2).stimulus = stim2; % unmodulated noise-plus-tone
                
            case 16   % stimulus 16 = CMR Flanking Bands
                nconditions = 2; % compare responses to 2 stimuli
                freq = str2double(stimParamEdit{stimIdx,3}.String);
                No= str2double(stimParamEdit{stimIdx,4}.String); % Noise masker spectrum level (dB SPL / Hz)
                tone_level = str2double(stimParamEdit{stimIdx,5}.String); % Tone level (E/No) ( see Evilsizer et al 2001 )
                BW = str2double(stimParamEdit{stimIdx,6}.String); % This is calculate and displayed
                [stim1, stim2] = CMR_FB(dur, rampdur, freq, No, tone_level, BW, Fs); % call function to create stimuli
                Condition(1).stimulus = stim1; % comod noise plus tone
                Condition(2).stimulus = stim2; % codeviant noise-plus-tone
                
                %       case n    % Template for addition of new stimulus that is not a wavfile
                % Stimulus waveforms must be in scaled into pascals in stimulus function code.
                % Must pass sampling frequency (Fs) to stimulus code;
                % stimulus level in dB, Duration, and on/off ramp durations are read in above.
                % If only 1 stimulus waveform is to be used, set nconditions = 1 and use Condition(1).stimulus (see noise example above)
                % Condition(1).stimulus may be a null or baseline stimulus to compare against
                %(i.e. noise without a tone, a tone complex without an increment in the center, etc.)
                % Condition(1).stimulus = mystimulus(dur, rampdur, param1, param2, ..., param6, stimdB, Fs);
                % Then comparison stimulus should be placed in Condition(2):
                % Condition(2).stimulus = mystimulus(dur, rampdur, param1, param2, ..., param6, stimdB, Fs);
        end
        
        %% Model Parameters
        minCF = str2double(char(CFEditLo.String));
        maxCF = str2double(char(CFEditHi.String));
        CF_num =str2double(char(numFibersEdit.String));
        fiber_num = str2double(char(nrEdit.String));
        CF_range = [minCF, maxCF];
               
        dbloss1= str2double(char(OHCEdit.String));  % Hearing loss in decibels, to determine Cohc and Cihc for model
        dbloss2= str2double(char(OHCEdit2.String));  %   using function from Bruce and Zilany models, as in Bruce et al 2018 code
        dbloss3= str2double(char(OHCEdit3.String));
        dbloss4= str2double(char(OHCEdit4.String));
        dbloss5= str2double(char(OHCEdit5.String));
        dbloss6= str2double(char(OHCEdit6.String));
        dbloss7= str2double(char(OHCEdit7.String));
        ag_dbloss=[dbloss1,dbloss2,dbloss3,dbloss4,dbloss5,dbloss6,dbloss7];
        ag_fs = [125 250 500 1e3 2e3 4e3 8e3];  % audiometric frequencies
               
        %% Call Model and Plotting code
        UR_EAR_model_plots(Condition,nconditions,Which_IC,Which_AN,ag_fs,ag_dbloss,fiber_num,Fs,CF_range,CF_num,stimIdx,title1);
    end

    function closeButtonCallback(~,~)
        close(mainFig)
    end

    function stimBoxCallback(~,~,panelIdx,switchIdx)
        stimCheckBox{panelIdx,switchIdx}.Value = 0;
        StimStrings = stimTypeMenu.String;
        if strcmp(StimStrings{stimTypeMenu.Value}, 'Tone in Noise') == true
            SNR_display_callback([],[])
        end
    end

    function stimTypeMenuCallback(~,~)
        hideAllExcept(soundLevelPanel,stimTypeMenu.Value) % Display the appropriate parameter boxes for the selected stimulus
        hideAllExcept(stimParamPanel,stimTypeMenu.Value)  % Ditto
    end

    function filterTypeCallback(~,~)
        if complexToneMenu.Value == 1
            complexFiltEdit.Visible = 'off';
            complexFilttxt.Visible = 'off';
        else
            complexFiltEdit.Visible = 'on';
            complexFilttxt.Visible = 'on';
        end
    end

%%  Main Model code and plotting functions
    function UR_EAR_model_plots(Condition,nconditions,which_IC,Which_AN,ag_fs,ag_dbloss,fiber_num,Fs,CF_range,CF_num,stim_type,title1,M,Delta)
        
        % Display AN and IC population responses as a function of
        % Characteristic Frequency (CF) and Best Modulation Frequency (BMF).
        % Inputs: Condition.stimulus (pressure input, in pascals)
        %         cohc = Outer hair cell function (0-1 where 1 is normal)
        %         cihc = inner hair cell function
        
        RsFs = 10000;  %Resample rate for time_freq surface plots
        colors = ['g', 'b', 'r']; % colors for plots & labels of each stimulus condition
        
        clicks_wave = 1;   %  Initialize counters for toggling plots between conditions - Stimulus waveform plot
        clicks_wave_wide = 1;
        clicks_spectrogram = 1;  % Spectrogram plot
        clicks_spectrogram_wide =1;
        clicks_CFspec = 1;       % Spectrum over CF range
        clicks_vihc_timefreq = 1;  % AN time_freq plot
        clicks_ic_timefreq_wide =1;
        clicks_an_timefreq = 1;  % AN time_freq plot
        clicks_an_timefreq_wide =1;
        clicks_ic_timefreq = 1;  % IC time_freq plot
        clicks_ic_averate = 1;   % For toggling between IC BP and IC BS
        
        %% Set up main GUI title for Stimulus type and Conditions
        titles = {{'.wav file(s)',title1{1},title1{2}},{'Noise Band (Edge Pitch)','',''},...
            {'Notched Noise','Without Tone', 'With Tone'},{'Tone in Noise','Without Tone','With Tone'},...
            {'Profile Analysis','Without Increment','With Increment'},{'Pinna Cues','Notch',''},...
            {'SAM Tone','Unmodulated','Modulated'},...
            {'Complex Tone','',''},{'Single Formant','',''},...
            {'Double Formant','',''},{'Schroeder','Positive C Value','Negative C Value'},...
            {'Noise in Notched Noise','Standard','Test (w/Increment)'},{'Fm Tone','Signal','Ref'},...
            {'Forward Masking','Mask+Probe','Mask only'},{'CMR Band Widen', 'Mod With Tone', 'Unmod With Tone'},...
            {'CMR Flank Band', 'Comod With Tone', 'Codev With Tone'}}; % STIM
        
        wide = Displayoption.Value;
        
        uicontrol(mainFig,'style','text','String', titles{stim_type}{1}, 'FontSize',16,...
            'units','normalized','position', [(300/950),(840/900)+.005,100/950,50/900]); % Put title on GUI
        uicontrol(mainFig,'style','text','String', 'UR_EAR 2.1 monaural', 'FontSize',16, 'units',...
            'normalized','position', [(720/950),(860/900),200/950,30/900]); % Put UR_EAR logo on GUI
        a= uicontrol(mainFig,'style','text','String', 'Left Click on a plot to toggle conditions; Right click to "detach" plot.', 'FontSize',10, 'units',...
            'normalized','position', [(450/950),(20/900),400/950,20/900]); % Helpful Note
        
        if wide == 2
            a.Visible = 'off';
        end
        
        uicontrol(mainFig,'style','text','String', ' ','FontSize',12, 'units','normalized','position', [410/950,870/900,180/950,25/900]);
        % uicontrol(mainFig,'style','text','String', ' ','FontSize',15, 'units','normalized','position', [450/950,845/900,50/950,25/900]);
        uicontrol(mainFig,'style','text','String', ' ','FontSize',12, 'units','normalized','position', [410/950,840/900,180/950,25/900]);
        %  uicontrol(mainFig,'style','text','String', ' ','FontSize',12, 'units','normalized','position', [450/950,875/900,50/950,25/900]);
        %Show new titles
        condition_string1 = uicontrol(mainFig,'style','text','String', horzcat('C1: ', titles{stim_type}{2}),...
            'FontSize',14, 'units','normalized','position', [410/950,870/900,180/950,25/900]);
        set(condition_string1, 'ForegroundColor', colors(1));
        if nconditions > 1
            condition_string2 = uicontrol(mainFig,'style','text','String', horzcat('C2: ', titles{stim_type}{3}),...
                'FontSize',14, 'units','normalized','position', [410/950,840/900,180/950,25/900]);
            set(condition_string2, 'ForegroundColor', colors(2));
        end
        
        %% Play button(s)
        uicontrol(mainFig,'style','text','String', '<< Play Stimulus', 'FontSize',12,...
            'units','normalized','position', [615/950,865/900,100/950,20/900]); % Put "Play" string on GUI
        axes('Units', 'normalized', 'Visible', 'on','position',[450/950,875/900,50/950,25/900],'Parent', outputPanel);
        playim1 = imagesc(imread('play.jpg'));
        axis image;
        axis off
        set(playim1,'HitTest','on','ButtonDownFcn',@playim1_callback)       
        
        axes('Units', 'normalized', 'Visible', 'on','position',[450/950,875/900,50/950,25/900],'Parent', outputPanel2);
        playim1w = imagesc(imread('play.jpg'));
        axis image;
        axis off
        set(playim1w,'HitTest','on','ButtonDownFcn',@playim1_callback)

         if nconditions > 1  % add second play button when two stimuli are used
            axes('Units', 'normalized', 'Visible', 'on','position',[450/950,845/900,50/950,25/900],'Parent', outputPanel);
            playim2 = imagesc(imread('play.jpg'));
            axis image;
            axis off
            set(playim2,'HitTest','on','ButtonDownFcn',@playim2_callback)
            
            axes('Units', 'normalized', 'Visible', 'on','position',[450/950,845/900,50/950,25/900],'Parent', outputPanel2);
            playim2w = imagesc(imread('play.jpg'));
            axis image;
            axis off
            set(playim2w,'HitTest','on','ButtonDownFcn',@playim2_callback)
            
        end
        
        function  playim1_callback(~,~)
            sound(Condition(1).stimulus, Fs)
        end
        
        function  playim2_callback(~,~)
            if nconditions == 2  % only play stim #2 if nconditions = 2
                sound(Condition(2).stimulus, Fs)
            end
        end
        
        
        %% Model Selection and Parameters
        
        % Number of stimulus repetitions (only 1 rep is needed if probability of firing is displayed - more reps needed for looking at spike times)
        
        fiberType = spontTypePopup.Value;      % AN fiber type. (1 = low SR, 2 = medium SR, 3 = high SR)
        implnt = 0;         % 0 = approximate model, 1=exact powerlaw implementation(See Zilany etal., 2009)
        noiseType = 1;      % 0 for fixed fGn (1 for variable fGn) - this is the 'noise' associated with spontaneous activity of AN fibers - see Zilany et al., 2009. "0" lets you "freeze" it.
        species = speciesTypePopup.Value;% 1=cat; 2=human AN model parameters (with Shera tuning sharpness)
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
        
        %% Check for NaN in stimulus - this prevents NaN from being passed into .mex files and causing MATLAB to close
        for NaN_check_i = nconditions
            if sum(isnan(Condition(NaN_check_i).stimulus))>0
                error('One or more fields of the UR_EAR input were left blank or completed incorrectly.')
            end
        end
        
        %% Set up and RUN the simulation
        % Loop through conditions
        stimIdx = getVisibleIdx;
        nrep=1;
        for iicondition = 1:nconditions % One or Two stimulus conditions
            
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
        
        %% Stimulus Plot 1: Stimulus Waveform - Toggle between responses to two STIMULI
        stim_waveformplot_wide_callback([],[]);
        function  stim_waveformplot_wide_callback(~,~)
            axes(stim_waveform_axes_wide)
            cla('reset') % clear previous plot and axis labels
            clicks_wave_wide = clicks_wave_wide + 1; % toggle index
            stim_plot = rem(clicks_wave_wide,nconditions) + 1; % this will always be "1" when nconditions = 1
            plot(stim_waveform_axes_wide,(0:(length(Condition(stim_plot).stimulus)-1))/Fs,Condition(stim_plot).stimulus,'color',colors(stim_plot), 'HitTest', 'off'); % plot stim #1 as initial plot
            
            set(stim_waveform_axes_wide,'ButtonDownFcn',@stim_waveformplot_wide_callback)
            title(stim_waveform_axes_wide,'Stimulus Waveform')
            xlim([0,(length(Condition(stim_plot).stimulus)-1)/Fs]) %BNM 7/25/16
            ylabel('Amplitude (Pa)')
            %   set(gca,'TickDir','out','XtickLabel',[])
            xlabel('Time (sec)')
            stim_waveform_axes_wide.Visible = 'on'; % Make this plot visible
            make_detachable(stim_waveform_axes_wide) % allows plot to be detached and enlarged by right-click on axis
            switch stim_plot
                case 1
                    title('\color{black}Spectrogram:\color{green} C1')
                case 2
                    title('\color{black}Spectrogram:\color{blue} C2')
            end
        end
        stim_waveformplot_callback([],[]); % explicit call to callback function for initial plot
        function  stim_waveformplot_callback(~,~)
            axes(stim_waveform_axes)
            cla('reset') % clear previous plot and axis labels
            clicks_wave = clicks_wave + 1; % toggle index
            stim_plot = rem(clicks_wave,nconditions) + 1; % this will always be "1" when nconditions = 1
            plot(stim_waveform_axes,(0:(length(Condition(stim_plot).stimulus)-1))/Fs,Condition(stim_plot).stimulus,'color',colors(stim_plot), 'HitTest', 'off'); % plot stim #1 as initial plot
            set(stim_waveform_axes,'ButtonDownFcn',@stim_waveformplot_callback)
            title(stim_waveform_axes,'Stimulus Waveform')
            xlim([0,(length(Condition(stim_plot).stimulus)-1)/Fs]) %BNM 7/25/16
            ylabel('Amplitude (Pa)')
            xlabel('Time (sec)')
            stim_waveform_axes.Visible = 'on'; % Make this plot visible
            make_detachable(stim_waveform_axes) % allows plot to be detached and enlarged by right-click on axis
            switch stim_plot
                case 1
                    title('\color{black}Spectrogram:\color{green} C1')
                case 2
                    title('\color{black}Spectrogram:\color{blue} C2')
            end
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Plot 2: Spectrogram of stimulus - Toggle between responses to two STIMULI
        
        spec_plot_wide_callback([],[]); % explicit call to callback function for initial plot
        function spec_plot_wide_callback(~,~)
            clicks_spectrogram_wide = clicks_spectrogram_wide +1; % toggle index
            axes(spectrogram_plot_wide)
            cla('reset') % clear previous plot and axis labels
            stim_plot = rem(clicks_spectrogram_wide,nconditions) + 1; % this will always be "1" when nconditions = 1
            [sg,Ftmp,Ttmp] = spectrogram(Condition(stim_plot).stimulus,hanning(1000),[],2000,Fs); % 50% overlap (using even #'s to avoid "beating" with F0 for speech)
            spec_image = pcolor(Ttmp,Ftmp,abs(sg));
            shading interp; % 'flat' omits grid lines
            ylim([0.9*CF_range(1) 1.1*CF_range(2)]);
            ylim([0 1000]);
            set(spec_image,'HitTest','off'); %Hit Test must be turned off for button down function to work
            switch stim_plot
                case 1
                    title('\color{black}Spectrogram:\color{green} C1')
                case 2
                    title('\color{black}Spectrogram:\color{blue} C2')
            end
            set(spectrogram_plot_wide, 'ButtonDownFcn',@spec_plot_wide_callback);
            ylabel('Frequency (Hz)')
            % set(gca,'TickDir','out','XtickLabel',[])
            caxis([0 25]) % selected based on 65 dB SPL speech
            xlim([0,(length(Condition(stim_plot).stimulus)-1)/Fs]) %BNM 7/25/16
            spectrogram_plot_wide.Visible = 'on'; % Make this plot visible
            make_detachable(spectrogram_plot_wide)
        end
        
        spec_plot_callback([],[]); % explicit call to callback function for initial plot
        function spec_plot_callback(~,~)
            clicks_spectrogram = clicks_spectrogram +1; % toggle index
            axes(spectrogram_plot)
            cla('reset') % clear previous plot and axis labels
            stim_plot = rem(clicks_spectrogram,nconditions) + 1; % this will always be "1" when nconditions = 1
            [sg,Ftmp,Ttmp] = spectrogram(Condition(stim_plot).stimulus,hanning(1000),[],2000,Fs); % 50% overlap (using even #'s to avoid "beating" with F0 for speech)
            spec_image = pcolor(Ttmp,Ftmp,abs(sg));
            shading interp; % 'flat' omits grid lines
            ylim([0.9*CF_range(1) 1.1*CF_range(2)]);
            set(spec_image,'HitTest','off'); %Hit Test must be turned off for button down function to work
            switch stim_plot
                case 1
                    title('\color{black}Spectrogram:\color{green} C1')
                case 2
                    title('\color{black}Spectrogram:\color{blue} C2')
            end
            set(spectrogram_plot, 'ButtonDownFcn',@spec_plot_callback);
            ylabel('Frequency (Hz)')
            %set(gca,'TickDir','out','XtickLabel',[])
            caxis([0 25]) % selected based on 65 dB SPL speech
            %   caxis([0 40]) % selected based on 75 dB SPL speech
            %   xlabel('Time (sec)')
            xlim([0,(length(Condition(stim_plot).stimulus)-1)/Fs]) %BNM 7/25/16
            spectrogram_plot.Visible = 'on'; % Make this plot visible
            make_detachable(spectrogram_plot)
        end
        
        %% Plot 3: Spectrum of stimulus in CF range - Toggle between two STIMULI       
        
        spec_plot_CF_callback([],[]) % explicit call to callback for initial plot
        function  spec_plot_CF_callback(~,~)
            axes(spectrum_plot_CF_range)
            cla('reset')
            clicks_CFspec = clicks_CFspec + 1; % toggle counter
            stim_plot = rem(clicks_CFspec,nconditions) + 1; % this will always be "1" when nconditions = 1
            m = length(Condition(stim_plot).stimulus);
            nfft = pow2(nextpow2(m));  % Find next power of 2
            spectrum_plot = 20* log10(abs(2*fft(Condition(stim_plot).stimulus,nfft)/m/20e-6)); % see: http://12000.org/my_notes/on_scaling_factor_for_ftt_in_matlab/.
            %spectrum_plot = 20*log10(abs(fft(Condition(stim_plot).stimulus)/numel(Condition(stim_plot).stimulus)/20e-6)); % this normalization was missing in v1.0
            specplot_max = -inf; % intialize
            for icond = 1:nconditions  % use overall max (across nconditions) value for upper limit of ylim
                specplot_max = max(specplot_max, max(20* log10(abs( fft(Condition(stim_plot).stimulus,nfft)/nfft/20e-6))));
            end
            fres = Fs/nfft; % freq resolution = 1/Dur
            if plot_type(stimIdx) == 0 % linear axes
                plot(spectrum_plot_CF_range,fres*(0:nfft-1),spectrum_plot,'HitTest','off','color',colors(stim_plot));
            elseif plot_type(stimIdx) == 1 % log axes
                semilogx(spectrum_plot_CF_range,fres*(0:nfft-1),spectrum_plot,'HitTest','off','color',colors(stim_plot));
                %               semilogx(spectrum_plot_CF_range,fres*(0:nfft-1),spectrum_plot,'HitTest','off','color','k','linewidth',2); % black line, for figure
            end
            xlim(spectrum_plot_CF_range, [CF_range(1) CF_range(2)])
            ylim(spectrum_plot_CF_range, [(specplot_max - 40), specplot_max+10]) % plot 50 dB worth of spectral magnitudes
            title(spectrum_plot_CF_range,'Spectrum over CF range')
            ylabel('Magnitude (dB SPL)')
            xlabel('Frequency (Hz)')
            set(spectrum_plot_CF_range, 'XTick',[100 200 500 1000 2000 5000 10000]); % only labels within CF range will be used
            set(spectrum_plot_CF_range, 'ButtonDownFcn',@spec_plot_CF_callback);
            spectrum_plot_CF_range.Visible = 'on'; % Make this plot visible
            switch stim_plot
                case 1
                    title('\color{black}Spectrogram:\color{green} C1')
                case 2
                    title('\color{black}Spectrogram:\color{blue} C2')
            end
            make_detachable(spectrum_plot_CF_range)
            
        end
        
        %% Plot 3: VIHC Response - Time-Freq plot - Toggle between responses to two STIMULI
        VIHC_response_time_callback([],[]); % Explicitly call the callback function to make initial plot
        function  VIHC_response_time_callback(~,~)
            axes(VIHC_response_time);
            cla('reset')
            clicks_vihc_timefreq = clicks_vihc_timefreq + 1;
            vihc_clicks_stim = rem(clicks_vihc_timefreq,nconditions) + 1;
            
            data=Condition(vihc_clicks_stim).VIHC_population(:,floor(0.01*RsFs):floor(dur*RsFs));
            plotcolor = pcolor(VIHC_response_time,(1:length(data))/RsFs,CFs,data);
            
            plotcolor.HitTest = 'off';
            set(VIHC_response_time, 'ButtonDownFcn', @VIHC_response_time_callback);
            shading(VIHC_response_time,'interp');
            caxis([-.005 0.015]); % based on 75 dB SPL speech
            
            set(gca,'view',[0 90])
            
            switch vihc_clicks_stim
                case 1
                    title('\color{black}IHC Model:\color{green} C1')
                case 2
                    title('\color{black}IHC Model:\color{blue} C2')
            end
            ylabel('IHC BF (Hz)')
            if nconditions > 1
            xlim([0,(min(length(Condition(1).stimulus),length(Condition(2).stimulus))-1)/Fs]) %BNM 7/25/16
            else
               xlim([0,(length(Condition(1).stimulus)-1)/Fs]) 
            end
            
            c2=colorbar;  % set up and position the color bar for spike rate
            title(c2,'mV');
            VIHC_response_time.Units = 'pixels';
            x12=get(VIHC_response_time,'position');
            c2.Units = 'pixels';
            x32=get(c2,'Position');
            x32(3)= x32(3)*.5;
            x32(1)= x32(1)+60;
            x32(4) = x12(4);
            x32(2) = x12(2);
            set(c2,'Position',x32)
            set(VIHC_response_time,'position',x12)
            set(VIHC_response_time, 'Units', 'normalized')
            set(c2, 'Units', 'normalized')
            
            make_detachable(VIHC_response_time)
        end
        
        
        %% Plot 4: AN Response - Time-Freq plot - Toggle between responses to two STIMULI
        AN_response_time_callback([],[]); % Explicitly call the callback function to make initial plot
        
        function  AN_response_time_callback(~,~)
            axes(AN_response_time);
            cla('reset')
            clicks_an_timefreq = clicks_an_timefreq + 1;
            an_clicks_stim = rem(clicks_an_timefreq,nconditions) + 1;
            
            if Which_AN==1
          %      data=Condition(an_clicks_stim).an_sout_population(:,floor(0.01*RsFs):floor(dur*RsFs));
                data=Condition(an_clicks_stim).an_sout_population;  %LHC  9/20/18

                plotcolor = pcolor(AN_response_time,(1:length(data))/RsFs,CFs,data);
                plotcolor.HitTest = 'off';
            end
            if Which_AN==2
                data=Condition(an_clicks_stim).an_sout_population_plot(:,floor(0.01*Fs/16):floor(dur*Fs/16));
                plotcolor = pcolor(AN_response_time,(1:length(data))*16/Fs,CFs,data);
                plotcolor.HitTest = 'off';
                %      imagesc(t_ft,CFs,data);
                
            end
            
            
            set(AN_response_time, 'ButtonDownFcn', @AN_response_time_callback);
            shading(AN_response_time,'interp');
            set(gca,'view',[0 90])
            axis square
            
            
            switch an_clicks_stim
                case 1
                    title('\color{black}AN Model:\color{green} C1')
                case 2
                    title('\color{black}AN Model:\color{blue} C2')
            end
            ylabel('AN BF (Hz)')
            set(gca,'TickDir','out')
            xlabel('Time (sec)')
            if stimIdx ~= 14  % for Forward masking, plot entire response window
                xlim([((dur/2) - 0.025) ((dur/2) + 0.025)]) % for most stimuli, plot only 50 ms window, in middle of stimulus waveform
            end
            
            c2=colorbar;  % set up and position the color bar for spike rate
            title(c2,'spikes/sec');
            AN_response_time.Units = 'pixels';
            x12=get(AN_response_time,'position');
            c2.Units = 'pixels';
            x32=get(c2,'Position');
            x32(3)= x32(3)*.5;
            x32(1)= x32(1)+60;
            x32(4) = x12(4);
            x32(2) = x12(2);
            set(c2,'Position',x32)
            set(AN_response_time,'position',x12)
            set(AN_response_time, 'Units', 'normalized')
            set(c2, 'Units', 'normalized')
            make_detachable(AN_response_time)
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%for wide display %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        AN_response_time_wide_callback([],[]); % Explicitly call the callback function to make initial plot
        
        function  AN_response_time_wide_callback(~,~)
            axes(AN_response_time_wide);
            cla('reset')
            clicks_an_timefreq_wide = clicks_an_timefreq_wide + 1;
            an_clicks_stim = rem(clicks_an_timefreq_wide,nconditions) + 1;
            
            
            if Which_AN==1
                data=Condition(an_clicks_stim).an_sout_population(:,floor(0.01*RsFs):floor(dur*RsFs));
                plotcolor = pcolor(AN_response_time_wide,(1:length(data))/RsFs,CFs,data);
                plotcolor.HitTest = 'off';
                
                if nconditions > 1
                 caxis([0 max(max(Condition(1).an_sout_population(:)),max(Condition(2).an_sout_population(:)))]);
                else
                 caxis([0 (max(Condition(1).an_sout_population(:)))]);    
                end
            end
            
            if Which_AN==2
                data=Condition(an_clicks_stim).an_sout_population_plot(:,floor(0.01*Fs/16):floor(dur*Fs/16));
                plotcolor = pcolor(AN_response_time_wide,(1:length(data))*16/Fs,CFs,data);
                plotcolor.HitTest = 'off';
                 if nconditions > 1
                 caxis([0 max(max(Condition(1).an_sout_population_plot(:)),max(Condition(2).an_sout_population_plot(:)))]);        
                 else
                    caxis([0 max(Condition(1).an_sout_population_plot(:))]);   
                 end
                 
            end
                       
            set(AN_response_time_wide, 'ButtonDownFcn', @AN_response_time_wide_callback);
            shading(AN_response_time_wide,'interp');
    
         
            
            switch an_clicks_stim
                case 1
                    title('\color{black}AN Model:\color{green} C1')
                case 2
                    title('\color{black}AN Model:\color{blue} C2')
            end
            
            ylabel('AN BF (Hz)') ; % or:   ylabel('AN BF (Hz), Log')
            
            
            if nconditions > 1
            xlim([0,(min(length(Condition(1).stimulus),length(Condition(2).stimulus))-1)/Fs]) ;%BNM 7/25/16
            else
            xlim([0,(length(Condition(1).stimulus)-1)/Fs]) ;%BNM 7/25/16
            end
            
            
            c2=colorbar;  % set up and position the color bar for spike rate
            title(c2,'spikes/sec');
            AN_response_time_wide.Units = 'pixels';
            x12=get(AN_response_time_wide,'position');
            c2.Units = 'pixels';
            x32=get(c2,'Position');
            x32(3)= x32(3)*.5;
            x32(1)= x32(1)+60;
            x32(4) = x12(4);
            x32(2) = x12(2);
            set(c2,'Position',x32)
            set(AN_response_time_wide,'position',x12)
            set(AN_response_time_wide, 'Units', 'normalized')
            set(c2, 'Units', 'normalized')
            make_detachable(AN_response_time_wide)
        end
        
        %% Plot 5: IC BE Response - Time-Freq plot - Toggle between responses to two STIMULI      
        
        IC_response_time_callback([],[]); % Explicitly call the callback function here, for initial plot
        
        function  IC_response_time_callback(~,~)
            axes(IC_response_time); % include this so that even on 1st iteration it will use the correct axes
            cla('reset')
            clicks_ic_timefreq = clicks_ic_timefreq + 1; % increment "click" counter each time the plot is clicked upon
            ic_clicks_stim = rem(clicks_ic_timefreq,nconditions) + 1;  % scroll through the # of possible condition plots
            data = Condition(ic_clicks_stim).BE_sout_population;
                       
            IC_time_BF_plot = pcolor(IC_response_time,(0:length(data)-1)/RsFs,CFs,data);
            IC_time_BF_plot.HitTest = 'off';
             
            set(IC_response_time, 'ButtonDownFcn', @IC_response_time_callback);
            shading(IC_response_time,'interp');
            set(gca,'view',[0 90])
            axis square
            
            switch ic_clicks_stim
                case 1
                    title('\color{black}IC Model (BE Cell):\color{green} C1')
                case 2
                    title('\color{black}IC Model (BE Cell):\color{blue} C2')
            end
            set(gca,'TickDir','out')
            ylabel('IC BF (Hz)')
            xlabel('Time (sec)')
            xlim([((dur/2) - 0.025) ((dur/2) + 0.025)]) % plot 50 ms window, in middle of stimulus waveform
            
            c4 = colorbar;
            title(c4,'spikes/sec');
            IC_response_time.Units = 'pixels';
            x11=get(IC_response_time,'position');
            c4.Units = 'pixels';
            x31=get(c4,'Position');
            x31(3)= x31(3)*.5;
            x31(1)= x31(1)+60;
            x31(4) = x11(4);
            x31(2) = x11(2);
            set(c4,'Position',x31)
            set(IC_response_time,'position',x11)
            set(IC_response_time, 'Units', 'normalized')
            set(c4, 'Units', 'normalized')
            make_detachable(IC_response_time)
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% for wide display%%%%%%%%%%%%%%%%%%%%%%%%
        
        IC_response_time_wide_callback([],[]); % Explicitly call the callback function here, for initial plot
        
        function  IC_response_time_wide_callback(~,~)
            
            axes(IC_response_time_wide); % include this so that even on 1st iteration it will use the correct axes
            cla('reset')
            clicks_ic_timefreq_wide = clicks_ic_timefreq_wide + 1; % increment "click" counter each time the plot is clicked upon
            ic_clicks_stim = rem(clicks_ic_timefreq_wide,nconditions) + 1;  % scroll through the # of possible condition plots
            data = Condition(ic_clicks_stim).BE_sout_population;
            % LOG CF axis            IC_time_BF_plot = pcolor(IC_response_time,(0:length(data)-1)/RsFs,log10(CFs),data);
            
            IC_time_BF_plot = pcolor(IC_response_time_wide,(0:length(data)-1)/RsFs,CFs,data);
            IC_time_BF_plot.HitTest = 'off';           
            
            set(IC_response_time_wide, 'ButtonDownFcn', @IC_response_time_wide_callback);
            shading(IC_response_time_wide,'interp');
  %          caxis([0 100])
  if nconditions> 1
     caxis([0 max(max(Condition(1).BE_sout_population(:)),max(Condition(2).BE_sout_population(:)))]);     
  else
    caxis([0 max(Condition(1).BE_sout_population(:))]);    
  end
  
            switch ic_clicks_stim
                case 1
                    title('\color{black}IC Model (BE Cell):\color{green} C1')
                case 2
                    title('\color{black}IC Model (BE Cell):\color{blue} C2')
            end
            set(gca,'TickDir','out')
            % Log CFs          ylabel('IC BF (Hz), Log')
            ylabel('IC BF (Hz)')
            xlabel('Time (sec)')
            if nconditions> 1
            xlim([0,(min(length(Condition(1).stimulus),length(Condition(2).stimulus))-1)/Fs]) %BNM 7/25/16
            else
            xlim([0,((length(Condition(1).stimulus))-1)/Fs]) %BNM 7/25/16    
            end
            c4 = colorbar;
            title(c4,'spikes/sec');
            IC_response_time_wide.Units = 'pixels';
            x11=get(IC_response_time_wide,'position');
            c4.Units = 'pixels';
            x31=get(c4,'Position');
            x31(3)= x31(3)*.5;
            x31(1)= x31(1)+60;
            x31(4) = x11(4);
            x31(2) = x11(2);
            set(c4,'Position',x31)
            set(IC_response_time_wide,'position',x11)
            set(IC_response_time_wide, 'Units', 'normalized')
            set(c4, 'Units', 'normalized')
            make_detachable(IC_response_time_wide)
        end
        
        %% Plot 6: Average AN Model Response %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        AN_response_avg_callback([],[]); % explicit call to callback function for initial plot
        
        function  AN_response_avg_callback(~,~)
            axes(AN_response_avg)
            cla('reset')
            for iicondition = 1:nconditions
                if iicondition == 1; cla('reset'); end % clear only before 1st condition is plotted
                if plot_type(stimIdx) == 0
                    plot(CFs, Condition(iicondition).AN_average,'linewidth',2,'color',colors(iicondition)) % linear axes
                else
                    semilogx(CFs, Condition(iicondition).AN_average,'linewidth',2,'color',colors(iicondition)) % log axes
                end
                hold on
            end
            xlim([CF_range(1) CF_range(2)]);
            ylim([0,350]) % fix rate (sp/sec) axis to allow comparisons
            set(gca, 'XTick',[100 200 500 1000 2000 5000 10000]); % only labels within CF range will be used
            title('AN Average Response')
            xlabel('AN BF (Hz)')
            ylabel('Average Rate (sp/sec)')
            make_detachable(AN_response_avg)
        end
        %% Plot 7: Average CN Response
        axes(CN_response_avg)
        cla('reset')
        if exist('cn_sout_contra','var') == true
            for iicondition = 1:nconditions
                if iicondition == 1; cla('reset'); end
                switch plot_type(stimIdx)
                    case 0  % for linear plots
                        plot(CFs, Condition(iicondition).cn_sout_avg,'linewidth',2,'color',colors(iicondition))
                    case 1  %  for log plots
                        semilogx(CFs, Condition(iicondition).cn_sout_avg,'linewidth',2,'color',colors(iicondition))
                end
                hold on
            end
            title('CN Average Response')
            xlabel('CN BF (Hz)')
            ylabel('Average Rate (sp/sec)')
            xlim([CF_range(1) CF_range(2)]);
            set(gca, 'XTick',[100 200 500 1000 2000 5000 10000]); % only labels within CF range will be used
            ylim([0,350])
            make_detachable(CN_response_avg)
        else
            set(CN_response_avg,'Visible','off');
            align([AN_response_avg,IC_response_avg], 'top',50);
        end
        
        %% FINAL PLOT: AVERAGE BE/BS IC RESPONSE - plot average rates for population of IC BE model cells (Toggles to BS cells for SFIE model)
        IC_response_avg_callback([],[]); % explicit call to callback function for initial plot
        function  IC_response_avg_callback(~,~)
            axes(IC_response_avg)
            clicks_ic_averate = clicks_ic_averate + 1; % counter for toggle
            if which_IC == 1  % SFIE model - plot toggles between BE and BS model responses
                if rem(clicks_ic_averate,2)==0
                    for icondition = 1:nconditions
                        if icondition == 1; cla('reset'); end
                        if plot_type(stimIdx) == 0  % linear plot
                            plot(IC_response_avg,CFs, Condition(icondition).average_ic_sout_BE,'linewidth',2,'color',colors(icondition),'HitTest', 'off')
                        else
                            semilogx(IC_response_avg,CFs, Condition(icondition).average_ic_sout_BE,'linewidth',2,'color',colors(icondition),'HitTest', 'off')
                        end
                        hold on
                    end
                    title(IC_response_avg,'Avg. IC Rate: Band-Enhanced')
                elseif rem(clicks_ic_averate,2)==1
                    for icondition = 1:nconditions
                        if icondition == 1; cla('reset'); end
                        if plot_type(stimIdx) == 0  % linear plot
                            plot(IC_response_avg,CFs, Condition(icondition).average_ic_sout_BS,'linewidth',2,'color',colors(icondition),'HitTest', 'off')
                        else
                            semilogx(IC_response_avg,CFs, Condition(icondition).average_ic_sout_BS,'linewidth',2,'color',colors(icondition),'HitTest', 'off')
                        end
                        hold on
                    end
                    title(IC_response_avg,'Avg. IC Rate: Band-Suppressed') % see Carney et al., 2015 eNeuro
                end
                set(IC_response_avg, 'ButtonDownFcn', @IC_response_avg_callback);
                xlabel('IC BF (Hz)')
                ylabel('Average Rate (sp/sec)')
                xlim([CF_range(1) CF_range(2)]);
                set(gca, 'XTick',[100 200 500 1000 2000 5000 10000]); % only labels within CF range will be used
                max_rate = 0; % intialize
                for icondition = 1:nconditions  % use overall max value (across conditions) for upper limit of ylim
                    max_rate = max(max_rate,max(Condition(icondition).average_ic_sout_BE));
                end
                for icondition = 1:nconditions
                    max_rate = max(max_rate,max(Condition(icondition).average_ic_sout_BS));
                end
                ylim([0 (1.1 * max_rate)]);
            elseif which_IC == 2 % AN_ModFilt model (models only Band-Enhanced cells)
                for icondition = 1:nconditions
                    if icondition == 1; cla('reset'); end
                   if plot_type(stimIdx) == 0
                        plot(IC_response_avg,CFs, Condition(icondition).average_ic_sout_BE,...
                           'linewidth',2,'color',colors(icondition),'HitTest', 'off')
                   else
                       semilogx(IC_response_avg,CFs, Condition(icondition).average_ic_sout_BE,...
                           'linewidth',2,'color',colors(icondition),'HitTest', 'off')
                   end
                    hold on
                    
                end
                title(['Avg. IC Rate: Band-Enhanced (BMF=' num2str(BMF) ' Hz)'])
                xlabel('IC BF (Hz)')
                ylabel('Average Rate (sp/sec)')
                xlim([CF_range(1) CF_range(2)]);
                set(gca, 'XTick',[100 200 500 1000 2000 5000 10000]); % only labels within CF range will be used
                YL = ylim;
                ylim([0, YL(2)]);  % force rate axis to have 0 sp/sec as minimum
                
            end
            make_detachable(IC_response_avg)
            
            %% to write out some data for additional analysis - Plot a single CF using quick_model_plot.m (simple-minded, but effective!)
            save('UR_EAR_model_data.mat','CFs','Condition');
        end
        %% Useful Utility function
        function detach_fcn = make_detachable(ax)
            %make_detachable: Click on a context menu to copy the axes to a new figure.
            %  Syntax:  make_detachable(AXES_HANDLE)
            % Author: Doug Schwarz, douglas.schwarz@rochester.edu
            
            parent_fig = ancestor(ax,'figure');
            detach_cm = uicontextmenu('Parent',parent_fig);
            uimenu(detach_cm,'Label','Detach Plot','Callback',{@detach_plot,ax});
            set(ax,'UIContextMenu',detach_cm)
            if nargout > 0
                detach_fcn = @(~,~)detach_plot([],[],ax);
            end
            
            function detach_plot(~,~,ax)
                newfig = figure;
                newax = copyobj(ax,newfig);
                % MATLAB bug workaround. -DMS
                h = findobj(newax,'Type','hggroup');
                for i = 1:length(h)
                    hh = handle(h(i));
                    if isfield(hh,'BarPeer')
                        hh.BarPeer = hh;
                    end
                end
                % End of workaround.
                set(newax,'Units','default','Position','default')
    %            set(get(newax,'Children'),'ButtonDownFcn','')
                set(get(newax,'Children'),'ButtonDownFcn','','HitTest','on') % this version allows data cursor, etc. to work in detached plots.
                txt = findobj(newax,'Type','text');
                set([newax;txt],'FontSize','default')
                set(get(newax,'XLabel'),'FontSize','default')
                set(get(newax,'YLabel'),'FontSize','default')
                set(get(newax,'Title'),'FontSize','default')
            end
        end
    end

%%  Callback for AN & IC PSTH Figure
    function quickplot(~,~)
        qpdata = load('UR_EAR_model_data.mat');
        Rsfs = 10000; % sampling rate is 100 kHz for model responses, but resampled for time-freq plots
        
        CF_plot = str2double(char(PSTH_CFedit.String)) ; % approximate CF to be plotted (Hz)
        [~,CFindex] = min(abs(qpdata.CFs - CF_plot)); % find CF in population closest to desired CF
                
        figure
        subplot(3,1,1)
        t = (1:length(qpdata.Condition(1).an_sout_population(CFindex,:)))/Rsfs; % time vector for plots
        plot(t,qpdata.Condition(1).an_sout_population(CFindex,:),'g')
        title(['Condition 1: AN fiber, CF = ' num2str(qpdata.CFs(CFindex),'%.4g') ' Hz']);
        ylabel('Spikes/s')
        tmp_axis = axis;
        ylim([0 tmp_axis(4)]);
        tmp_size = size(qpdata.Condition);
        if tmp_size(2) > 1
            subplot(3,1,2)
            t = (1:length(qpdata.Condition(2).an_sout_population(CFindex,:)))/Rsfs; % time vector for plots
            plot(t,qpdata.Condition(2).an_sout_population(CFindex,:),'b')
            ylabel('Spikes/s')
            title(['Condition 2: AN fiber, CF = ' num2str(qpdata.CFs(CFindex),'%.4g') ' Hz']);
            tmp_axis = axis;
            ylim([0 tmp_axis(4)]);
        end
        
        subplot(3,1,3)
        t = (1:length(qpdata.Condition(1).BE_sout_population(CFindex,:)))/Rsfs; % time vector for plots
        plot(t, qpdata.Condition(1).BE_sout_population(CFindex,:),'g')
        hold on
        if tmp_size(2) > 1
            t = (1:length(qpdata.Condition(2).BE_sout_population(CFindex,:)))/Rsfs; % time vector for plots
            plot(t, qpdata.Condition(2).BE_sout_population(CFindex,:),'b')
            title(['Both Conditions: IC BE model, CF = ' num2str(qpdata.CFs(CFindex),'%.4g') ' Hz']);
        else
            title(['Condition 1: IC BE model, CF = ' num2str(qpdata.CFs(CFindex),'%.4g') ' Hz']);
        end
        xlabel('Time (s)')
        ylabel('Spikes/s')
        tmp_axis = axis;
        ylim([0 tmp_axis(4)]);
    end

%%  Callback for Wide Display Figure
    function widedisplay(~,~)
        wide = Displayoption.Value;
        if wide == 1
            outputPanel2.Visible = 'on';
        else
            outputPanel2.Visible = 'off';
        end
    end
end
