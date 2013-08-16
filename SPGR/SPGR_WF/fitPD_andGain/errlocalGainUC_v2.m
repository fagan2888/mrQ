function [err]=errlocalGainUC_v2(x,box,Poly,coefdat,use,coils)
%
%[err]=errlocalGainUC_v2(x,box,Poly,coefdat,use,coils)
%
% # estimation of the coils bias. we try to fit the different bias so:
% 1. all coil will have the same pd -->  PD=Coil_data/Coil_Bias
% 2. the different coils should not gain corrlation after removing the pd
% from all of them. becouse grater coralation mean adding bias part that
% will exsist in all coils and therefor pd estimations
%
% InPuts:
% x     - are the polynomials coeficient for each coil 
% his is a 2D matrix ( coeficient X coils )  
%
% box   -  is the coils data we fit to (2d (coils X data) (box is about 20^3x10).
%
% Poly  - are the polynomials we multipal the coeficient with
%
% coefdat -  coralation coeficient of the input coil by coil data ( in box).
%
% use - the location of the usiable data along the box (this is brain mask and clean for  out layers).
%
%OutPut
%err -the error in the estimation for unique PD with no added bias

%%
%arbitrary Penalty parameter
correlationPenalty = 5;

% The gain for each of the coils, estimated by the parameter x
Gain = Poly*x(:,:)';

%we checak if the coil gain fit goes wild. Gain can't be less then one we
%don't lose signal ....


%%  calculate the PD
%Gain =reshape(Gain(use),[],coils);
err4=0;
if find(Gain<1) ; err4=1-mean(Gain(Gain<1));end
%this is the predicted brain in each coil (row)
%  the reshape is faster way to do that --> the gain in the useable voxels
%    for i=1:10; tt(:,i)=Gain(use(:,i),i);end

Val = box./Gain;
% We want the mean to stay invariant, only minimizing on the total
% variation, not the mean
%Val = Val./mean(Val(:)); %we normalize by the mean 

% This is the std of the estimate of each brain voxel.  We want the
% coefficients find a solution that minimizes the different brain estimates
% across the coils. So this std is across the coil dimension.  We get a std
% for every box entry (brain voxel).
%err1 = std(Val,[],2);
% faster with norm(.,1) - this means sum(abs(val - mean(val)))
%
%err1=sum((abs(Val - mean(Val(:)))),2);

%%
%%%the error in fit
err1=( abs(Val - repmat(mean(Val,2),1,coils)) )./repmat(mean(Val,2),1,coils);
%err2=std(err1,[],1);


err1=sum(err1,2);

%% we don't use this for now
%we prefer a constant error and not local fits
%err1=err1*(1+sum(err2));

%%
% %, turn your attention to the correlation (overlap) between the coil
% gain functions.  We compute the corrcoefs and and take out the lower
% triangular (non-redundant) part of these.  -1 means take everything below
% the diagonal
coefG =  tril(corrcoef(Gain),-1);

% Outside of this routine we already calculated
%   coefdat =tril(corrcoef(box),-1);
% Here we compare the two correlation coefficients
% The correlation coefficients of the data (coefdat) should be larger than
% the corr coef of the gain (coefG).
err2 = (coefdat(coefdat~=0)-coefG(coefdat~=0))./abs(coefdat(coefdat~=0)); 

% If the difference is positive, there is no penalty.
err2(err2>0)=0;

% The remaining terms have a penalty, so we add them up and multiply by 5.
% That value is arbitrary.
err2 = sum(abs(err2))*correlationPenalty;

% Combine the two errors by multiplying them.
% Could be err1 + correlationPenalty*err2  
err = err1*(1+err2);

%% cheack for crazy fit
%let not alow minos brain!!!
err3=0;
if find(Val<0) ; err3=mean(Val(Val<0));end


err=err*(1+abs(err3));
%% 
%gain shouldn't go under 1 there is no such thing
err=err*(1+abs(err4));

%% we don't use this for now

%let not allow crazy local fit
% SDF=std(Val,2);
% if SDF>SDD*10
%     err=err*(1+abs(SDF/SDD));
% end;

%%
% Replace the infinite values with a large value to help later computations
err(isinf(err))=1e10;

return



%% old code and visaliztion for debuging



% err0=((abs(Val - repmat(mean(Val,2),1,coils)) )./repmat(mean(Val,2),1,coils));
% % % 
% Gain1 = Poly*x(:,:)';
%  box1=zeros([27 27 25 coils]);
%  val1=zeros([27 27 25 coils]);
%  %G=zeros([27 27 25 coils]);
%   val2=zeros([27 27 25 coils]);
% for i=1:coils,
%         tmp1=zeros([27 27 25]);
% 
%     tmp=zeros([27 27 25]);
%     tmp(use(:,1))=Val(:,i);
%     tmp1(use(:,1))=Val(:,i)./Gain1(:,i);
% val1(:,:,:,i)=tmp;
% val2(:,:,:,i)=tmp1;
% %  tmp(use(:,1))=box(:,i);
%box1(:,:,:,i)=tmp;
%tmp=reshape(Gain1(:,i),size(tmp));
%G(:,:,:,i)=tmp;
%val2(:,:,:,i)=box1(:,:,:,i)./G(:,:,:,i);

end


%%
% a simultion for the coraltion reduction argument
% a1 = posrect(3+randn(500,1000));
%  a2 = posrect(3+randn(500,1000));
%  a3 = posrect(3+randn(500,1000));
%  a1a2 = calccorrelation(a1,a2,2);
%  a1a2new = calccorrelation(a1.*a3,a2.*a3,2);
%  figure;scatter(a1a2,a1a2new,'r.');
%  xlabel('original correlation (r)');
%  ylabel('correlation after corruption by a3 (r)');
