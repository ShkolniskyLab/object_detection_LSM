function [V_y] = V_y_per_u(Y_peaks,Y_peaks_loc,true_locations,u_grid)
%UNTITLED2 Summary of this function goes here
Y_peaks_noise = zeros(size(Y_peaks));
    for j = 1:length(Y_peaks)
        if true_locations(Y_peaks_loc(j,1),Y_peaks_loc(j,2)) == 0
             Y_peaks_noise(j) = Y_peaks(j);
        end
    end
    V_y = zeros(length(u_grid),1);
    for i = 1:length(u_grid)
        V_y(i) = nnz(Y_peaks_noise>=u_grid(i));
    end
end

