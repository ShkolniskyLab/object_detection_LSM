mapfile=cryo_fetch_emdID(2660);
volref = ReadMRC(mapfile);
N = 1000;
rots = rand_rots(N);
projs = cryo_project(volref,rots,128);
projs = permute(projs,[2,1,3]);
viewstack(projs,5,5)
SNR=100;
noisy_projs=cryo_addnoise(projs,SNR,'gaussian');
[~,var_s,var_n]=cryo_estimate_snr(noisy_projs);
[sPCA_data,denoised_images] = sPCA_PSWF(noisy_projs,  var_n);

c=sPCA_data.Coeff(:,1);

%reconstruct the images.
tmp = 2*real(sPCA_data.eig_im(:, Freqs~=0)*sPCA_data.Coeff(Freqs~=0, :));
tmp = tmp + sPCA_data.eig_im(:, Freqs==0)*real(Coeff(Freqs==0, :));
tmp = tmp+sPCA_data.Mean
I = zeros(128, 128, N);
tmp2 = zeros(128);
for i=1:5

    I(:, :, i)=tmp2+Mean;
end;