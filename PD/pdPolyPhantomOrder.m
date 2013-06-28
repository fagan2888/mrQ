function [OutPut]=pdPolyPhantomOrder(nSamples, nCoils,nDims,pOrder,noiseRange,sampleLocation,printImages,smoothkernel)

%
% function analyzes the polynomial order needed for different size boxes
%
%Inputs:
% nSamples                 nmber of voxel around the center voxal.
% sampleLocation        location of central voxel. posibale location are peaked and number 1:5is used to chose betwwn them
% nCoils                        the number of coils
% nDims                        1, 2 or 3 for the dimention of the problem
% pOrder                       the polyoms order to fit to the problem 1 2 3
% noiseRange                 a value of the M0 under we thing the SNR is too low
% plotImage                     make an image defult false
%
%       Output:
% OutPut                    is a stracture that include this fielled 
%                                M0,M0_v, params,M0S_v,VarEx,SZ, meanVal, pBasis, s,rSize,nVoxels,nVoxels

%  We evaluate the percent error in the polynomial approximation for each
%
%  combination of box size and polynomial order.
%
%  We will use this to justify our choice of polynomial order and box size.
%
%  It appears that nSamples =5 and pOrder = 2 is a good choice that
%  provides a polynomial accuracy to about 1.2 percent precision.
%  We only improve to 0.76 percent when we go to pOrder = 3, which adds 10
%  more parameters.
%
%  N.B.  We only evaluate the error when the M0 is at least 500.  We know
%  that the data are very noisy at levels below this (M0 ranges up to
%  3000). So, this number is good for the coil intensities within
%
% Copyright Vistasoft Team, 2013



%% Set up parameters for N realistic coils
if notDefined('sampleLocation')
    sampleLocation = 3;   % This is
end
if notDefined('nSamples')
    nSamples = 1;   % This is
end
if notDefined('nCoils')
    nCoils = 1;   % This is
end
if notDefined('nDims')
    nDims = 3;   % This is
end
if notDefined('pOrder')
    pOrder =2;   % This is
end
if notDefined('noiseRange')
    noiseRange =5;   % This is
end
if notDefined('printImages')
    printImages = false;   % This is
end
if notDefined('smoothkernel')
smoothkernel = [];   % This is
else
    OutPut.smoothkernel=smoothkernel;
end

%% Get M0 sample data from the coil

%4D
% M0 are the phantom data.  SZ is the size.  meanVal are the mean value
% from each coil

[M0, SZ, meanVal ]= phantomGetData(nSamples,sampleLocation,smoothkernel);

% Visualize the box.  The order is each panel is sorted by Z.
% Within each panel there are -nSamples:nSamples points
% showMontage(M0)

% Reshape the M0 data to a 2D image
% This has each coil data in a column
% Each column sweeps out the (x,y,z) values for that coil.
% We think it cycles as x, then, y, then z.  So, (1,1,1), (2,1,1), ... and
% then (1, 2, 1), (2, 2, 1), ...
M0_v = reshape(M0, prod(SZ(1:3)), nCoils);
if printImages==1
    mrvNewGraphWin; imagesc(M0_v)
end
%% This is phantom data and we approximate them by polynomials

% Create the basis functions for the polynomials
[pBasis,s, pTerms]  = polyCreateMatrix(nSamples,pOrder,nDims);
rSize       = length(s);
nVoxels     = rSize^nDims;
nPolyParams = size(pBasis,2);

% Get the phantom polynomial coefficients assuming the phantom PD equals
% one.  data = pMatrix * params.  So, pMatrix \ data
params = zeros(nPolyParams , nCoils);
for ii=1:nCoils
    params(:,ii)= pBasis \ M0_v(:,ii);
end

%% We check whether the approximation is accurate for the box

% M0 prediction as a vector for each coil
M0S_v = zeros(nVoxels,nCoils);
for ii=1:nCoils
    M0S_v(:,ii)= pBasis*params(:,ii);
end

%  std(  M0S_v(:) - M0_v(:) )
lst = M0_v > noiseRange;
percentError=std( (M0S_v(lst) - M0_v(lst)) ./ M0_v(lst));
if printImages==1
    mrvNewGraphWin; plot(M0S_v(:),M0_v(:),'.');
end
OutPut.M0=M0;
OutPut.M0_v=M0_v;
OutPut.params=params;
OutPut.M0S_v=M0S_v;
OutPut.percentError=percentError;
OutPut.meanVal=meanVal;
OutPut.pBasis=pBasis;
OutPut.s=s;
OutPut.rSize=rSize;
OutPut.nVoxels=nVoxels;
OutPut.nVoxels=nVoxels;




