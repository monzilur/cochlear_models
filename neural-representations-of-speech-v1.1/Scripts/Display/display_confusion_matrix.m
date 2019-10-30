function display_confusion_matrix(confusions, labels, order, maxsize)
  if nargin<4,maxsize=60;end
  if nargin<3,order=1:numel(labels);end
  
  % Scale the confusion matrix
  confusions=maxsize*confusions/max(confusions(:));
  
  % Set a minimum value
  epsilon=0.1;
  confusions(confusions<epsilon)=epsilon;
  
  labels=labels(order);
  confusions=confusions(order,order);
  
  nclasses=numel(labels);
  x=repmat(1:nclasses,nclasses,1);
  y=x';
  
  scatter(x(:),y(:),confusions(:),...
    'ko','markerfacecolor','k');

  set(gca,'xlim',[0,nclasses+1],'ylim',[0,nclasses+1],...
    'TickLabelInterpreter', 'tex',...
    'xtick',1:nclasses,'ytick',1:nclasses,...
    'xticklabel',labels,'yticklabel',labels,...
    'fontsize',8);
  title('CONFUSION MATRIX');
end