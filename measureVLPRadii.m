function T = measureVLPRadii(imageFile, candidates, nm_per_px)

I = imread(imageFile);
I = mat2gray(I);

[H,W] = size(I);
n = size(candidates,1);

dInner_px = NaN(n,1);
dOuter_px = NaN(n,1);
confidence = NaN(n,1);

% Use template radius as outer radius
load("vlp_template.mat","template")
particleRadiusPx = round(template.rOuterMean);

for i = 1:n

    x0 = round(candidates(i,1));
    y0 = round(candidates(i,2));

    rOuter = particleRadiusPx;

    % Horizontal profile
    xRange = max(1,x0-rOuter):min(W,x0+rOuter);
    hProfile = I(y0, xRange);

    % Vertical profile
    yRange = max(1,y0-rOuter):min(H,y0+rOuter);
    vProfile = I(yRange, x0)';

    % Smooth
    hProfile = smoothdata(hProfile,'gaussian',5);
    vProfile = smoothdata(vProfile,'gaussian',5);

    dH = computeDiameter(hProfile);
    dV = computeDiameter(vProfile);

    if ~isnan(dH) && ~isnan(dV)
        dInner_px(i) = mean([dH dV]);
        dOuter_px(i) = 2*rOuter;
        confidence(i) = 1/(std([dH dV])+eps);
    end
end

dInner_nm = dInner_px * nm_per_px;
dOuter_nm = dOuter_px * nm_per_px;

T = table( ...
    candidates(:,1), candidates(:,2), ...
    dInner_px, dInner_nm, ...
    dOuter_px, dOuter_nm, ...
    confidence, ...
    'VariableNames',{ ...
        'x','y', ...
        'dInner_px','dInner_nm', ...
        'dOuter_px','dOuter_nm', ...
        'confidence'});
end


function diameter = computeDiameter(profile)

grad = gradient(profile);

% Find strongest negative gradient (entering dark core)
[~, idxNeg] = min(grad);

% Find positive gradients AFTER idxNeg
posCandidates = find(grad > 0);

posCandidates = posCandidates(posCandidates > idxNeg);

if isempty(posCandidates)
    diameter = NaN;
    return
end

% Among those, find the strongest positive gradient
[~, maxIdx] = max(grad(posCandidates));

idxPos = posCandidates(maxIdx);

diameter = abs(idxPos - idxNeg);

end