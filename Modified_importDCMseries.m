% ---------------------------------------------------------
% Import DICOM image series
% ---------------------------------------------------------
% P Dvorak 2018 Moded by JG to bring in Structure Set 26/07/2020
% ---------------------------------------------------------
% Reconstruct an image series from DICOM files in current directory.
% One DICOM file per axial/coronal/sagital slice is expected.
% ---------------------------------------------------------
%
% INPUT:
% - single series image files in current folder
%
% OUTPUT: cell array with the following components:
% - image matrix
% - Modality (CT, MR, PT,...)
% - Patient position (string: HFS, FFS, HFP, etc.)
% - Slice orientation (string: axial/coronal/sagital)
% - Image orientation patient (6 element vector)
% - Pixel spacing (2 element vector for direction of rows and columns)
% - Slice thickness (single figure if uniform within the series, min & max otherwise, 'N/A' if not available or empty)
% - Slice spacing (distance between neighboring slice location (single figure if uniform within the series, min & max otherwise, empty if not available)
% - OriginXYZ (3 element vector indicating DICOM origin reference point)
% ---------------------------------------------------------
%
% Syntax: importDCMseries
% ---------------------------------------------------------
%
% Dependent user-functions:
% - none
% ---------------------------------------------------------
%
%         Version: 1/2018
% Version History: none
% ---------------------------------------------------------

function [dcmImgImport SS SSNames] = importDCMseries(path)   
  SS=[];SSNames=[];
    dcmFiles = dir(path);
    UID = {};
    disp('Extracting DICOM information...');
    n=0;
    for i=1:length(dcmFiles)
        if dcmFiles(i).bytes>0
            fileInfo = dicominfo([path '\' dcmFiles(i).name], 'UseDictionaryVR', true, 'UseVRHeuristic',false);
            fileInfo.SeriesInstanceUID;
            %check if ss
            if (strcmp(fileInfo.MediaStorageSOPClassUID,'1.2.840.10008.5.1.4.1.1.481.3'))
        [SS SSNames]= CreateSS(fileInfo);
            end
            Modality=fileInfo.Modality;
            if length(Modality)==2
                if (Modality=='CT')|(Modality=='MR')|(Modality=='PT')
                    Rows(n+1) = fileInfo.Rows;
                    Columns(n+1) = fileInfo.Columns;
                    SliceLocationFile(n+1,:) = [i,fileInfo.ImagePositionPatient'];
                    UID{n+1} = fileInfo.SOPInstanceUID;
                    n = n+1;
                    
                end
            end
        end
    end
    disp('OK');
    
    %rows and columns consistency check
    if max(abs(diff(Rows)))>0
        RowsRange = [min(Rows),max(Rows)]
        error('ERROR! Number of rows inconsistent within the series')
    end

    if max(abs(diff(Columns)))>0
        ColumnsRange = [min(Columns),max(Columns)]
        error('ERROR! Number of columns inconsistent within the series')
    end
    %END: rows and columns consistency check
    
    fileInfo = dicominfo([path '\' dcmFiles(SliceLocationFile(1,1)).name]);
    Modality = fileInfo.Modality;
    Rows = fileInfo.Rows;
    Columns = fileInfo.Columns;
    SlicesNumber = n;
    PatientPosition = fileInfo.PatientPosition;
    ImageOrientationPatient = fileInfo.ImageOrientationPatient;
    
    imgMatrix = zeros(Rows, Columns, SlicesNumber);
    SliceThicknessSeries = [];
    
    if abs(round(ImageOrientationPatient)) == [1,0,0,0,1,0]'
        SliceOrientation='axial';
        SlicesDirection=3;
    elseif abs(round(ImageOrientationPatient)) == [1,0,0,0,0,1]'
        SliceOrientation='coronal';
        SlicesDirection=2;
    elseif abs(round(ImageOrientationPatient)) == [0,1,0,0,0,1]'
        SliceOrientation='sagital';
        SlicesDirection=1;
    else
        disp('Unknown slice orientation')
        SliceOrientation='unknown';
    end
   
    
    if size(SliceLocationFile,1)>1
        for i=1:size(SliceLocationFile,1)
            SliceLocationFile(i,5)=(SliceLocationFile(i,2:4)-SliceLocationFile(1,2:4))/(SliceLocationFile(2,2:4)-SliceLocationFile(1,2:4))*norm(SliceLocationFile(2,2:4)-SliceLocationFile(1,2:4));
        end
    else
        SliceLocationFile(1,5)=0;
    end
    
    %SliceLocation = sortrows(SliceLocationFile,5);  %sorting DICOM files by SliceLocation in appropriate coordinate...
    SliceLocation = sortrows(SliceLocationFile,4,'ascend'); 
    clear Rows Columns

    
    disp('Importing DICOM images...');
    for j=1:size(SliceLocation,1)
        fileInfo = dicominfo([path '\' dcmFiles(SliceLocation(j,1)).name]);
          UID{j} = fileInfo.SOPInstanceUID;
        if (isfield(fileInfo,'SliceThickness')) && (~isempty(fileInfo.SliceThickness))
            SliceThicknessSeries(j) = fileInfo.SliceThickness;
        end
        
        PixelSpacingSeries(j,:) = fileInfo.PixelSpacing;
        imgMatrix(:,:,j) = double(dicomread([path '\' dcmFiles(SliceLocation(j,1)).name]));
        if isfield(fileInfo,'RescaleSlope')
            imgMatrix(:,:,j)=imgMatrix(:,:,j)*fileInfo.RescaleSlope+fileInfo.RescaleIntercept;
        end
    end
    disp('OK');
    disp('     ');


    if max(abs(diff(PixelSpacingSeries)))>0.0001
        disp('WARNING! PixelSpacing inconsistent within the series')
        PixelSpacing = [min(abs(diff(PixelSpacingSeries))),max(abs(diff(PixelSpacingSeries)))];
    else
        PixelSpacing = PixelSpacingSeries(1,:);
    end
    
    if max(abs(diff(SliceThicknessSeries)))>0.0001
        disp('WARNING! SliceThickness inconsistent within the series')
        SliceThickness = [min(abs(diff(SliceThicknessSeries))),max(abs(diff(SliceThicknessSeries)))];
    elseif length(SliceThicknessSeries)>0
        SliceThickness = SliceThicknessSeries(1);
    else
        SliceThickness = 'N/A';
    end

    if max(abs(diff(diff(SliceLocation))))>0.0001
        disp('WARNING! SliceLocation (slice spacing) inconsistent within the series')
        SliceSpacing = [min(abs(diff(SliceLocation(:,SlicesDirection+1)))),max(abs(diff(SliceLocation(:,SlicesDirection+1))))];
    else
        SliceSpacing = min(abs(diff(SliceLocation(:,SlicesDirection+1))));
    end

    fileInfoLast=dicominfo([path '\' dcmFiles(SliceLocation(end,1)).name]);
    OriginXYZ=fileInfoLast.ImagePositionPatient;
    
    disp('   ')
   
    dcmImgImport{1} = imgMatrix;
    dcmImgImport{2} = Modality;
    dcmImgImport{3} = PatientPosition;
    dcmImgImport{4} = SliceOrientation;
    dcmImgImport{5} = ImageOrientationPatient;
    dcmImgImport{6} = PixelSpacing;
    dcmImgImport{7} = SliceThickness;
    dcmImgImport{8} = SliceSpacing;
    dcmImgImport{9} = OriginXYZ;
    dcmImgImport{11}= SliceLocation;
    dcmImgImport{10} = UID;
    disp('- - - - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - -')
    disp('   ')
    disp(['Image matrix dimensions =  ',num2str(size(imgMatrix))])
    disp(['Image modality =  ',Modality])
    disp(['Image patient position =  ',PatientPosition])
    disp(['Image slice orientation =  ',SliceOrientation])
    disp(['Image orientation patient =  ',num2str(ImageOrientationPatient')])
    disp(['Image pixel spacing =  ',num2str(PixelSpacing)])
    disp(['Image slice thickness =  ',num2str(SliceThickness)])
    disp(['Image slice spacing =  ',num2str(SliceSpacing)])
    disp(['Image DICOM origin =  ',num2str(OriginXYZ')])
    
end


 
 

