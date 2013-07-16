function err = errFitNestBiLinearT1reg(g,M0,pBasis,nPositions,nCoils,R1basis,RegWeight)
% Bilinear estimation subject to T1 regularization as well
%
%  err =
%  errFitNestBiLinearT1reg(g,M0,pBasis,nPositions,nCoils,R1basis,RegWeight) 
%
% AM/BW(c) VISTASOFT Team, 2013

%estimate coil coefficients across the volume
G = pBasis*g;

% Estimate the best PD for each position a linear sulotion
% This makes it a nested bilinear problem

PD = zeros(nPositions,1);
for ii=1:nPositions
    PD(ii) = G(ii,:)' \ M0(ii,:)';
end

% Normalize by the first PD value
% Could wait until the end to do this.
G  = G  .* PD(1);
PD = PD ./ PD(1);

% get the predicted M0 for all of the coils
M0P = G.*repmat( PD,1,nCoils);

% Given the known T1, which is sent in, we have an expectation that it will
% be linearly related to the estimated PD via this equation:
%
%  1/PD = C1/T1+ C2
%
% So, we have a PD predicted from the T1.  These are the coefficients of
% the estimated linear relationship
% co     = R1basis \ ( 1./PD(:) );
% PDpred = R1basis*co;
PDpred     = R1basis* (R1basis \ ( 1./PD(:) ));
PDpred     = 1 ./ PDpred;

% mrvNewGraphWin; plot(PD(:),PDpred(:),'o')
% PDpred     = R1basis* (R1basis \ ( 1./PD(:) ));
% PDpred     = 1 ./ PDpred;

% The error is PD - PDpred
%
% An alternative is to calculate the correlation coefficient
% c = corrcoef(R1basis(:,2), 1./PD(:)); err = RegWeight*(1 - c(1,2));
% And then use this number at the end

% The error is a vector with positive and negative values representing the
% M0 difference and the T1 linearity failures
err = [ M0(:) - M0P(:); RegWeight*(PD(:) - PDpred(:))];

end