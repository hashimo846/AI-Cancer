DATA_ROOT = fullfile('/export', 'hashimoto', 'Matlab', 'ResultFiles');
% for Load (新形式のデータのみ)
LOAD_DIR = fullfile(DATA_ROOT, 'Results', 'crop_center');
LOAD_EXTENSION = '*.mat';
% for Save (新形式のデータのみ)
PROJECT_NAME = 'make_dataset';
SAVE_DIR = fullfile(DATA_ROOT, 'Results', PROJECT_NAME);
IMG_DIR = fullfile(SAVE_DIR, 'img');
mkdir(SAVE_DIR);
mkdir(IMG_DIR);
DATASET = fopen(fullfile(SAVE_DIR, 'dataset.json'), 'w');
fprintf(DATASET, '{\n');
% for Log
LOG_DIR = fullfile(DATA_ROOT, 'Logs', PROJECT_NAME);
mkdir(LOG_DIR);
log_file = fopen(fullfile(LOG_DIR, 'log.md'), 'w');

data_list = dir(fullfile(LOAD_DIR, LOAD_EXTENSION));

id = '';
anon_num = 0;
for i = 1:length(data_list)
    % for anonymize
    if ~strcmp(id, data_list(i).name(1:10))
        anon_num = anon_num + 1;
        id = data_list(i).name(1:10);
    end

    % log
    text = ['## Data: ', data_list(i).name ,'(', num2str(i), '/', num2str(length(data_list)), ')'];
    disp(text);
    fprintf(log_file, '%s\n\n', text);
    
    data = load(fullfile(LOAD_DIR, data_list(i).name)).data;
    
    [~, ~, slice, sequence] = size(data.T1DSUB);

    filename = [num2str(anon_num), data_list(i).name(20:end-4), '_ROI', '.png'];
    imwrite(data.MASK_IMAGE, fullfile(IMG_DIR, filename));
    json.ROI = filename;

    t2files = string(zeros(1, slice));
    adcfiles = string(zeros(1, slice));
    t1dfiles = string(zeros(sequence, slice));
    for j = 1 : slice
        filename = [num2str(anon_num), data_list(i).name(20:end-4), '_T2_', num2str(j), '.png'];
        imwrite(squeeze(data.T2(:,:,j)), fullfile(IMG_DIR, filename));
        t2files(j) = filename;

        filename = [num2str(anon_num), data_list(i).name(20:end-4), '_ADC_', num2str(j), '.png'];
        imwrite(squeeze(data.ADC(:,:,j)), fullfile(IMG_DIR, filename));
        adcfiles(j) = filename;

        for k = 1 : sequence
            filename = [num2str(anon_num), data_list(i).name(20:end-4), '_T1D_', num2str(k),'_',num2str(j), '.png'];
            imwrite(squeeze(data.T1D(:,:,j,k)), fullfile(IMG_DIR, filename));
            t1dfiles(k,j) = filename;
        end
    end

    json.T2 = t2files;
    json.ADC = adcfiles;
    json.T1D = t1dfiles;

    % write json
    if i == length(data_list)
        fprintf(DATASET, '\"%s\":%s\n', [num2str(anon_num), data_list(i).name(end-5:end-4)], jsonencode(json, 'PrettyPrint', true));
    else
        fprintf(DATASET, '\"%s\":%s,\n', [num2str(anon_num), data_list(i).name(end-5:end-4)], jsonencode(json, 'PrettyPrint', true));
    end

    % Log
    text = ['saved. (', num2str(anon_num), data_list(i).name(end-5:end-4), ')'];
    disp(text);
    fprintf(log_file, '%s\n\n', text);

end
fprintf(DATASET, '}');
fclose(DATASET);
disp('Done.');