function candidates = detectVLPs_2DTemplate(imageFile, tpl2D, particleRadiusPx)

I = imread(imageFile);
I = mat2gray(I);

C = normxcorr2(tpl2D, I);

[th,tw] = size(tpl2D);
offsetX = floor(tw/2);
offsetY = floor(th/2);

C = C(offsetY+1:offsetY+size(I,1), ...
      offsetX+1:offsetX+size(I,2));

mu = mean(C(:));
sigma = std(C(:));
thr = mu + 3*sigma;

mask = C > thr;
peaks = imregionalmax(C) & mask;

[y,x] = find(peaks);
scores = C(peaks);

% Keep strongest 75% (much less strict than 10%)
keepFrac = 0.75;

if numel(scores) > 0
    scoreCut = quantile(scores, 1 - keepFrac);
    strong = scores >= scoreCut;
else
    strong = false(size(scores));
end

x = x(strong);
y = y(strong);
scores = scores(strong);

keep = true(numel(x),1);

for i = 1:numel(x)
    if ~keep(i), continue; end
    dx = x(i) - x;
    dy = y(i) - y;
    d2 = dx.^2 + dy.^2;
    suppress = d2 < particleRadiusPx^2 & scores < scores(i);
    keep(suppress) = false;
end

x = x(keep);
y = y(keep);
scores = scores(keep);

dOuter_px = repmat(2*particleRadiusPx, numel(x),1);

candidates = [x, y, scores, dOuter_px];

end