% 🌟 강의 목표:
% 1. 숙제 12 해설: maximum doses 계산하기
% 2. DICOM RT structure로부터 mask image 만들기 (mask image에 대한 이해)
% 3. DVH curve를 만드는 과정 대략적으로 이해하기 (왜 mask image가 필요한지)

% 🌟 주요 MATLAB 함수:
% 1. createMask
% 2. createMaskJK (customized)
% 3. interp1, interp2, interp3
%       interp1(x,v, xq)        : 'spline' 옵션
%       interp2(X,Y,V, xq,yq)   : meshgrid 필수
%       interp3(X,Y,Z,V, xq,yq,zq)
% 4. meshgrid
%%

% mask
% DVH -> 전체 영역의 선량중에 특정 st에 대한 선량값만 추출
% RT structure 내부=1, 외부=0

% meshgrid + interpolation
% RT dose, mask의 범위가 달라서 보간법 사용

clear all;
close all;
clc;

% folder, files (CT, RTst, RTDOSE)
patientDataFolder = fullfile(pwd, 'data', 'patient-example');
folders = dir(patientDataFolder);

for ff = 1:size(folders, 1)
    if contains(folders(ff).name, '_CT_')
        CTFolder = fullfile(folders(ff).folder, folders(ff).name);     % CT
    elseif contains(folders(ff).name, '_RTst')
        RTstFolder = fullfile(folders(ff).folder, folders(ff).name);   % RT structure
    elseif contains(folders(ff).name, '_RTDOSE_')
        RTDOSEFolder = fullfile(folders(ff).folder, folders(ff).name);   % RT Dose
    end
end

files_rtst = dir(fullfile(RTstFolder, '*.dcm'));        % exist(RTstFolder, 'dir') 활용 가능
files_rtdose = dir(fullfile(RTDOSEFolder, '*.dcm'));

RTstFile = fullfile(files_rtst(1).folder, files_rtst(1).name);
RTDOSEFile = fullfile(files_rtdose(1).folder, files_rtdose(1).name);


% CT
[image, spatial, dim] = dicomreadVolume(CTFolder);

image = squeeze(image);
image = image - 3614; % for CT number

image_origin = spatial.PatientPositions(1,:);
image_spacing = spatial.PixelSpacings(1,:);
image_spacing(3) = spatial.PatientPositions(2,3) - spatial.PatientPositions(1,3);
image_size = spatial.ImageSize;

x_image = zeros(image_size(1), 1);
y_image = zeros(image_size(2), 1);
z_image = zeros(image_size(3), 1);

for ii = 1:image_size(1)
    x_image(ii) = image_origin(1) + image_spacing(1)*(ii-1);
end
for jj = 1:image_size(2)
    y_image(jj) = image_origin(2) + image_spacing(2)*(jj-1);
end
for kk = 1:image_size(3)
    z_image(kk) = image_origin(3) + image_spacing(3)*(kk-1);
end


% RT Structure
rtst_info = dicominfo(RTstFile, 'UseVRHeuristic', false);   % 'UseVRHeuristic', false : 없으면 오류
contour = dicomContours(rtst_info);

ROIs = contour.ROIs; % rois

name = ROIs.Name;
contourData = ROIs.ContourData; % 각 slice 수
color = ROIs.Color;

nROIs = size(ROIs, 1);

% selected ROI
ROIname_selected = {'GTV'; 'ITV'; 'PTV 1250x4 Dmax~'};
nROIs_selected = size(ROIname_selected, 1);

index = zeros(nROIs_selected, 1);

for roi = 1:nROIs_selected
    for st = 1:nROIs
        if strcmp(name{st, 1}, ROIname_selected{roi,1})
            index(roi, 1) = st;
        end
    end
end

% contour (for selected ROI)
roiData = struct([]);

for roi = 1:nROIs_selected
    contourData_selected = contourData{index(roi, 1)};
    color_selected = color{index(roi, 1)};

    z_roi = [];
    nSlice = size(contourData_selected, 1);

    for ss = 1:nSlice
        contourData_slice = contourData_selected{ss, 1};
        z_slice = contourData_slice(:, 3);
        z_roi = [z_roi; z_slice];
    end
    z_roi = unique(z_roi); % 원하는 contour(ROI)의 slice 개수만큼의 z좌표

    roiData(roi).ContourData = contourData_selected;
    roiData(roi).Color = color_selected;
    roiData(roi).z_roi = z_roi;
end


% RT dose
rtdose_info = dicominfo(RTDOSEFile);

rtdose_data = dicomread(rtdose_info);
rtdose_data = squeeze(rtdose_data);

rtdose_gridscaling = rtdose_info.DoseGridScaling;
rtdose = rtdose_gridscaling * double(rtdose_data); % for real dose

rtdose_origin = rtdose_info.ImagePositionPatient;
rtdose_spacing(1:2) = rtdose_info.PixelSpacing;
rtdose_spacing(3) = rtdose_info.SliceThickness;
rtdose_size = size(rtdose_data);

x_rtdose = zeros(rtdose_size(2), 1);
y_rtdose = zeros(rtdose_size(1), 1);
z_rtdose = zeros(rtdose_size(3), 1);

for ii = 1:rtdose_size(2)
    x_rtdose(ii) = rtdose_origin(1) + rtdose_spacing(1)*(ii-1);
end
for jj = 1:rtdose_size(1)
    y_rtdose(jj) = rtdose_origin(2) + rtdose_spacing(2)*(jj-1);
end
for kk = 1:rtdose_size(3)
    z_rtdose(kk) = rtdose_origin(3) + rtdose_spacing(3)*(kk-1);
end


%% lec 13 %%
% calc mean doses
[X_rtdose, Y_rtdose, Z_rtdose] = meshgrid(x_rtdose, y_rtdose, z_rtdose);    % dose grid

for roi = 1:nROIs_selected
    [mask, x_mask, y_mask, z_mask] = createMaskJK(contour, index(roi,1));
    [X_mask, Y_mask, Z_mask] = meshgrid(x_mask, y_mask, z_mask);            % mask grid
    
    % interp
    rtdose_mask_interp = interp3(X_rtdose,Y_rtdose,Z_rtdose, rtdose, X_mask,Y_mask,Z_mask); % 영역 맞추기
    rtdose_masked = rtdose_mask_interp(mask == 1); % mask에 해당하는 rtdose
    
    fprintf('%s: %.2f Gy\n', ROIname_selected{roi,1}, mean(rtdose_masked));
end