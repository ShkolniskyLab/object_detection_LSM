function [V_z] = V_z_per_u(noise_peaks,u_grid)
V_z = zeros(length(u_grid),1);
%UNTITLED2 Summary of this function goes here
    for i = 1:length(u_grid)
        V_z(i) = nnz(noise_peaks>=u_grid(i));
    end
end

