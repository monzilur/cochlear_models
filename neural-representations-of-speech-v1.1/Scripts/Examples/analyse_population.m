% This script will determin classifier performance for a population of
% neurons responding to the same set of stimuli.
%
% By Mark A Steadman

datadir='L:\Mark\DATA_NOTTINGHAM\Frontiers\inferior colliculus';
files=dir(fullfile(datadir,'*.mat'));
files=arrayfun(@(x) fullfile(datadir,x.name),files,'uni',0);

% Build response neurograms
binsize=1e-3; % 1 ms bin size
duration=0.65;% 650 ms stimulus duration
disp('Building neurograms...');
neurograms=buildneurograms(files,0.001,0.65);

% Define classifier parameters
parameters.window_length=100;   % 100 ms smoothing
parameters.window_func=@hamming;
parameters.max_shift=100;       % Relative shift -100 to 100 ms
parameters.verbose=true;

% Run neural classifier
disp('Running classifier...');
results=classify(neurograms,parameters);

% Display the results
disp(['Mean Percent Correct = ' num2str(mean([results.correct]))]);
mean_confusion_matrix=mean(cat(3,results.confusions),3);
consonants={'B','D','F','G','K','L','M','N','P','S','SH','T','TH','V','Y','Z'};
figure();pos=get(gcf,'position');x=pos(1);y=pos(2);w=300;h=300;
set(gcf,'position',[x,y,w,h]);
display_confusion_matrix(mean_confusion_matrix,consonants);