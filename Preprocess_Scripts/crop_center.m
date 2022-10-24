DATA_ROOT = fullfile('/export', 'hashimoto', 'Matlab', 'ResultFiles');
% for Load
LOAD_DIR = fullfile(DATA_ROOT, 'Results', 'extract_slice20220817_20220820');
CENTER_DIR = fullfile(DATA_ROOT, 'Results', 'find_center20220817_20220820');
LOAD_OLD_DIR = fullfile(LOAD_DIR, 'OldTypeData');
LOAD_EXTENSION = '*.mat';
% for Save
PROJECT_NAME = 'crop_center';
SAVE_DIR = fullfile(DATA_ROOT, 'Results', PROJECT_NAME);
SAVE_OLD_DIR = fullfile(SAVE_DIR, 'OldTypeData');
mkdir(SAVE_DIR);
mkdir(SAVE_OLD_DIR);
% for Log
LOG_DIR = fullfile(DATA_ROOT, 'Logs', PROJECT_NAME);
IMG_DIR = fullfile(LOG_DIR, 'img');
mkdir(LOG_DIR);
mkdir(IMG_DIR);
log_file = fopen(fullfile(LOG_DIR, 'log.md'), 'w');
% for Error
ERROR_DIR = fullfile(SAVE_DIR, 'error');
mkdir(ERROR_DIR);
error_file = fopen(fullfile(ERROR_DIR, 'error.csv'), 'w');

% crop size (original size 384)
CROP_SIZE = 256;

new_data_list = dir(fullfile(LOAD_DIR, LOAD_EXTENSION));
old_data_list = dir(fullfile(LOAD_OLD_DIR, LOAD_EXTENSION));
data_list = cat(1, new_data_list, old_data_list);

for i = 1 : length(data_list)
    % log
    text = ['## Data: ', data_list(i).name ,'(', num2str(i), '/', num2str(length(data_list)), ')'];
    disp(text);
    fprintf(log_file, '%s\n\n', text);

    if i <= length(new_data_list)
        new_check = true;
    else
        new_check = false;
    end  

    % load
    if new_check
        data = load(fullfile(LOAD_DIR, data_list(i).name)).data;
    else
        data =load(fullfile(LOAD_OLD_DIR, data_list(i).name)).data;
    end
    center = load(fullfile(CENTER_DIR, data_list(i).name)).data;

    % data size
    [image_size,~,slice,sequence] = size(data.T1DSUB);

    % centering with prostate center
    offset = [0.5-center.x, 0.5-center.y];
    offsetIndex = int16(offset*image_size);
    data.ROI_IMAGE = imtranslate(data.ROI_IMAGE, offsetIndex);
    if strcmp(data.ROI_TYPE, 'Tissue4D')
        data.MAP_IMAGE = imtranslate(data.MAP_IMAGE, offsetIndex);
    end
    data.MASK_IMAGE = imtranslate(data.MASK_IMAGE, offsetIndex);
    data.T2 = imtranslate(data.T2, offsetIndex);
    data.ADC = imtranslate(data.ADC, offsetIndex);
    if new_check
        data.T1D = imtranslate(data.T1D, offsetIndex);
    end
    data.T1DSUB = imtranslate(data.T1DSUB, offsetIndex);
    
    % crop
    space_x = int16((length(data.T2(:,1,1))-CROP_SIZE)/2);
    space_y = int16((length(data.T2(1,:,1))-CROP_SIZE)/2);
    data.ROI_IMAGE = data.ROI_IMAGE(space_x+1:space_x+CROP_SIZE, space_y+1:space_y+CROP_SIZE,:);
    if strcmp(data.ROI_TYPE, 'Tissue4D')
        data.MAP_IMAGE = data.MAP_IMAGE(space_x+1:space_x+CROP_SIZE, space_y+1:space_y+CROP_SIZE,:);
    end
    data.MASK_IMAGE = data.MASK_IMAGE(space_x+1:space_x+CROP_SIZE, space_y+1:space_y+CROP_SIZE,:);
    data.T2 = data.T2(space_x+1:space_x+CROP_SIZE, space_y+1:space_y+CROP_SIZE,:);
    data.ADC = data.ADC(space_x+1:space_x+CROP_SIZE, space_y+1:space_y+CROP_SIZE,:);
    if new_check
        data.T1D = data.T1D(space_x+1:space_x+CROP_SIZE, space_y+1:space_y+CROP_SIZE,:,:);
        data.T1D = reshape(data.T1D, [CROP_SIZE, CROP_SIZE, slice, sequence+1]);
    end
    data.T1DSUB = data.T1DSUB(space_x+1:space_x+CROP_SIZE, space_y+1:space_y+CROP_SIZE,:,:);
    data.T1DSUB = reshape(data.T1DSUB, [CROP_SIZE, CROP_SIZE, slice, sequence]);

    % check for roi inside
    if isequal(uint8(data.MASK_IMAGE), zeros(size(data.MASK_IMAGE), 'uint8'))
        % log
        text = 'skiped.';
        disp(text);
        fprintf(log_file, '\t%s\n\n', text);
        continue;
    end
    
    % save
    name = data_list(i).name;
    if new_check
        save(fullfile(SAVE_DIR, name));
    else
        save(fullfile(SAVE_OLD_DIR, name));
    end

    disp(data);

    % log
    text = [name, ' saved.'];
    disp(text);
    fprintf(log_file, '\t%s\n\n', text);

    % log image
    filename = [name(1:end-4),'_','RoiImage.png'];
    imwrite(data.ROI_IMAGE, fullfile(IMG_DIR, filename));
    text = ['![RoiImage](img/',filename,')'];
    fprintf(log_file, '%s\n', text);
    
    filename = [name(1:end-4),'_','MaskImage.png'];
    imwrite(data.MASK_IMAGE, fullfile(IMG_DIR, filename));
    text = ['![MaskImage](img/',filename,')'];
    fprintf(log_file, '%s\n', text);

    if strcmp(data.ROI_TYPE, 'Tissue4D')
        % MapImage
        filename = [name(1:end-4),'_','MapImage.png'];
        imwrite(data.MAP_IMAGE, fullfile(IMG_DIR, filename));
        text = ['![MapImage](img/',filename,')'];
        fprintf(log_file, '%s\n', text);
    end

    filename = [name(1:end-4),'_','T2.png'];
    imwrite(squeeze(data.T2(:,:,2)), fullfile(IMG_DIR, filename));
    text = ['![T2](img/',filename,')'];
    fprintf(log_file, '%s\n', text);

    filename = [name(1:end-4),'_','ADC.png'];
    imwrite(squeeze(data.ADC(:,:,2)), fullfile(IMG_DIR, filename));
    text = ['![ADC](img/',filename,')'];
    fprintf(log_file, '%s\n', text);

    if new_check
        filename = [name(1:end-4),'_','T1D.png'];
        imwrite(squeeze(data.T1D(:,:,2,end)), fullfile(IMG_DIR, filename));
        text = ['![T1D](img/',filename,')'];
        fprintf(log_file, '%s\n', text);
    end

    filename = [name(1:end-4),'_','T1DSUB.png'];
    imwrite(squeeze(data.T1DSUB(:,:,2,end)), fullfile(IMG_DIR, filename));
    text = ['![T1DSUB](img/',filename,')'];
    fprintf(log_file, '%s\n\n', text);
end