% Generates auditory nerve responses to a set of stimuli
outdir=pwd;
wavdir='L:\Mark\STIM\VCVs\unprocessed';
wavfiles=dir(fullfile(wavdir,'*.wav'));
wavfiles=arrayfun(@(x) fullfile(wavdir,x.name),wavfiles,'uni',0);

% Extract the parameters of the wavfiles
info=cellfun(@audioinfo,wavfiles);
wavparams.duration=cat(1,info.Duration);

expr='M(\d)A(\w+)A';
x=cellfun(@(x) regexp(x,expr,'tokens','once'),wavfiles,'uni',0);
x=cat(1,x{:});

wavparams.talkerID=cellfun(@str2double,x(:,1));

nstim=numel(wavfiles);
uconsonant=unique(x(:,2));
consonantID=zeros(nstim,1);
for i=1:nstim,consonantID(i)=find(ismember(uconsonant,x(i,2)));end
wavparams.consonantID=consonantID;

% Run the model
dbSPL=70;
%BFs=round(greenwood(100,100,5000));
BFs=2000;
nreps=10;

paramnames={'GP_LSR','GP_MSR','GP_HSR'};
for i=1:numel(paramnames)
  modeldata=runexperiment(wavfiles,dbSPL,wavparams,BFs,nreps,paramnames{i});
  
  for j=1:numel(modeldata)
    fname=fullfile(outdir,[paramnames{i},'_CF=',num2str(BFs(j)),'Hz.mat']);
    spkdata=modeldata(j);
    save(fname,'spkdata');
  end
end