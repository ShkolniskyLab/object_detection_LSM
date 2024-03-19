function [z_tilde,S_z] = projected_noise_simulation_from_noise_patches_noise_types(z,basis,num_of_exp_noise)
%     mu = zeros(size(noise_samples,1),1);
%     noise_samples = mvnrnd(mu,noise_cov,num_of_exp_noise);
    basis = gpuArray(basis);
%     noise_samples = gpuArray(noise_samples);
    sz = size(z,1);
    sz_pn = size(conv2(reshape(z(:,:,1),sz,sz),flip(flip(basis(:,:,1),1),2),'valid'),1);
    S_z = zeros(sz_pn,sz_pn,num_of_exp_noise);
    z_tilde = zeros(sz_pn,sz_pn,num_of_exp_noise);
    parfor i=1:num_of_exp_noise
        i
        S = gpuArray(zeros(sz_pn,sz_pn,size(basis,3)));
        for j = 1:size(basis,3)
            S(:,:,j) =conv2(z(:,:,i),flip(flip(basis(:,:,j),1),2),'valid').^2;
        end
        z_tilde(:,:,i) = max(S,[],3)*size(basis,3);
        S = sum(S,3);
        S_z(:,:,i) = S;
    end
%     S_z = gather(S_z);
%     z_tilde = gather(z_tilde);
end