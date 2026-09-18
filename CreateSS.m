function [ SS SSNames] = CreateSS( info )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
SS=[];
ROIContourSequence = info.ROIContourSequence;
SS = ROIContourSequence;
RS = info.StructureSetROISequence;
VOIsNo=length(fieldnames(RS)); %number of VOIs

VOIs={};

for i=1:VOIsNo
    ROINumber=eval(['RS.Item_',num2str(i),'.ROINumber']);
    ROIName=eval(['RS.Item_',num2str(i),'.ROIName']);
    disp(['Rank in the sequence = ',num2str(i),'   ROINumber = ',num2str(ROINumber),'   ROIName = ',ROIName])
    VOIs{i,1}=i;
    VOIs{i,2}=ROINumber;
    VOIs{i,3}=ROIName;
end
SSNames=VOIs;
end

