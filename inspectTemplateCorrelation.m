function inspectTemplateCorrelation(imageFile, tpl)

I = imread(imageFile);
I = mat2gray(I);

C = normxcorr2(tpl, I);

figure;
imagesc(C); axis image; colorbar
title('Raw template correlation map')

end
