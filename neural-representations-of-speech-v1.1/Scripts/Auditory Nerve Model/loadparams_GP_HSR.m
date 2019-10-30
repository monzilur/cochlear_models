function loadparams_GP_HSR(BF)

params.BFlist=BF;

%% OME filter
params.OME.filters(1).order=2;
params.OME.filters(1).locut=4000;
params.OME.filters(1).hicut=25000;

params.OME.filters(2).order=2;
params.OME.filters(2).locut=300;
params.OME.filters(2).hicut=25000;
params.OME.gain=1.4e-10; % Stapes scalar

%% DRNL filter
p0_BWnl  = 0.8;   m_BWnl  = 0.58;
p0_a     = 1.87;  m_a     = 0.45;
p0_b     =-5.65;  m_b     = 0.875;
p0_CFlin = 0.339; m_CFlin = 0.895;
p0_BWlin = 1.3;   m_BWlin = 0.53;
p0_Glin  = 5.68;  m_Glin  =-0.97;

params.DRNL.a=evalParameter(p0_a,m_a,BF);
params.DRNL.b=evalParameter(p0_b,m_b,BF);
params.DRNL.c=0.1; % compression exponent
params.DRNL.nonlinCascade=3;
params.DRNL.nonlinCFs=BF;
params.DRNL.nonlinBWs=evalParameter(p0_BWnl,m_BWnl,BF);  
params.DRNL.nonlinLpOrder=2;
params.DRNL.nonlinLpCascade=4;

params.DRNL.g=evalParameter(p0_Glin,m_Glin,BF);%linear path gain
params.DRNL.linCascade=3; % order of linear gammatone filters
params.DRNL.linCFs=evalParameter(p0_CFlin,m_CFlin,BF);
params.DRNL.linBWs=evalParameter(p0_BWlin,m_BWlin,BF);
params.DRNL.linLpOrder=2;
params.DRNL.linLpCascade=4;

%% Inner hair cell
params.IHC.Et=0.1;      % endocochlear potential (V)
params.IHC.Ek=-70.45e-3;% potassium reversal potential (V)
params.IHC.G0=1.974e-9; % resting conductance
params.IHC.Gk=18e-9;    % potassium conductance (S)
params.IHC.Rpc=0.04;    % correction, Rp/(Rt + Rp)
params.IHC.Gmax=8e-9;   % max. mechanical conductance (S)
params.IHC.s0=85e-9;    % displacement sensitivity (/m)
params.IHC.u0=7e-9;     % displacement offset (m)
params.IHC.s1=5e-9;     % displacement sensitivity (/m)
params.IHC.u1=7e-9;     % displacement offset (m)
params.IHC.Cab=6e-12;   % total capacitance (F)
params.IHC.tc=2.13e-3;  % cilia/BM time constant (s)
params.IHC.C=16;        % gain factor (dB)
params.IHC.Ga=params.IHC.G0-params.IHC.Gmax./...
  (1+exp(params.IHC.u0/params.IHC.s0).*...
     (1 + exp(params.IHC.u1/params.IHC.s1)));   

%% Pre-synapse
params.synapse.z=2e32;
params.synapse.ECa=0.066;    % calcium equilibrium potential
params.synapse.beta=400;     % determine Ca channel opening
params.synapse.gamma=130;    % determine Ca channel opening
params.synapse.tauM=1e-4;    % calcium current time constant (s)
params.synapse.tauCa=1e-4;
params.synapse.power=3;      % k(t)=z([Ca_2+](t)^synapse.power) 
params.synapse.GmaxCa=7.2e-9;% MSR fiber (Sumner et al 2003b)
params.synapse.Ca_thresh=0;

%% Synapse
params.synapse.y=10;                     % replenishment rate (Meddis & O.Mard 2005)
params.synapse.l=2580;                   % loss rate
params.synapse.x=66.3;                   % reprocessing rate (Meddis & O.Mard 2005)
params.synapse.r=6580;                   % recovery rate
params.synapse.M=10;                     % maximum vesicles at synapse
params.synapse.refractoryPeriod=0.75e-3; % refractory period

assignin('caller','params',params);

function p=evalParameter(p0,m,BF)
  p=10.^(p0+m*log10(BF));