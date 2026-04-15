function labelVLPs(imageFile, outFile)
% Robust freehand labeler for Virus-Like Particles (VLPs)
% User labels INNER shell and OUTER shell
% Uses explicit dialogs to avoid UI lockups

I = imread(imageFile);
I = mat2gray(I);

labels = struct( ...
    'innerMask',{}, ...
    'outerMask',{}, ...
    'imageFile',{}, ...
    'index',{} );

fig = figure('Name','VLP Labeler','NumberTitle','off');
imshow(I,[]); hold on

k = 0;
keepLabeling = true;

while keepLabeling

    % ---- INNER SHELL ----
    title({'Draw INNER shell (dark structure)', ...
           'Double-click to finish'});
    hInner = imfreehand;
    innerMask = hInner.createMask;
    delete(hInner)

    visboundaries(innerMask,'Color','g');

    % ---- OUTER SHELL ----
    title({'Draw OUTER shell (light envelope)', ...
           'Double-click to finish'});
    hOuter = imfreehand;
    outerMask = hOuter.createMask;
    delete(hOuter)

    visboundaries(outerMask,'Color','r');

    % ---- CONFIRM ----
    choice = questdlg( ...
        'Keep this labeled VLP?', ...
        'Confirm label', ...
        'Yes','Redo','Finish','Yes');

    switch choice
        case 'Yes'
            k = k + 1;
            labels(k).innerMask = innerMask;
            labels(k).outerMask = outerMask;
            labels(k).imageFile = imageFile;
            labels(k).index = k;

        case 'Redo'
            % Do nothing, just redraw
        case 'Finish'
            keepLabeling = false;
    end

    % Reset view
    cla
    imshow(I,[]); hold on

end

close(fig)

save(outFile,'labels')
fprintf('Saved %d labeled VLPs to %s\n',numel(labels),outFile)

end
