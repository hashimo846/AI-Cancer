DATA_ROOT = fullfile('/export', 'hashimoto', 'Matlab', 'ResultFiles');
% for Load
LOAD_DIR = fullfile(DATA_ROOT, 'Results', 'fit_images');
LOAD_OLD_DIR = fullfile(LOAD_DIR, 'OldTypeData');
LOAD_EXTENSION = '*.mat';
% for Save
PROJECT_NAME = 'standardize';
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
        new_check = true;
    else
        data = load(fullfile(LOAD_OLD_DIR, data_list(i).name)).data;
        new_check = false;
    end

    % ADC
    data.ADC = data.ADC .* 300;
    filename = [data_list(i).name(1:end-4),'_','ADC.png'];
    imwrite(data.ADC(:,:,1), fullfile(IMG_DIR, filename));
    text = ['![ADC](img/',filename,')'];
    fprintf(log_file, '%s\n', text);
    
    % T2
    data.T2 = double(data.T2) ./ double(max(data.T2(:)));
    filename = [data_list(i).name(1:end-4),'_','T2.png'];
    imwrite(data.T2(:,:,1), fullfile(IMG_DIR, filename));
    text = ['![T2](img/',filename,')'];
    fprintf(log_file, '%s\n', text);

    % T1D
    if new_check
        data.T1D = double(data.T1D) ./ double(max(data.T1D(:)));
        filename = [data_list(i).name(1:end-4),'_','T1D.png'];
        imwrite(data.T1D(:,:,1,end), fullfile(IMG_DIR,filename));
        text = ['![T1D](img/',filename,')'];
        fprintf(log_file, '%s\n', text);
    end

    % T1DSUB
    data.T1DSUB = double(data.T1DSUB) ./ double(max(data.T1DSUB(:)));
    filename = [data_list(i).name(1:end-4),'_','T1DSUB.png'];
    imwrite(data.T1DSUB(:,:,1,end), fullfile(IMG_DIR, filename));
    text = ['![T1DSUB](img/',filename,')'];
    fprintf(log_file, '%s\n', text);

    % ROI_IMAGE
    data.ROI_IMAGE = uint8(data.ROI_IMAGE);
    filename = [data_list(i).name(1:end-4),'_','RoiImage.png'];
    imwrite(data.ROI_IMAGE, fullfile(IMG_DIR, filename));
    text = ['![ROI_IMAGE](img/',filename,')'];
    fprintf(log_file, '%s\n', text);

    if strcmp(data.ROI_TYPE, 'Tissue4D')
        % MAP_IMAGE
        data.MAP_IMAGE = uint8(data.MAP_IMAGE);
        filename = [data_list(i).name(1:end-4),'_','MapImage.png'];
        imwrite(data.MAP_IMAGE, fullfile(IMG_DIR, filename));
        text = ['![MAP_IMAGE](img/',filename,')'];
        fprintf(log_file, '%s\n', text);
    end

    % MASK_IMAGE
    data.MASK_IMAGE = uint8(data.MASK_IMAGE);
    filename = [data_list(i).name(1:end-4),'_','MaskImage.png'];
    imwrite(data.MASK_IMAGE, fullfile(IMG_DIR, filename));
    text = ['![MASK_IMAGE](img/',filename,')'];
    fprintf(log_file, '%s\n', text);

    % save
    if new_check
        save(fullfile(SAVE_DIR, data_list(i).name), 'data');
    else
        save(fullfile(SAVE_OLD_DIR, data_list(i).name), 'data');
    end

    disp(data);
end 

% ログ
text = ['Done'];
disp(text);
fprintf(log_file, '%s\n', text);