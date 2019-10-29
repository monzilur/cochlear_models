function [psth,neurogram_ft] = generate_neurogram_UREAR2(stim,Fs_stim,species,ag_fs,ag_dbloss,CF_num,dur,iCF,fiber_num,CF_range,fiberType)

% model fiber parameters
numcfs = CF_num;
%CFs   = logspace(log10(250),log10(16e3),numcfs);  % CF in Hz;
CFs = logspace(log10(CF_range(1)),log10(CF_range(2)),CF_num);
% cohcs  = ones(1,numcfs);  % normal ohc function
% cihcs  = ones(1,numcfs);  % normal ihc function

dbloss = interp1(ag_fs,ag_dbloss,CFs,'linear','extrap');

% mixed loss
[cohcs,cihcs,OHC_Loss]=fitaudiogram2(CFs,dbloss,species);

% OHC loss
% [cohcs,cihcs,OHC_Loss]=fitaudiogram(CFs,dbloss,species,dbloss);

% IHC loss
% [cohcs,cihcs,OHC_Loss]=fitaudiogram(CFs,dbloss,species,zeros(size(CFs)));
numsponts_healthy=[0,0,0];
if fiberType==1
numsponts_healthy = [fiber_num 0 0]; % Number of low-spont, medium-spont, and high-spont fibers at each CF in a healthy AN
elseif fiberType==2
numsponts_healthy = [0 fiber_num 0];
elseif fiberType==3
numsponts_healthy = [0 0 fiber_num];
end

if exist('ANpopulation.mat','file')
    load('ANpopulation.mat');
    disp('Loading existing population of AN fibers saved in ANpopulation.mat')
    if (size(sponts.LS,2)<numsponts_healthy(1))||(size(sponts.MS,2)<numsponts_healthy(2))||(size(sponts.HS,2)<numsponts_healthy(3))||(size(sponts.HS,1)<numcfs||~exist('tabss','var'))
        disp('Saved population of AN fibers in ANpopulation.mat is too small - generating a new population');
        [sponts,tabss,trels] = generateANpopulation(numcfs,numsponts_healthy);
    end
else
    [sponts,tabss,trels] = generateANpopulation(numcfs,numsponts_healthy);
    disp('Generating population of AN fibers, saved in ANpopulation.mat')
end

implnt = 0;    % "0" for approximate or "1" for actual implementation of the power-law functions in the Synapse
noiseType = 1;  % 0 for fixed fGn (1 for variable fGn)



% PSTH parameters

psthbinwidth_mr = 100e-6; % mean-rate binwidth in seconds;
windur_ft=32;
smw_ft = hamming(windur_ft);
windur_mr=128;
smw_mr = hamming(windur_mr);


pin = stim(:).';

clear stim100k

simdur = ceil(dur*1.2/psthbinwidth_mr)*psthbinwidth_mr;

 
    
   CFlp = iCF;
        
    CF = CFs(CFlp);
    cohc = cohcs(CFlp);
    cihc = cihcs(CFlp);
    
    numsponts = round([1 1 1].*numsponts_healthy); % Healthy AN
    %     numsponts = round([0.5 0.5 0.5].*numsponts_healthy); % 50% fiber loss of all types
    %     numsponts = round([0 1 1].*numsponts_healthy); % Loss of all LS fibers
    %     numsponts = round([cihc 1 cihc].*numsponts_healthy); % loss of LS and HS fibers proportional to IHC impairment
    
    sponts_concat = [sponts.LS(CFlp,1:numsponts(1)) sponts.MS(CFlp,1:numsponts(2)) sponts.HS(CFlp,1:numsponts(3))];
    tabss_concat = [tabss.LS(CFlp,1:numsponts(1)) tabss.MS(CFlp,1:numsponts(2)) tabss.HS(CFlp,1:numsponts(3))];
    trels_concat = [trels.LS(CFlp,1:numsponts(1)) trels.MS(CFlp,1:numsponts(2)) trels.HS(CFlp,1:numsponts(3))];
    nrep=1;
    vihc = model_IHC_BEZ2018(pin,CF,nrep,1/Fs_stim,simdur,cohc,cihc,species);
    
     for  spontlp = 1:sum(numsponts)
        
 
        if exist ('OCTAVE_VERSION', 'builtin') ~= 0
            fflush(stdout);
        end
        
        
        spont = sponts_concat(spontlp);
        tabs = tabss_concat(spontlp);
        trel = trels_concat(spontlp);
        [psth_ft,~,~,~] = model_Synapse_BEZ2018(vihc,CF,nrep,1/Fs_stim,noiseType,implnt,spont,tabs,trel);
        
       
        
if spontlp == 1
            neurogram_ft = filter(smw_ft,1,psth_ft);
            psth = psth_ft;
           
else

            psth= psth+psth_ft;
            neurogram_ft = neurogram_ft+filter(smw_ft,1,psth_ft);
end
     
     end % end of for Spontlp
   
    neurogram_ft = neurogram_ft(1:windur_ft/2:end); % 50% overlap in Hamming window 
    


