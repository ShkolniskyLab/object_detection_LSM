function [X,true_locations,lst_of_object_centers,num_of_obj] = constructing_clean_img(img_sz,num_of_obj,basis,d_obj,objects)
% Constructing the clean obj image
% This function construct the object as well as placing them randomlly
% inside an image

X = zeros(img_sz,img_sz);
true_locations = zeros(img_sz,img_sz);
lst_of_object_centers = zeros(1,2);
num_of_basis_functions = size(basis,3);
obj_sz = size(basis,1);

%% placing the clean obj in the micrograph
cnt_obj = 1;
idx_mat = ones(img_sz,img_sz);
idx_mat(1:floor(obj_sz)+1,:) = 0;
idx_mat(img_sz-floor(obj_sz)-1:img_sz,:) = 0;
idx_mat(:,1:floor(obj_sz)+1) = 0;
idx_mat(:,img_sz-floor(obj_sz)-1:img_sz) = 0;
while cnt_obj<=num_of_obj
    [row,col] = find(idx_mat);
    if or(isempty(row),isempty(col))
        num_of_obj = size(lst_of_object_centers,1);
        break
    end
    i = randi([1,length(row)]);
    i_row = row(i);
    i_col = col(i);
    row_del = max(i_row-d_obj,1):min(i_row+d_obj,img_sz);
    col_del = max(i_col-d_obj,1):min(i_col+d_obj,img_sz);
    idx_mat(row_del,col_del) = 0;
    X(i_row-floor(obj_sz/2)+1:i_row+floor(obj_sz/2),i_col-floor(obj_sz/2)+1:i_col+floor(obj_sz/2))=objects(:,:,cnt_obj);
    true_locations(i_row-floor(obj_sz/2)+1:i_row+floor(obj_sz/2),i_col-floor(obj_sz/2)+1:i_col+floor(obj_sz/2))=1;
    lst_of_object_centers(cnt_obj,1) = i_row; lst_of_object_centers(cnt_obj,2) = i_col;
    cnt_obj = cnt_obj + 1;
%     imagesc(X); colormap('gray')
end
end

