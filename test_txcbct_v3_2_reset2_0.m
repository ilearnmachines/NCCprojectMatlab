%script to calculate NCC on a structure given the primary CT set
%the acquired CBCT and the registration objecy
%the planning structure set needs to be in same directory as the primary CT
%set

close all;clear all;


[folderPath] = uigetdir('Q:\Projects in progress\FORMANIYARMSC\Replanned_Patients','GetPatient');
fprintf('Source directory: %s. \n', folderPath)

%patient_number = folderPath(end:end);

% for patients 10-23
patient_number = folderPath(end-1:end);

contents = dir(folderPath);
contents = contents(~ismember({contents.name}, {'.', '..'}));

totalItems = numel(contents);
fprintf('Total items in folder: %d\n', totalItems);
total_CBCTs = totalItems-3;

NCCMetricOverall = zeros(1, total_CBCTs);
NCCMetricAverage = zeros(1, total_CBCTs);


% Fraction number of the first fraction where the treatment adaptation took
% place. First fraction where the replan set was used.  
AdaptFract = input('Which fraction did the treatment adaptation occur in?: ');

for i = 10:total_CBCTs
%for i = 27:30


    if i == 1
        fullPath = fullfile(folderPath, 'Plan_Set');
        [CT SSpr SSNames_pr]= importDCMseries(fullPath);
        plansetmsg = sprintf('in loop %d the plan set was imported', i);

    elseif i == AdaptFract
        fullPath = fullfile(folderPath, 'Replan_Set');
        [CT SSpr SSNames_pr] = Modified_importDCMseries(fullPath);
        plansetmsg = sprintf('in loop %d the replan set was imported', i);

    end
    
    % 1. Try to find the exact match for 'All_PTV'
    rowIdx = find(strcmp(SSNames_pr(:,3), 'PTV_6500'));
    
    % 2. If 'All_PTV' wasn't found, search for anything containing 'PTV_'
    if isempty(rowIdx)
        % contains() handles the wildcard logic (looks for 'PTV_')
        rowIdx = find(strcmp(SSNames_pr(:,3), 'PTV_6000'));
    end
    if isempty(rowIdx)
        % contains() handles the wildcard logic (looks for 'PTV_')
        rowIdx = find(contains(SSNames_pr(:,3), 'PTV_7'));
    end

    if isempty(rowIdx)
        % contains() handles the wildcard logic (looks for 'PTV_')
        rowIdx = find(contains(SSNames_pr(:,3), 'PTV_6'));
    end
    
            % 2. If 'All_PTV' wasn't found, search for anything containing 'PTV_'
    if isempty(rowIdx)
        % contains() handles the wildcard logic (looks for 'PTV_')
        rowIdx = find(contains(SSNames_pr(:,3), 'All_PTV'));
    end

    if isempty(rowIdx)
        % contains() handles the wildcard logic (looks for 'PTV_')
        rowIdx = find(contains(SSNames_pr(:,3), 'Primary_PTV'));
    end

    if isempty(rowIdx)
        % contains() handles the wildcard logic (looks for 'PTV_')
        rowIdx = find(contains(SSNames_pr(:,3), 'PTV_primary'));
    end
    
    if isempty(rowIdx)
        % contains() handles the wildcard logic (looks for 'PTV_')
        rowIdx = find(contains(SSNames_pr(:,3), 'PTV_60'));
    end
    
    % 3. Extract the number if a match was found (taking the first match if multiple)
    if ~isempty(rowIdx)
        % We use rowIdx(1) just in case multiple PTV_ items were found
        StructureValue = SSNames_pr{rowIdx(1), 1};
        
        % If your numbers are nested like {[ 1]}, peel it:
        if iscell(StructureValue)
            StructureValue = StructureValue{1};
        end
        
        selected_structure = SSNames_pr{StructureValue, 3};
        msg = sprintf('Selected Index: %d from Row: %d. This corresponds to %s\n', StructureValue, rowIdx(1), selected_structure);
        
    else
        msg = warning('Neither PTV_primary nor any PTV_6 or PTV_5 variant was found.');
    end
    
    Structure = sprintf('Item_%d', StructureValue);


    close all % close figures before each loop
    CBCTFoldername = sprintf('CBCT_%d', i);
    fullPath = fullfile(folderPath, CBCTFoldername);
    [CBCT SS SSNames]= importDCMseries(fullPath);
    
    
    ROfolder = sprintf('Registration_objects/RO_CBCT_%d', i);
    ROfilelocation = fullfile(folderPath, ROfolder);
    contents = dir(ROfilelocation);
    fileContents = contents(~[contents.isdir]);
    %string containing file name
    file = fileContents(1).name;
    
    ROfilePath = fullfile(ROfilelocation,file);
    %Get [file path] from this location 

    sprintf('loop %d of imports completed', i);




%{


%get CBCT
%The importDCMseries function creates a structure which holds info about
%the CT series including HU, pixel spacing, origin etc.
[path] = uigetdir('Q:\Projects in progress\FORMANIYARMSC\Patient1_S1985683','GetCBCT');
str = path
[CBCT SS SSNames]= importDCMseries(str);

%get primary
%[path] = uigetdir('Q:\Projects in progress\FORMANIYARMSC\Patient1_S1985683','GetPlanSet');
[path] = 'Q:\Projects in progress\FORMANIYARMSC\Patient1_S1985683\Plan_Set'
str = path
[CT SSpr SSNames_pr]= importDCMseries(str);

%get the registration object
[file path] = uigetfile('*.dcm','Get RegistrationObject','Q:\Projects in progress\FORMANIYARMSC\Patient1_S1985683\Registration_objects');
str = path

%}


%assocaite contour data  with slices
CT_r = LinkStructures(CT,SSpr);

cb_origin = [CBCT{9}(1); CBCT{9}(2); CBCT{11}(1,4)];%origin
cb_pixel = CBCT{6}(1);%pixel spacing, assumes same in both x,y
cb_slice = CBCT{7};%slice thickness


%ct_origin = CT{9};
ct_origin = [CT{9}(1); CT{9}(2); CT{11}(1,4)];%origin
ct_pixel = CT{6}(1);%pixel spacing, assumes same in both x,y
ct_slice = CT{7};%slice thickness


path = [ROfilelocation, '\'];
str = [path file];
info = dicominfo(str);
Regn = GetRegMatrix(info);

ct = CT{1};
Sct = size(ct);
zct = ct_origin(3):ct_slice:ct_origin(3)+(Sct(3)-1)*ct_slice;
xct = ct_origin(1):ct_pixel:ct_origin(1)+ct_pixel*(Sct(1)-1);
yct = ct_origin(2):ct_pixel:ct_origin(2)+ct_pixel*(Sct(2)-1);

cb = CBCT{1};
Scb = size(cb);
zcbct = cb_origin(3):cb_slice:cb_origin(3) + (Scb(3)-1)*cb_slice;
xcbct = cb_origin(1):cb_pixel:cb_origin(1)+cb_pixel*(Scb(1)-1);
ycbct =  cb_origin(2):cb_pixel: cb_origin(2)+cb_pixel*(Scb(2)-1);            


xlimcbct = [xcbct(1) xcbct(end)];
ylimcbct = [ycbct(1) ycbct(end)];
zlimcbct = [zcbct(1) zcbct(end)];


xlimct = [xct(1) xct(end)];
ylimct = [yct(1) yct(end)];
zlimct = [zct(1) zct(end)];




T = reshape(Regn, [4 4])';

tform = affine3d(T);


Rfixed  = imref3d(size(ct),xlimct,ylimct,zlimct );
RMoving = imref3d(size(cb), xlimcbct,ylimcbct,zlimcbct);

registeredCBCT = imwarp(cb,RMoving,tform,'OutputView',Rfixed);

Index =90;

SagSliceCBCT = squeeze(registeredCBCT(:,:,Index));

  SagSliceCT = squeeze(ct(:,:,Index));

  figure;imshowpair(SagSliceCBCT,SagSliceCT);axis square


 figure;imagesc(xct,yct,SagSliceCT);colormap('gray');axis square;title("CT")
ax = gca;


hold on

    ContourData = CT_r{12}(Index);
    F = ContourData{1,1};
    Fi =fields(F);
    Sc=size(Fi);
    Nc = Sc(1);
        for n=1:Nc
            str= ['Item_' num2str((n))];
            str=Fi(n);
            if (isfield(F,str))
                Scd =size(F.(Fi{n}).CD);   
                    for loop=1:Scd(2)
                    data = F.(Fi{n}).CD{loop}.Data;
                    Col = F.(Fi{n}).CD{loop}.Col;
                    xcont = data(1:3:end);          
                    ycont = data(2:3:end);
                    plot(xcont,ycont,'Color',Col/255);
                    end
            end
        end
hold off

 iPixDataCT1 = [];
 iPixDataCT2 = [];

%ptvb=18


%to pick a different structure just need to examine the structureset name 
%variable to get the correct one.
%obviously could be guified etc,.
ptvb_cont = SSpr.('Item_1').ContourSequence;
Mct = max(max(max(ct)));
Mcbct =max(max(max(registeredCBCT)));
xmin = xct(1);
ymin = yct(1);
xmax = xct(end);
ymax = yct(end);

%ct = ct./Mct;
%V1 = V1./Mcbct;
F=fieldnames(ptvb_cont);%will contain the structures per slice.
S = size(F,1);
for n=1:S % iterate through each contour
str = ['Item_' num2str(n)];%establish which image the contour belongs to. Multiple contours on same image shoudnt be a problem.
refctslice = ptvb_cont.(str).ContourImageSequence.Item_1.ReferencedSOPInstanceUID; 
for j=1:Sct(3)%iterate through slices

%iPixDataCT1 =[];
  %     iPixDataCT2=[];
  % 
  

  if strcmp(refctslice,CT{10}(j)) & zct(j)>=zlimcbct(1) & zct(j)<=zlimcbct(2) %is this the correct slice
      Imct = ct(:,:,j);% get the Primary data HUs

      Imcbct = registeredCBCT(:,:,j);%get the transformed cbct HUs


      contour_data = ptvb_cont.(str).ContourData;
      xcont = contour_data(1:3:end);
      ycont = contour_data(2:3:end);
  
      BW = roipoly([xmin xmax],[ymin ymax],Imct(:,:),xcont,ycont);%create a mask

      tCT1=Imct(BW)';%extarct pixel HU from mask
      tCT2=Imcbct(BW)';
      % append data into array
      iPixDataCT2 =   [iPixDataCT2 tCT2];
      iPixDataCT1 =   [iPixDataCT1 tCT1];
      
      %calc ncc
      avP = mean(iPixDataCT1);% calc NCC
      avC = mean(iPixDataCT2);
      sdP = std(iPixDataCT1);
      sdC = std(iPixDataCT2);
      N= length(iPixDataCT1);
%need to check but I think I need to reset iPixData if I want an NCC per
%image else it accumulates.
      NCC_im(n) = sum((iPixDataCT1 - avP).*(iPixDataCT2 - avC)./(sdP*sdC))./N;

              %  imct(BW)= -1000;
                
end
  

end
end
NCC_AV=mean(NCC_im);
avP = mean(iPixDataCT1);
avC = mean(iPixDataCT2);
sdP = std(iPixDataCT1);
sdC = std(iPixDataCT2);
N= length(iPixDataCT1);

                 NCC_overall = sum((iPixDataCT1 - avP).*(iPixDataCT2 - avC)./(sdP*sdC))./N;



NCCMetricAverage(i) = NCC_AV
NCCMetricOverall(i) = NCC_overall
fprintf('%s\n', msg)
fprintf('%s\n', plansetmsg)
end
NCCMetricAverage;
NCCMetricOverall;

%index_vector =strings(1, total_CBCTs);

%for z = 1:total_CBCTs
%    index_vector(z) = sprintf('Fraction %d', z);
%end

index_vector = (1:total_CBCTs);

NCCMetricFile = table(index_vector', NCCMetricAverage', NCCMetricOverall', 'VariableNames', {'FractionNumber','NCCMetricAvg', 'NCCMetricOverall'});
filename = sprintf('Q:\\Projects_in_progress\\FORMANIYARMSC\\Results\\Replanned_All_PTV_2.0\\NCCresults_patient_%s_%s_auto.xlsx', ...
                    patient_number, selected_structure);

writetable(NCCMetricFile, filename);% 
% 
% % %
% % 
% % slice_for_plot = zct(Index);
% % f = fieldnames(bladder.ContourSequence);
% % Si = size(f);
% % cnt_data=[];
% % for n=1:Si(1)
% %     str= ['Item_' num2str(n)];
% %     cnt= bladder.ContourSequence.(str);
% %     s = cnt.ContourData(3);
% %     if (s==slice_for_plot)
% %     cnt_data = bladder.ContourSequence.(str).ContourData;
% %     end
% % 
% % 
% % end
% % hold on
% %  xcont = cnt_data(1:3:end);          
% %                     ycont = -cnt_data(2:3:end);
% %                     plot(xcont,ycont,'Color','r');
% % hold off
% 




