function [empty] = mrQ_isDataBox(opt,brainMask,fb)
% 
% [empty,Avmap] = mrQ_isDataBox(opt,brainMask,fb)
% 
% Comments to come...
% 
% INPUTS:
%       opt     - 
%    brainMask  - 
%       fb      - 
%     Avmap     - 
% 
% OUTPUTS:
%       empty   - 
%       Avmap   -
% 
%      
% 
% (C) AM Stanford University, VISTA
% 

%%

sz = size(brainMask);

Xx(1)=opt.X(fb(1),fb(2),fb(3))-opt.HboxS(1);
Xx(2)=opt.X(fb(1),fb(2),fb(3))+opt.HboxS(1);
Yy(1)=opt.Y(fb(1),fb(2),fb(3))-opt.HboxS(2);
Yy(2)=opt.Y(fb(1),fb(2),fb(3))+opt.HboxS(2);
Zz(1)=opt.Z(fb(1),fb(2),fb(3))-opt.HboxS(3);
Zz(2)=opt.Z(fb(1),fb(2),fb(3))+opt.HboxS(3);




%check this is not out side the image
if (sz(1)< Xx(1) || sz(1)< Xx(2))
    box=[];
elseif (sz(2)< Yy(1) || sz(2)< Yy(2))
    box=[];
elseif (sz(3)< Zz(1) || sz(3)< Zz(2))
    box=[];
else
    box=brainMask(Xx(1):Xx(2),Yy(1):Yy(2),Zz(1):Zz(2));
end

% if (60> Xx(1) &&  60< Xx(2)  && 176> Yy(1) &&  176< Yy(2) && 100> Zz(1) &&  100< Zz(2)   )
%     c=1;
% end

cutT=length(box(:)).*0.05; % we will work only with boxes that have data on at least 5% of it. and at least 200 voxels

%check it's not almost empty from mask voxel
if (length(find(box))>cutT && length(find(box))>200)
    empty=0;
  
    
elseif length(find(box))<1
    empty=1;
else
    empty=-1;
    
end