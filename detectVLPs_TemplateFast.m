function candidates = detectVLPs_TemplateFast(imageFile, template)
% Phase 3: Fast VLP detection using
% (1) LoG for candidate proposal
% (2) Learned radial template for confirmation
%
% Returns: [x y score] for confirmed VLP candidates

% --- Load image ---
I = imread(imageFile);
I = mat2gray(I);
[H,W] = size(I);

% --- ===============================
% Stage 1: LoG candidate proposal
% ===============================

sigma = template.rOuterMean / 2;
h = fspecial('log', ceil(6*sigma), sigma);
LoG = -imfilter(I, h, 'replicate');

% Conservative threshold
thr = mean(LoG(:)) + 1.5*std(LoG(:));
proposalMask = LoG > thr;

% Non-maximum suppression
proposalMask = proposalMask & imregionalmax(LoG);

[y0,x0] = find(proposalMask);

fprintf('Template confirmation on %d candidates...\n', numel(x0));

% --- ===============================
% Prepare template
% ===============================

tpl = template.meanProfile(:);
tpl = tpl - mean(tpl);
tpl = tpl / norm(tpl);

R = length(tpl) - 1;

% Pad image
Ip = padarray(I,[R R],'replicate');

% Precompute distance map
[Xg,Yg] = meshgrid(-R:R, -R:R);
D = round(sqrt(Xg.^2 + Yg.^2));

scores = NaN(numel(x0),1);
keep   = false(numel(x0),1);

% --- ===============================
% Stage 2: Template confirmation
% ===============================

for k = 1:numel(x0)

    x = x0(k);
    y = y0(k);

    % Extract patch
    patch = Ip(y:y+2*R, x:x+2*R);

    % Only use pixels within template radius
    mask = D <= R;
    d = D(mask) + 1;
    v = patch(mask);

    % Radial profile (mean intensity per radius)
    prof = accumarray(d(:), v(:), [R+1 1], @mean, NaN);

    % Reject incomplete profiles
    if any(isnan(prof))
        continue
    end

    % Normalize profile
    p = prof - mean(prof);
    p = p / (norm(p) + eps);

    % Correlation score
    scores(k) = dot(p, tpl);

end

% --- ===============================
% Acceptance rule (conservative)
% ===============================

validScores = scores(~isnan(scores));

if isempty(validScores)
    candidates = zeros(0,3);
    fprintf('No valid template matches.\n');
    return
end

fprintf('Score stats: min=%.3f, median=%.3f, max=%.3f\n', ...
    min(validScores), median(validScores), max(validScores));

% Keep top matches (data-driven threshold)
% --- Local maximum selection (object-level decision) ---
keep = false(size(scores));

for k = 1:numel(scores)
    if isnan(scores(k))
        continue
    end

    % Keep if score is locally high
    if scores(k) > median(validScores)
        keep(k) = true;
    end
end

candidates = [x0(keep), y0(keep), scores(keep)];


end
