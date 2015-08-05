function mrQ_fitM0boxesCall(opt_logname,SunGrid,RunSelectedJob,GridOutputDir)
% this function load the opt straction that have all the fit information
% and send it in to the computer grid if one is defined (SunGrid).  If not
% it will send it to local compoter solver
%


load (opt_logname);
dirname=opt.dirname;
sgename=opt.SGE;
jumpindex=opt.jumpindex ;

fullID=sgename(isstrprop(sgename, 'digit'));
id=str2double(fullID(1:8));
if notDefined('GridOutputDir')
    GridOutputDir=pwd;
end
%%   Perform the gain fits
% Perform the fits for each box using the Sun Grid Engine
if SunGrid==1;
    
    % Check to see if there is an existing SGE job that can be
    % restarted. If not start the job, if yes prompt the user.
    
    if (~exist(dirname,'dir'))
        %     if notDefined('RunSelectedJob')
        %          this a fresh run, process all boxes.
        mkdir(dirname);
        eval(['!rm -f ~/sgeoutput/*' sgename '*'])
        %         if proclass==1
        %             sgerun2('mrQ_CoilPD_gridFit(opt,jumpindex,jobindex);',sgename,1,1:ceil(length(opt.wh)/jumpindex),[],[],5000);
        %         else
        %             sgerun('mrQ_CoilPD_gridFit(opt,jumpindex,jobindex);',sgename,1,1:ceil(length(opt.wh)/jumpindex),[],[],5000);
        %
        %         end
        for jobindex=1:ceil(length(opt.wh)/jumpindex)
            jobname=1000*str2double(fullID(1:3))+jobindex;
            command=sprintf('qsub -cwd -j y -b y -N job_%g -o %s "matlab -nodisplay -r ''mrQ_CoilPD_gridFit(%f,%g,%g); exit'' >log"', jobname,GridOutputDir, id,jumpindex,jobindex);
            [stat,res]= system(command);
            
            if ~mod(jobindex,100)
                fprintf('%g jobs out of %g have been submitted     \n',jobindex,ceil(length(opt.wh)/jumpindex));
            end
        end
        
    else
        
        %         run selected job is defined, meaning there was an existing job
        %         that can be finished
        an1 = input( 'Unfinished SGE run found: Would you like to try and finish the existing SGE run? Press 1 if yes. To start over, press 0 ');
        if an1==1
            % Continue existing SGE run from where we left it last time
            % we find the fits that are missing
            
            % User opted to try to finish the started SGE run
            MissingFileNumber=mrQ_multiFit_WhoIsMissing(dirname,length(opt.wh),jumpindex);
            if ~isempty(MissingFileNumber)
                
                for kk=1:length(MissingFileNumber)
                    jobindex=MissingFileNumber(kk);
                    jobname=1000*str2double(fullID(1:3))+jobindex;
                    %   sgerun2('mrQ_CoilPD_gridFit(opt,jumpindex,jobindex);',[sgename num2str(kk)],1,reval(kk),                       [],[],5000);
                    command=sprintf('qsub -cwd -j y -o %s -b y -N job_%g "matlab -nodisplay -r ''mrQ_CoilPD_gridFit(%f,%g,%g); exit'' >log"',GridOutputDir, jobname, id,jumpindex,jobindex);
                    %                     command=sprintf('qsub -cwd -j y -b y -N job_%g "matlab -nodisplay -r ''mrQ_CoilPD_gridFit(%f,%g,%g); exit'' >log"', jobname, id,jumpindex,jobindex);
                    [stat,res]=system(command);
                    if ~mod(kk,100)
                        fprintf('%g jobs out of %g have been submitted       \n',kk,length(MissingFileNumber));
                    end
                end
            end
            %                 else
            %                     sgerun('mrQ_CoilPD_gridFit(opt,jumpindex,jobindex);',sgename,1,reval,[],[],5000);
            %                 end
            
            % User opted to restart the existing SGE run
        elseif an1==0,
            t = pwd;
            cd (opt.outDir)
            eval(['!rm -rf ' dirname]);
            cd (t);
            eval(['!rm -f ~/sgeoutput/*' sgename '*'])
            mkdir(dirname);
            for jobindex=1:ceil(length(opt.wh)/jumpindex)
                jobname=1000*str2double(fullID(1:3))+jobindex;
                command=sprintf('qsub -cwd -j y -o %s -b y -N job_%g "matlab -nodisplay -r ''mrQ_CoilPD_gridFit(%f,%g,%g); exit'' >log"',GridOutputDir, jobname, id,jumpindex,jobindex);
                %               command=sprintf('qsub -cwd -j y -b y -N job_%g "matlab -nodisplay -r ''mrQ_CoilPD_gridFit(%f,%g,%g); exit'' >log"', jobname, id,jumpindex,jobindex);
                [stat,res]=system(command);
                if ~mod(jobindex,100)
                    fprintf('%g jobs out of %g have been submitted         \n',jobindex,ceil(length(opt.wh)/jumpindex));
                end
            end
            %             if proclass==1
            %                 sgerun2('mrQ_CoilPD_gridFit(opt,jumpindex,jobindex);',sgename,1,1:ceil(length(opt.wh)/jumpindex),[],[],5000);
            %             else
            %                 sgerun('mrQ_CoilPD_gridFit(opt,jumpindex,jobindex);',sgename,1,1:ceil(length(opt.wh)/jumpindex),[],[],5000);
            %
            %             end
        else
            error('User cancelled');
        end
        
    end
    
    % This loop checks if all the outputs have been saved and waits until
    % they are all done
    StopAndSave=0;
    fNum=ceil(length(opt.wh)/jumpindex);
    tic
    while StopAndSave==0
        % List all the files that have been created from the gris call
        list=ls(opt.outDir);
        
        % Check if all the files have been made.  If they have, move on.
        if length(regexp(list, '.mat'))==fNum,
            StopAndSave=1;
        else % meaning not all jobs are there
            jobname=fullID(1:3);
            qStatCommand    = [' qstat | grep -i  job_' jobname];
            [status result] = system(qStatCommand);
            tt=toc;
            if (isempty(result) && tt>60)
                pause(5);
                qStatCommand    = [' qstat | grep -i  job_' jobname];
                [status result] = system(qStatCommand);
                if (isempty(result))
                    
                    % then the are no jobs running or on queue but not all jobs
                    % are there so we will need to run the missing jobs.
                    MissingFileNumber=mrQ_multiFit_WhoIsMissing(dirname,length(opt.wh),jumpindex);
                    if ~isempty(MissingFileNumber)
                        % clean the sge output dir and run the missing fit
                        eval(['!rm -f ~/sgeoutput/*' sgename '*'])
                        for kk=1:length(MissingFileNumber)
                            jobindex=MissingFileNumber(kk);
                            jobname=1000*str2double(fullID(1:3))+jobindex;
                            %   sgerun2('mrQ_CoilPD_gridFit(opt,jumpindex,jobindex);',[sgename num2str(kk)],1,reval(kk),                       [],[],5000);
                            command=sprintf('qsub -cwd -j y -o %s -b y -N job_%g "matlab -nodisplay -r ''mrQ_CoilPD_gridFit(%f,%g,%g); exit'' >log"',GridOutputDir, jobname, id,jumpindex,jobindex);
                            %                                                         command=sprintf('qsub -cwd -j y -b y -N job_%g "matlab -nodisplay -r ''mrQ_CoilPD_gridFit(%f,%g,%g); exit'' >log"', jobname, id,jumpindex,jobindex);
                            [stat,res]=system(command);
                            if ~mod(kk,100)
                                fprintf('%g jobs out of %g have been submitted       \n',kk,length(MissingFileNumber));
                            end
                        end
                    end
                end
                
            else
                % if there are jobs running or on queue, we should wait untill
                % the're finished -->   keep waiting
            end
            
        end
    end
    
    
    
else
    % with out grid call that will take a very long
    disp(  'No parallel computation grid is used to fit PD. Using the local machine instead , this may take a very long time !!!');
    if (~exist(dirname,'dir')),
        mkdir(dirname);
    end
    jumpindex=   length(opt.wh);
    opt.jumpindex=jumpindex;
    
    mrQ_CoilPD_gridFit(id,jumpindex,1);
    save(opt.logname,'opt');
end


if SunGrid
    jobname=fullID(1:3);
    filesPath=[GridOutputDir,'/job_',num2str(jobname),'*'];
    delCommand=sprintf('rm %s', filesPath);
    [status, result]=system(delCommand);
end



%% the runselected job was used a tad differently
%         if notDefined('RunSelectedJob')
%
%             % Prompt the user
%             inputstr = sprintf('An existing SGE run was found. \n Would you like to try and finish the exist SGE run?');
%             RunSelectedJob = questdlg( inputstr,'mrQ_fitM0boxesCall','Yes','No','Yes' );
%             if strcmpi(RunSelectedJob,'yes'), RunSelectedJob = true; end
%             if strcmpi(RunSelectedJob,'no'),  RunSelectedJob = false; end
%         end
