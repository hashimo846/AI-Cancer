DATA_ROOT = fullfile('/export', 'hashimoto', 'Matlab', 'ResultFiles');
% for Load
LOAD_DIR = fullfile(DATA_ROOT, 'Results', 'standardize');
LOAD_OLD_DIR = fullfile(LOAD_DIR, 'OldTypeData');
LOAD_EXTENSION = '*.mat';
% for Save
PROJECT_NAME = 'extract_slice';
SAVE_DIR = fullfile(DATA_ROOT, 'Results', PROJECT_NAME);
SAVE_OLD_DIR = fullfile(SAVE_DIR, 'OldTypeData');
mkdir(SAVE_DIR);
mkdir(SAVE_OLD_DIR);
LOG_DIR = fullfile(DATA_ROOT, 'Logs', PROJECT_NAME);
IMG_DIR = fullfile(LOG_DIR, 'img');
mkdir(LOG_DIR);
mkdir(IMG_DIR);
log_file = fopen(fullfile(LOG_DIR, 'log.md'), 'w');
ERROR_DIR = fullfile(LOAD_DIR, 'error');
mkdir(ERROR_DIR);
error_file = fopen(fullfile(ERROR_DIR, 'error.csv'), 'w');
% main param(抽出するスライス数)
SLICE_NUM = 3;
T1_SLICE_DEPTH = 3.5;
T2_SLICE_DEPTH = 3;

new_data_list = dir(fullfile(LOAD_DIR, LOAD_EXTENSION));
old_data_list = dir(fullfile(LOAD_OLD_DIR, LOAD_EXTENSION));
data_list = cat(1, new_data_list, old_data_list);

% default 1
start_num = 1;
for i = start_num:length(data_list)

    % ログ
    text = ['## Data : ',data_list(i).name,' (', num2str(i), '/', num2str(length(data_list)), ')'];
    disp(text);
    fprintf(log_file, '%s\n', text);

    % load
    if i <= length(new_data_list)
        data = load(fullfile(LOAD_DIR, data_list(i).name)).data;
        new_check = true;
    else
        data = load(fullfile(LOAD_OLD_DIR, data_list(i).name)).data;
        new_check = false;
    end

    % ログ
    text = strcat('New Check: ', string(new_check),'   ROI Type: ', data.ROI_TYPE);
    disp(text);
    fprintf(log_file, '%s\n', text);

    % ここの場合分け、要検討
    if strcmp(data.ROI_TYPE, 'Tissue4D')
        if new_check
            [slice, series] = findMatchSlice(data.MAP_IMAGE, data.T1D);
        else
            [slice, series] = findMatchSlice(data.MAP_IMAGE, data.T1DSUB);
        end

    elseif strcmp(data.ROI_TYPE, 'KROI')
        % KROI画像を他の画像にあわせる
        data.ROI_IMAGE = imrotate(data.ROI_IMAGE, -90);
        data.MASK_IMAGE = imrotate(data.MASK_IMAGE, -90);
        if new_check
            [slice, series] = findMatchSlice(data.ROI_IMAGE, data.T1D);
        else
            [slice, series] = findMatchSlice(data.ROI_IMAGE, data.T1DSUB);   
        end
    end

    % ログ
    text = ['Target Slice: ', num2str(slice),'   Target Series: ', num2str(series)];
    disp(text);
    fprintf(log_file, '%s\n', text);

    % エラー処理
    if slice <= uint8(SLICE_NUM/2-0.5) | (24-uint8(SLICE_NUM/2-0.5)) < slice
        fprintf(error_file, '%s,%s\n', data_list(i).name(1:10), data_list(i).name(12:19));
        if new_check
            disp(['movefile ', fullfile(LOAD_DIR, data_list(i).name), ' ', ERROR_DIR]);
            movefile(fullfile(LOAD_DIR, data_list(i).name), ERROR_DIR);
        else
            disp(['movefile ', fullfile(LOAD_OLD_DIR, data_list(i).name), ' ', ERROR_DIR]);
            movefile(fullfile(LOAD_OLD_DIR, data_list(i).name), ERROR_DIR);
        end
        % ログ
        text = strcat('error skip');
        disp(text);
        fprintf(log_file, '%s\n', text);
        continue;
    end

    if strcmp(data.ROI_TYPE, 'Tissue4D')
        % MapImage
        filename = [data_list(i).name(1:end-4),'_','MapImage.png'];
        imwrite(data.MAP_IMAGE, fullfile(IMG_DIR, filename));
        text = ['![MapImage](img/',filename,')'];
        fprintf(log_file, '%s\n', text);
    elseif strcmp(data.ROI_TYPE, 'KROI')
        % RoiImage
        filename = [data_list(i).name(1:end-4),'_','RoiImage.png'];
        imwrite(data.ROI_IMAGE, fullfile(IMG_DIR, filename));
        text = ['![RoiImage](img/',filename,')'];
        fprintf(log_file, '%s\n', text);
    end

    % スライス抽出
    if new_check
        data.T1D = data.T1D(:,:,slice - uint8(SLICE_NUM/2-0.5) : slice + uint8(SLICE_NUM/2-0.5),:);
        data.T1DSUB = data.T1DSUB(:,:,slice - uint8(SLICE_NUM/2-0.5):slice + uint8(SLICE_NUM/2-0.5),:);
        depth = T1_SLICE_DEPTH * slice;
        slice = uint32(depth / T2_SLICE_DEPTH);
        data.T2 = data.T2(:,:,slice - uint32(SLICE_NUM/2-0.5) : slice + uint32(SLICE_NUM/2-0.5));
        data.ADC = data.ADC(:,:,slice - uint32(SLICE_NUM/2-0.5) : slice + uint32(SLICE_NUM/2-0.5));
    else
        data.T1DSUB = data.T1DSUB(:,:,slice - uint8(SLICE_NUM/2-0.5):slice + uint8(SLICE_NUM/2-0.5),:);
        depth = T1_SLICE_DEPTH * slice;
        slice = uint32(depth / T2_SLICE_DEPTH);
        data.T2 = data.T2(:,:,slice - uint32(SLICE_NUM/2-0.5) : slice + uint32(SLICE_NUM/2-0.5));
        data.ADC = data.ADC(:,:,slice - uint32(SLICE_NUM/2-0.5) : slice + uint32(SLICE_NUM/2-0.5));
    end

    center = uint8(SLICE_NUM/2+0.5);

    if new_check
        % T1D
        filename = [data_list(i).name(1:end-4),'_','T1D.png'];
        imwrite(squeeze(data.T1D(:,:,center,series)), fullfile(IMG_DIR, filename));
        text = ['![T1D](img/',filename,')'];
        fprintf(log_file, '%s\n', text);

        % T1DSUB
        filename = [data_list(i).name(1:end-4),'_','T1DSUB.png'];
        imwrite(squeeze(data.T1DSUB(:,:,center,end)), fullfile(IMG_DIR, filename));
        text = ['![T1DSUB](img/',filename,')'];
        fprintf(log_file, '%s\n', text);
    else
        % T1DSUB
        filename = [data_list(i).name(1:end-4),'_','T1DSUB.png'];
        imwrite(squeeze(data.T1DSUB(:,:,center,series)), fullfile(IMG_DIR, filename));
        text = ['![T1DSUB](img/',filename,')'];
        fprintf(log_file, '%s\n', text);
    end

    % ADC
    filename = [data_list(i).name(1:end-4),'_','ADC.png'];
    imwrite(squeeze(data.ADC(:,:,center)), fullfile(IMG_DIR, filename));
    text = ['![ADC](img/',filename,')'];
    fprintf(log_file, '%s\n', text);

    % T2
    filename = [data_list(i).name(1:end-4),'_','T2.png'];
    imwrite(squeeze(data.T2(:,:,center)), fullfile(IMG_DIR, filename));
    text = ['![T2](img/',filename,')'];
    fprintf(log_file, '%s\n', text);

    

    % save
    if new_check == true
        save(fullfile(SAVE_DIR, data_list(i).name), 'data');
    else
        save(fullfile(SAVE_OLD_DIR, data_list(i).name), 'data');
    end

    disp(data);

    
end

function [index, seriesIndex] = findMatchSlice(mapImage, T1D)

    [w,h,c] = size(mapImage);
    T1D = imresize(T1D, [w,h]);

    T1D = double(T1D) ./ double(max(T1D(:)));
    mapImage = double(mapImage) ./ double(max(mapImage(:)));

    [~,~,slice,series] = size(T1D);
    cosineMax = 0;
    index = 0;
    seriesIndex = 0;
    for t = 1 : series
        for i = 1 : slice
            ip = 0;
            norm1 = 0;
            norm2 = 0;
            
            for j = 1 : w
                for k = 1 : h
                    if mapImage(j,k,1) == mapImage(j,k,2) && mapImage(j,k,1) == mapImage(j,k,3)
                        ip = ip + mapImage(j,k,1) * T1D(j,k,i,t);
                        norm1 = norm1 + (mapImage(j,k,1) ^ 2);
                        norm2 = norm2 + (T1D(j,k,i,t) ^ 2);
                    end
                end
            end

            cosine = ip / (sqrt(norm1) * sqrt(norm2));
            if cosineMax < cosine
                cosineMax = cosine;
                index = i;
                seriesIndex = t;
            end
        end
    end
end