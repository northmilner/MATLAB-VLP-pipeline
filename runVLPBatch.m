function runVLPBatch(imageFolder)

load("vlp_template.mat","template","tpl2D")
load("calibration.mat","calibration")

files = dir(fullfile(imageFolder,"*.tif"));

outDir = fullfile(imageFolder,"VLP_results");
if ~exist(outDir,'dir')
    mkdir(outDir)
end

allResults = table();

for k = 1:numel(files)

    imageName = files(k).name;
    imageFile = fullfile(files(k).folder, imageName);
    fprintf("\nProcessing %s\n", imageName);

    idx = find(calibration.image == imageName);
    if isempty(idx)
        continue
    end

    nmPerPx = calibration.nm_per_px(idx);

    particleRadiusPx = round(template.rOuterMean);

    candidates = detectVLPs_2DTemplate( ...
        imageFile, ...
        tpl2D, ...
        particleRadiusPx );

    if isempty(candidates)
        continue
    end

    T = measureVLPRadii(imageFile, candidates, nmPerPx);

    T.image = repmat(string(imageName), height(T), 1);
    allResults = [allResults; T];

    I = imread(imageFile);
    fig = figure('Visible','off');
    imshow(I,[]); hold on
    theta = linspace(0,2*pi,200);

    for j = 1:height(T)

        rOuter = T.dOuter_px(j)/2;
        xCirc = T.x(j) + rOuter*cos(theta);
        yCirc = T.y(j) + rOuter*sin(theta);
        plot(xCirc,yCirc,'r','LineWidth',1.5);

        rInner = T.dInner_px(j)/2;
        xCirc = T.x(j) + rInner*cos(theta);
        yCirc = T.y(j) + rInner*sin(theta);
        plot(xCirc,yCirc,'g','LineWidth',1.2);
    end

    saveas(fig, fullfile(outDir, replace(imageName,'.tif','_overlay.png')));
    close(fig)

    writetable(T, fullfile(outDir, replace(imageName,'.tif','_vlp.csv')))
end

writetable(allResults, fullfile(outDir,"VLP_all_results.csv"))

fprintf("\nBatch complete.\n");

end