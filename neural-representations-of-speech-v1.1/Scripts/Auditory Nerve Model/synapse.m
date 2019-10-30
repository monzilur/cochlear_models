% SYNAPSE  Performs simulation of the IHC/AN synapse
%   output = synapse(signal,fs,params) performs a simulation of the inner
%   hair cell to auditory nerve synapse given the receptor potential
%   provided in the N X M matrix SIGNAL for each of N inner hair cells. The
%   output is the probability of release of a neurotransmitter vesicle into
%   the synaptic cleft.
%
%   Synaptic parameters are proved to the function through the data
%   structure PARAMS, which mus contain the following fields:
% 
%     ---Pre-synpase---
%     z:         Scalar to convert calcium cubed to probability
%     ECa:       Calcium equilibrium potential
%     beta:      Determine Ca channel opening
%     gamma:     Determine Ca channel opening
%     tauM:      Calcium current time constant (s)
%     tauCa:     Calcium clearancet time constant (s)
%     power:     k(t)=z([Ca_2+](t)^power) 
%     GmaxCa:    Maximum Ca conductance
%     Ca_thresh: Calcium threshold
% 
%     ---Synpase---
%     y:                replenishment rate
%     l:                loss rate
%     x:                reprocessing rate
%     r:                recovery rate
%     M:                maximum vesicles at synapse
%     refractoryPeriod: refractory period
%
%   Mark Steadman
%   12/01/2015
%   
%   marks@ihr.mrc.ac.uk

function output=synapse(signal,fs,params)

  mICaINF=1./(1+exp(-params.gamma*signal)/params.beta);
  mICaNow=1./(1+exp(-params.gamma*signal(:,1))/params.beta);
  ICaNow=(params.GmaxCa*mICaNow.^3).*(signal(:,1)-params.ECa);
  mICa=zeros(size(signal));  
  kt0=params.z*((-ICaNow.*params.tauCa).^params.power);
  
  for i=1:size(signal,2);
    mICaNow=mICaNow+(mICaINF(:,i)-mICaNow)*(1/(fs*params.tauM));
    mICa(:,i)=mICaNow;
  end
  
  ICa=(params.GmaxCa*mICa.^params.power).*(signal-params.ECa);  
  CaNow=-ICaNow.*params.tauCa;
  synapseCa=zeros(size(signal));
  
  for i=1:size(signal,2)
    CaNow=CaNow+(ICa(:,i)-CaNow)./(fs*params.tauCa);
    synapseCa(:,i)=-CaNow;
  end
  
  % Calculate the vesicle release rate (Calcium influx model)
  signal=max(params.z*...
    (synapseCa.^params.power-params.Ca_thresh^params.power),0);
  
  % Convert vesicle release rate to spike firing probabilities
  
  % Initialise nerve fibre properties
  ANcleft=kt0*params.y*params.M./...
    (params.y*(params.l+params.r)+kt0*params.l);
  ANavailable=round(ANcleft*(params.l+params.r)./kt0);
  ANreprocess=ANcleft*params.r/params.x;
  
  rdt=params.r/fs;
  ldt=params.l/fs;
  xdt=params.x/fs;
  ydt=params.y/fs;
  
  output=zeros(numel(kt0),size(signal,2));
  
  for i=1:size(signal,2)
    Mq=params.M-ANavailable;
    Mq(Mq<0)=0;
        
    ejected=ANavailable.*(signal(:,i)/fs);   
    replenish=Mq.*ydt;
    reprocessed=ANreprocess.*xdt;
    reuptakeandlost=(rdt+ldt).*ANcleft;
    reuptake=rdt.*ANcleft;
    
    ANavailable=ANavailable+replenish-ejected+reprocessed;
    ANavailable(ANavailable<0)=0;
    ANcleft=ANcleft+ejected-reuptakeandlost;
    ANreprocess=ANreprocess+reuptake-reprocessed;
    
    output(:,i)=ejected;
  end
end