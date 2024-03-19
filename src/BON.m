function [K] = BON(test_val,alpha,M_L)
if isempty(test_val)
    K = 0;
else
    K=length(test_val);
        for l=1:length(test_val)
            if test_val(l)>alpha/M_L
                    K=l-1;
                    break
            end 
        end
end

end
