function [sigOpt,b1,a1,b2,a2,b3,a3] = unitgain_bpFilter( sigIpt, bmf, fs)
%{
This is a very simple model for anIC bandpass tunedcell - It's just a
bandpass filter applied to the AN response (the AN fiber locks to the
envelope of the stimulus, plus fine structure - here, we just use a bandpass filter
to simulate the IC cells modulation transfer fucntion, then we 1/2-wave rectify.)
% This is a simple version of the Nelson & Carney 2004 (JASA) model - this
one allows you to look at a "bank" of filter to see how a population of
cells would respond.  LHC 12/16/14

This function cascades three 2nd Order BP filters to create 
sixth order BP filter that models IC bandpass behavior. All three filters
have center frequencies at bmf/fs and a Q of 1.
Inputs: 
    sigIpt: input signal
    bmf: best modulated frequency
    fs: sampling frequency
Outputs: 
    sigOpt: Output signal
    b1-3 and a1-3: Coefficients of the transfer function that are used
                   for ploting filters frequency responses. 
%}

%Setting Q and center frequencies for each filter. 
Q  = 1; 
f1 = bmf/fs;
f2 = f1;
f3 = f1;

%Filter design and cascade. Each filter involves Alpha and Beta values
%derived from sources filter design. 
    %Filter 1: filters input signal
    alpha1 = (4*Q / (abs(sin(2*pi*f1)) + 2*Q))-1;                  
    beta1 = (-4*Q / (abs(sin(2*pi*f1)) + 2*Q))*cos(2*pi*f1);    
    sos1 = [ 1 0 -1 1 beta1 alpha1 ];                           % sets up sos matrix for sos2tf
    [b1 a1] = sos2tf( sos1,(1-alpha1)/2 );                      % creates filter transfer function 
    sig1 = filter( b1,a1,sigIpt );                              % filters input signal
    
    %Filter 2: filters output of first filter (same steps as filter 1) 
    alpha2 = (4*Q / (abs(sin(2*pi*f2)) + 2*Q))-1;
    beta2 = (-4*Q / (abs(sin(2*pi*f2)) + 2*Q))*cos(2*pi*f2);
    sos2 = [ 1 0 -1 1 beta2 alpha2 ] ;
    [b2 a2] = sos2tf( sos2,(1-alpha2)/2 );
    sig2 = filter( b2,a2,sig1 );                         
    
    %Filter 3: filters output of second filter (same steps as previous filters) 
    alpha3 = (4*Q / (abs(sin(2*pi*f3)) + 2*Q))-1;
    beta3 = (-4*Q / (abs(sin(2*pi*f3)) + 2*Q))*cos(2*pi*f3);
    sos3 = [ 1 0 -1 1 beta3 alpha3 ] ;
    [b3 a3] = sos2tf( sos3,(1-alpha3)/2 );
    sig3 = filter( b3,a3,sig2 );
    
    %Output 
    sigOpt = sig3;
    
    sigOpt = max(sigOpt,0.); % half-wave rectify the filter output (to simulate neural response)
end
%{
SOURCE: BP Filter Design  
 
[1] Lutovac, Miroslav D., Dejan V. To?i?, and Brian L. Evans. "Bandpass Transfer
        Function." Filter Design for Signal Processing Using MATLAB and Mathematica.
        Upper Saddle River, NJ: Prentice Hall, 2001. 339-40. Print.

http://books.google.com/books?id=h_MxJeVdWw8C&pg=PA339&lpg=PA339&dq=bandpa
ss+filter+design+matlab+central&source=bl&ots=H_-Cc6n7UZ&sig=20Nq-aHguxkSI
QhCVbql-rH-EoY&hl=en&sa=X&ei=G3QoU5nZHKiQyAGxs4GwAQ&ved=0CGwQ6AEwCQ#v=onep
age&q=bandpass%20filter%20design%20matlab%20central&f=true
%}
    