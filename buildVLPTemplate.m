function template = buildVLPTemplate(imageFile, labelFile)
% Build a radial contrast template from labeled VLPs
% Phase 2: learning only (no detection)

I = imread(imageFile);
I = mat2gray(I);

load(labelFile,'labels');
n = numel(labels);

maxR = 0;
profiles = {};
rInners = zeros(n,1);
rOuters = zeros(n,1);

for k = 1:n

    innerMask = labels(k).innerMask;
    outerMask = labels(k).outerMask;

    % Approximate outer radius from area
    rOuter = sqrt(nnz(outerMask)/pi);
    rOuters(k) = rOuter;

    % Approximate inner radius
    rInner = sqrt(nnz(innerMask)/pi);
    rInners(k) = rInner;

    % Distance transform from outer shell inward
    D = bwdist(~outerMask);

    % Sample intensities by distance
    r = round(D(outerMask));
    vals = I(outerMask);

    % Aggregate by radius
    maxR = max(maxR, max(r));
    prof = accumarray(r+1, vals, [], @mean, NaN);

    profiles{end+1} = prof; %#ok<AGROW>
end

% Align profiles to common length
R = maxR;
P = NaN(n, R+1);

for k = 1:n
    prof = profiles{k};
    L = min(length(prof), R+1);
    P(k,1:L) = prof(1:L);
end

% Normalize profiles (contrast relative to background)
bg = nanmean(P(:,end-5:end),2);
Pnorm = P - bg;

% Compute template statistics
template.meanProfile = nanmean(Pnorm,1);
template.stdProfile  = nanstd(Pnorm,[],1);
template.rAxis       = 0:R;

template.rInnerMean = median(rInners);
template.rOuterMean = median(rOuters);
template.rInnerRange = prctile(rInners,[10 90]);
template.rOuterRange = prctile(rOuters,[10 90]);

end
