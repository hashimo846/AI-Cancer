DATA_ROOT = fullfile('/export', 'hashimoto', 'DATA');
LOAD_DIR = fullfile(DATA_ROOT, 'noanon_prostate20220701');
KROI_DIR = fullfile(DATA_ROOT, 'Kishimoto', 'AIstudy2_3');

RESULT_ROOT = fullfile('/export','hashimoto','Matlab','ResultFiles');
PROJECT_NAME = 'extract_data';
SAVE_DIR = fullfile(RESULT_ROOT, 'Results', PROJECT_NAME);
SAVE_OLD_DIR = fullfile(SAVE_DIR, 'OldTypeData');
LOG_DIR = fullfile(RESULT_ROOT, 'Logs', PROJECT_NAME);
mkdir(SAVE_DIR);
mkdir(SAVE_OLD_DIR);
mkdir(LOG_DIR);

% 任意の患者だけ実行する場合に指定(''を指定するとすべての患者について実行される)
TARGET_PATIENT = '';

log_file = fopen(fullfile(LOG_DIR, ['log', TARGET_PATIENT, '.txt']), 'w');

% 読み込む各ファイル名
ROI_FILENAME = 'x_Tissue4D_Collection*.nii.gz';
DWI_FILENAME = 'Resolve_multiB_prostate_tra_TRACEW*.nii.gz';
T2_FILENAME = 't2_tse_tra.nii.gz';
T1D_FILENAME = 't1_fl3d_axi_Dynamic*.nii.gz';
OLD_T1D_FILENAME = 'x*_phase.nii.gz';

% 処理したデータの患者数とデータ数のカウント
all_patient = 0;
ok_patient = 0;
all_data = 0;
ok_data = 0;
roi_data = 0;
old_data = 0;
new_data = 0;


if strcmp(TARGET_PATIENT,'')
    % 患者ごとのデータリスト (IDが'0'から始まる)
    patient_list = dir(fullfile(LOAD_DIR, '0*'));
else
    patient_list = dir(fullfile(LOAD_DIR, [TARGET_PATIENT, '*']));
end
all_patient = length(patient_list);
for i = 1 : length(patient_list)

    % ログ
    text = ['patientID:',patient_list(i).name,' (',num2str(i),'/',num2str(all_patient),')'];
    disp(text);
    fprintf(log_file, '%s\n', text);

    %この患者のデータのうち一つでも利用可能なものがあるか
    patient_check = false;

    % ダイナミックのデータが新しいかどうか
    new_check = false;

    % 同一患者内のデータリスト (2000年代のデータのみ)
    data_list = dir(fullfile(LOAD_DIR, patient_list(i).name, '2*'));
    for j = 1 : length(data_list)
        
        % ROIデータの数
        roi_num = 0;

        all_data = all_data + 1;

        % 必要なファイルがあるかチェック (ダイナミック造影等)
        working_dir = fullfile(LOAD_DIR, patient_list(i).name, data_list(j).name);
        roi_dir = fullfile(working_dir, ROI_FILENAME);
        kroi_dir = fullfile(KROI_DIR, num2str(str2num(patient_list(i).name)));
        dwi_dir = fullfile(working_dir, DWI_FILENAME);
        t2_dir = fullfile(working_dir, T2_FILENAME);
        t1d_dir = fullfile(working_dir, T1D_FILENAME);
        old_t1d_dir = fullfile(working_dir, OLD_T1D_FILENAME);

        % DWIとT2WIのファイルが存在する場合
        if length(dir(dwi_dir)) > 0 && length(dir(t2_dir)) > 0
            
            % 新形式のダイナミックの場合
            if length(dir(t1d_dir)) > 0
                new_check = true;
                new_data = new_data + 1;
                % ダイナミック造影T1WIを読み込み T1D(row, column, slice, series)
                t1d_list = dir(t1d_dir);
                temp = load_untouch_nii(fullfile(working_dir, t1d_list(1).name)).img;
                T1D = int16(zeros([size(temp), length(t1d_list)]));
                for k = 1 : length(t1d_list)
                    T1D(:,:,:,k) = load_untouch_nii(fullfile(working_dir, t1d_list(k).name)).img;
                end
                % 旧データ用のサブトラ画像を生成
                T1DSUB = int16(zeros([size(temp), length(t1d_list)-1]));
                for k = 2:length(t1d_list)
                    T1DSUB(:,:,:,k-1) = T1D(:,:,:,k) - T1D(:,:,:,1);
                end

            % 旧形式のダイナミックの場合
            elseif length(dir(old_t1d_dir)) > 0
                new_check = false;
                old_data = old_data + 1;
                % ダイナミック造影T1WI(サブトラ)を読み込み T1D(row, column, slice, series)
                t1d_list = dir(old_t1d_dir);
                temp = load_untouch_nii(fullfile(working_dir, t1d_list(1).name)).img;
                T1DSUB = int16(zeros([size(temp), length(t1d_list)]));
                for k = 1 : length(t1d_list)
                    T1DSUB(:, :, :, k) = load_untouch_nii(fullfile(working_dir, t1d_list(k).name)).img;
                end
                % ダイナミックの元画像はないので
                T1D = zeros(0);

            % ダイナミックのシーケンスが見つからないのでスキップ
            else 
                % ログ
                text = ['  dataID:',data_list(j).name,' (',num2str(j),'/',num2str(length(data_list)),')'];
                disp(text);
                fprintf(log_file, '%s\n', text);

                text = '    this data is skipped.';
                disp(text);
                fprintf(log_file, '%s\n', text);
                continue;
            end

            patient_check = true;
            ok_data = ok_data + 1;

            % T2WIの読み込み
            T2 = load_untouch_nii(t2_dir).img;

            % ROIデータの読み込み
            roi_list = dir(roi_dir);
            roi_num = length(roi_list);

            % 1つ以上のROIデータを読み込み
            if roi_num > 0
                roi_data = roi_data + 1;
                roi = load_untouch_nii(fullfile(working_dir, roi_list(1).name)).img;
                [w,h,~,c] = size(roi);
                image_num = countRoiImage(roi);
                ROI_IMAGE = zeros([w,h,c,roi_num]);
                MAP_IMAGE = zeros([w,h,c,roi_num]);
                ROI_INFO = strings([1,roi_num]);
                for k = 1 : roi_num
                    roi = load_untouch_nii(fullfile(working_dir, roi_list(k).name)).img;
                    [ROI_IMAGE(:,:,:,k), MAP_IMAGE(:,:,:,k)] = findRoiImage(roi);
                    ROI_INFO(k) = roi_list(k).name;
                end

            % ROIデータがない場合
            else
                % ROIデータがないので
                ROI_IMAGE = zeros(0);
                MAP_IMAGE = zeros(0);
                ROI_INFO = zeros(0);
            end

            % Kishimoto ROI の読み込み
            [image_size,~,~,~] = size(T1DSUB); % T1Dと同じ画像サイズに変形したい
            kroi_list1 = dir(fullfile(kroi_dir, '*.jpg'));
            kroi_list2 = dir(fullfile(kroi_dir, '*.JPG'));
            kroi_list = cat(1,kroi_list1,kroi_list2);
            KROI = zeros([image_size, image_size, 3, length(kroi_list)]);

            for k = 1 : length(kroi_list)
                kroi = imread(fullfile(kroi_dir, kroi_list(k).name));
                KROI(:,:,:,k) = crop_resize(kroi, image_size);
            end

            % DWI から ADC Map を計算
            b = 1000;
            dim = 3;
            dwi_list = dir(dwi_dir);
            if length(dwi_list) == 1
                dwi = load_untouch_nii(fullfile(working_dir, dwi_list(1).name)).img;
                b0 = double(dwi(:,:,:,1));
                bk = double(dwi(:,:,:,dim));
            else
                b0 = double(load_untouch_nii(fullfile(working_dir, dwi_list(1).name)).img);
                bk = double(load_untouch_nii(fullfile(working_dir, dwi_list(dim).name)).img);
            end
            ADC = -log(bk./b0)/b;
            ADC(ADC < 0 | b0 == 0 | bk == 0) = 0;

            % ファイル保存
            data = struct('ROI_IMAGE', ROI_IMAGE, 'MAP_IMAGE', MAP_IMAGE, 'ROI_INFO', ROI_INFO, 'KROI', KROI, 'ADC', ADC, 'T2', T2, 'T1D', T1D, 'T1DSUB', T1DSUB);
            save_file = [patient_list(i).name, '_', data_list(j).name, '.mat'];

            disp(new_check);
            disp(data);

            if new_check
                save(fullfile(SAVE_DIR, save_file), 'data');
            else
                save(fullfile(SAVE_OLD_DIR, save_file), 'data');
            end

            % ログ
            text = ['  dataID:',data_list(j).name,' (',num2str(j),'/',num2str(length(data_list)),')'];
            disp(text);
            fprintf(log_file, '%s\n', text);

            if new_check
                status = ['(ROI_NUM:',num2str(roi_num),'  Type:New)'];
            else
                status = ['(ROI_NUM:',num2str(roi_num),'  Type:Old)'];
            end
            text = ['    ',save_file, ' is saved.', status];
            disp(text);
            fprintf(log_file, '%s\n', text);
            
        else
            % ログ
            text = ['  dataID:',data_list(j).name,' (',num2str(j),'/',num2str(length(data_list)),')'];
            disp(text);
            fprintf(log_file, '%s\n', text);

            text = '    this data is skipped.';
            disp(text);
            fprintf(log_file, '%s\n', text);
        end
    end

    if patient_check
        ok_patient = ok_patient + 1;
    end
end

% ログ
text = ['[Done]'];
disp(text);
fprintf(log_file, '%s\n', text);

text = ['All Patient:', num2str(all_patient), '  Output Patient:', num2str(ok_patient)];
disp(text);
fprintf(log_file, '%s\n', text);

text = ['All Data:', num2str(all_data), '  Output Data:', num2str(ok_data)];
disp(text);
fprintf(log_file, '%s\n', text);

text = ['New Data:', num2str(new_data), '  Old Data:', num2str(old_data), '  ROI Exist Data:', num2str(roi_data)];
disp(text);
fprintf(log_file, '%s\n', text);

fclose(log_file);

function [result_image] = crop_resize(kroi, image_size)
    THRESHOLD = 10000;
    [w,h,c] = size(kroi);
    monotone = zeros(size(kroi));
    for i = 1:w
        for j = 1:h
            if kroi(i,j,1) == kroi(i,j,2) & kroi(i,j,2) == kroi(i,j,3)
                monotone(i,j,:) = kroi(i,j,:); 
            else
                monotone(i,j,:) = [0;0;0];
            end
        end
    end

    start_w = 0;
    start_h = 0;
    for i = 1:w
        if sum(monotone(i,:,1), 2) > THRESHOLD
            start_w = i;
            break;
        end
    end
    for i = 1:h
        if sum(monotone(:,i,1), 1) > THRESHOLD
            start_h = i;
            break;
        end
    end

    end_w = 0;
    end_h = 0;
    for i = 0:w-1
        if sum(monotone(w-i,:,1), 2) > THRESHOLD
            end_w = w-i;
            break;
        end
    end
    for i = 0:h-1
        if sum(monotone(:,h-i,1), 1) > THRESHOLD
            end_h = h-i;
            break;
        end
    end

    kroi = kroi(start_w:end_w, start_h:end_h, :);
    result_image = imresize(kroi, [image_size image_size]);
end

function [image_num] = countRoiImage(ROI)
    image_num = 0;
    [w,h,n,c] = size(ROI);
    for i = 1 : n
        %find roiImage
        if isIncludeMagenta(squeeze(ROI(:,:,i,:)))
            image_num = image_num + 1
        end
    end
end

function [roiImage, mapImage] = findRoiImage(ROI)

    [w,h,n,c] = size(ROI);

    maxColorPixel = 0;
    maxIndex = 1;

    roiImage = zeros([w,h,c]);

    for i = 1 : n
        %find roiImage
        if isIncludeMagenta(squeeze(ROI(:,:,i,:)))
            roiImage = squeeze(ROI(:,:,i,:));
        end

        %find most colorful image
        temp = countColorPixel(squeeze(ROI(:,:,i,:)));
        if maxColorPixel < temp
            maxColorPixel = temp;
            maxIndex = i;
        end
    end

    mapImage = squeeze(ROI(:,:,maxIndex,:));
end

function [check] = isIncludeMagenta(image)
    
    MAGENTA = [255; 0; 255];

    [w,h,c] = size(image);

    check = false;

    for i = 1 : w
        for j = 1 : h
            if isequal(squeeze(image(i,j,:)), MAGENTA)
                check = true;
                return;
            end
        end
    end
    
end

function [count] = countColorPixel(image)

     [w,h,~] = size(image);

     count = 0;

     for i = 1 : w
        for j = 1 : h
            if image(i,j,1) == image(i,j,2) && image(i,j,2) == image(i,j,3)
                continue;
            else
                count = count + 1;
            end
        end
    end
end