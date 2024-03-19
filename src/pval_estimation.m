function [p_val,m_l] = pval_estimation(S_z,Y_peaks,sideLengthAlgorithm,img_sz)
% Estimation the pval from the paper
r_test_val = floor(sideLengthAlgorithm/3);
num_of_patch = floor(img_sz/r_test_val);
m_l = floor(img_sz/r_test_val)^2;
V_z = zeros(size(S_z,3),length(Y_peaks));
max_noise_patches = zeros(num_of_patch,num_of_patch,size(S_z,3));
for exp_noise = 1:size(S_z,3)
    for i=1:num_of_patch
        for j=1:num_of_patch
            tmp = S_z((i-1)*r_test_val+1:(i-1)*r_test_val+r_test_val,(j-1)*r_test_val+1:(j-1)*r_test_val+r_test_val,exp_noise);
            max_noise_patches(i,j,exp_noise) = max(tmp(:));
        end
    end
    for u_grid = 1:length(Y_peaks)
        V_z(exp_noise,u_grid) = nnz(max_noise_patches(:,:,exp_noise)>Y_peaks(u_grid));
    end
end
EV_Z = mean(V_z,1);
p_val = EV_Z/m_l;
end

