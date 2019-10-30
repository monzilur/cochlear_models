function spk_display_set(myset,binsize,fbounds)
if nargin<3
  fmin=10e3;
  fmax=110e3;
else
  fmin=fbounds(1);
  fmax=fbounds(2);
end
if nargin<2,binsize=0.01;end

  nfft=512;
  swin=hamming(nfft);
  
  pos=get(gca,'position');
  delete(gca);
  x=pos(1);y=pos(2);w=pos(3);h=pos(4);
  
  %% Spectrogram
  h1=axes('position',[x,y,w,h/2]);
  stim=myset.stimulus.values;
  %f=logspace(log10(fmin),log10(fmax),100);
  f=linspace(fmin,fmax,100);
  [s,~,t]=spectrogram(stim,swin,nfft*0.75,f,myset.stimulus.fs);
  imagesc(t,f/1000,log(abs(s))); axis('xy');
  colormap(flipud(colormap(gray)))
  caxis([-2,4]);
  box('off');
  ylim([fmin,fmax]/1000);
  set(h1,'visible','off');
  h4=axes('position',get(h1,'position'),'yscale','log','ylim',[fmin,fmax]/1000,'color','none');
  
  set(gca,'fontsize',7);
  xlabel('Time, seconds');
  %ylabel('Freq, kHz');
  
  %% Rasters
  h2=axes('position',[x,y+h/2,w,h/4]);
  nreps=numel(myset.sweeps);
  for i=1:nreps
    ts=myset.sweeps{i};
    ts=ts(ts<t(end));
    yvals=i*ones(numel(ts),1);
    plot(ts,yvals,'kd',...
      'markerfacecolor','r',...
      'markeredgecolor','r',...
      'markersize',2);
    hold('on');
  end; hold('off');
  set(gca,'box','off','xtick',[],'ytick',[],...
    'ylim',[1-nreps*0.1,nreps*1.1],'fontsize',7);
  ylabel('Rasters');
  
  %% PSTH
  h3=axes('position',[x,y+3*h/4,w,h/4]);
  spikes=cat(1,myset.sweeps{:});
  edges=t(1):binsize:t(end);
  psth=hist(spikes,edges);
  bar(edges(1:end-1),psth(1:end-1),'k');
  set(gca,'box','off','xtick',[],'ytick',[],'fontsize',7);
  ylabel('PSTH');
  xlim([t(1),t(end)]);
  
  %%
  linkaxes([h1,h2,h3,h4],'x');
  xlim([t(1),t(end)]);
  h=zoom;
  h.Motion='horizontal';
end