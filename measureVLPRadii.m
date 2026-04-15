function T = measureVLPRadii(imageFile, candidates, nm_per_px)

I = imread(imageFile);
I = mat2gray(I);

[H,W] = size(I);
n = size(candidates,1);

dInner_px = NaN(n,1);
dOuter_px = NaN(n,1);
confidence = NaN(n,1);

angles = linspace(0, 2*pi, 60);   % many angles for radial averaging

for i = 1:n

    x0 = round(candidates(i,1));
    y0 = round(candidates(i,2));
    rMax = round(candidates(i,4)/2);

    % -------- INNER (cross-section rotated max) --------
    innerDiameters = [];

    rotAngles = linspace(0, pi, 18);

    for a = rotAngles

        xLine = round(x0 + (-rMax:rMax) * cos(a));
        yLine = round(y0 + (-rMax:rMax) * sin(a));

        valid = xLine>=1 & xLine<=W & yLine>=1 & yLine<=H;
        xLine = xLine(valid);
        yLine = yLine(valid);

        if numel(xLine) < 30
            continue
        end

        profile = I(sub2ind(size(I), yLine, xLine));
        profile = smoothdata(profile,'gaussian',5);

        grad = gradient(profile);

      [~, idxNeg] = min(grad);

% Find positive gradient indices after idxNeg
posCandidates = find(grad > 0);
posCandidates = posCandidates(posCandidates > idxNeg);

if isempty(posCandidates)
    continue
end

% Choose strongest positive gradient after idxNeg
[~, relIdx] = max(grad(posCandidates));
idxPos = posCandidates(relIdx);
        innerDiameters(end+1) = abs(idxPos - idxNeg); %#ok<AGROW>
    end

    if isempty(innerDiameters)
        continue
    end

    dInner_px(i) = max(innerDiameters);

% -------- OUTER (local radial refinement) --------

r0 = round(candidates(i,4)/2);  % template-based radius

radii = (r0-10):(r0+10);
radii = radii(radii > 5);  % avoid too small radii

radialProfile = zeros(size(radii));

for idxR = 1:length(radii)
    r = radii(idxR);
    intensitySum = 0;
    count = 0;

    for a = linspace(0,2*pi,60)
        x = round(x0 + r*cos(a));
        y = round(y0 + r*sin(a));

        if x>=1 && x<=W && y>=1 && y<=H
            intensitySum = intensitySum + I(y,x);
            count = count + 1;
        end
    end

    if count > 0
        radialProfile(idxR) = intensitySum / count;
    else
        radialProfile(idxR) = NaN;
    end
end

radialProfile = smoothdata(radialProfile,'gaussian',3);

gradR = gradient(radialProfile);

[~, idxBest] = min(gradR);  % strongest outward drop

rRefined = radii(idxBest);

dOuter_px(i) = 2*rRefined;

    confidence(i) = 1/(std(innerDiameters)+eps);

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
