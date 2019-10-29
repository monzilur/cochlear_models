% IHC Implements the inner hair cell model
%   output = IHC(signal,fs,params) converts basilar membrane velocity at N
%   sites in the N X M matrix SIGNAL, sampled at fs Hz to receptor
%   potential at N inner hair cells. Cells are modelled using parameters
%   specified in PARAMS. PARAMS is a data structure that must contain the
%   following fields:
%
%     Et:   endocochlear potential (V)
%     Ek:   potassium reversal potential (V)
%     G0:   resting conductance
%     Gk:   potassium conductance (S)
%     Rpc:  correction, Rp/(Rt + Rp)
%     Gmax: max. mechanical conductance (S)
%     s0:   displacement sensitivity (/m)
%     u0:   displacement offset (m)
%     s1:   displacement sensitivity (/m)
%     u1:   displacement offset (m)
%     Cab:  total capacitance (F)
%     tc:   cilia/BM time constant (s)
%     C:    gain factor (dB)
%     Ga:   passive conductance in apical membrane
%
%   Mark Steadman
%   12/01/2015
%   
%   marks@ihr.mrc.ac.uk

function output=ihc(signal,fs,params)
  dt=1/fs;
  signal=signal*10^(params.C/20);
  
  % Set up initial conditions
  Gu0=params.Ga+params.Gmax/...
    (1+exp(params.u0/params.s0)*...
    (1+exp(params.u1/params.s1)));
  Ekp=params.Ek+params.Et*params.Rpc;
  restingPotential=(params.Gk*Ekp+Gu0*params.Et)/(Gu0+params.Gk);
  
  u=zeros(size(signal,1),1);                 % initial voltage
  v=restingPotential*ones(size(signal,1),1); % initial displacement
  output=zeros(size(signal));
  
  % Main
  for i=1:size(signal,2)
    u=u+dt*(signal(:,i)-u/params.tc);
    output(:,i)=u;
  end
  
  gu=params.Ga+params.Gmax./...
    (1+exp(-(output-params.u0)/params.s0).*...
    (1+exp(-(output-params.u1)/params.s1)));
  
  for i=1:size(signal,2)
    v=v+(-gu(:,i).*(v-params.Et)-params.Gk*(v-Ekp))*dt/params.Cab;
    output(:,i)=v;
  end
end