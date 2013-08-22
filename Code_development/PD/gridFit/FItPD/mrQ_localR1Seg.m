function  [ Segmask, C]= mrQ_localR1Seg(R1,BM1)
%
%  [ Segmask C]= mrQ_localR1Seg(R1,T1cut)
% segmetation of a given T1 values (in secound) by there values to three
% regiond. the region are acourdind to the median with +-T1cut (0.5sec
% defult ). the T1cut will grow if most of the T1 value does not fall into
% three T1 semetation value.

if notDefined('R1cut')
        R1cut=0.1;
end
      doneSeg=0;
      
        Segmask=zeros(size(R1));
        
        CSF= R1<0.35; %any tisuue with T1> ~0.2.85 is mostlly water and is a differnt tissue (CSF) then brain tissue
        R1=R1(~CSF);
        
         [IDX,C] =kmeans(t1,3);
       %  cheack if the center are close. if so  we will use less clusters 
         if abs(1-C(1)/C(2))<0.1  &&  abs(1-C(1)/C(3))<0.1
             [IDX,C] =kmeans(t1,1);
         elseif abs(1-C(1)/C(2))<0.1
             [IDX,C] =kmeans(t1,2);
         elseif abs(1-C(1)/C(3))<0.1
             [IDX,C] =kmeans(t1,2);
         elseif abs(1-C(2)/C(3))<0.1
             [IDX,C] =kmeans(t1,2);
         end
         
         % take only the voxel that are close to the centers
        while doneSeg==0
        for ii=1:max(IDX)
        
        maskT= Segmask==0 & t1>(C(ii)*(1-T1cut) )  & t1<(C(ii)* (1+T1cut) );
        if  length(find(maskT))>100
        Segmask(maskT)=ii;
        end
        
        end
        
        % check if most of the values were segmented if not we will permit
        % greater distance form the center
        if  length(find(Segmask))>(length(Segmask)*0.6)
            doneSeg=1;
        else
            T1cut=T1cut*1.1;
                    Segmask=zeros(size(t1));
        end
        end
        