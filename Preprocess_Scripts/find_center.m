DATA_ROOT = fullfile('/export', 'hashimoto');
% for load
LOAD_DIR = fullfile(DATA_ROOT, 'DockerMount', 'files', 'eval');
% for save
SAVE_DIR = fullfile(DATA_ROOT, 'Matlab', 'ResultFiles', 'Results', 'find_center');
mkdir(SAVE_DIR);
% parameter
IGNORE_SLICE = 15;
IGNORE_PIXEL = 45;

data_list = dir(fullfile(LOAD_DIR, '0*'));
disp(length(data_list));
for i = 1 : length(data_list)
    disp(i);
    volume = load_untouch_nii(fullfile(LOAD_DIR, data_list(i).name, [data_list(i).name, '_seg.nii.gz'])).img;
    [w h s] = size(volume);

    count = 0;
    x_sum = 0;
    y_sum = 0;
    for j = IGNORE_SLICE+1 : s-IGNORE_SLICE 
        for k = IGNORE_PIXEL+1 : w-IGNORE_PIXEL
            for l = IGNORE_PIXEL : h-IGNORE_PIXEL
                if volume(k,l,j) ~= 0
                    count = count + 1;
                    x_sum = x_sum + k;
                    y_sum = y_sum + l;
                end
            end
        end
    end
    x = x_sum/count;
    y = y_sum/count;

    % save
    data = struct('x', x/w, 'y', y/h);
    save(fullfile(SAVE_DIR, [data_list(i).name, '.mat']), 'data');
    disp([num2str(i),'/',num2str(length(data_list)),'(x:',num2str(data.x),' y:',num2str(data.y),')']);
end