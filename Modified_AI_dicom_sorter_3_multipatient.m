% DICOM Sorter by Date
% This script scans a directory for DICOM files, reads their StudyDate,
% and moves them into folders named by that date (YYYY-MM-DD).

% 0. Looping for all patients
parentDir = uigetdir(pwd, 'Select the folder containing patient folders');
fprintf('Parent directory: %s. \n', parentDir)

if isequal(parentDir, 0) || isequal(destDir, 0)
   error('User cancelled folder selection.');
end 

contents = dir(parentDir);
contents = contents(~ismember({contents.name}, {'.', '..'}));

totalItems = numel(contents);
fprintf('Total items in folder: %d\n', totalItems);

for j = 13:totalItems
    % 1. Setup paths
    ROFolderName = sprintf('Patient%d\\Registration_objects', j);
    sourceDir = fullfile(parentDir, ROFolderName);
    
    intermediateDir = 'L:\Projects_in_progress\FORMANIYARMSC\ROs_sorted_based_on_dates\Normal_Patients';
    
    folderName = sprintf('dates_nROs_p%d', j);
    destDir = fullfile(intermediateDir, folderName);
    dates_destination = mkdir(destDir);
    

  
    
    % 2. Get list of all files
    fileList = dir(fullfile(sourceDir, '*.dcm')); 
    % Note: You can change '*' to '*.dcm' if your files have extensions
    
    fprintf('Processing files...\n');
    
    for i = 1:length(fileList)
        % Skip directories
        if fileList(i).isdir, continue; end
        
        filePath = fullfile(sourceDir, fileList(i).name);
        
        try
            % 3. Read DICOM header
            info = dicominfo(filePath);
            
            % Extract StudyDate (Format is usually 'YYYYMMDD')
            if isfield(info, 'SeriesDate') && ~isempty(info.SeriesDate)
                rawDate = info.SeriesDate;
                % Format date for folder name: YYYY-MM-DD
                % folderName = sprintf('RO_CBCT_%d', i);
                folderName = sprintf('%s-%s-%s_%s', rawDate(1:4), rawDate(5:6), rawDate(7:8), info.SeriesTime(1:6));
            else
                folderName = 'Unknown_Date';
            end
            
            % 4. Create destination subfolder
            targetFolder = fullfile(destDir, folderName);
            if ~exist(targetFolder, 'dir')
                mkdir(targetFolder);
            end
            
            % 5. Move the file
            copyfile(filePath, fullfile(targetFolder, fileList(i).name));
            fprintf('Copied: %s -> %s\n', fileList(i).name, folderName);
            
        catch
            fprintf('Skipped (Not a valid DICOM): %s\n', fileList(i).name);
        end
    end
    
    fprintf('Sorting based on dates complete!\n');
    
    %------------------------------------------------------------------------
    
    fprintf('Now sorting to match script format!\n');
    
    %final_destDir = uigetdir(pwd, 'Select the folder you want to deposit final files');
    % hardcoding the final destination
    final_destDir = sourceDir;
    
    if isequal(final_destDir, 0)
        error('User cancelled folder selection.');
    end
    
    contents = dir(destDir);
    
    % 2. Filter to keep only actual directories, excluding '.' and '..'
    % This ensures we don't try to rename the current or parent directory references.
    dirFlags = [contents.isdir] & ~ismember({contents.name}, {'.', '..'});
    folderList = contents(dirFlags);
    
    % 3. Sort folders by name (alphabetical/chronological)
    % Since dates are YYYY-MM-DD, a standard sort puts them in order.
    [~, idx] = sort({folderList.name});
    folderList = folderList(idx);
    
    fprintf('Starting renaming process...\n');
    
    % 4. Loop through and rename
    for i = 1:length(folderList)
        oldName = folderList(i).name;
        newName = sprintf('RO_CBCT_%d', i); % Format: Folder_1, Folder_2, etc.
        
        oldPath = fullfile(destDir, oldName);
        newPath = fullfile(final_destDir, newName);
        
        % Perform the rename
        copyfile(oldPath, newPath);
        
        fprintf('Renamed: %s  -->  %s\n', oldName, newName);
    end
    
    fprintf('Done! Renamed %d folders.\n', length(folderList));
    fprintf('Patient %d''s ROs ready for analysis.\n', j);
end 