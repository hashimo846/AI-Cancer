DATA_ROOT = fullfile('/export', 'hashimoto', 'Matlab', 'ResultFiles');
% for Load
LOAD_DIR = fullfile(DATA_ROOT, 'Results', 'fit_images');
LOAD_OLD_DIR = fullfile(DATA_ROOT, 'Results', 'fit_images','OldTypeData');
NII_DIR = fullfile('/export/hashimoto/DATA/', 'noanon_prostate20220701');
LOAD_EXTENSION = '*.mat';
T2WI_NII = 't2_tse_tra.nii.gz';
% for save
SAVE_DIR = fullfile(DATA_ROOT, 'Results', 'make_seg_input');
mkdir(SAVE_DIR);
% for json
SAVE_JSON = 'seg_input.json';
HEADER = '{\n\t\"num_testing\": 1,\n\t\"num_training\": 0,\n\t\"num_validation\": 0,\n\t\"testing\": [\n';
FOOTER = '\t],\n\t\"training\": [],\n\t\"validation\": []\n}';

new_data_list = dir(fullfile(LOAD_DIR, LOAD_EXTENSION));
old_data_list = dir(fullfile(LOAD_OLD_DIR, LOAD_EXTENSION));
data_list = cat(1, new_data_list, old_data_list);

fileID = fopen(fullfile(SAVE_DIR, SAVE_JSON), 'w');

fprintf(fileID, HEADER);
for i = 1 : length(data_list)
    % load
    id = data_list(i).name(1:10);
    date = data_list(i).name(12:19);
    t2_nii = load_untouch_nii(fullfile(NII_DIR, id, date, T2WI_NII));
    if i <= length(new_data_list)
        data = load(fullfile(LOAD_DIR, data_list(i).name)).data;
    else
        data = load(fullfile(LOAD_OLD_DIR, data_list(i).name)).data;
    end
    
    disp(['id:', id, '    date:', date, '    (', num2str(i), '/', num2str(length(data_list)), ')']);

    % get info
    pixdim = t2_nii.hdr.dime.pixdim(2:4);
    [w h s] = size(data.T2);
    output = int16(ones(w, h, s, 2));

    % T2
    data.T2 = single(data.T2) ./ single(max(data.T2(:)));
    data.T2 = int16(data.T2 .* 1600);
    output(:,:,:,1) = data.T2;

    % ADC
    data.ADC = (data.ADC .* (1000 * 1000));
    data.ADC(data.ADC<0) = 0;
    output(:,:,:,2) = data.ADC;

    % output nii
    nii = make_nii(output, pixdim);
    save_nii(nii, fullfile(SAVE_DIR, [data_list(i).name(1:end-4),'.nii']));
    fprintf(fileID, '\t\t{\n');

    % output json
    fprintf(fileID, '\t\t\t\"image\": \"%s.gz\",\n', [data_list(i).name(1:end-4), '.nii']);
    fprintf(fileID, '\t\t\t\"label\": \"\"\n');
    if i == length(data_list)
        fprintf(fileID, '\t\t}\n');
    else
        fprintf(fileID, '\t\t},\n');
    end

    disp('    saved.');
    
end
fprintf(fileID, FOOTER);
disp('Done.')