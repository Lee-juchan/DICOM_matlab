% 🌟 강의 목표:
% 1. MATLAB을 열고 간단한 코드를 실행할 수 있다.
% 2. DICOM CT 파일을 열고, 헤더 정보를 확인할 수 있다.
% 3. DICOM 데이터에서 추출한 헤더정보를 text파일 형태로 내보낼 수 있다.

% 🌟 주요 MATLAB 함수
% 1. dicominfo()
% 2. fopen()
% 3. fprintf()
%%

clear all;
close all;
clc;

%% lec 1 %%
% file
filename = fullfile(pwd, 'data', 'test.dcm');

info = dicominfo(filename);

PixelSpacing = info.PixelSpacing;
PatientName = info.PatientName;
PatientGivenName = PatientName.GivenName;
PatientFamilyName = PatientName.FamilyName;
Width = info.Width;

% print
% to screen
fprintf('Pixel Spacing: %.3f, %.3f\n',PixelSpacing);
fprintf('Patient Name: %s, %s\n',PatientFamilyName,PatientGivenName);
fprintf('Width: %d\n',Width);

% to file
fid = fopen(fullfile(pwd, 'data', 'test.txt'), 'w');

fprintf(fid,'Pixel Spacing: %.3f, %.3f\n',PixelSpacing);
fprintf(fid,'Patient Name: %s, %s\n',PatientFamilyName,PatientGivenName);
fprintf(fid,'Width: %d\n',Width);

fclose(fid);