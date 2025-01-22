% 🌟 강의 목표:
% 1. Image raw value를 CT number로 변환하는 방법
% 2. Window width, window level
% 3. 숙제3 해설: 특정 slice location의 axial slice를 plot하기
% 4. CT image를 개별 slice 이미지로 읽지 않고, 하나의 volumetric image로 읽는 방법

% 🌟 주요 MATLAB 함수
% 1. dicomreadVolume()
% 2. squeeze()
% 3. double()

%% 1.
% raw value:    CT scanner가 측정한 값 (DICOM 이미지의 픽셀 값)
% CT number:    조직의 밀도 정보를 나타내는 값 (HU 단위)

%   CT number = (rescale slope * raw value) + rescale intercept

% HU (Hounsfield Unit): 물을 기준으로 조직의 밀도 차이를 나타내는 단위
%                       (water=0, air=-1000, fat=-120~-90, soft tissue=100~300, bone≈300~1900)


%% 2.
% Window:   CT 이미지에서 표시할 HU 범위    (Window Width, WW)  -> high constrast = narrow window
% Level:    window(HU)의 중심 값          (Window Center, WC)

% lower limit = level - (1/2) * window
% upper limit = level + (1/2) * window

% -> using clim()


% 3.
% [V, spatial] = dicomreadVolume(__path)


clear all;
close all;
clc;


%% for octave
pkg load dicom; % for /octave

% contains()
function [res] = contains(str, pattern)
    if iscell(str)
        res = cellfun(@(s) ~isempty(strfind(s, pattern)), str);
    else
        res = ~isempty(strfind(str, pattern));
    end
end
%%


workingFolder = 'C:\Users\DESKTOP\workspace\DICOM_matlab';
patientDataFolder = strcat(workingFolder, '\data', '\patient-example')

% get CT Folder from patient folder
folders = dir(sprintf('%s\\', patientDataFolder));

for ff = 1:size(folders, dim=1)
    if contains(folders(ff).name, 'CT')
        CTFolder = sprintf('%s\\%s', folders(ff).folder, folders(ff).name);
    end
end

%%%%%%%%
% load image volume
[image, spatial] = dicomreadVolume(CTFolder);

%%%%%%%%


% get DICOM files
files = dir(sprintf('%s\\*.dcm', CTFolder));

for ff = 1:1%size(files, dim=1)
    filename =  sprintf('%s\\%s', files(ff).folder, files(ff).name);
    
    info = dicominfo(filename);
    sliceLocation = info.SliceLocation;
    rescaleSlope = info.RescaleSlope;
    rescaleIntercept = info.RescaleIntercept;

    fprintf('Slice location = %.1f\n', sliceLocation);

    image_raw = dicomread(info);
    image = image_raw*rescaleSlope + rescaleIntercept;     % raw value -> CT number

    % get header information to create coordinates
    image_origin = info.ImagePositionPatient;
    image_spacing = info.PixelSpacing;
    image_size = size(image);

    % define coordinates in x,y directions
    x = zeros(image_size(1), 1);
    y = zeros(image_size(2), 1);

    for ii = 1:image_size(1)
        x(ii) = image_origin(1) + image_spacing(1)*(ii-1);
    end
    for jj = 1:image_size(2)
        y(jj) = image_origin(2) + image_spacing(2)*(jj-1);
    end

    % set window, level
    window = 350;
    level = 50;

    lower_limit = level - 0.5*window;
    upper_limit = level + 0.5*window;

    % plot
    figure('Color', 'w');
    imagesc(x,y, image); % -> x, y 좌표가 이미지에 표시됨 (-250 ~ 250)
    colormap('gray');
    axis equal;
    axis tight;
    caxis([lower_limit, upper_limit]); % window 지정 (clim for mat)
    xlabel('R-L distance (mm)', 'Fontsize', 20);
    ylabel('A-P distance (mm)', 'Fontsize', 20);
    title('Axial view');
end

