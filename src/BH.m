function [K] = BH(p_val,alpha,M_L)
K=-1;
    for l=0:length(p_val)-1
%         p_val(end-l)
%         ((length(p_val)-l)*alpha)/M_L
        if p_val(end-l)<=((length(p_val)-l)*alpha)/M_L
                K=length(p_val)-l;
                break
        end 
    end
end
