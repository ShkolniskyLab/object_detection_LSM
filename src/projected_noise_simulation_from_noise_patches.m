function [z_tilde,S_z] = projected_noise_simulation_from_noise_patches(z,basis,num_of_exp_noise,gpu_use)
    z = repmat(z,[1,1,size(basis,3)]);
    sz = size(z,1);
    sz_pn = size(conv2(reshape(z(:,:,1),sz,sz),basis(:,:,1),'valid'),1);
    S_z = zeros(sz_pn,sz_pn,num_of_exp_noise);
    z_tilde = zeros(sz_pn,sz_pn,num_of_exp_noise);
    
    for i=1:num_of_exp_noise
        if gpu_use == 1
            S = gpuArray(zeros(sz_pn,sz_pn,size(basis,3)));
        else
            S = zeros(sz_pn,sz_pn,size(basis,3));
        end
        for j = 1:size(basis,3)
            S(:,:,j) =conv2(z(:,:,i),basis(:,:,j),'valid').^2;
        end
        z_tilde(:,:,i) = max(S,[],3)*size(basis,3);
        S = sum(S,3);
        S_z(:,:,i) = S;
    end
    S_z = gather(S_z);
    z_tilde = gather(z_tilde);
end