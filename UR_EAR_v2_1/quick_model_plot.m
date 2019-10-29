% Script to plot some model responses from the population
load('UR_EAR_model_data.mat')
Rsfs = 10000; % sampling rate is 100 kHz for model responses, but resampled for time-freq plots

disp('This will plot PSTHs for a specified AN fiber and IC Band-Enhanced neuron)')

CF_plot = input('Specify an approximate CF to be plotted? (Hz):')
[~,CFindex] = min(abs(CFs - CF_plot)); % find CF in population closest to desired CF

t = (1:length(Condition(1).an_sout_population(CFindex,:)))/Rsfs; % time vector for plots

figure
subplot(3,1,1)
t = (1:length(Condition(1).an_sout_population(CFindex,:)))/Rsfs; % time vector for plots
plot(t,Condition(1).an_sout_population(CFindex,:),'g')
title(['Condition 1: AN fiber, CF = ' num2str(CFs(CFindex),'%.4g') ' Hz']);
ylabel('Spikes/s')
tmp_axis = axis;
ylim([0 tmp_axis(4)]);

tmp_size = size(Condition)
if tmp_size(2) > 1
    subplot(3,1,2)
    t = (1:length(Condition(2).an_sout_population(CFindex,:)))/Rsfs; % time vector for plots
    plot(t,Condition(2).an_sout_population(CFindex,:),'b')
    ylabel('Spikes/s')
    title(['Condition 2: AN fiber, CF = ' num2str(CFs(CFindex),'%.4g') ' Hz']);
    tmp_axis = axis;
    ylim([0 tmp_axis(4)]);
end

subplot(3,1,3)
t = (1:length(Condition(1).BE_sout_population(CFindex,:)))/Rsfs; % time vector for plots
plot(t, Condition(1).BE_sout_population(CFindex,:),'g')
hold on
if tmp_size(2) > 1
    t = (1:length(Condition(2).BE_sout_population(CFindex,:)))/Rsfs; % time vector for plots
    plot(t, Condition(2).BE_sout_population(CFindex,:),'b')
    title(['Both Conditions: IC BE model, CF = ' num2str(CFs(CFindex),'%.4g') ' Hz']);
else
    title(['Condition 1: IC BE model, CF = ' num2str(CFs(CFindex),'%.4g') ' Hz']);
end
xlabel('Time (s)')
ylabel('Spikes/s')
tmp_axis = axis;
ylim([0 tmp_axis(4)]);


