%% Working out the multiple coil case.
%
%
% TODO
%   1.  Realistic gains if possible -done X
%   2.  Extend to 3D  X
%   3.  Add a fourth coil or even make a function for N-coils  X
%   4.  Summarize the error distribution maybe in PD space? Coil space?  X
%   5.  Virtual coil analysis
%   6.  What else?
%   7.  Make the solution with eig and stuff a function  X
%   8.  Make the printing out and comparison a simple function  X
%  9.  Realistic noise
%

%% If you are in the mrQ directory, run this to set the path
addpath(genpath(fullfile(mrqRootPath)));

%% Run the script for the pdPolyPhantomOrder
nCoils   = 32;     % A whole bunch of coils
nDims    = 3;      % XYZ
pOrder   = 2;      % Second order is good for up to 5 samples
nSamples = 5;      % The box is -nSamples:nSamples
noiseFloor = 500;  % This is the smallest level we consider
sampleLocation = 3;% Which box location

% This produces the key variables for comparing data and polynomial
% approximations. We will turn it into a function before long.
% Variables include M0S_v, pBasis, params, SZ
[M0, M0_v, params,M0S_v, percentError, SZ, meanVal, pBasis, s,rSize,nVoxels,nPolyParams,pTerms] ...
    = pdPolyPhantomOrder(nSamples, nCoils, nDims, pOrder, noiseFloor, sampleLocation);

percentError = 100*percentError;
fprintf('Polynomial approximation to the data (percent error): %0.4f\n',percentError)

%% To visualize the simulation versus the fits
%M0S = reshape(M0S_v,SZ);

% We also use M0S for some calculations below

% lets hold each time one dimation and look on the center  inplain
% plotRawandSimProfile(nCoils,M0,M0S,[1 1 1],10)
% plotRawandSimProfile(nCoils,M0,M0S,round(SZ(1:3)/2),11)
% plotRawandSimProfile(nCoils,M0,M0S,SZ(1:3),12)


%% Fit poly to Ratios
coilList = [1,2,3];

%% First, try a pure simulation

% Fit the relative polynomial gain functions for the selected coils
% The 'est' parameter are the polynomial coefficients for each of the
% coils.
% This calculation uses the ratio of the coil data.
% The returned coil gains are specified up to an unknown scalar (they are
% relative).
[estGainCoefficients, polyRatioMat] = polySolveRatio(M0S_v(:,coilList), pBasis);
cond(polyRatioMat)

% calculate PD fits error and param error in comper to the % the params derived from the phantom.
Res = polyRatioErr(estGainCoefficients, params(:,coilList), pBasis);

% Show how well it does for pure simulation
estCoilGains  = pBasis*Res.estGainParams';
trueCoilGains = pBasis*Res.trueGainParams';
mrvNewGraphWin; plot(estCoilGains(:),trueCoilGains(:),'.')

%%  With real data, the fits go badly. 
% This is what we have to fix.
[estGainCoefficients, polyRatioMat] = polySolveRatio(M0_v(:,coilList), pBasis);

% calculate PD fits error and param error in comper to the % the params derived from the phantom.
Res = polyRatioErr(estGainCoefficients,params(:,coilList),pBasis);

% Show how well it does for pure simulation
estCoilGains  = pBasis*Res.estGainParams';
trueCoilGains = pBasis*Res.trueGainParams';
mrvNewGraphWin; plot(estCoilGains(:),trueCoilGains(:),'.')


%% the real Data; 

% We also know that the data are similar to the simulations.  But, they are
% not exact.  When we send in the data, which are fit by the simulations to
% within about 1.2 percent, we don't get a good result.

[Res.est, Res.polyRatioMat] = polySolveRatio(M0_v(:,coilList),pBasis);

% calculate PD fits error and param error in comper to the % the params derived from the phantom.
[Res.CoilCoefErr, Res.PDerr,  Res.estMatrix,  Res.ParMatrix, ...
    Res.G, Res.M00, Res.PD, Res.PDspaceErr]= ...
    polyRatioErr(Res.est,params(:,coilList),pBasis);

Res=Res_D;




%%  make simulation with  noise and smooth in space

% do it on bigger size voulume and then crop (so the smooth will be homgenius in the relevant voulume)
noiseLevel=5;

 clear M0SNS M0SNS_v M0SN M0SN_v  st ed N rSizeDD nVoxelsDD pMatrixDD sDD
[pMatrixDD,sDD] = polyCreateMatrix(nSamples*10,2,3);
rSizeDD = length(sDD);
nVoxelsDD = rSizeDD^nDims;
M0SN_v = zeros(nVoxelsDD,nCoils);
for ii=1:nCoils
    M0SN_v(:,ii)= pMatrixDD*params(:,ii) +randn(nVoxelsDD,1)*noiseLevel;
end
M0SN=reshape(M0SN_v,[rSizeDD rSizeDD rSizeDD  SZ(4)]);
for i=1:nCoils
    A=smooth3(M0SN(:,:,:,i),'gaussian',[21 21 21]);
     %   A=smooth3(M0SNSd(:,:,:,i));
    M0SNS(:,:,:,i)=A;                 
end
N=(rSizeDD-rSize)/2;
st=N+1;
ed=rSizeDD-N;

M0SNS=M0SNS(st:ed,st:ed,st:ed,:);
M0SN=M0SN(st:ed,st:ed,st:ed,:);
showMontage(M0S-M0SNS);title('sim- noisey sim smooth')
showMontage(-M0S-M0SN) ;title('sim- noisey sim')

M0SN_v=reshape(M0SN,prod(SZ(1:3)),SZ(4));
M0SNS_v=reshape(M0SNS,prod(SZ(1:3)),SZ(4));
clear st ed N rSizeDD nVoxelsDD pMatrixDD sDD
%% Fits and plots
coilList = [5 6];


%simultions
[ Res_S ]   = fitRatioandPlotPD(coilList,M0S_v,M0S,pMatrix,params, 'Sim',0);

%simulted noise
SNR = 20*log10(mean(mean(M0S_v(:,coilList))) /noiseLevel)
[ Res_SN]   = fitRatioandPlotPD(coilList,M0SN_v,M0SN,pMatrix,params, 'SimNoise',0);
% Smooth simulted noise
[ Res_SNS]   = fitRatioandPlotPD(coilList,M0SNS_v,M0SNS,pMatrix,params, 'SimNoiseSmooth',1);


% Data
[ Res_data]   = fitRatioandPlotPD(coilList,M0_v,M0,pMatrix,params, 'data',0);




%%

 showMontage(100* ((Res_S.R- Res_SN.R)./ Res_S.R ) ,[],[],[],[],7 );colormap hot;title('100X(RS- RSN)/RS')
 showMontage( 100* ((Res_S.R- Res_SNS.R)./ Res_S.R   )  ,[],[],[],[],8 );colormap hot;title('100X(RS- RSNS)/RS')
 showMontage( 100* ((Res_S.R- Res_data.R)./ Res_S.R )  ,[],[],[],[],9 );colormap hot;title('RS- Rdata/RS')

%%
G1=reshape(Res_S.G,[SZ(1:3) 2]);
G2=reshape(Res_SN.G,[SZ(1:3) 2]);

         plotRawandSimProfile(2,G1,G2,[1 1 1],10,{'no noise' 'noise'})


%%
% i should study if the noise effect is depend on the R are there R that
% are less susptipble to noise the other like when it far from 1? 
%noise as function of R

% i should try and see of constrain like the same Z variation. or miror
% image in X dimantion that decrice the serarch space can make the sulotion
% more robust.

%i need for the first point:
%a function that 1 allow me to ingect ratio instade of Mo. i will use that to gradually and locally change the noise.
%in respect to R or space or M0. of gain params
%
%for the secound point i need a way to reduce the number of parameters or
%the dimantion in the matrix. for that i need to write the eqations. and
%see what fulling .
% i also need to explore the data and see what is the resons of simitry.
% are the in all the D parameters or becuse of a joinning of them.




%% % can i smoth R will this help?

R1=smooth3(Res_SimNoise.R,'gaussian');

showMontage(100* ((Res_Sim.R- R1)./ Res_Sim.R ))


Rparams= polyfitPhantomCoef(Res_SimNoise.R(:),pMatrix);
R2=pMatrix*Rparams;
R2=reshape(R2,SZ(1:3));

degree=4
[Poly,str] = constructpolynomialmatrix3d(SZ(1:3),find(ones(SZ(1:3))),degree); 
          
                [Rparams] = fit3dpolynomialmodel(Res_SimNoise.R,logical(Res_SimNoise.R) ,degree);
             R2=Poly*Rparams';
R2=reshape(R2,SZ(1:3));
 showMontage(100* ((Res_Sim.R- R2)./ Res_Sim.R ));colormap hot; caxis([-1.5 1.5])

 % answer: no no really this is not diffrent then smooth the data.that was
 % not helpful