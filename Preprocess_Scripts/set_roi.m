DATA_ROOT = fullfile('/export', 'hashimoto');
% 新形式のDynamicを持つデータのディレクトリ
LOAD_DIR = fullfile(DATA_ROOT, 'Matlab', 'ResultFiles', 'Results', 'extract_data');
% 旧形式のDynamicを持つデータのディレクトリ
OLD_DIR = fullfile(LOAD_DIR, 'OldTypeData');

% 岸本CSV
CSV_FILE = fullfile(DATA_ROOT, 'DATA', 'Kishimoto', 'patient_list220817_integrated.csv');

RESULT_ROOT = fullfile('/export','hashimoto','Matlab','ResultFiles');
PROJECT_NAME = 'set_roi';
SAVE_DIR = fullfile(RESULT_ROOT, 'Results', PROJECT_NAME);
SAVE_OLD_DIR = fullfile(SAVE_DIR, 'OldTypeData');
LOG_DIR = fullfile(RESULT_ROOT, 'Logs', PROJECT_NAME);
mkdir(SAVE_DIR);
mkdir(SAVE_OLD_DIR);
mkdir(LOG_DIR);
mkdir(fullfile(LOG_DIR,'img'));

log_file = fopen(fullfile(LOG_DIR, 'log.md'), 'w');

% 岸本CSV読み込み
k_data = readtable(CSV_FILE,'Encoding','UTF-8','Format','%s%s%s%s%s%s');

output_count = 0;
start_num = 109; % default 1
for i = start_num : height(k_data)
    % ログ
    text = ['========================================================================'];
    disp(text);

    % ログ
    text = ['## ID:', k_data.ID{i}, ' Date:', k_data.Date{i}, ' (', num2str(i), '/', num2str(height(k_data)), ')'];
    disp(text);
    fprintf(log_file, '%s\n', text);

    % すでにアノテーションされているかどうか
    filename = [k_data.ID{i}, '*.mat'];
    if 0 < length(dir(fullfile(SAVE_DIR, filename))) | 0 < length(dir(fullfile(SAVE_OLD_DIR, filename)))
        text = 'This data is skip. (Already ROI set.)';
        disp(text);
        fprintf(log_file, '%s\n', text);
        continue;
    end
    
    if strcmp(k_data.Dynamic{i}, 'TRUE')
        % データロード
        new_check = false;
        filename = [k_data.ID{i}, '_', k_data.Date{i}, '.mat'];
        if length(dir(fullfile(LOAD_DIR, filename))) > 0
            new_check = true;
            predata = load(fullfile(LOAD_DIR, filename)).data;
        elseif length(dir(fullfile(OLD_DIR, filename))) > 0
            new_check = false;
            predata = load(fullfile(OLD_DIR, filename)).data;
        else
            % ログ
            text = 'This data is skip. (Could not find Mat file.)';
            disp(text);
            fprintf(log_file, '%s\n', text);
            continue;
        end

        % ログ
        if new_check
            type = 'New';
        else
            type = 'Old';
        end
        text = ['### Type:',type,'   KROI:',k_data.External_FILE{i},'   OK_ROI:',k_data.ROI_OK{i}];
        disp(text);
        fprintf(log_file, '%s\n', text);
        text = ['### Comment:', k_data.Comment{i}];
        disp(text);
        fprintf(log_file, '%s\n', text);
        
        % ログ
        text = ['### All ROI Data'];
        disp(text);
        fprintf(log_file, '%s\n', text);
        
        file_num = 0;
        for j = 1 : length(predata.ROI_INFO)
            file_num = file_num + 1;
            % ログ
            text = [num2str(file_num),'. ',predata.ROI_INFO{j}];
            disp(text);
            fprintf(log_file, '%s  \n', text);
        end
        [~,~,~,len] = size(predata.KROI);
        for j = 1 : len
            file_num = file_num + 1;
            text = [num2str(file_num),'. ','KROI',num2str(j)];
            disp(text);
            fprintf(log_file, '%s  \n', text);
        end

        roi_count = 0;
        while true
            % ログ
            text = ['Select a number of ROI data.(If you want to finish, input 0.) -> '];
            fprintf(log_file, '%s', text);
            % 入力受付
            select = input(text);
            fprintf(log_file, '%s  \n', num2str(select));

            % finish
            if select == 0
                break;
            % if select KROI
            elseif 0 < select & select <= length(predata.ROI_INFO)
                ROI_TYPE = 'Tissue4D';
                [x,y,~] = impixel(uint8(predata.ROI_IMAGE(:,:,:,select)));
                ROI_IMAGE = predata.ROI_IMAGE(:,:,:,select);
                MAP_IMAGE = predata.MAP_IMAGE(:,:,:,select);
                MASK_IMAGE = zeros(size(predata.ROI_IMAGE(:,:,:,select)));
            % if select Tissue4D
            elseif length(predata.ROI_INFO) < select & select <= file_num
                ROI_TYPE = 'KROI';
                [x,y,~] = impixel(uint8(predata.KROI(:,:,:,select-length(predata.ROI_INFO))));
                ROI_IMAGE = predata.KROI(:,:,:,select-length(predata.ROI_INFO));
                MAP_IMAGE = zeros(0);
                MASK_IMAGE = zeros(size(predata.KROI(:,:,:,select-length(predata.ROI_INFO))));
            % other value
            else
                disp('invalid value. please retry.');
                continue;
            end
            % close figure
            close;

            % save files
            for j = 1 : length(x)
                roi_count = roi_count + 1;

                % ログ
                text = ['set roi.(',num2str(x(j)),',',num2str(y(j)),')'];
                disp(text);
                fprintf(log_file, '%s\n', text);

                MASK_IMAGE(y(j),x(j),:) = [255;255;255];

                data = struct('ROI_IMAGE', ROI_IMAGE, 'MAP_IMAGE', MAP_IMAGE,'MASK_IMAGE', MASK_IMAGE, 'ROI_TYPE', ROI_TYPE, 'ADC', predata.ADC, 'T2', predata.T2, 'T1D', predata.T1D, 'T1DSUB', predata.T1DSUB);
                save_file = [k_data.ID{i}, '_', k_data.Date{i},'_',num2str(roi_count),'.mat'];
                if new_check
                    save(fullfile(SAVE_DIR, save_file), 'data');
                else
                    save(fullfile(SAVE_OLD_DIR, save_file), 'data');
                end

                % ログ
                text = [save_file,' is saved.'];
                disp(text);
                fprintf(log_file, '%s\n', text);

                filename1 = [k_data.ID{i}, '_', k_data.Date{i},'_',num2str(roi_count),'_','roiImage.png'];
                filename2 = [k_data.ID{i}, '_', k_data.Date{i},'_',num2str(roi_count),'_','maskImage.png'];
                imwrite(uint8(ROI_IMAGE), fullfile(LOG_DIR,'img',filename1));
                imwrite(uint8(MASK_IMAGE), fullfile(LOG_DIR,'img',filename2));
                
                % ログ
                text = ['![roiImage](img/',filename1,')'];
                disp(text);
                fprintf(log_file, '%s\n', text);
                text = ['![roiImage](img/',filename2,')'];
                disp(text);
                fprintf(log_file, '%s\n', text);

                MASK_IMAGE(y(j),x(j),:) = [0;0;0];
            end
        end
        output_count = output_count + roi_count;
    else
        % ログ
        text = ['This data is skip. (Dynamic is not found.)'];
        disp(text);
        fprintf(log_file, '%s\n', text);
    end
    % ログ
    text = ['========================================================================'];
    disp(text);
end
