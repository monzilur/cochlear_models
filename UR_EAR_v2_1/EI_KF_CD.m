function [lambda_EE] = EI_KF_CD(an_sout_E_1,lambda_I1,an_sout_E_2,lambda_I2,fs,M,Delta)
% Version with two AN inputs 3/17/18 LHC
%  Preliminary version 10/23/16  LHC
% EI model of Krips & Furst 2009a,b (Neural Computation & JASA)
% lambda_E is just an_sout from the AN model
% lambda_EI_BP is equivalent to ic_sout_BE from the SFIE model (units in
% sp/sec)

% This version is just for Band-Pass MTF (later - will epxlore adding
% band-suppressed/low pass MTF.  Hybrid??

%%  Need to map out relation beteen BMF and model parameters
% Values below are for ~100 Hz BMF (change inh_delay to shift BMF, for now.)
lambda_E1=an_sout_E_1;
lambda_E2=an_sout_E_2;
% EI model parameters

n_delta = floor(Delta*fs); %  # of points within the coincidence window




lambda_EI1_mul_final=1;
lambda_EI2_mul_final=1;


% disp('line 27 is done');
parfor ii = (n_delta+1):length(lambda_E2)
%disp('line 29 is done');
%size(lambda_EI1)  
%tic
%parfor times=1:2
lambda_EI1_mul=ones(1,M);
lambda_EI2_mul=ones(1,M);
lambda_EI1 = zeros(1,length(lambda_E1)); %initialize the output array (most important to have the zeros at the beginning of this array)
lambda_EI2 = zeros(1,length(lambda_E2)); %initialize the output array (most important to have the zeros at the beginning of this array)    
for i=1:1:M  
       
      %lambda_EI1_mul(times)=lambda_EI1_mul(times).*(1 - (1/fs)* sum(lambda_I1{i}(( ii-n_delta):ii)));
      %lambda_EI2_mul(times)=lambda_EI2_mul(times).*(1 - (1/fs)* sum(lambda_I2{i}(( ii-n_delta):ii))) ;
       lambda_EI1_mul(i+1) = lambda_EI1_mul(i).* (1 - (1/fs)* sum(lambda_I1{i}(( ii-n_delta):ii)));
       lambda_EI2_mul(i+1) = lambda_EI2_mul(i).* (1 - (1/fs)* sum(lambda_I2{i}(( ii-n_delta):ii)));
end
   % disp (['javaaab = ' int2str(lambda_EI1_mul)]) 
   
    

%end
%  disp('line 44 is done');
    %lambda_EI1_mul_final=lambda_EI1_mul(1).*lambda_EI1_mul(2);
    %lambda_EI2_mul_final=lambda_EI2_mul(1).*lambda_EI2_mul(2);
    
    lambda_EI1(ii) = lambda_EI1_mul(M+1) .* lambda_E1(ii);
     lambda_EI2(ii) = lambda_EI1_mul(M+1) .* lambda_E2(ii); 
 %disp('line 50 is done');

lambda_EE_term1 = lambda_EI1(ii) .* ((1/fs) * sum(lambda_EI2((ii-n_delta):ii))); % this assumes that the inhibitions are identical; could vary them (internal noise/averaging)
lambda_EE_term2 = lambda_EI2(ii) .* ((1/fs) * sum(lambda_EI1((ii-n_delta):ii))); % this assumes that the inhibitions are identical; could vary them (internal noise/averaging)
lambda_EE(ii) = (lambda_EE_term1 + lambda_EE_term2);


% disp('line 555 is done');

%toc
end


 








% EE cell that receives these two EI cells as inputs (Fig 8 in K&F Comp Neuro)
% Lambda_EE_L with L=2
% for excitation:
%Delta = 100e-6; % (sec) "coincidence" window; inhibitory spikes within this time window will suppress cell's response


end