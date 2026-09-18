
% 0. Looping for all patients
parentDir = uigetdir(pwd, 'Select the folder containing patient folders');
fprintf('Parent directory: %s. \n', parentDir)

contents = dir(parentDir);
contents = contents(~ismember({contents.name}, {'.', '..'}));

totalItems = numel(contents);
fprintf('Total items in folder: %d\n', totalItems);

for j = 15:totalItems
% Varian CBCT Series Organizer
    CBCTFolderName = sprintf('Patient%d\\CBCTs', j);
    sourceDir = fullfile(parentDir, CBCTFolderName);
    fprintf('Source directory: %s. \n', sourceDir)
    
    intermediateDir = 'L:\Projects_in_progress\FORMANIYARMSC\CBCTs_sortedbydate\Normal_patients';
    
    folderName = sprintf('nCBCT_sortedbydate_for_p%d', j);
    destDir = fullfile(intermediateDir, folderName);
    dates_destination = mkdir(destDir);
    
    %final_destDir = uigetdir(pwd, 'Select the folder you want to deposit final files');
    % Hardcoding the final destination
    
    final_destDir = sourceDir(1:end-6);
    fprintf('Destination directory: %s. \n', final_destDir)
    
    
    if isequal(sourceDir, 0) || isequal(destDir, 0), return; end
    
    fileList = dir(fullfile(sourceDir, '*dcm')); % Catch all files
    fprintf('Scanning files...\n');
    
    if isequal(final_destDir, 0)
        error('User cancelled folder selection.');
    end
    
    %------------------------------------------------------------------------%
    
    for i = 1:length(fileList)
        if fileList(i).isdir, continue; end
        filePath = fullfile(sourceDir, fileList(i).name);
        
        try
            info = dicominfo(filePath);
            
            % Discriminator: SeriesInstanceUID (Identifies the 3D Volume)
            sUID = info.SeriesInstanceUID;
            
            % Folder Name: Using SeriesDate (20250110) and patient number
            % Plus we add the last 5 of the UID 
            rawDate = info.SeriesDate;
            folderName = sprintf('%s-%s-%s_%s_Series_%s_patient%d', rawDate(1:4), rawDate(5:6), rawDate(7:8), info.SeriesTime(1:6), sUID(end-4:end), j);
            
            targetPath = fullfile(destDir, folderName);
            if ~exist(targetPath, 'dir'), mkdir(targetPath); end
            
            % New File Name: Sorted by Slice (Instance) Number
            newFileName = sprintf('Slice_%03d.dcm', info.InstanceNumber);
            
            movefile(filePath, fullfile(targetPath, newFileName));
            % Gives progress updates after every 100 files
            if mod(i, 100) == 0
                
                fprintf('Processed %d files...\n',i)
            end
            
        catch
            % This catches non-DICOM files or system files
        end
    
    end
    fprintf('Done! Files sorted into Series folders.\n');
    
    %------------------------------------------------------------------------%
    
    fprintf('Now sorting to match script format!\n');
    
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
        newName = sprintf('CBCT_%d', i); % Format: Folder_1, Folder_2, etc.
        
        oldPath = fullfile(destDir, oldName);
        newPath = fullfile(final_destDir, newName);
        
        % Perform the rename
        copyfile(oldPath, newPath);
        
        fprintf('Renamed: %s  -->  %s\n', oldName, newName);
    end
    
    rmdir(sourceDir)
    fprintf('Done! Renamed %d folders.\n', length(folderList));
    fprintf('Normal Patient %d''s CBCTs ready for analysis.\n', j);

end