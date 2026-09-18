function [NCC_vals,NCC_imret,NCC_slices] = CalcNcc(CT1,CT2,Contours)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
Ncc_vals =[];
NCC_imret=[];
pixeldataCT1=[];
pixeldataCT2=[];

S = size(CT1{1});
Origin = CT1{9};
pix_space = CT1{6}(1);

ImCT1 =CT1{1};
ImCT2 =CT2{1};
xmin = Origin(1);
ymin = Origin(2);
xmax = xmin+ pix_space*S(1);
ymax = ymin+ pix_space*S(2);

Nroi=size(Contours);
nImages = S(3);
for loopROI = 1:Nroi(2)
str = ['Item_' num2str(Contours(loopROI))];
pixeldataCT1=[];
pixeldataCT2=[];
valid=0;
for nI = 1:nImages
       iPixDataCT1 =[];
       iPixDataCT2=[];
  
        
    AllContourDataCT1 = CT1{11}(nI);
        CellArray = AllContourDataCT1{1,1};
        do_calc=0;
        if isfield(CellArray,str)
        Data = CellArray.(str);
        Sdatacd =size(Data.CD);   
            for c = 1:Sdatacd(2)
            d = CellArray.(str).CD{c}.Data;
             x = d(1:3:end);
             y = d(2:3:end);
            BW = roipoly([xmax xmin],[ymin ymax],ImCT1(:,:,nI),x,y);
            I1 = ImCT1(:,:,nI);
            I2 = ImCT2(:,:,nI);
            tCT1=I1(BW)';
            tCT2=I2(BW)';
            if (~isnan(tCT1) & ~isnan(tCT2))
                pixeldataCT1 = [pixeldataCT1 I1(BW)'];
                pixeldataCT2 = [pixeldataCT2 I2(BW)'];
                iPixDataCT1 =   [iPixDataCT1 tCT1];
                iPixDataCT2 =   [iPixDataCT2 tCT2];
                valid=1;
            end
            if ~isempty(iPixDataCT1)& ~isempty(iPixDataCT2)& valid==1
                avP = mean(iPixDataCT1);
                avC = mean(iPixDataCT2);
                sdP = std(iPixDataCT1);
                sdC = std(iPixDataCT2);
                N= length(iPixDataCT1);
                if sdP>0 & sdC>0
                NCC_im(loopROI,nI) = sum((iPixDataCT1 - avP).*(iPixDataCT2 - avC)./(sdP*sdC))./N;
                end
               valid=0;
            end
            
            
            end
        
        end
  
   
 
      end
       avP = mean(pixeldataCT1);
    avC = mean(pixeldataCT2);
    sdP = std(pixeldataCT1);
    sdC = std(pixeldataCT2);
    N= length(pixeldataCT1);
    if sdP>0 & sdC>0
        
    NCC(loopROI) = sum((pixeldataCT1 - avP).*(pixeldataCT2 - avC)/(sdP*sdC))/N;
    end
      
    end%nImages
    %calculate statistic
    for n=1:Nroi(2)
        indices = find(NCC_im(n,:));
        NCC_imret{n} = NCC_im(n,indices);
        NCC_slices{n} = indices;
    end
    
    
    NCC_vals =NCC;
      
end




