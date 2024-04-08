%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Numerical Simulations %%%%%%%%%%%%%%%%%%%%%%%%%%
% This script implements the Simulation section in the paper "Object
% Detection Under The Linear Subspace Model." The script often uses
% variables which are defined in the aforementioned paper.
% 
% Input:
% pre_process               if equal one, then use the saved basis and
%                           test function estimation. This is highly
%                           recommended for systems without strong GPUs
%                           (see running times below).
% img_sz                    size of each noisy image.
% obj_sz                    size of each object.
% objects_density           (number_of_objects * object_size) / img_size.
% num_of_basis_functions    dimension of the object subspace.
% delta                     delta parameter that should satisfy the delta
%                           property (see the accompanying paper).
% alpha                     error rate control parameter.
% test_fun                  if equal one use S^z for the test function,
%                           else, use z~.
% gpu_choice                number of GPUs to use. 0 to not use the GPU.
%                           'all' to use all availables GPUs.
% parallel_com              if equal one, use parallel computing.
% SNR_lst                   SNRs list for the experiments.
% num_of_exp                number of experiments to conduct.
% output_folder_figs        folder to save figures. Create if not exists.
%
% Outputs:
% The outputs will be saved in ./figs/z~ or /figs/S^z, depending on the test
% function parameter.
% Plots of FWER, FDR, and the corresponding Power per SNR.
% Examples of the images Y, X, Z, S^y, and X with the detected object marked on it per SNR.
%
% Running time:
% Running time on a Linux machine with 16 cores running at 2.1GHz, 768GB of memory, and an Nvidia Titan GPU, without preprocessing, is approximately 35 minutes.
% Running time on MacBook Pro 14 with 8 cores running at 3.2GHz without the GPU and with preprocessing is approximately 97 minutes.


%% parameters
pre_process = 1;
% sample formation
img_sz = 2^10;
obj_sz = 2^6;
objects_density = 0.5;
num_of_basis_functions = 50;
% Algorithm
delta = 10;
alpha = 0.05;
test_fun = 1;
% general
num_of_exp =500;
gpu_choice = 0;
paralell_com = 0;
SNR_lst = [0.05,0.03,0.025,0.02];
output_folder_figs = './figs/'; 

if pre_process == 1 % this parameters should be used
    img_sz = 2^10;
    obj_sz = 2^6;
    num_of_basis_functions = 50;
    delta = 10;
end
% GPU validation
delete(gcp('nocreate')) % start a new pool.
% number of available GPUs
availableGPUs = gpuDeviceCount("available");
if gpu_choice =='all'
    gpu_choice = availableGPUs;
end
% Validate user input
if gpu_choice < 0 || gpu_choice > availableGPUs
    error(['Invalid GPU choice. Please choose a number within the available range: ','[0,',num2str(availableGPUs),']']);
end
% assign gpu_use for code. 0 to not use the gpu
if gpu_choice ==0
    gpu_use = 0;
else
    gpu_use = 1;
    % Set chosen GPU as the current device
    parpool("Processes",gpu_choice);
end

%% run simulations
addpath('./src/')
object_detection_simulation(pre_process,img_sz,obj_sz,objects_density,num_of_basis_functions,delta,alpha,test_fun,num_of_exp,gpu_use,paralell_com,SNR_lst,output_folder_figs);
