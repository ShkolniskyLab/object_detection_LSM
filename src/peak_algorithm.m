function [peaks,peaks_loc,S] = peak_algorithm(img,basis,sideLengthAlgorithm,gpu_use)
% computing the set tau from article
% Output: 
% peaks        list of peaks values
% peaks_loc    list of peak locations
% S            scoring map
if gpu_use == 1
    basis = gpuArray(basis);
end
num_of_basis_functions = size(basis,3);
img_sz = size(img,1);
rDelAlgorithm = floor(sideLengthAlgorithm/2);
peaks = zeros(floor(img_sz/rDelAlgorithm)^2,1);
peaks_loc = zeros(floor(img_sz/(rDelAlgorithm))^2,2);
obj_sz=size(basis,1);
% basis = gpuArray(basis);
if gpu_use==1
    img = gpuArray(img);
    S = zeros(img_sz,img_sz,num_of_basis_functions); 
    for m=1:num_of_basis_functions
        
        S(:,:,m) =gather(conv2(img,flip(flip(basis(:,:,m),1),2),'same').^2);
    end
    S = gather(sum(S,3));
else
    S = zeros(img_sz,img_sz,num_of_basis_functions); 
    for m=1:num_of_basis_functions
        S(:,:,m) =conv2(img,flip(flip(basis(:,:,m),1),2),'same').^2;
    end
    S =  sum(S,3);
end

scoringMat = S;
scoringMat(1:floor(obj_sz/2),:) = 0;scoringMat(:,1:floor(obj_sz/2)) = 0;
scoringMat(end-floor(obj_sz/2):end,:) = 0;scoringMat(:,end-floor(obj_sz/2):end) = 0;
scoring_mat_sz = size(scoringMat,1);
idxRow = 1:size(scoringMat,1);
idxCol = 1:size(scoringMat,2);
cnt = 1;
pMax = 1;
    while pMax>0 
            [pMax,I] = max(scoringMat(:));
            if pMax<=0 
               break;
            end
            peaks(cnt) = pMax; % storing the maximum values;
            idxRowCandidate = zeros(1,scoring_mat_sz); idxColCandidate = zeros(1,scoring_mat_sz);
            [i_row, i_col] = ind2sub(size(scoringMat),I);
            peaks_loc(cnt,:) = [i_row,i_col];
            idxRowCandidate (max(i_row-rDelAlgorithm,1):min(i_row+rDelAlgorithm,scoring_mat_sz)) = 1;
            idxColCandidate (max(i_col-rDelAlgorithm,1):min(i_col+rDelAlgorithm,scoring_mat_sz)) = 1;
            scoringMat(idxRow(idxRowCandidate==1),idxCol(idxColCandidate==1)) = 0;
            cnt = cnt + 1;
%             if cnt==95
%                 x = 1;
%             end
    end
    peaks = peaks(1:cnt-1);
    peaks_loc = peaks_loc(1:cnt-1,:);
end

