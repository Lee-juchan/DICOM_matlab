% 🌟 강의 목표:
% 1. Image raw value를 CT number로 변환하는 방법
% 2. Window width, window level
% 3. 숙제3 해설: 특정 slice location의 axial slice를 plot하기
% 4. CT image를 개별 slice 이미지로 읽지 않고, 하나의 volumetric image로 읽는 방법

% 🌟 주요 MATLAB 함수
% 1. [V, spatial] = dicomreadVolume()
% 2. squeeze()
% 3. double()
%%

%%% 1.
% raw value:    CT scanner가 측정한 값 (DICOM 이미지의 픽셀 값)
% CT number:    조직의 밀도 정보를 나타내는 값 (HU 단위)                (CT number = (rescale slope * raw value) + rescale intercept)

% HU (Hounsfield Unit): 물을 기준으로 조직의 밀도 차이를 나타내는 단위  (water=0, air=-1000, fat=-120~-90, soft tissue=100~300, bone≈300~1900)

%%% 2.
% Window:   CT 이미지에서 표시할 HU 범위    (= Window Width, WW)  -> high constrast = narrow window
% Level:    window(HU)의 중심 값          (= Window Center, WC)

% lower limit = level - (1/2) * window
% upper limit = level + (1/2) * window

%%% 3.
% [V, spatial] = dicomreadVolume(__path)

% spactial
% PatientPositions: [337x3 double]      : 각 이미지의 ImagePositionPatient (origin 값)
% PixelSpacings: [337x2 double]         : 각 이미지의 픽셀 간격
% PatientOrientations: [2x3x337 double] : 각 이미지의 회전 방향 (MR 필수)
% ImageSize: [512 512 337]              : 각 이미지 크기

clear all;
close all;
clc;

% folder (CT)
patientDataFolder = fullfile(pwd, 'data', 'patient-example');
folders = dir(patientDataFolder);

for ff = 1:size(folders, 1)
    if contains(folders(ff).name, 'CT')
        CTFolder = fullfile(folders(ff).folder, folders(ff).name);
    end
end

%% lec4 %%
% % 3d image
% [image, spatial] = dicomreadVolume(CTFolder);   % (512, 512, 1, 337)
% image = squeeze(image);                         % -> (512, 512, 337)

% % image coordinates
% image_origin = spatial.PatientPositions(1,:);
% image_spacing(1:2) = spatial.PixelSpacings(1,:);                                    % x,y 간격
% image_spacing(3) = spatial.PatientPositions(2,3) - spatial.PatientPositions(1,3);   % z 간격
% image_size = spatial.ImageSize; % = size(image);
%%

% files (2d images)
files = dir(fullfile(CTFolder, '*.dcm'));

for ff = 1:1%size(files, 1)
    filename =  fullfile(files(ff).folder, files(ff).name);
    
    info = dicominfo(filename);
    image_raw = dicomread(info);

    %% lec4 %%
    % CT number
    rescaleSlope = info.RescaleSlope;
    rescaleIntercept = info.RescaleIntercept;
    
    image = image_raw*rescaleSlope + rescaleIntercept;     % raw value -> CT number
    %%

    % image coordinates
    image_origin = info.ImagePositionPatient;
    image_spacing = info.PixelSpacing;
    image_size = size(image);

    x = zeros(image_size(1), 1);
    y = zeros(image_size(2), 1);

    for ii = 1:image_size(1)
        x(ii) = image_origin(1) + image_spacing(1)*(ii-1);
    end
    for jj = 1:image_size(2)
        y(jj) = image_origin(2) + image_spacing(2)*(jj-1);
    end

    %% lec4 %%
    % window, level
    window = 350;
    level = 50;

    lower_limit = level - 0.5*window;
    upper_limit = level + 0.5*window;
    %%

    % plot
    figure('Color', 'w');
    imagesc(x,y, image);
    colormap('gray');
    axis equal;
    axis tight;
    clim([lower_limit, upper_limit]);
    xlabel('R-L distance (mm)', 'Fontsize', 20);
    ylabel('A-P distance (mm)', 'Fontsize', 20);
    title('Axial view');
end
