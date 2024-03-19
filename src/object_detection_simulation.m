
function object_detection_simulation(img_sz,obj_sz,objects_density,num_of_basis_functions,delta,alpha,test_fun,num_of_exp,gpu_use,SNR_lst,output_folder_figs)
%%%% object_detection_simulation %%%%%
%% parameters 
sideLengthAlgorithm = ceil(2*obj_sz+delta); % deletion parameter r
dist_obj_centers = ceil(obj_sz+1.5*delta); % distance between objects
num_of_exp_noise = 10^5; % for estimating the test value
num_of_exp_noise_for_snr = 10^3; % for estimating the expectation of the noise norm in a box of obj_sz side length

error_per_exp_bh = zeros(num_of_exp,1);
power_per_exp_bh = zeros(num_of_exp,1);
error_per_exp_bon = zeros(num_of_exp,1);
power_per_exp_bon = zeros(num_of_exp,1);

%% creating the 2d bessel basis
basis_full = fb_basis([obj_sz,obj_sz], Inf, 0);
rand_idx_basis = randperm(num_of_basis_functions,num_of_basis_functions);
basis = zeros(obj_sz,obj_sz,num_of_basis_functions);
for i=1:num_of_basis_functions
    v = zeros(basis_full.count,1);
    v(rand_idx_basis(i)) = 1;
    basis(:,:,i)= basis_full.evaluate(v);
    basis(:,:,i) = basis(:,:,i)./norm(basis(:,:,i),"fro");
end

%% creating the objects
num_of_obj_max = floor((img_sz/obj_sz)^2*objects_density); 
objects = zeros(obj_sz,obj_sz,num_of_obj_max); 
    for j=1:num_of_obj_max
        coeffs = randn(num_of_basis_functions,1);
        coeffs = coeffs/norm(coeffs,'fro');
        for m = 1:num_of_basis_functions
            objects(:,:,j) = objects(:,:,j) + coeffs(m)*basis(:,:,m);
        end
    end
    
%% estimating the expectation of the norm the noise to determaine SNR
[z,~,~,~]=noise_exp2d(obj_sz,num_of_exp_noise_for_snr,1,gpu_use);
norm_z_vec = zeros(num_of_exp_noise_for_snr,1);
for i =1:num_of_exp_noise_for_snr
   norm_z_vec(i) = norm(z(:,:,i),'fro');
end
norm_z = mean(norm_z_vec);

 %% computing S^z and z_tilde to estimate the test function
[z,~,~,~]=noise_exp2d(sideLengthAlgorithm+obj_sz,num_of_exp_noise,1,gpu_use);
[z_tilde,S_z]= projected_noise_simulation_from_noise_patches(z,basis,num_of_exp_noise,gpu_use);
if test_fun == 1
    z_test = S_z;
else
    z_test = z_tilde;
end
z_max = zeros(1,size(z_test,3));
for i=1:size(z_test,3)
    z_max(i) = max(z_test(:,:,i),[],"all");
end
if test_fun==1
    str_test = 'Sz';
else
    str_test = 'ztilde';
end
%% constructing the noise for the experiments
[Z,~,~,~]=noise_exp2d(img_sz,num_of_exp,0,gpu_use);

%% starting experiments for each SNR
for l = 1:length(SNR_lst)
    SNR = SNR_lst(l);
    % Make dirs for figs
    output_folder_bh= [output_folder_figs,str_test,'/bh/snr',num2str(SNR)];                                              
    output_folder_bon= [output_folder_figs,str_test,'/bon/snr',num2str(SNR)];
    output_folder= [output_folder_figs,str_test,'/gen/snr',num2str(SNR)];   
    if ~exist(output_folder_bh,"dir")
        mkdir(output_folder_bh);
    end
    if ~exist(output_folder_bon,"dir")
        mkdir(output_folder_bon);
    end
    if ~exist(output_folder,"dir")
        mkdir(output_folder);
    end


for exp = 1:num_of_exp
    %% constructing the clean image
    [X,true_locations,lst_of_object_centers,num_of_obj_per_exp] = constructing_clean_img(img_sz,num_of_obj_max,basis,dist_obj_centers,objects);
    %% constructind the data
    snr_param = 1/(sqrt(SNR*norm_z^2));
    Y = X + snr_param*Z(:,:,num_of_exp);
    [Y_peaks,Y_peaks_loc,Y_scoring_map] = peak_algorithm(Y,basis,floor(sideLengthAlgorithm),gpu_use);
    %% estimating the test function
    z_max_snr = (snr_param^2)*z_max;
    [test_val] = test_function_estimation(z_max_snr,Y_peaks);
    %% multiple testing procedure
    M_L = (size(Y,1)/(sideLengthAlgorithm/2))^2;
    [K_bon] = BON(test_val,alpha,M_L); 
    [K_bh] = BH(test_val,alpha,M_L);
    %% computing power and error rates per exp
    [power_per_exp_bh(exp),error_per_exp_bh(exp)] = power_and_fdr_per_exp(Y_peaks_loc,lst_of_object_centers,true_locations,K_bh,num_of_obj_per_exp,delta);
    [power_per_exp_bon(exp),error_per_exp_bon(exp)] = power_and_fwer_per_exp(Y_peaks_loc,lst_of_object_centers,true_locations,K_bon,num_of_obj_per_exp,delta);
   
end
%% ploting and figures
%% fdr and power plot
figure;
plot(1:num_of_exp,error_per_exp_bh);hold on; plot(1:num_of_exp,alpha*ones(1,num_of_exp)); xlabel('Experiments'); title(['FDR = ',num2str(mean(error_per_exp_bh))]);
save_fig(output_folder_bh,'fdr.jpg')
figure;
plot(1:num_of_exp,power_per_exp_bh); xlabel('Experiments'); title(['Power = ',num2str(mean(power_per_exp_bh))]);
save_fig(output_folder_bh,'power.jpg')

%% fwer and Power plot
figure;
plot(1:num_of_exp,error_per_exp_bon);hold on; plot(1:num_of_exp,alpha*ones(1,num_of_exp)); xlabel('Experiments'); title(['FWER = ',num2str(mean(error_per_exp_bon))]);
save_fig(output_folder_bon,'bon.jpg')
figure;
plot(1:num_of_exp,power_per_exp_bon); xlabel('Experiments');title(['Power = ',num2str(mean(power_per_exp_bon))]);
save_fig(output_folder_bon,'power.jpg')
 %% example of images
figure;imagesc(Y);colormap('gray');axis image; axis off
save_fig(output_folder,"Y.jpg")
figure;imagesc(X);colormap('gray');axis image; axis off
save_fig(output_folder,"X.jpg")
figure;imagesc(Z(:,:,num_of_exp));colormap('gray');axis image; axis off
save_fig(output_folder,"Z.jpg")
figure;imagesc(Y_scoring_map);colormap('hot');axis image; axis off
save_fig(output_folder,"Y_score.jpg")

%% circles on detected objects fdr
figure;imagesc(X);colormap('gray');axis image;axis off;
Y_peaks_loc_tmp = flip(Y_peaks_loc(1:K_bh,:),2);
viscircles(Y_peaks_loc_tmp,ceil((obj_sz+5)/2)*ones(size(Y_peaks_loc_tmp,1),1),'Color','green','LineWidth',0.5);
save_fig(output_folder_bh,"X_circles.jpg")
%% circles on detected objects fwer
figure;imagesc(X);colormap('gray');axis image;axis off;
Y_peaks_loc_tmp = flip(Y_peaks_loc(1:K_bon,:),2);
viscircles(Y_peaks_loc_tmp,ceil((obj_sz+5)/2)*ones(size(Y_peaks_loc_tmp,1),1),'Color','green','LineWidth',0.5);
save_fig(output_folder_bon,"X_circles.jpg")
close all;
end

