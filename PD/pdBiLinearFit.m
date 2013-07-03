function OutPut=pdBiLinearFit(M0_v,pBasis,Lambda,maxLoops,sCriterion,PD,plotResults,TruePar)
%            OutPut=pdBiLinearFit(M0_v,pBasis,Lambda,maxLoops,sCriterion,PD,plotResults,TruePar)
%
% This fancrtion running a while loop solving the M0=GPD bi-linear problem.
% using ridge regression with regularisation coeffisent Lamdea for the gain
% problem. im each interval of the loop. the coil gain are estimated given
% a PD values. then the PD is evaluated again given the coil gain sulotion.
% the loop stop when the solotion convarge up to the stopping criterion or
% when it reach the maxsimal iteration
% Input
%  M0_v:         Columns containing the 3D M0 values in a vector (nVoxels x nCoils)
%  pBasis:         Polynomial basis (nPositions x nCoef)
%  Lambda       A ridge regration regularization term
%  maxLoops   maxsimal iteration of the while loop
%  sCriterion    Stopping criterion to stop the while loop (this  define what when the problem converge)
%  PD               initial PD sulotion
%  plotResults   when true (1) output a set of images showing the progess of the fit
% TruePar               the true coil gain coepicent parameters if they are
% known. like in the casses of   simulation or phantoms.
%OutPuts:
% OutPut is a stracture with a list of outputs:
%OutPut.PD             -  the final PD values
%OutPut.Gn             -  the final coils gain values
%OutPut.g                -  the final coils gain coeficents  (G = pBasis*g)
%OutPut.PDchange -  a vector of the PD change in each step
%OutPut.NumOfIter - number of iteration
%OutPut.convarge    - 1 if convarge 0 if not
%
%   AM/BW Copyright VISTASOFT Team 2013

%% intiate parameters

if notDefined('maxLoops')
    maxLoops = 100;
end
if notDefined('sCriterion')
    sCriterion = 1e-4;  % Stopping criterion
end
if notDefined('PDi')
    % This is the PD that will be returned if we won't have multi coil
    % information
    PD = sqrt(sum(M0_v.^2,2));
    PD = PD./ mean(PD);   % THere are options - e.g., we could set PD(1) to 1
end

if notDefined('plotResults')
    plotResults = 0;
end

nCoils    = size(M0_v,2);
nPolyCoef = size(pBasis,2);

% loop and solve by ridge regration
k = 0;                % number of iteration
tryagain = 1;         % go for the while loop
PDchange = zeros(1,maxLoops);

%% the inital sulotion
% When PD is given and M0 is given, we can form an estimate of the coil
% gains.  But note that this estimate is not immediately inside of the
% polynomial space.  So,
G = zeros(size(M0_v));
g0 = zeros(nPolyCoef,nCoils);
for ii=1:nCoils
    G(:,ii)  = M0_v(:,ii) ./ PD;         % Raw estimate
    g0(:,ii) = pBasis \ G(:,ii);  % Polynomial approximation
end


if plotResults==1
    
    if    notDefined('TruePar')
        Par=g0;
        GetPar=1;
        str='last interval coefisents';
    else
        Par=TruePar;
        str='True gains';
        GetPar=0;
    end
    % Plot the starting point
    mrvNewGraphWin(num2str(k));
    subplot(1,2,1); plot(g0(:),Par(:),'.')
    identityLine(gca);
    xlabel('Estimated gains'); ylabel(str);
    
    subplot(1,2,2); plot(PD,'.'); set(gca,'ylim',[.5 1.5]);
    ylabel('Estimated PD');xlabel('voxel');
    
end
%%  loop to try to solve the bilinear problem
while tryagain == 1
    k = k+1; % count Ridge regression steps
    
    % fit linear equation coefficients using ridge regression
    g = RidgeRegressCoilfit(PD, Lambda, M0_v, pBasis);
    
    % Calculate the coil gain of each coil over space from the estimate
    % Calculate PD for each coil
    [PDn, Gn] = pdEstimate(M0_v, pBasis, g);
    
    % normalized to have mean of 1.  Should we also multiply the gains, to
    % keep them consistent?
    PDn = PDn ./ mean(PDn(:));
    Gn  = Gn  .* mean(PDn(:));
    
    % Check if the new estimate differs from the one before or it's
    % converged
    PDchange(k) = std(PD - PDn);
    if PDchange(k) < sCriterion;
        % If stable to within 1 percent, stop.
        %
        % We could check the gains, rather than PD, or both
        % if std(G-Gn)<0.01
        
        % if the two solutions are stable --> stop
        tryagain=0;
    else
        % Keep going.
        % Update the new PD and and Gain
        PD = PDn;
        G  = Gn;
        if plotResults==1
            
            % plot the new estimations for coil gain and PD
            mrvNewGraphWin(num2str(k));
            subplot(1,2,1);plot(g(:)/g(1),Par(:),'.')
            identityLine(gca);
            xlabel('Estimated gains'); ylabel(str);
            
            subplot(1,2,2);
            plot(PDn,'.'); set(gca,'ylim',[.5 1.5]);
            ylabel('Estimated PD');xlabel('voxel');
            
            if  GetPar==1
                PAr=g;
            end
        end
    end
    % we have to stop some time if it's not convarging
    if k == maxLoops
        tryagain=0;
        if plotResults==1
            fprintf(' rich  % 0.f  iterations. Stop before convarge \n :',maxLoops);
        end
    end
end


if plotResults==1
    mrvNewGraphWin; semilogy(1:k,PDchange(1:k),'o');
    xlabel('steps'); ylabel('Change in PD')
end
%% Outputs
%make a list of outputs:
OutPut.PD=PDn; % the final PD values
OutPut.Gn=Gn; % the final coils gain values
OutPut.g=g; % the final coils gain coeficents  (G = pBasis*g)
OutPut.PDchange=PDchange;  % a vector of the PD change in each step
OutPut.NumOfIter=k;  % number of iteration
if k == maxLoops
    OutPut.convarge=0;  % the problem while loop got to it's last interval with out convarges
else
    OutPut.convarge=1;  % the problem lo convarges
end


