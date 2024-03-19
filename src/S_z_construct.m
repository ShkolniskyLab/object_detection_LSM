function [S] = S_z_construct(img,basis)
% computing the set tau from article
num_of_basis_functions = size(basis,3);
img_sz = size(img,1);
    if img_sz<7000
        img = gpuArray(img);
        S = zeros(img_sz,img_sz,num_of_basis_functions); 
        parfor m=1:num_of_basis_functions
            S(:,:,m) =gather(conv2(img,flip(flip(basis(:,:,m),1),2),'same').^2);
        end
        S = sum(S,3);
    else
        S = zeros(img_sz,img_sz,num_of_basis_functions); 
        parfor m=1:num_of_basis_functions
            S(:,:,m) =conv2(img,flip(flip(basis(:,:,m),1),2),'same').^2;
        end
        S = sum(S,3);
    end
end

