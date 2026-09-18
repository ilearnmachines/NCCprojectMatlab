function [CBCT] = ResampleCT(CBCT,pCT)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
CBCTr =[];
ImCBCT = CBCT{1};
Scbct =size(ImCBCT);

ImPCT = pCT{1};
Spct = size(ImPCT);

Origin_cbct = CBCT{9};
Origin_pct = pCT{9};

pix_space_cbct = CBCT{6};
pix_space_cbct = pix_space_cbct(1);

pix_space_pct = pCT{6};
pix_space_pct = pix_space_pct(1);


slice_spacing_cbct = CBCT{8};
slice_spacing_pct = pCT{8};

nPixelCBCT = Scbct(1);
nPixelpCT =Spct(1);


% xcbct = Origin_cbct(1):pix_space_cbct:Origin_cbct(1)+  (nPixelCBCT(1)-1)*pix_space_cbct;
% ycbct = Origin_cbct(2):pix_space_cbct:Origin_cbct(2)+  (nPixelCBCT(1)-1)*pix_space_cbct;
% ycbct=fliplr(ycbct);
% zcbct = Origin_cbct(3):-slice_spacing_cbct: Origin_cbct(3) - (Scbct(3)-1)*slice_spacing_cbct ;
% 
% xpct = Origin_pct(1):pix_space_pct:Origin_pct(1)+  (nPixelpCT(1)-1)*pix_space_pct;
% ypct = Origin_pct(2):pix_space_pct:Origin_pct(2)+  (nPixelpCT(1)-1)*pix_space_pct;
% ypct=fliplr(ypct);
% zpct = Origin_pct(3):-slice_spacing_pct: Origin_pct(3)-(Spct(3)-1)*slice_spacing_pct  

xv =  Origin_pct(1):pix_space_pct:(Spct(1)-1)*pix_space_pct + Origin_pct(1);
zv = Origin_pct(2):pix_space_pct:(Spct(2)-1)*pix_space_pct + Origin_pct(2);       
yv = Origin_pct(3):-slice_spacing_pct:Origin_pct(3) - (Spct(3)-1)*slice_spacing_pct;

yv = Origin_pct(3) + (Spct(3)-1)*slice_spacing_pct:-slice_spacing_pct:Origin_pct(3);

%zv=-1*zv;
xpct = xv;
ypct = zv;
zpct = yv;

xv =  Origin_cbct(1):pix_space_cbct:(Scbct(1)-1)*pix_space_cbct + Origin_cbct(1);
zv = Origin_cbct(2):pix_space_cbct:(Scbct(2)-1)*pix_space_cbct + Origin_cbct(2);       
yv = Origin_cbct(3):-slice_spacing_cbct:Origin_cbct(3) -(Scbct(3)-1)*slice_spacing_cbct;
%zv=-1*zv;
xcbct = xv
ycbct = zv;
zcbct = yv;



[Xc,Yc,Zc] = meshgrid(xcbct,ycbct,zcbct);
[Xp,Yp,Zp] = meshgrid(xpct,ypct,zpct);

V = interp3(Xc,Yc,Zc,ImCBCT,Xp,Yp,Zp,'linear',0);

CBCT=pCT;
CBCT{1} =V;



end

