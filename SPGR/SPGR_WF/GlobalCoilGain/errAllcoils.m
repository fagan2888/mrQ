function err=errAllcoils(x,Gain,Py,M,MM,coefdat,coils)

    
   for i=1:coils 
    
    Gain(MM(:,i),i)=Py{i}.Poly*x(:,i);
   end
    
    err=nanstd(M./Gain,[],2);    
     err=sqrt(abs(err));
     
Gain(isnan(Gain))=0;
coefG=tril(corrcoef(Gain),-1);     
     
% Outside of this routine we already calculated
%   coefdat =tril(corrcoef(box),-1);
% Here we compare the two correlation coefficients
% The correlation coefficients of the data (coefdat) should be larger than
% the corr coef of the gain (coefG).
err2 = (coefdat(coefdat~=0)-coefG(coefdat~=0))./abs(coefdat(coefdat~=0)); 

% If the difference is positive, there is no penalty.
err2(err2>0)=0;
correlationPenalty=5;
% The remaining terms have a penalty, so we add them up and multiply by 5.
% That value is arbitrary.
err2 = sum(abs(err2))*correlationPenalty;
 
 
 err = err*(1+err2);
    
  if find(isinf(err))
     err(isinf(err))=10e10;
 end
 if find(isnan(err))
     err(isnan(err))=10e10;
 end
   
    