ex=randi(2,10,17,12)-1;
E=permute(ex,[2,1,3]);
[r,c]=find(E);
N=zeros(size(ex,1),1,size(ex,3));
for k=1:size(ex,3)*size(ex,1)
    f=find(c==k);
    try%in case some rows don't have any 1's
        N(k)=r(f(randperm(length(f),1)));
    end
end