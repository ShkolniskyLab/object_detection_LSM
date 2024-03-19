function [test_val] = test_function_real_data(z_max,Y_peaks)
% Estimation of the test function by using the law of large number of the indicator
test_val = zeros(size(Y_peaks,1),1);
for i = 1:size(Y_peaks,1)
    test_val(i) = mean(z_max>Y_peaks(i));
end


