DATA_ROOT = fullfile('/export', 'hashimoto', 'Matlab', 'ResultFiles');
% for Load
LOAD_DIR = fullfile(DATA_ROOT, 'Results', 'set_roi');
LOAD_OLD_DIR = fullfile(LOAD_DIR, 'OldTypeData');
LOAD_EXTENSION = '*.mat';
% for Save
PROJECT_NAME = 'fit_images';
SAVE_DIR = fullfile(DATA_ROOT, 'Results', PROJECT_NAME);
SAVE_OLD_DIR = fullfile(SAVE_DIR, 'OldTypeData');
mkdir(SAVE_DIR);
mkdir(SAVE_OLD_DIR);
LOG_DIR = fullfile(DATA_ROOT, 'Logs', PROJECT_NAME);
IMG_DIR = fullfile(LOG_DIR, 'img');
mkdir(LOG_DIR);
mkdir(IMG_DIR);
log_file = fopen(fullfile(LOG_DIR, 'log.md'), 'w');


new_data_list = dir(fullfile(LOAD_DIR, LOAD_EXTENSION));
old_data_list = dir(fullfile(LOAD_OLD_DIR, LOAD_EXTENSION));
data_list = cat(1, new_data_list, old_data_list);

for i = 1:length(data_list)
    % ログ
    text = ['## Data : ',data_list(i).name,' (', num2str(i), '/', num2str(length(data_list)), ')'];
    disp(text);
    fprintf(log_file, '%s\n', text);

    % load
    if i <= length(new_data_list)
        data = load(fullfile(LOAD_DIR, data_list(i).name)).data;
    else
        data = load(fullfile(LOAD_OLD_DIR, data_list(i).name)).data;
    end

    % size info
    sizeT1D = squeeze(size(data.T1D(:,:,1,1)));
    sizeT2 = squeeze(size(data.T2(:,:,1)));

    % fitting ADC, T1D, T1DSUB
    data.ADC = fitADC(data.ADC, sizeT2);
    if i <= length(new_data_list)
        data.T1D = fitT1D(data.T1D, sizeT2);
    end
    data.T1DSUB = fitT1D(data.T1DSUB, sizeT2);

    % fitting ROI images
    if strcmp(data.ROI_TYPE, 'Tissue4D')
        circleInfo = findCirclesCenter(data.ROI_IMAGE, data.MAP_IMAGE);
        [centerRoi, centerMap] = centerImage(data.ROI_IMAGE, data.MAP_IMAGE, circleInfo);
        [overlay, data.ROI_IMAGE] = fitRoiImage(data.ROI_IMAGE, data.MAP_IMAGE, sizeT1D, sizeT2, circleInfo);
        [~, data.MASK_IMAGE] = fitRoiImage(data.MASK_IMAGE, data.MAP_IMAGE, sizeT1D, sizeT2, circleInfo);
        data.ROI_IMAGE = fitT1D(data.ROI_IMAGE, sizeT2);
        data.MASK_IMAGE = fitT1D(data.MASK_IMAGE, sizeT2);
        data.MAP_IMAGE = fitT1D(data.MAP_IMAGE, sizeT2);
        overlay = fitT1D(overlay, sizeT2);
    elseif strcmp(data.ROI_TYPE, 'KROI')
        data.ROI_IMAGE = fitT1D(data.ROI_IMAGE, sizeT2);
        data.MASK_IMAGE = fitT1D(data.MASK_IMAGE, sizeT2);
    end

    % save images for log
    filename = [data_list(i).name(1:end-4),'_','ADC.png'];
    imwrite(double(squeeze(data.ADC(:,:,1)))*100, fullfile(IMG_DIR, filename));
    text = ['![ADC](img/',filename,')'];
    fprintf(log_file, '%s\n', text);

    filename = [data_list(i).name(1:end-4),'_','T2.png'];
    imwrite(double(squeeze(data.T2(:,:,1)))/double(max(data.T2(:))), fullfile(IMG_DIR, filename));
    text = ['![T2](img/',filename,')'];
    fprintf(log_file, '%s\n', text);

    if i <= length(new_data_list)
        filename = [data_list(i).name(1:end-4),'_','T1D.png'];
        imwrite(double(squeeze(data.T1D(:,:,1,1)))/double(max(data.T1D(:))), fullfile(IMG_DIR, filename));
        text = ['![T1D](img/',filename,')'];
        fprintf(log_file, '%s\n', text);
    end

    filename = [data_list(i).name(1:end-4),'_','T1DSUB.png'];
    imwrite(double(squeeze(data.T1DSUB(:,:,1,end)))/double(max(data.T1DSUB(:))), fullfile(IMG_DIR, filename));
    text = ['![T1DSUB](img/',filename,')'];
    fprintf(log_file, '%s\n', text);

    
    filename = [data_list(i).name(1:end-4),'_','RoiImage.png'];
    imwrite(uint8(data.ROI_IMAGE), fullfile(IMG_DIR, filename));
    text = ['![RoiImage](img/',filename,')'];
    fprintf(log_file, '%s\n', text);
    
    if strcmp(data.ROI_TYPE, 'Tissue4D')
        filename = [data_list(i).name(1:end-4),'_','MapImage.png'];
        imwrite(uint8(data.MAP_IMAGE), fullfile(IMG_DIR, filename));
        text = ['![MapImage](img/',filename,')'];
        fprintf(log_file, '%s\n', text);
        
        filename = [data_list(i).name(1:end-4),'_','Overlay.png'];
        imwrite(uint8(overlay), fullfile(IMG_DIR, filename));
        text = ['![Overlay](img/',filename,')'];
        fprintf(log_file, '%s\n', text);
    end

    filename = [data_list(i).name(1:end-4),'_','MaskImage.png'];
    imwrite(uint8(data.MASK_IMAGE), fullfile(IMG_DIR, filename));
    text = ['![MaskImage](img/',filename,')'];
    fprintf(log_file, '%s\n', text);

    % save
    if i <= length(new_data_list)
        save(fullfile(SAVE_DIR, data_list(i).name), 'data');
    else
        save(fullfile(SAVE_OLD_DIR, data_list(i).name), 'data');
    end
   
end
% ログ
text = ['Done'];
disp(text);
fprintf(log_file, '%s\n', text); 

function [output] = fitADC(ADC, T2size)
% Fitting ADC Images with the Center to fit FoV of T2WI
    
    % header info
    T2_FoV_height = 180;
    T2_FoV_width = 180;
    ADC_FoV_height = 280;
    ADC_FoV_width = 350;
            
    [w, h, ~] = size(ADC);
            
    height = uint32(h * (T2_FoV_height/ADC_FoV_height));
    width = uint32(w * (T2_FoV_width/ADC_FoV_width));
    
    wspace = uint32((w-width)/2);
    hspace = uint32((h-height)/2);
    
    output = ADC(wspace+1:wspace+width, hspace+1:hspace+height, :);
    output = imresize(output, T2size);  
end
    
function [output] = fitT1D(T1D, T2size)
% Fitting T1Dynamic Images with the Center to fit FoV of T2WI
    
    % header info
    T1D_FoV_height = 250;
    T1D_FoV_width = 250;
    T2_FoV_height = 180;
    T2_FoV_width = 180;
        
    [w, h, ~, ~] = size(T1D);
        
    width = uint32(w * (T2_FoV_width/T1D_FoV_width));
    height = uint32(h * (T2_FoV_height/T1D_FoV_height));
        
    wspace = uint32((w-width)/2);
    hspace = uint32((h-height)/2);
    
    output = T1D(wspace+1:wspace+width, hspace+1:hspace+height, :, :);
    output = imresize(output, T2size); 
end

function [overlay, fitImage] = fitRoiImage(roiImage, mapImage, sizeT1D, sizeT2, circleInfo)
% Fitting ROI and roiImage for with mapImage and FoV of T1WI and T2WI

    T1D_FoV_height = 250;
    T1D_FoV_width = 250;
    T2_FoV_height = 180;
    T2_FoV_width = 180;

    ROI_RADIUS = 2;
    COLOR =[[255,0,0];
            [0,255,0];
            [255,255,0];
            [0,255,255]];

    ALPHA = 0.6;

    magentaWSize = circleInfo.magentaWRange(2) - circleInfo.magentaWRange(1) + 1;
    colorWSize = circleInfo.colorWRange(2) - circleInfo.colorWRange(1)+ 1;
    roiImage = imresize(roiImage, colorWSize/magentaWSize);

    [w,h,c] = size(roiImage);
    [W,H,C] = size(mapImage);
    overlay = mapImage;
    fitImage = zeros(size(mapImage));
    initPos = [ circleInfo.colorCenter(1) - uint32(circleInfo.magentaCenter(1)*colorWSize/magentaWSize) + 1, ...
                circleInfo.colorCenter(2) - uint32(circleInfo.magentaCenter(2)*colorWSize/magentaWSize) + 1 ];
    for i = 1 : w
        for j = 1 : h
            overlayPos = [initPos(1)+i-1, initPos(2)+j-1];
            if 0 < overlayPos(1) && overlayPos(1) <= W && 0 < overlayPos(2) && overlayPos(2) <= H
                overlay(overlayPos(1), overlayPos(2), :) = ... 
                    (1-ALPHA) .* overlay(overlayPos(1), overlayPos(2), :) + ALPHA .* roiImage(i,j,:);
                fitImage(overlayPos(1), overlayPos(2), :) = roiImage(i,j,:);
            end
        end
    end
    overlay(overlay > 255) = 255;
end

function [roiImage, mapImage] = centerImage(roiImage, mapImage, circleInfo)
    [w,h,c] = size(roiImage);
    WHITE = [255; 255; 255];
    
    for i = 1 : w
        for j = 1 : h
            if i == circleInfo.magentaCenter(1)
                roiImage(i,j,:) = WHITE;
            end
            if j == circleInfo.magentaCenter(2)
                roiImage(i,j,:) = WHITE;
            end
            if i == circleInfo.colorCenter(1)
                mapImage(i,j,:) = WHITE;
            end
            if j == circleInfo.colorCenter(2)
                mapImage(i,j,:) = WHITE;
            end
        end
    end
end

function [circleInfo] = findCirclesCenter(roiImage, mapImage)

    IGNORE_RANGE = 80;
    MAGENTA = [255; 0; 255];

    [w, h, c] = size(roiImage); 

    magentaWMin = w;
    magentaWMax = 0;
    magentaHMin = h;
    magentaHMax = 0;
    for i = 1 : w
        for j = 1 : h
            if isequal(squeeze(roiImage(i,j,:)), MAGENTA)
                if i < magentaWMin
                    magentaWMin = i;
                end
                if magentaWMax < i
                    magentaWMax = i;
                end
            end
        end
    end
    for i = 1 : w
        for j = 1 : h
            if isequal(squeeze(roiImage(i,j,:)), MAGENTA)
                if i == magentaWMin || i == magentaWMax
                    if j < magentaHMin
                        magentaHMin = j;
                    end
                    if magentaHMax < j
                        magentaHMax = j;
                    end
                end
            end
        end
    end
    magentaWCenter = magentaWMin + uint32((magentaWMax - magentaWMin)/2);
    magentaHCenter = magentaHMin + uint32((magentaHMax - magentaHMin)/2);

    magentaCenter = [magentaWCenter, magentaHCenter];
    magentaWRange = [magentaWMin, magentaWMax];


    colorWMin = w;
    colorWMax = 0;
    colorHMin = h;
    colorHMax = 0;
    for i = IGNORE_RANGE : w - IGNORE_RANGE
        for j = IGNORE_RANGE : h - IGNORE_RANGE
            if mapImage(i,j,1) == mapImage(i,j,2) && mapImage(i,j,1) == mapImage(i,j,3)
                continue;
            else
                if i < colorWMin
                    colorWMin = i;
                end
                if colorWMax < i
                    colorWMax = i;
                end
            end
        end
    end
    for i = IGNORE_RANGE : w - IGNORE_RANGE
        for j = IGNORE_RANGE : h - IGNORE_RANGE
            if mapImage(i,j,1) == mapImage(i,j,2) && mapImage(i,j,1) == mapImage(i,j,3)
                continue;
            else
                if i == colorWMin || i == colorWMax
                    if j < colorHMin
                        colorHMin = j;
                    end
                    if colorHMax < j
                        colorHMax = j;
                    end
                end
            end
        end
    end
    colorWCenter = colorWMin + uint32((colorWMax - colorWMin)/2);
    colorHCenter = colorHMin + uint32((colorHMax - colorHMin)/2);
    
    colorCenter = [colorWCenter, colorHCenter];
    colorWRange = [colorWMin, colorWMax];


    circleInfo = struct('magentaCenter', magentaCenter, ...
                        'colorCenter', colorCenter, ...
                        'magentaWRange', magentaWRange, ...
                        'colorWRange', colorWRange);
end