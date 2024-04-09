
function object_detection_simulation(pre_process,img_sz,obj_sz,objects_density,num_of_basis_functions,delta,alpha,test_fun,num_of_exp,gpu_use,paralell_com,SNR_lst,output_folder_figs)
%%%% object_detection_simulation %%%%%
%% parameters 
sideLengthAlgorithm = ceil(2*obj_sz+delta); % deletion parameter r
dist_obj_centers = ceil(obj_sz+1.5*delta); % distance between objects
num_of_exp_noise = 10^5; % for estimating the test value

error_per_exp_bh = zeros(num_of_exp,1);
power_per_exp_bh = zeros(num_of_exp,1);
error_per_exp_bon = zeros(num_of_exp,1);
power_per_exp_bon = zeros(num_of_exp,1);
disp('Constructing the objects');
if pre_process == 1
    if test_fun == 0
        basis = load('./pre_process/basis_test_zero.mat');
        basis = basis.basis;
        z_max = load('./pre_process/z_max_test_zero.mat');
        z_max = z_max.z_max;
    else
        basis = load('./pre_process/basis_test_one.mat');
        basis = basis.basis;
        z_max = load('./pre_process/z_max_test_one.mat');
        z_max = z_max.z_max;
    end
else
    % creating the 2d bessel basis
    basis_full = fb_basis([obj_sz,obj_sz], Inf, 0);
    rand_idx_basis = randperm(max(200,num_of_basis_functions),num_of_basis_functions); % choose randomly basis functions
    basis = zeros(obj_sz,obj_sz,num_of_basis_functions);
    for i=1:num_of_basis_functions
        v = zeros(basis_full.count,1);
        v(rand_idx_basis(i)) = 1;
        basis(:,:,i)= basis_full.evaluate(v);
        basis(:,:,i) = basis(:,:,i)./norm(basis(:,:,i),"fro");
    end

end

%% creating the objects and translating the basis
num_of_obj_max = floor((img_sz/obj_sz)^2*objects_density); 
objects = zeros(obj_sz,obj_sz,num_of_obj_max); 
    for j=1:num_of_obj_max
        coeffs = randn(num_of_basis_functions,1);
        coeffs = coeffs/norm(coeffs,'fro');
        for m = 1:num_of_basis_functions
            objects(:,:,j) = objects(:,:,j) + coeffs(m)*basis(:,:,m);
        end
    end
basis_trans = zeros(size(basis));
for j = 1:size(basis,3)
    basis_trans(:,:,j) = flip(flip(basis(:,:,j),1),2);
end
if gpu_use == 1
    basis_trans = gpuArray(basis_trans);
end
disp('Estimate the test function');
 %% computing  z_tilde and S^z to estimate the test function
if pre_process == 0
    z_max = zeros(1,num_of_exp_noise);
    if paralell_com==0
        for i=1:num_of_exp_noise
            [z]=noise_exp2d(ceil(sideLengthAlgorithm/2)+obj_sz,1,0,gpu_use);
            [z_tilde,S_z]= projected_noise_simulation_from_noise_patches(z,basis_trans,1,gpu_use);
            if test_fun == 1
             z_test = S_z;
            else
             z_test = z_tilde;
            end
            z_max(i) = max(z_test,[],"all");
        end
    else
       parfor i=1:num_of_exp_noise
            [z]=noise_exp2d(ceil(sideLengthAlgorithm/2)+obj_sz,1,0,gpu_use);
            [z_tilde,S_z]= projected_noise_simulation_from_noise_patches(z,basis_trans,1,gpu_use);
            if test_fun == 1
             z_test = S_z;
            else
             z_test = z_tilde;
            end
            z_max(i) = max(z_test,[],"all");
       end 
    end
end

if test_fun==1
    str_test = 'Sz';
else
    str_test = 'ztilde';
end

%% starting experiments for each SNR
    for l = 1:length(SNR_lst)
        SNR = SNR_lst(l);
        disp(['Starting Experiment for SNR=',num2str(SNR)]);
        sigma_noise = 1/(sqrt(SNR*obj_sz^2));
        z_max_snr = (sigma_noise^2)*z_max;
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
    
        if paralell_com==0
            % Initialize progress bar
            % h = waitbar(0, 'Progress', 'Name', ['progress for SNR= ',num2str(SNR)]);
            WaitMessage = parfor_wait(num_of_exp, 'Waitbar', true,'SNR',num2str(SNR));
            for exp = 1:num_of_exp
                WaitMessage.Send;
                %% constructing the clean image
                [X,true_locations,lst_of_object_centers,num_of_obj_per_exp] = constructing_clean_img(img_sz,num_of_obj_max,basis,dist_obj_centers,objects);
                %% constructind the data
                [Z]=noise_exp2d(img_sz,1,0,gpu_use);
                Y = X + sigma_noise*Z;
                [Y_peaks,Y_peaks_loc,Y_scoring_map] = peak_algorithm(Y,basis_trans,floor(sideLengthAlgorithm),gpu_use);
                %% estimating the test function
                [test_val] = test_function_estimation(z_max_snr,Y_peaks);
                %% multiple testing procedure
                M_L = (ceil(size(Y,1)/(sideLengthAlgorithm/2)))^2;
                [K_bon] = BON(test_val,alpha,M_L); 
                [K_bh] = BH(test_val,alpha,M_L);
                %% computing power and error rates per exp
                [power_per_exp_bh(exp),error_per_exp_bh(exp)] = power_and_fdr_per_exp(Y_peaks_loc,lst_of_object_centers,true_locations,K_bh,num_of_obj_per_exp,delta);
                [power_per_exp_bon(exp),error_per_exp_bon(exp)] = power_and_fwer_per_exp(Y_peaks_loc,lst_of_object_centers,true_locations,K_bon,num_of_obj_per_exp,delta);      
                % Update waitbar
                % waitbar(exp/num_of_exp, h, sprintf('Progress: %d%%', round(exp/num_of_exp * 100)));
                % pause(0.1); % This pause is just for demonstration purposes, remove or adjust as needed
                if exp==1
                     %% example of images
                    figure('Visible', 'off');imagesc(Y);colormap('gray');axis image; axis off
                    save_fig(output_folder,"Y.jpg")
                    figure('Visible', 'off');imagesc(X);colormap('gray');axis image; axis off
                    save_fig(output_folder,"X.jpg")
                    figure('Visible', 'off');imagesc(Z);colormap('gray');axis image; axis off
                    save_fig(output_folder,"Z.jpg")
                    figure('Visible', 'off');imagesc(Y_scoring_map);colormap('hot');axis image; axis off
                    save_fig(output_folder,"Y_score.jpg")
                    
                    %% circles on detected objects fdr
                    figure('Visible', 'off');imagesc(X);colormap('gray');axis image;axis off;
                    Y_peaks_loc_tmp = flip(Y_peaks_loc(1:K_bh,:),2);
                    viscircles(Y_peaks_loc_tmp,ceil((obj_sz+5)/2)*ones(size(Y_peaks_loc_tmp,1),1),'Color','green','LineWidth',0.5);
                    save_fig(output_folder_bh,"X_circles.jpg")
                    %% circles on detected objects fwer
                    figure('Visible', 'off');imagesc(X);colormap('gray');axis image;axis off;
                    Y_peaks_loc_tmp = flip(Y_peaks_loc(1:K_bon,:),2);
                    viscircles(Y_peaks_loc_tmp,ceil((obj_sz+5)/2)*ones(size(Y_peaks_loc_tmp,1),1),'Color','green','LineWidth',0.5);
                    save_fig(output_folder_bon,"X_circles.jpg")
                end
            end
            WaitMessage.Destroy
        else
            WaitMessage = parfor_wait(num_of_exp, 'Waitbar', true,'SNR',num2str(SNR));
            parfor exp = 1:num_of_exp
                WaitMessage.Send;
                %% constructing the clean image
                [X,true_locations,lst_of_object_centers,num_of_obj_per_exp] = constructing_clean_img(img_sz,num_of_obj_max,basis,dist_obj_centers,objects);
                %% constructind the data
                [Z]=noise_exp2d(img_sz,1,0,gpu_use);
                Y = X + sigma_noise*Z;
                [Y_peaks,Y_peaks_loc,Y_scoring_map] = peak_algorithm(Y,basis_trans,floor(sideLengthAlgorithm),gpu_use);
                %% estimating the test function
                [test_val] = test_function_estimation(z_max_snr,Y_peaks);
                %% multiple testing procedure
                M_L = (size(Y,1)/(sideLengthAlgorithm/2))^2;
                [K_bon] = BON(test_val,alpha,M_L); 
                [K_bh] = BH(test_val,alpha,M_L);
                %% computing power and error rates per exp
                [power_per_exp_bh(exp),error_per_exp_bh(exp)] = power_and_fdr_per_exp(Y_peaks_loc,lst_of_object_centers,true_locations,K_bh,num_of_obj_per_exp,delta);
                [power_per_exp_bon(exp),error_per_exp_bon(exp)] = power_and_fwer_per_exp(Y_peaks_loc,lst_of_object_centers,true_locations,K_bon,num_of_obj_per_exp,delta);      
                if exp==1
                     %% example of images
                    figure('Visible', 'off');imagesc(Y);colormap('gray');axis image; axis off
                    save_fig(output_folder,"Y.jpg")
                    figure('Visible', 'off');imagesc(X);colormap('gray');axis image; axis off
                    save_fig(output_folder,"X.jpg")
                    figure('Visible', 'off');imagesc(Z(:,:,exp));colormap('gray');axis image; axis off
                    save_fig(output_folder,"Z.jpg")
                    figure('Visible', 'off');imagesc(Y_scoring_map);colormap('hot');axis image; axis off
                    save_fig(output_folder,"Sy.jpg")          
                    %% circles on detected objects fdr
                    figure('Visible', 'off');imagesc(X);colormap('gray');axis image;axis off;
                    Y_peaks_loc_tmp = flip(Y_peaks_loc(1:K_bh,:),2);
                    viscircles(Y_peaks_loc_tmp,ceil((obj_sz+5)/2)*ones(size(Y_peaks_loc_tmp,1),1),'Color','green','LineWidth',0.5);
                    save_fig(output_folder_bh,"Xcircles.jpg")
                    %% circles on detected objects fwer
                    figure('Visible', 'off');imagesc(X);colormap('gray');axis image;axis off;
                    Y_peaks_loc_tmp = flip(Y_peaks_loc(1:K_bon,:),2);
                    viscircles(Y_peaks_loc_tmp,ceil((obj_sz+5)/2)*ones(size(Y_peaks_loc_tmp,1),1),'Color','green','LineWidth',0.5);
                    save_fig(output_folder_bon,"Xcircles.jpg")
                end
        
            end
            WaitMessage.Destroy
        end
        %% ploting and figures
        %% fdr and power plot
        figure('Visible', 'off');
        plot(1:num_of_exp,error_per_exp_bh);hold on; plot(1:num_of_exp,alpha*ones(1,num_of_exp)); xlabel('Experiments'); title(['FDR = ',num2str(mean(error_per_exp_bh))]);
        save_fig(output_folder_bh,'fdr.jpg')
        figure('Visible', 'off');
        plot(1:num_of_exp,power_per_exp_bh); xlabel('Experiments'); title(['Power = ',num2str(mean(power_per_exp_bh))]);
        save_fig(output_folder_bh,'power.jpg')
        
        %% fwer and Power plot
        figure('Visible', 'off');
        plot(1:num_of_exp,error_per_exp_bon);hold on; plot(1:num_of_exp,alpha*ones(1,num_of_exp)); xlabel('Experiments'); title(['FWER = ',num2str(mean(error_per_exp_bon))]);
        save_fig(output_folder_bon,'bon.jpg')
        figure('Visible', 'off');
        plot(1:num_of_exp,power_per_exp_bon); xlabel('Experiments');title(['Power = ',num2str(mean(power_per_exp_bon))]);
        save_fig(output_folder_bon,'power.jpg')
    end
end
