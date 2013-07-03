%% Illustrate the bilinear alternative fit using ridge regression
%
% AM/BW VISTASOFT Team, 2013

%% If you are in the mrQ directory, run this to set the path
addpath(genpath(fullfile(mrqRootPath)));

%% Run the script for the pdPolyPhantomOrder
nCoils   = 32;     % A whole bunch of coils
nDims    = 3;      % XYZ
pOrder   = 3;      % Second order is good for up to 5 samples
nSamples = 4;      % The box is -nSamples:nSamples
noiseFloor = 500;  % This is the smallest level we consider
sampleLocation = 2;% Which box location
oFlag = true;

printImages = false;
smoothkernel=[];
% This produces the key variables for comparing data and polynomial
% approximations. We will turn it into a function before long.
% Variables include M0S_v, pBasis, params, SZ
[OutPut] = pdPolyPhantomOrder(nSamples, nCoils, nDims, pOrder, ...
    noiseFloor, sampleLocation, printImages, smoothkernel, oFlag);
% mrvNewGraphWin; imagesc(OutPut.pBasis);
% tmp = reshape(OutPut.pBasis,9,9,9,20);
% showMontage(tmp(:,:,:,1))

percentError = 100*OutPut.percentError;
fprintf('Polynomial approximation to the data (percent error): %0.4f\n',percentError)

%% Initiate params for the ridge regression
% 
k = 0;% number of iteration
tryagain = 1; % go for the while loop

%  the coil we use. i try different combintion and less combination it is
%  almost as good
coilList = 1:2; 
% the original estimated parameters from the noisy phantom data
Par = OutPut.params(:,coilList);  % Each coil 
Par = Par./Par(1);
   % The M0 values from the phantom
maxLoops = 100;
sCriterion = 1e-4;  % Stopping criterion    
% Set lambda.
Lambda = 0.1;

                            % I check lambda's any thing between 1- 0.1 was
                            % good. smaller lamda convarge slower
                            % higer lamda also convarge but tolarant some bias. in particular
                            % when less coils are used.
plotResults=1;
%%

BL=pdBiLinearFit( OutPut.M0_v(:,coilList),OutPut.pBasis,Lambda,maxLoops,sCriterion,[],plotResults,Par);
%            OutPut=pdBiLinearFit(M0_v,                               pBasis,             Lambda,maxLoops,sCriterion,PD,plotResults,TruePar)

PDFinal = reshape(BL.PD,OutPut.SZ(1:3));
showMontage(PDFinal)


%% now lets simulate noise 
noiseLevel=5;
PDtype=[];
PD=[];
[M0SN, M0S,SNR, PDsim]=simM0(OutPut.M0S_v(:,coilList),PD,noiseLevel,PDtype,plotResults);
PDsim=reshape(PDsim,OutPut.SZ(1:3));

BLSim=pdBiLinearFit( M0SN,OutPut.pBasis,Lambda,maxLoops,sCriterion,[],plotResults,Par);
PDFinal = reshape(BLSim.PD,OutPut.SZ(1:3));
showMontage(PDFinal-PDsim)


%% now lets simulate noise and PD
noiseLevel=5;
PDtype='1';
PD=[];

[M0SN, M0S,SNR, PDsim]=simM0(OutPut.M0S_v(:,coilList),PD,noiseLevel,PDtype,plotResults);
PDsim=reshape(PDsim,OutPut.SZ(1:3));

BLSim=pdBiLinearFit( M0SN,OutPut.pBasis,Lambda,maxLoops,sCriterion,[],plotResults,Par);
PDFinal = reshape(BLSim.PD,OutPut.SZ(1:3));
PDsim=reshape(PDsim,OutPut.SZ(1:3));
showMontage(PDFinal-PDsim)




