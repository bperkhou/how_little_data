function [] = run_sim_func_dt_spikes_random_rays(N,randseed,k_div_n,numangles)
%RUN_SIM_FUNC_DT_SPIKES_RANDOM_RAYS 
% Run single reconstruction. Wrapper of core_sim_func_k to
% simplify parameter sweep to create DT phase diagram reconstructions.
%
% Jakob S. Joergensen (jakj@dtu.dk), 2014.

%% Include necessary packages

addpath ../ext/mosek_wrap/
addpath ../ext/AIRtools_1.0/
addpath ../sim_funcs/

%% Set up the image class and problem_type

image_id = 'spikes';

problem_type = 'BP_NONNEG';

%% Set solver

solver = 'mosek_wrap';

solver_pars.precision = 'medium';
solver_pars.verbose   = 3;

lowlev_pars = struct;
lowlev_pars.MSK_IPAR_INTPNT_BASIS = 'MSK_BI_NEVER';

%% Set up the sampling matrix.

matrixtype = 'random_rays';
angle_interval = [0,360];

%% Directory to save results to

resultspath = fullfile(...
    '../../data_raw/dt/random_rays',...
    image_id,...
    solver);

%% Run the core simulation which saves results to the directory resultspath

k = k_div_n*numangles*2*N

core_sim_func_k(N,randseed,numangles,k,image_id,...
    solver,solver_pars,lowlev_pars,resultspath, problem_type, ...
    matrixtype, angle_interval)