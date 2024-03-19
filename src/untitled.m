for i = 1:20
figure;imagesc(basis(:,:,i));colormap('gray');axis image;axis off;
save_fig('./images/',['b',num2str(i),'.jpg'])
figure;imagesc(objects(:,:,i));colormap('gray');axis image;axis off;
save_fig('./images/',['o',num2str(i),'.jpg'])
end