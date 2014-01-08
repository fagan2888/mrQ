function [Cbox,SHub] =mrQ_boxScaleGlobLinear(ScaleMat)
%[Cbox,SHub] =mrQ_boxScaleGlobLinear(ScaleMat)
%we will find the scale of each box so it will agreee with the values in the
%overlap boxes ( a scalar term). We assume that the boxPD  are free from gain and the only different is a scaler that need to be fit.
% all the diffent scalr or each two box are input ScaleMat.
% boxII= boxJJ*Ratio
 %               scaleFactor(ii,jj)=1./Ratio;
  %              scaleFactor(jj,ii)=Ratio;
                
%we will right a minimization eqation so all the scalares thogther will be adjasted.
%the idea is  box(i) -box(j)*scaler equal 0. we will build such set of eqations for all
%the overlap boxes and solve them thogther in the end.
% one box will be a refernce box.
%in the case of the reference we deside that scaler is 1;
%
% simulation of the problem we solve is at SimLinBoxJoin.m 
%
%
% AM (C) Stanford University, VISTA

%% find the bigest network of connected boxes

% what is the tipical ratio between two box?
MScale=median(ScaleMat(ScaleMat>0));
% if a ratio is more then 2 fold the usual it might be wrong. it might be
% better to get ride of those box. tipically this is only a small fraction
% then the box >>1%. this operation is usful for the solving the linear
% system without outlayers.
ScaleMat(ScaleMat>MScale*2)=0;
ScaleMat(ScaleMat<MScale*0.5)=0;



 [S, C]= graphconncomp(double(sparse(logical(ScaleMat))));
 for ii=1:S
 NudeN(ii)= length(find(C==ii));
 end
  [N,ind]=sort(NudeN);
  
% all the box that are conectet in the bigest network
boxT0Use=(C==ind(end)) ;
% let's save the clean Scale  matrix that have only  get only the boxes we like to
% work with.
ScaleMatNew=zeros(size(ScaleMat));
ScaleMatNew(boxT0Use,boxT0Use)=ScaleMat(boxT0Use,boxT0Use);
% build the  matrix for the scale linear calculation
LinScaleMat=zeros(size(ScaleMatNew));



%



% calcualte how many conction each box got
NConect=sum(logical(ScaleMatNew),1);
 Hub= (NConect==max(NConect)) & boxT0Use;

 %find the nude that highly conected and select one
 
 SHub=find(Hub);SHub=SHub(1,1);



%% Build the linear equations to solve for the XXX with respect to one box.

% We have removed the coil sensitivity from each of the boxes before
% getting here.  The only difference between the boxes is the unknown scale
% factor, which we created above and stored in ScaleMat.

% Therfore, the relationship between the data in the boxes is, say,
%
%   box1 = s12*box2, and perhaps box1 = s1J*boxJ
%
% We do not have an sij for every box relationship, but we do have it for
% many and an interlocking set of boxes.
%
% So, to solve for the sij given the boxes, we can set up the linear
% equation
%
%   N*box1 = \sum_j s1j*boxj
%
% where the sum is over all the boxes that overlap with box 1.

% So, we can set up a linear equation that has a row for every box and a
%
% We expect that after scaling the entries in the box
for   ii=find(boxT0Use)
   % if (ii ~=SHub)
       
 %           boxII= boxJJ*Ratio
 %               scaleFactor(ii,jj)=1./Ratio;
 %              scaleFactor(jj,ii)=Ratio;

     
 LinScaleMat(ii,:)=-ScaleMatNew(ii,:);
 LinScaleMat(ii,ii)=NConect(ii);
%    end
end
LinScaleMat(end+1,SHub)=1;


%% Solve for y = [SIJ] * [BoxMean]
%
% 0 = [K, -s1J .... (Matrix)] * [boxMean1 .... boxMeanN]
%

BoxLocation=[find(boxT0Use)   ];

y=zeros(size(LinScaleMat,1),1);

y=y(BoxLocation);
Mat=LinScaleMat(BoxLocation,BoxLocation);
% let's add one more eqation that will make the Hub box to have a scale
% coefisent of one.
% 
Mat(end+1,:)=0;
Mat(:,end+1)=0;
Mat(end,find(BoxLocation==SHub))=1;
y(end+1)=1;

%solve it as multi linear eqation
C=pinv(Mat'*Mat)*Mat'*y;
% the C we need is one over the one we fit


Cbox=zeros(length(BoxLocation),1);

Cbox(BoxLocation)=C(1:end-1);



