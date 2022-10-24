DATA_ROOT = fullfile('/export', 'hashimoto', 'Matlab', 'ResultFiles');
% for load
LOAD_DIR = fullfile(DATA_ROOT, 'Results', 'standardize', 'error');
LOAD_EXTENSION = '*.mat';
% CSV
csv_file = fopen(fullfile(LOAD_DIR, 'error.csv'), 'w');
fprintf(csv_file, 'id,date\n');

data_list = dir(fullfile(LOAD_DIR, LOAD_EXTENSION));
id = '';
date = '';
for i = 1 : length(data_list)
    if strcmp(id, data_list(i).name(1:10)) & strcmp(date, data_list(i).name(12:19))
        continue;
    else
        id = data_list(i).name(1:10);
        date = data_list(i).name(12:19);
        fprintf(csv_file, '%s,%s\n', id ,date);
    end
end
fclose(csv_file);