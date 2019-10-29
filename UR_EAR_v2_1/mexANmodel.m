clear all;
mex -v GCC='/usr/bin/gcc-4.8' model_IHC_BEZ2018.c complex.c  
clear all;
mex -v GCC='/usr/bin/gcc-4.8' model_Synapse_BEZ2018.c complex.c 
