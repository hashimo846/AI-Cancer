DATA_ROOT = fullfile('/export', 'hashimoto', 'Matlab', 'ResultFiles');
NEW_DIR = fullfile(DATA_ROOT, 'Results', 'extract_data');
OLD_DIR = fullfile(NEW_DIR, 'OldTypeData');

RESULT_ROOT = fullfile('/export','hashimoto','Matlab','ResultFiles');
PROJECT_NAME = 'check_all_data';
LOG_DIR = fullfile(RESULT_ROOT, 'Logs', PROJECT_NAME);
IMG_DIR = fullfile(LOG_DIR, 'img');
mkdir(LOG_DIR);
mkdir(IMG_DIR);

diary(fullfile(LOG_DIR, 'log.md'));

% データリスト (ID'0'から始まる)
disp('# New data');
new_data_list = dir(fullfile(NEW_DIR, '0*'));
for i = 1 : length(new_data_list)
    % ログ
    disp(['## ',new_data_list(i).name,' (',num2str(i),'/',num2str(length(new_data_list)),')']);

    data = load(fullfile(NEW_DIR, new_data_list(i).name)).data;
    
    % Summary
    disp(data);

    % Image Output
    disp('### ROI, Map Image');
    for j = 1:length(data.ROI_INFO)
        disp(data.ROI_INFO(j));

        filename = [new_data_list(i).name(1:end-4), 'roiImage_', num2str(j), '.png'];
        imwrite(uint8(data.ROI_IMAGE(:,:,:,j)), fullfile(IMG_DIR, filename));
        disp(['![roiImage](img/',filename,')']);

        filename = [new_data_list(i).name(1:end-4), 'mapImage_', num2str(j), '.png'];
        imwrite(uint8(data.MAP_IMAGE(:,:,:,j)), fullfile(IMG_DIR, filename));
        disp(['![mapImage](img/',filename,')']);
    end
    disp('### KROI Image');
    [~,~,~,kroi_num] = size(data.KROI);
    for j = 1 : kroi_num
        filename = [new_data_list(i).name(1:end-4), 'kroi_', num2str(j), '.png'];
        imwrite(uint8(data.KROI(:,:,:,j)), fullfile(IMG_DIR, filename));
        disp(['![kroiImage](img/',filename,')']);
    end
end

disp('# Old data');
old_data_list = dir(fullfile(OLD_DIR, '0*'));
for i = 1 : length(old_data_list)
    % ログ
    disp(['## ',old_data_list(i).name,' (',num2str(i),'/',num2str(length(old_data_list)),')']);

    data = load(fullfile(OLD_DIR, old_data_list(i).name)).data;
    
    % Summary
    disp(data);

    % Image Output
    disp('### ROI, Map Image');
    for j = 1:length(data.ROI_INFO)
        disp(data.ROI_INFO(j));

        filename = [old_data_list(i).name(1:end-4), 'roiImage_', num2str(j), '.png'];
        imwrite(uint8(data.ROI_IMAGE(:,:,:,j)), fullfile(IMG_DIR, filename));
        disp(['![roiImage](img/',filename,')']);

        filename = [old_data_list(i).name(1:end-4), 'mapImage_', num2str(j), '.png'];
        imwrite(uint8(data.MAP_IMAGE(:,:,:,j)), fullfile(IMG_DIR, filename));
        disp(['![mapImage](img/',filename,')']);
    end
    disp('### KROI Image');
    [~,~,~,kroi_num] = size(data.KROI);
    for j = 1 : kroi_num
        filename = [old_data_list(i).name(1:end-4), 'kroi_', num2str(j), '.png'];
        imwrite(uint8(data.KROI(:,:,:,j)), fullfile(IMG_DIR, filename));
        disp(['![kroiImage](img/',filename,')']);
    end
end

% ログ
disp('Done');

diary('off');
