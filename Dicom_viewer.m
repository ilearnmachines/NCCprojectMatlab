[file, path] = uigetfile('*dcm', 'Select the file containing DICOM files');
fullpath = fullfile(path, file)
info = dicominfo(fullpath);