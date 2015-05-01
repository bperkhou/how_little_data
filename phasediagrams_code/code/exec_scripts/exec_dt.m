%
% Script to be run for executing all reconstruction simulations for
% creation of DT phase diagram. One particular phase diagram and desired 
% parameters should be selected and the script will loop over all
% parameteres saving the reconstructed and original images in separate
% files.
%
% Jakob S. Joergensen (jakj@dtu.dk), 2014.
%

clear
clc

%% Which DT phase diagram to construct raw simulation data for?

% Choose 1-14 to generate one of the 14 DT phase diagrams from the paper:

run_func_choice = 1;

run_func_list = {...
    'run_sim_func_dt_signedspikes_fanbeam_equi_offset20',...
    'run_sim_func_dt_signedspikes_gaussian',...
    'run_sim_func_dt_signedspikes_fanbeam_rand',...
    'run_sim_func_dt_signedspikes_random_rays',...
    'run_sim_func_dt_spikes_fanbeam_equi_offset20',...
    'run_sim_func_dt_spikes_gaussian',...
    'run_sim_func_dt_spikes_fanbeam_rand',...
    'run_sim_func_dt_spikes_random_rays',...
    'run_sim_func_dt_fftpower_2_0_fanbeam_equi_offset20',...
    'run_sim_func_dt_fftpower_2_0_gaussian',...
    'run_sim_func_dt_altprojisotv_fanbeam_equi_offset20',...
    'run_sim_func_dt_altprojisotv_gaussian',...
    'run_sim_func_dt_altprojisotv_fanbeam_rand',...
    'run_sim_func_dt_altprojisotv_random_rays'};
run_func = run_func_list{run_func_choice}

%% Includes

% MOSEK MUST BE INSTALLED AND ON THE MATLAB PATH
% addpath to mosek

addpath ../ext/parobj/
addpath ../run_funcs/

%% set up pars

% Image side length
N = 64;

% Random seeds
seed = 0:99;

% Relative sparsities
k_div_n = (1:32)/32

% Number of angles
numangles = 1:26;

% Set up the parameter object specifying which parameters to loop over.
po = parobj;
po.setValues( {N, seed, k_div_n, numangles} )
po.setNames( {'N', 'seed', 'k_div_n','numangles'} )
po.setTypes( {'%d', '%f', '%d', '%d'} );
po.setStub( 'res' );
po.buildArray()


%% Run sweep over all parameters

% Do not use the automatic savefilename generated by parsweep because the
% filename is set up inside the simulation.
use_parsweep_auto_savefilename = false;

% Run all for all parameters
po.parsweep(run_func,use_parsweep_auto_savefilename)