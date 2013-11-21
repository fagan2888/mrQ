function [logname]=mrQ_PD_multicoil_RgXv_GridCall(outDir,SunGrid,proclass,subName,degrees,M0file,T1file,BMfile,outMm,boxSize,pracent_overlap,Coilsinfo,T1Reg,clobber)
%
%   [opt]=mrQ_PD_multicoil_RgXv_GridCall(outDir,SunGrid,proclass,subName,degrees,M0file,T1file,BMfile,outMm,boxSize,pracent_overlap,Coilsinfo,clobber)
% # Create a stracture of information to fit the M0 boxes ffor coil gain
% and PD using parallel computation (grid) using SGE
%
% INPUTS:
%   outDir      - The output directory - also reading file from there
%
%   SunGrid     - Flag to use the SGE for computations
%  proclass   - actived a Stanford local parralel computing grid to fit
%  (using SGE )
%   M0file     - The combined/aligned M0 data
% T1file         - The fitted T1 map
% BMfile       - The defied brain mask
%   degrees     - Polynomial degrees for the coil estimation
%   subName     - the subject name for the SGE run
%  outMm        - resample (undersample) resultoion of those images. defult
%                       (2X2X2) this can shorten the fits. The fit prociger was wrriten to this
%                       resulotion. This resulotion is asumed to be high given the low feqencicy
%                       change of the coils gain. 
% boxSize        the box size in mm that are used for the fit
% pracent_overlap  the overlap between the boxes (defult 0.5  --> 50%)
% Coilsinfo   coil info a stracture with three filled define the coil to be (used see below)
%  clobber:     - Overwrite existing data and reprocess. [default = false]
%
% OUTPUTS:
% opt           - a  structure that save the fit parameter is saved in the outdir and in
%               the tmp directory named fitLog.mat
%               calling to FitM0_sanGrid_v2 that save the output fitted files in tmp directorry
%              this will be used lster by mrQfitPD_multiCoils_M0 to make the PD map
%
%
% SEE ALSO:
%   mrQ_CoilPDFit_grid.m
%
%
% ASSUMPTIONS:
%   This code assumes that your SGE output directory is '~/sgeoutput'
% :
%
% AM (C) Stanford University, VISTA
%
%


%% CHECK INPUTS AND SET DEFAULTS
%  Saving parameters and relevant information for the Gain fit in the opt stracture. This allow to send them to all the
% grid call running  in parallel


if (notDefined('outDir') || ~exist(outDir,'dir'))
    outDir = uigetDir(pwd,'Select outDir');
end
opt.outDir  = outDir;

if(~exist('degrees','var'))
    disp('Using the defult polynomials: Degrees = 3 for coil estimation');
    degrees = 3;
end
opt.degrees = degrees;
% if the M0file is not an input  we load the file that was made by
% mrQ_multicoilM0.m (defult)
if(~exist('M0file','var') || isempty(M0file))
    M0file = fullfile(outDir,'AligncombineCoilsM0.nii.gz');
    if ~exist(M0file,'file')
        disp(' can not find the multi coils M0 file')
        error
    end
end
opt.M0file = M0file;


%using sungrid  defult no
if(~exist('SunGrid','var'))
    disp('SGE will not be used.');
    SunGrid = false;
end

if notDefined('boxSize')
    boxSize =14;
end
if notDefined('pracent_overlap')
    pracent_overlap =0.5;
end
if notDefined('Coilsinfo')
    % we define the number of coil that will be used to the fit and the
    % pull of best coil
    Coilsinfo.maxCoil=4;
    Coilsinfo.minCoil=4;
    Coilsinfo.useCoil=[1:16];
end

% In casses of high resltion data we can undersample the data to outMm
% resulotion
if notDefined('outMm')
    outMm=[2 2 2];
end
% defult T1 regularization
if notDefined('T1Reg')
    T1Reg=1;
end
% no regulariation if T1file is set to 0
if ~notDefined('T1file')
    if (T1file==0 )
        T1Reg=0;
    end
end

% in case of T1 regularization load the T1 map.
if  T1Reg==0
    
    opt.T1reg=0;
else
    opt.T1reg=1;
    
    if(~exist('T1file','var') || isempty(T1file))
        T1file = fullfile(outDir,'T1_map_lsq.nii.gz');
    end
    if ~exist(T1file,'file')
        T1file = fullfile(outDir,'maps/T1_lsq.nii.gz');
    end
    if ~exist(T1file,'file')
        
        disp(' can not find theT1 file')
        error
    end
    opt.T1file=T1file;
end




% Load the brain mask file
if(~exist('BMfile','var') || isempty(BMfile))
    BMfile = fullfile(outDir,'brainMask.nii.gz');
end
if (exist(BMfile,'file'))
    disp(['Loading brain Mask data from ' BMfile '...']);
    brainMask = readFileNifti(BMfile);
    mmPerVox  = brainMask.pixdim;
    opt.BMfile = BMfile;

    % In casses of high resltion data we can undersample the data when we fit the coil gains this may shorter the fit time.  not that the Coil gain was writtern for 2X2X2 resultion.
    % images different resultion may need some changes in the regularization protocol.
    if (outMm(1)~=mmPerVox(1) || outMm(2)~=mmPerVox(2) || outMm(3)~=mmPerVox(3) )
        [opt]=mrQ_resamp4G_fit(opt,outMm);
        brainMask = readFileNifti(opt.BMfile);
        mmPerVox  = brainMask.pixdim;
    end
    brainMask = logical(brainMask.data);
else
    error('Cannot find the file: %s', BMfile);
end


% Get the subject prefix for SGE job naming
if notDefined('subName')
    % This is a job name we get from the for SGE
    [~, subName] = fileparts(fileparts(fileparts(fileparts(fileparts(outDir)))));
    disp([' Subject name for lsq fit is ' subName]);
end


% Clobber flag. Overwrite existing fit if it already exists and redo the PD
% Gain fits. Not  implamented full yet
if notDefined('clobber')
    clobber = false;
end



if opt.T1reg


%segmening R1 to tissue types 
opt=R1Seg(opt);

end
%% find the boxes we will to fit


% Try to fill the brain with boxes of roughly boxSize mm^3 and with an
% overlap of 2;
sz   = (size(brainMask));
boxS = round(boxSize./mmPerVox);
even = find(mod(boxS,2)==0);

boxS(even)  = boxS(even)+1;
opt.boxS = boxS;

% Determine the percentage of pracent_overlap  (0.1, 0.5, 0.7)
overlap = round(boxS.*pracent_overlap);

% Grid of the center of the boxs that will be used to fit
[opt.X,opt.Y,opt.Z] = meshgrid(round(boxS(1)./2):boxS(1)-overlap(1):sz(1)    ,    round(boxS(2)./2):boxS(2)-overlap(2):sz(2)    , round(boxS(3)./2):boxS(3)-overlap(3):sz(3));

%donemask is a voulume of the center locations that are used for boc keeping. (which
%boxes are  done and which need be done of skip.)
donemask = zeros(size(opt.X));

opt.HboxS = (boxS-1)/2;


%% Loop over the box to fit and check there is data there

ii = 1;
opt.donemask = donemask;

for i=1:prod(size(opt.X))
    
    [fb(1) fb(2) fb(3)] = ind2sub(size(opt.X),i);
    [empty] = mrQ_isDataBox(opt,brainMask,fb);
    if empty == 0 % this is a good box
        opt.wh(ii) = i;
        ii = ii+1;
        
    elseif empty == 1 %box we won't use
        donemask(fb(1),fb(2),fb(3)) = -1e3;
        
    elseif empty == -1 %box we won't use
        donemask(fb(1),fb(2),fb(3)) = -2e3;
        opt.wh(ii) = i;
        ii = ii+1;
    end
    
end

opt.donemask = donemask;

%% Intiate other parameters for the fit and SGE call

opt.BasisFlag = 'qr'; %ortonormal basis for the coil  polynomyals
opt.lambda = [1e4 5e3 1e3 5e2 1e2 5e1 1e1 5  1e0 0.5 1e-1 0] ;%[1e4  1e3 5e2 1e2  1e1  1e0  0] ; %the different wights (lambda) for the T1 regularization we will check the differnt lambda by cross validation.
opt.Kfold=2;   % the cross validation fold ( use split half)

if ~opt.T1reg
opt.lambda=[ 1e16  1e15 1e14  1e12 1e10 1e9 1e8  1e4  1e0  0];
end

% the coils information how many coil to use and to poll from.
opt.maxCoil=Coilsinfo.maxCoil;
opt.minCoil=Coilsinfo.minCoil;
opt.useCoil=Coilsinfo.useCoil;

opt.smoothkernel=0;
sgename    = [subName '_MultiCoilM0'];
dirname    = [outDir '/tmpSGM0' ];
dirDatname = [outDir '/tmpSGM0dat'];
jumpindex  = 5; %number of boxs fro each SGR run

opt.dirDatname = dirDatname;
opt.name = [dirname '/M0boxfit_iter'] ;
opt.date = date;
opt.jumpindex = jumpindex;
opt.dirname=dirname;

opt.SGE=sgename;
% Save out a logfile with all the options used during processing
logname = [outDir '/fitLog.mat'];
opt.logname=logname;
%saving an information file we can load after if needed
save(opt.logname,'opt');


if clobber && (exist(dirname,'dir'))
    % in the case we start over and there are  old fits, so we will
    % deleat them
    eval(['! rm -r ' dirname]);
end



% %%   Perform the gain fits
% % Perform the fits for each box using the Sun Grid Engine
% if SunGrid==1;
%     
%     % Check to see if there is an existing SGE job that can be
%     % restarted. If not start the job, if yes prompt the user.
%     if (~exist(dirname,'dir')),
%         mkdir(dirname);
%         eval(['!rm -f ~/sgeoutput/*' sgename '*'])
%         if proclass==1
%             sgerun2('mrQ_CoilPD_gridFit(opt,jumpindex,jobindex);',sgename,1,1:ceil(length(opt.wh)/jumpindex),[],[],5000);
%         else
%             sgerun('mrQ_CoilPD_gridFit(opt,jumpindex,jobindex);',sgename,1,1:ceil(length(opt.wh)/jumpindex),[],[],5000);
%             
%         end
%     else
%         % Prompt the user
%         inputstr = sprintf('An existing SGE run was found. \n Would you like to try and finish the exsist SGE run?');
%         an1 = questdlg( inputstr,'mrQ_fitPD_multiCoils','Yes','No','Yes' );
%         if strcmpi(an1,'yes'), an1 = 1; end
%         if strcmpi(an1,'no'),  an1 = 0; end
%         
%         % User opted to try to finish the started SGE run
%         if an1==1
%             reval = [];
%             list  = ls(dirname);
%             ch    = 1:jumpindex:length(opt.wh);
%             k     = 0;
%             
%             for ii=1:length(ch),
%                 ex=['_' num2str(ch(ii)) '_'];
%                 if length(regexp(list, ex))==0,
%                     k=k+1;
%                     reval(k)=(ii);
%                 end
%             end
%             
%             if length(find(reval)) > 0
%                 eval(['!rm -f ~/sgeoutput/*' sgename '*'])
%                 if proclass==1
%                     for kk=1:length(reval)
%                         sgerun2('mrQ_CoilPD_gridFit(opt,jumpindex,jobindex);',[sgename num2str(kk)],1,reval(kk),[],[],5000);
%                     end
%                 else
%                     sgerun('mrQ_CoilPD_gridFit(opt,jumpindex,jobindex);',sgename,1,reval,[],[],5000);
%                 end
%             end
%             
%             % User opted to restart the existing SGE run
%         elseif an1==0,
%             t = pwd;
%             cd (outDir)
%             eval(['!rm -rf ' dirname]);
%             cd (t);
%             eval(['!rm -f ~/sgeoutput/*' sgename '*'])
%             mkdir(dirname);
%             if proclass==1
%                 sgerun2('mrQ_CoilPD_gridFit(opt,jumpindex,jobindex);',sgename,1,1:ceil(length(opt.wh)/jumpindex),[],[],5000);
%             else
%                 sgerun('mrQ_CoilPD_gridFit(opt,jumpindex,jobindex);',sgename,1,1:ceil(length(opt.wh)/jumpindex),[],[],5000);
%                 
%             end
%         else
%             error('User cancelled');
%         end
%     end
%     
% else
%     % with out grid call that will take very long
%     disp(  'No parallre computation grid is used to fit PD. Using the local machin instaed , this may take very long time !!!');
%     jumpindex=   length(opt.wh);
%     opt.jumpindex=jumpindex;
%     
%     mrQ_CoilPD_gridFit(opt,jumpindex,1);
%     save(opt.logname,'opt');
% end

%end

