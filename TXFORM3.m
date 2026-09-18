close all;clear all;

[path] = uigetdir('Q:\Projects_in_Progress\FORMANIYARMSC','GetPriamry');
str = path
[CT SSpr SSNames_pr]= importDCMseries(str);
ct = CT{1};
Sct = size(ct);

for repeat=1:10

[path] = uigetdir('Q:\Projects_in_Progress\FORMANIYARMSC','GetCBCT');
str = path
[CBCT SS SSNames]= importDCMseries(str);
cb = CBCT{1};
Scb = size(cb);



[file path] = uigetfile('*.dcm','Get Tx','Q:\Projects_in_Progress\FORMANIYARMSC');

str = path


%assocaite contour data  with slices
CT_r = LinkStructures(CT,SSpr);

cb_origin = [CBCT{9}(1); CBCT{9}(2); CBCT{11}(1,4)];%origin
cb_pixel = CBCT{6}(1);%pixel spacing, assumes same in both x,y
cb_slice = CBCT{7};%slice thickness


%ct_origin = CT{9};
ct_origin = [CT{9}(1); CT{9}(2); CT{11}(1,4)];%origin
ct_pixel = CT{6}(1);%pixel spacing, assumes same in both x,y
ct_slice = CT{7};%slice thickness



str = [path file];
info = dicominfo(str);
Regn = GetRegMatrix(info);

zct = ct_origin(3):ct_slice:ct_origin(3)+(Sct(3)-1)*ct_slice;
xct = ct_origin(1):ct_pixel:ct_origin(1)+ct_pixel*(Sct(1)-1);
yct = ct_origin(2):ct_pixel:ct_origin(2)+ct_pixel*(Sct(2)-1);


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
NCC_AV=mean(NCC_im)
avP = mean(iPixDataCT1);
avC = mean(iPixDataCT2);
sdP = std(iPixDataCT1);
sdC = std(iPixDataCT2);
N= length(iPixDataCT1);

                 NCC_overall = sum((iPixDataCT1 - avP).*(iPixDataCT2 - avC)./(sdP*sdC))./N


end