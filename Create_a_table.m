sourceDir = uigetdir('Q:\Projects in progress\FORMANIYARMSC','Get Unsorted CT slices');
fileList = dir(fullfile(sourceDir, 'CT.*.dcm'));
