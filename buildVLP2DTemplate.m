function tpl = buildVLP2DTemplate(imageFile, labelFile, R)

I = imread(imageFile);
I = mat2gray(I);

load(labelFile,'labels');
n = numel(labels);

sz = 2*R + 1;
accum = zeros(sz,sz);
count = zeros(sz,sz);

[X,Y] = meshgrid(-R:R,-R:R);

for k = 1:n
    outer = labels(k).outerMask;
    inner = labels(k).innerMask;

    [y,x] = find(outer);
    cx = round(mean(x));
    cy = round(mean(y));

    if cx-R < 1 || cy-R < 1 || ...
       cx+R > size(I,2) || cy+R > size(I,1)
        continue
    end

    patch = I(cy-R:cy+R, cx-R:cx+R);

    accum = accum + patch;
    count = count + 1;
end

tpl = accum ./ max(count,1);
tpl = tpl - mean(tpl(:));
tpl = tpl / norm(tpl(:));

end
