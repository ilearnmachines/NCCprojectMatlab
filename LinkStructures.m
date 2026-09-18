function [CT_r] = LinkStructures( CT,SS)
%Link Structures iterates through structure set and associates structures
%with appropriate images
% J Gittins 27/7/2020


% Inputs
%   CT  : structure of CT data% see importDCMSeries for details
%   SS  : Structure set contour data
%   SSNames:%not currently needed
%Outputs:
%CT: CT structure but has contour Data per slice appended
Sct =size(CT{1});
nImages = Sct(3);
%Col=[];
CT_r =CT;
F = fields(SS);
Sn = size(F);
ContourData=cell(Sn);

for nI = 1:nImages%iterate through all images in set
 currentUID = CT{10}(nI);%get uid of current image
  
    for nROI = 1:Sn(1)%iterate thorough all structures
        str_sel = ['Item_' num2str(nROI)];  
            if isfield(SS.(str_sel),'ContourSequence')
                current_contour = SS.(str_sel).ContourSequence;
                Field_Current_Contour = fields(current_contour);
                Sfcc = size(Field_Current_Contour);
                nc=1;%possibly more than one contour for structures on a slice
                for nCC = 1:Sfcc(1)
                    UID = current_contour.(Field_Current_Contour{nCC}).ContourImageSequence.Item_1.ReferencedSOPInstanceUID;
                    %Get uid of ciurrent contour
                    if strcmp(UID,currentUID)
                        %need to know if muliple contours on same slice 
                        ds.Data= current_contour.(Field_Current_Contour{nCC}).ContourData;
                        ds.Display = 0;
                        ds.Col = SS.(str_sel).ROIDisplayColor;
                        ContourData{nI}.(str_sel).CD{nc} =ds;
                        nc=nc+1;
                end%if srcmp
            end%for ncc
        end%isfield
    end%for nROI
end%nImages
CT_r{12}=ContourData;




















