function mrQ_fitT1PDLW_SGE(opt,jumpindex,jobindex)
%
% Perform the T1 and PD fitting using the SGE
%
% mrQ_fitT1PD_SGE(opt,jumpindex,jobindex)
%
% Saves: 'res','resnorm','st','ed'
%    TO: [opt.outDir opt.name '_' num2str(st) '_' num2str(ed)]
%
% See Also:
%   mrQ_fitT1M0.m, mrQ_fitT1PD_LSQ.m
%

%%

% Set the maximum number of computational threads avaiable to Matlab
%maxnumcompthreads(1)

j  = 0;
st = 1 +(jobindex-1)*jumpindex;
ed = st+jumpindex-1;

if ed>length(opt.wh)
    ed = length(opt.wh);
end

%%
for i= st:ed,
    j=j+1;
    if (find(isnan(opt.s(i,:))) | find(opt.s(i,:)==0) |   find(isinf(opt.s(i,:))))
        res(1:4,j)=nan;
        
    else
        TR=opt.tr;
        fa=opt.flipAngles/180*pi*opt.B1(i);
        y = (opt.s(i,:))./sin(fa);
        x = (opt.s(i,:))./tan(fa);
        Vals = polyfit(x, y, 1);
        slopeBiased = Vals(1);
        result = abs(-TR./log(slopeBiased));
        
        %slopeBiased=pi^(-TR/linearT1)
        %
            t1Biased= result;
       
        %% PD
      
            pdBias=opt.s(i,:)./((1-exp(-TR./t1Biased)).*sin(fa)./(1-exp(-TR./t1Biased).*cos(fa)));
       
        pdBias=mean(pdBias)./opt.Gain(i);
        
        
                    
        weights = (sin(fa)./(1 - slopeBiased.*cos(fa))).^2;
        
        weights(isinf(weights)) = 0; %remove points with infinite weight
        
        Vals2 = polyfitweighted(x, y, 1, weights);
        slopeUnbiased = Vals2(1);
        t1Unbiased = abs(-TR./log(slopeUnbiased));
       
        %PD
     
            pdUnBias=opt.s(i,:)./((1-exp(-TR./t1Unbiased)).*sin(fa)./(1-exp(-TR./t1Unbiased).*cos(fa)));
       
        pdUnBias=mean(pdUnBias)./opt.Gain(i);
       
        res(1,j)=t1Unbiased;
        res(2,j)=pdUnBias;
        res(3,j)=t1Biased;
        res(4,j)=pdBias;
        
        
        
    end
end
List={'t1Unbiased' 'pdUnBias','t1biased' 'pdBias'};
%%

name = [opt.outDir opt.name '_' num2str(st) '_' num2str(ed)];
save(name,'res','st','ed','List')
