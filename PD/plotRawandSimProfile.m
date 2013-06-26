function plotRawandSimProfile(nCoils,M0,M0S,slices,figNum)

if notDefined('slices')
       slices=[1 1 1];
end
if notDefined('figNum')
      figNum=1;
end

figure(figNum);
        for ii=1:nCoils
            subplot(6,nCoils,ii); imagesc(squeeze(M0(slices(1),:,:,ii))); axis image%;title( 'YZ')
            if ii==round(nCoils/2)
                title(' YZ plain Data')
            end
            subplot(6,nCoils,nCoils+ii); imagesc(squeeze(M0S(slices(1),:,:,ii))); axis image%;title( 'YZ')
            if ii==round(nCoils/2)
                title(' YZ plain Simulations')
            end
       
            subplot(6,nCoils,2*nCoils+ii); imagesc(squeeze(M0(:,slices(2),:,ii))); axis image%;title( 'YZ')
            if ii==round(nCoils/2)
                title(' XZ plain Data')
            end
            subplot(6,nCoils,3*nCoils+ii); imagesc(squeeze(M0S(:,slices(2),:,ii))); axis image%;title( 'YZ')
            if ii==round(nCoils/2)
                title(' XZ plain Simulations')
            end
               subplot(6,nCoils,4*nCoils+ii); imagesc(squeeze(M0(:,:,slices(3),ii))); axis image%;title( 'YZ')
            if ii==round(nCoils/2)
                title(' XY plain Data')
            end
            subplot(6,nCoils,5*nCoils+ii); imagesc(squeeze(M0S(:,:,slices(3),ii))); axis image%;title( 'YZ')
            if ii==round(nCoils/2)
               title(' XY plain Simulations')
            end

        end