function [power_per_exp,error_per_exp] = power_and_fwer_per_exp(Y_peaks_loc,lst_of_object_centers,true_locations,R_y_per_exp,num_of_obj,delta)
%UNTITLED Summary of this function goes here
    power_per_exp = 0;
    V_y_per_exp = 0;
    % R_y_per_exp = K;
    for i = 1:R_y_per_exp
        peak_is_true = 0;
        for j = 1:num_of_obj
            if norm(Y_peaks_loc(i,:)-lst_of_object_centers(j,:),Inf)<=ceil(delta/2)
              power_per_exp = power_per_exp + 1;
              peak_is_true = 1;
              break
            end
        end
        if peak_is_true == 0  % no Peak was found
            V_y_per_exp = V_y_per_exp + 1;
        end
    end
    power_per_exp = power_per_exp/num_of_obj;
    if V_y_per_exp>=1
       error_per_exp = 1;
    else
        error_per_exp = 0;
    end
end

