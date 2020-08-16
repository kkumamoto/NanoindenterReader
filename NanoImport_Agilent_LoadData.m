%% NanoImport_Agilent_LoadData
% This works on each loaded indent array spreadsheet from at a time an
% Agilent CSM or QS output.

function [OutPut,SpreadSheetName] = NanoImport_Agilent_LoadData(debugON,file,filename,changeBBsStruct,w,XDataCol,NoYCols,mode,varNames,waitTime)
    title = 'NanoMachineImport_Agilent - MainProcess Function';
    [ProgressBar,SpreadSheetName] = NanoMachineImport_first_stage(title,file);
    
    % This accesses the data produced from changeBinBoundaries
    DepthLimit = changeBBsStruct.DepthLimit;
    bin_boundaries = changeBBsStruct.bin_boundaries;
    bin_midpoints = changeBBsStruct.bin_midpoints;
    bins = changeBBsStruct.bins;
    message = sprintf('%s: Set-up - Bin Calculations Imported',SpreadSheetName);
    waitbar(1/3,ProgressBar,message);
    
    % This is a list of all of the sheet names for that spreadsheet file.
    SheetNames = sheetnames(filename);
    
    % This accesses the first sheet named 'Results'
    opts_Sheet1 = detectImportOptions(filename,'Sheet','Results','FileType','spreadsheet','PreserveVariableNames',true);
    Table_Sheet1 = readtable(filename,opts_Sheet1);
    % This then calculates the number of indents from which it will cycle
    % through, hence if you delete entries on here and their associated
    % sheets it will be fine
    NumOfIndents = size(Table_Sheet1,1)-3;
    message = sprintf('%s: Set-up - "Results" Analysed',SpreadSheetName);
    waitbar(2/3,ProgressBar,message);


    
    % This is a 3D array which will store the force, time, HCS, H, and E
    % data, with the 3rd axis being for each indent.
    PenultimateArray = zeros(bins,NoYCols,NumOfIndents);
    PenultimateErrors = zeros(bins,NoYCols,NumOfIndents);
    
    if debugON == true
        disp('Arrays debug');
        arraySizeDebug(PenultimateArray,'PenultimateArray');
        arraySizeDebug(PenultimateErrors,'PenultimateErrors');
    end
    
    message = sprintf('%s: Set-up Complete!',SpreadSheetName);
    waitbar(1,ProgressBar,message);
    
    indProTime = nan(NumOfIndents,1);
    
    % This for loop cycles for each indent
    for currIndNum = 1:NumOfIndents
        tic
        % This updates the progress bar with required details.
        [indAvgTime,RemainingTime] = NanoMachineImport_avg_time_per_indent(ProgressBar,indProTime,currIndNum,NumOfIndents,SpreadSheetName);

        % There are 4 sheets auto-generated that aren't indent data, then
        % it works from right to left, hence minus the indent number.
        SheetNum = 4+NumOfIndents-currIndNum;
        
        if debugON == true
            fprintf("Current indent number %d/%d\n",currIndNum,NumOfIndents);
            fprintf('Cuurent Avg. time per indent is %.3g secs\n\n',indAvgTime(end));
        end
        
        % Preparing for NanoMachineImport_bin_func
        SheetName = SheetNames(SheetNum);
        Table_Current = TablePrep(filename,SheetName,mode);
        BinStruct = struct('XDataCol',XDataCol,'bins',bins,'bin_boundaries',bin_boundaries);
        msg_struct = struct('IDName',SpreadSheetName,'currIndNum',currIndNum,'NumOfIndents',NumOfIndents,'RemainingTime',RemainingTime,'ProgressBar',ProgressBar);

        % This obtains arrays which are binned for both the value and
        % standard dev., along with producing an array of the bin counts.
        [TemplateArray,TemplateErrors,N] = NanoMachineImport_bin_func(debugON,w,Table_Current,BinStruct,msg_struct);
        PenultimateArray(:,:,currIndNum) = TemplateArray;
        PenultimateErrors(:,:,currIndNum) = TemplateErrors;
        clearvars('TemplateArray','TemplateErrors');
        
        indProTime(currIndNum,1) = toc;
    end
    waitbar(1,ProgressBar,'Finished working on indents!');
    
    % This gets the penultimate array data and the other essential
    % information to produce an output structure containing all of the
    % information from the imported Excel spreadsheet.
    OutPut = NanoMachineImport_final_stage(PenultimateArray,w,NumOfIndents,bin_midpoints,bin_boundaries,DepthLimit,N,debugON,waitTime,varNames);
    close(ProgressBar);
    fprintf('%s: Completed!\n',title);
end

%% Nested Functions
    
function Table_Current = TablePrep(filename,SheetName,mode)
    
    % This changes the range to the appropriate length
    if strcmp(mode,'csm') == true
        SheetRange = 'B:G';
        NoColsOfData = 6;
    elseif strcmp(mode,'qs') == true
        SheetRange = 'B:H';
        NoColsOfData = 7;
    end

    Table_Sheet = readmatrix(filename,'Sheet',SheetName,'FileType','spreadsheet','Range',SheetRange,'NumHeaderLines',2,'OutputType','double','ExpectedNumVariables',NoColsOfData);

    if strcmp(mode,'csm') == true
        % We look at H and E so that we can neglect data for which
        % unusually high magnitude numbers are produced.        
        GoodRows = (abs(Table_Sheet(:,5)) < 10^3) & (abs(Table_Sheet(:,6)) < 10^3);
        Table_Current = Table_Sheet(GoodRows,:);
    elseif strcmp(mode,'qs') == true
        % Assumes that we do not need to vet out bad y-data for
        % quasi-static method.
        Table_Current = Table_Sheet(:,:);
    end
end