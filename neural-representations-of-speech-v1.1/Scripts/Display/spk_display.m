function spk_display(spkdata,binsize,fbounds)
  if ischar(spkdata),load(spkdata);end
  
  nsets=numel(spkdata.sets);
  ncols=floor(sqrt(nsets));
  nrows=ceil(nsets/ncols);
  
  for i=1:nsets
    subplot(nrows,ncols,i);
    spk_display_set(spkdata.sets(i),binsize,fbounds);
    title(['Set ',num2str(i)]);
  end
end