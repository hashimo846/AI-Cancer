DATA_ROOT = fullfile('/export', 'hashimoto', 'Matlab', 'ResultFiles');
% for Load
LOAD_DIR = fullfile(DATA_ROOT, 'Results', 'fit_images');
LOAD_OLD_DIR = fullfile(LOAD_DIR, 'OldTypeData');
LOAD_EXTENSION = '*.mat';
ERROR_DIR = fullfile(DATA_ROOT, 'Logs', 'fit_images', 'error'); 
ERROR_EXTENSION = '*.png';
% for Save
SAVE_DIR = fullfile(LOAD_DIR, 'error');
mkdir(SAVE_DIR);
CSV_FILE = fopen(fullfile(SAVE_DIR, 'error.csv'), 'w');

error_list = dir(fullfile(ERROR_DIR, ERROR_EXTENSION));

for i = 1 : length(error_list)
    id = error_list(i).name(1:10);
    date = error_list(i).name(12:19);
    disp(['id:', id, '   date:', date ]);

    % output csv
    fprintf(CSV_FILE, '%s,%s\n', id, date);

    name = [id, '_', date, LOAD_EXTENSION];
    new_list = dir(fullfile(LOAD_DIR, name));
    old_list = dir(fullfile(LOAD_OLD_DIR, name));

    if length(new_list) > 0
        new_check = true;
        data_list = new_list;
    elseif length(old_list) > 0
        new_check = false;
        data_list = old_list;
    else
        disp('    Mat file is not found.');
        continue
    end
    
    filename = [id, '_', date, LOAD_EXTENSION];
    if new_check
        movefile(fullfile(LOAD_DIR, filename), SAVE_DIR);
    else
        movefile(fullfile(LOAD_OLD_DIR, filename), SAVE_DIR);
    end

    disp('    finish.')
end

fclose(CSV_FILE);