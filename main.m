%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 2d statistical max score Simulation %%%%%%%%%%%%%%%%%%%%%%%%%%
% This script implements the Simulation Section in the paper Object
% Detection Under The Linear Subspace Model.
% Input:
% img_sz                    Size of each noisy image (in pixels).
% obj_sz                    Size of each object (in pixels).
% objects_density           Number_of_objects*object_size/img_size. YS: No ^2 missing?
% num_of_basis_functions    Dimension of the objects subspace.          
% delta                     delta parameter that should satisfy the delta
%                           propery from the paper.
% alpha                     error_rate control parameter.
% test_fun                  If equal one use alternative test function.
% gpu_choice                Number of gpus to use. 0 to use cpu only.
%                           'all' to use all gpus.   
% paralell_com              If equal one use paralell computing.
% SNR_lst                   SNRs' list for the experiments.
% num_of_exp                Number of experiment to conduct.
% output_folder_figs        Folder to save figs. Will be created if does
%                           not not exist. 

% Outputs:
% plots of FDR and FWER per SNR.
% Examples of one image with the detected object per SNR.

% Running time:
% 1. Running time on a Linux machine with 16 cores running at 2.1GHz, 768GB
%    of memory, and an Nvidia Titan GPU, is approximately 35 minuets. 
% 2. Running time on MacBook Pro 14 with 8 cores running at 3.2GHz without
%    the GPU is approximately 3 hours and 30 minuets. 

%% parameters 

% sample formation
img_sz = 2^10;
obj_sz = 2^6;
objects_density = 0.5;
num_of_basis_functions = 50;

% Algorithm
delta = 10;
alpha = 0.05;
test_fun = 1;

% General
num_of_exp =500;
gpu_choice = 'all';
paralell_com = 1;
SNR_lst = [0.05,0.03,0.025,0.02];
output_folder_figs = './'; 

% GPU computing
delete(gcp('nocreate')) % start a new pool.
% number of available GPUs
availableGPUs = gpuDeviceCount("available");
if strcmpi(gpu_choice, 'all')
    gpu_choice = availableGPUs;
end

% Validate user input
if gpu_choice < 0 || gpu_choice > availableGPUs
    if availableGPUs > 0
        error(['Invalid number of GPUs requested. ',...
            'Please choose a number within the available range: ',...
            '[0,',num2str(availableGPUs),']']);
    else
        error('Cannot use GPUs as requested. No GPU available ');
    end
end

% Set GPU flag gpu_use. 0 to not use gpu.
if gpu_choice == 0
    gpu_use = 0;
else
    gpu_use = 1;
    % Set chosen GPU as the current device
    parpool("Processes",gpu_choice);
end

%% run simulations
addpath('./src/')
object_detection_simulation(img_sz,obj_sz,objects_density,...
    num_of_basis_functions,delta,alpha,test_fun,num_of_exp,...
    gpu_use,paralell_com,SNR_lst,output_folder_figs);