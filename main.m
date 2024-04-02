%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 2d statistical max score Simulation %%%%%%%%%%%%%%%%%%%%%%%%%%
% This script implements the Simulation Section in the paper Object
% Detection Under The Linear Subspace Model.
% Input:
% img_sz                    size of each noisy image
% obj_sz                    size of each object
% objects_density           number_of_objects*object_size/img_size
% num_of_basis_functions    dimension of the objects subspace.          
% delta                     delta parameter that should satisfy the delta propery from the paper
% alpha                     error_rate controll parameter
% test_fun                  if equal one use alternative test function.
% gpu_use                   if equal one use gpu
% paralell_com              if equal one use paralell computing.
% SNR_lst                   SNR's list for the experiments
% num_of_exp                number of experiment to conduct
% output_folder_figs        folder to save figs. Create if not exists.

% Outputs:
% plots of FDR and FWER per SNR
% Example of one image with the detected object per SNR.

% Running time
% Running time on a Linux machine with 16 cores running at 2.1GHz, 768GB of memory, and an Nvidia Titan GPU, is approximately 35 minuets.
% Running time on MacBook Pro 14 with 8 cores running at 3.2GHz without the GPU is approximately 3 hours and 30 minuets.

%% parameters 
% sample formation
img_sz = 2^10;
obj_sz = 2^6;
objects_density = 0.5;
num_of_basis_functions = 50;
% Algorithm
delta = 10;
alpha = 0.05;
test_fun = 0;
% general
num_of_exp =500;
gpu_use = 0;
paralell_com = 1;
SNR_lst = [1,0.5,0.4,0.39];
output_folder_figs = './figs/'; 
%% run simulations
addpath('./src/')
object_detection_simulation(img_sz,obj_sz,objects_density,num_of_basis_functions,delta,alpha,test_fun,num_of_exp,gpu_use,paralell_com,SNR_lst,output_folder_figs)

