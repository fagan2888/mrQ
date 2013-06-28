function [pMatrix,s, pTerms] = polyCreateMatrix(nSamples,order,dimension)
% Build 2D polynomial matrix
%
%    [pMatrix, s, pTerms] = polyCreateMatrix(nSamples,order,dimension)
%
% nSamples: Runs from -nSamples to +nSamples
% order   : polynomial order (linear, quadratic, cubic)
% dimension: 1, 2, or 3
%
% pMatrix: Polynomial basis functions for nth order and some number of
%          dimensions.   This matrix does NOT include the constant
% s:       Spatial samples
% pTerms:  String defining the polynomial terms
%
% Currently implemented for 2nd order, 1D, 2D and 3D
%
% Example:
%   nSamples = 20; order = 2; dimension = 2;
%   pMatrix = polyCreateMatrix(20,2,2);
%   imagesc(pMatrix);
%
% BW Copyright vistasoft 2013

s = -nSamples:nSamples;
%s=1:2*nSamples+1;
switch order
    case 1  % 1st order polynomial
        if dimension == 1
            X = s(:);
            pMatrix = [ones(size(X)), X];
            pTerms = '[1, X]';
        elseif dimension == 2
            [X, Y] = meshgrid(s,s);
            X = X(:);     Y = Y(:);
            pMatrix = [ones(size(X)), X, Y];
            pTerms = '[1, X, Y]';
            
        elseif dimension == 3
            [X, Y, Z] = meshgrid(s,s,s);
            X = X(:); Y = Y(:); Z = Z(:);
            pMatrix = [ones(size(X)), X, Y  Z ];
            pTerms = '[1, X, Y  Z ]';
        else
            error('Not yet implemented')
        end
        
    case 2  % 2nd order polynomial
        if dimension == 1
            X = s(:);
            X2 = X(:).^2;
            pMatrix = [ones(size(X)), X, X2];
            pTerms  = '[1, X, X2]';
            
        elseif dimension == 2
            [X, Y] = meshgrid(s,s);
            X = X(:);     Y = Y(:);
            X2 = X(:).^2; Y2 = Y(:).^2;
            XY = X(:).*Y(:);
            % Six parameters
            pMatrix = [ones(size(X)), X, X2, Y, Y2, XY];
            pTerms  = '[1, X, X2, Y, Y2, XY]';
            
        elseif dimension == 3
            [X, Y, Z] = meshgrid(s,s,s);
            X = X(:); Y = Y(:); Z = Z(:);
            X2 = X(:).^2; Y2 = Y(:).^2; Z2 = Z(:).^2;
            XY = X(:).*Y(:); XZ = X(:).*Z(:);  YZ = Y(:).*Z(:);
            % Ten parameters
            pMatrix = [ones(size(X)), X, X2, Y, Y2, XY  Z  Z2 XZ YZ];
            pTerms  = '[1, X, X2, Y, Y2, XY  Z  Z2 XZ YZ]';
            
        else
            error('Not yet implemented')
        end
        
    case 3
        
        if dimension == 1
            X = s(:);
            X2 = X(:).^2;
            X3 = X(:).^3;
            pMatrix = [ones(size(X)), X, X2, X3];
            pTerms  = '[1, X, X2, X3]';
            
        elseif dimension == 2
            [X, Y] = meshgrid(s,s);
            X = X(:);     Y = Y(:);
            X2 = X(:).^2; Y2 = Y(:).^2; 
            X3 = X(:).^3; Y3 = Y(:).^3; 
            XY = X(:).*Y(:); 
            X2Y = X2.*Y(:); XY2 = X(:).*Y2(:); 
            
            % 10 parameters
            pMatrix = [ones(size(X)), X, X2, Y, Y2, XY, X3, Y3, X2Y, XY2];
            pTerms  = '[1, X, X2, Y, Y2, XY, X3, Y3, X2Y, XY2]';

        elseif dimension == 3
            [X, Y, Z] = meshgrid(s,s,s);
            X = X(:); Y = Y(:); Z = Z(:);
            X2 = X(:).^2; Y2 = Y(:).^2; Z2 = Z(:).^2;
            X3 = X(:).^3; Y3 = Y(:).^3; Z3 = Z(:).^3;

            XY = X(:).*Y(:); XZ = X(:).*Z(:);  YZ = Y(:).*Z(:); 
            XYZ = X(:).*Y(:).*Z(:);
            X2Y = X2.*Y(:); X2Z = X2.*Z(:); 
            XY2 = X(:).*Y2(:); XZ2 = X(:).*Z2(:); 
            Y2Z = Y2(:).*Z(:); YZ2 = Y(:).*Z2(:);
            
            % Twenty parameters
            pMatrix = [ones(size(X)), X, X2, Y, Y2, XY ,X3, Y3, X2Y, XY2, Z, Z2, Z3, XZ, YZ, XYZ, X2Z, Y2Z, XZ2, YZ2];
            pTerms  = '[1, X, X2, Y, Y2, XY ,X3, Y3, X2Y, XY2, Z, Z2, Z3, XZ, YZ, XYZ, X2Z, Y2Z, XZ2, YZ2]';
        end
        
    otherwise
        error('Order %d not built',order);
end

return
