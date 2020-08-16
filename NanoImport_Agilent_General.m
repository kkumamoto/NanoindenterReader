%% NanoImport_Agilent_QS
% By Robert J Scales
% Because the Agilent data is exported as Excel spreadsheets which have
% multiple indent data stored in them. Then in order to mean across
% multiple arrays of indents made you have to load the data from multiple
% files. Bruker has the data from each indent as a singular file. Hence,
% this process is not needed.

function NanoImport_Agilent_General(debugON,bins,w,ErrorPlotMode,mode)
%% Starting Up
dlg_title = 'NanoImport_Agilent_General';
fprintf('%s: Started!\n\n',dlg_title);

testTF = false;

if testTF == true
    clc;
    WARN = warndlg('Currently in testing mode for NanoImport_Agilent_General!!');
    waitfor(WARN);
    debugON = true;
    bins = 100;
    w = 0;
    ErrorPlotMode = 'Standard deviation';
    mode = 'qs';
    clearvars('-except','dlg_title','debugON','bins','w','ErrorPlotMode','mode');
end

cd_init = cd; % Initial directory
waitTime = 3; % The time spent on each figure.

% The below data will be dependent on whether the data to import is CSM or
% QS... THIS IS IN QS MODE
switch mode
    case 'csm'
        NoColsOfData = 6;
        NoYCols = NoColsOfData-1;
        XDataCol = 1;
%         MaxDepthCol = 3;
        % This is the order in which the final data will be presented in
        % column wise!
        varNames = {'Depth (nm)','Load (mN)','Time (s)','HCS (N/m)','Hardness (GPa)','Modulus (GPa)'};
    case 'qs'
        NoColsOfData = 7;
        NoYCols = NoColsOfData-1;
        XDataCol = 2;
%         MaxDepthCol = 8;
        varNames = {'Depth (nm)','Time (s)','Load (uN)','X Pos (um)','Y Pos (um)','Raw Displacement (nm)','Raw Load (mN)'};
    otherwise
        DLG = errordlg('Unknown case for "mode" chosen for "%s"\n Value will be printed below...\n',dlg_title);
        waitfor(DLG);
        return
end


% This gets the file data for the sample.
[file,path] = uigetfile({'*.xlsx;*.xls'},'Select nanoindentation Excel file to import:','MultiSelect','on');

% Below uses the file and path data above and produces it into the correct
% format, along with producing other useful data.
[NoOfSamples,fileNameList,file] = getFileCompiler(debugON,path,file);

% The below has an initial look through all of the indent depth values
% reached for each indent in each sample, finds the maximum and generates
% the appropriate values dependent on that. It also allows the user to
% change these values!
[DepthLimit,bin_boundaries,binWidth,bin_boundaries_text,bin_midpoints,bins,OverwriteTF] = changeBinBoundaries(debugON,NoOfSamples,fileNameList,bins,mode,XDataCol);
changeBBsStruct = struct('OverwriteTF',OverwriteTF,'DepthLimit',DepthLimit,'bin_boundaries',bin_boundaries,'binWidth',binWidth,'bin_boundaries_text',bin_boundaries_text,'bin_midpoints',bin_midpoints,'bins',bins);
if debugON == true
    fprintf('DepthLimit = %d \t binWidth = %d \t Num of bins = %d \t \n',DepthLimit,binWidth,bins);
    disp('bin_boundaries_text...'); disp(bin_boundaries_text);
end

% The prepares arrays for the data to be filled in with.
PreValueData = zeros(bins,NoYCols,1);
IndentDepthLimits = nan(NoOfSamples,1);

%% Main Data Gathering

% Goes through each sample and runs NanoMachineImport on each and finds
% their indent depth limits to make sure it will bin the same for all
% of the samples. PreValueData is then concatenated in the 3rd
% dimension by the indents from each sample.
for i=1:NoOfSamples
    fprintf("Currently on sample number %d/%d\n",i,NoOfSamples);
    filename = fileNameList(i,2);
    [FunctionOutPut,SpreadSheetName] = NanoImport_Agilent_LoadData(debugON,file{i},filename,changeBBsStruct,w,XDataCol,NoYCols,mode,varNames,waitTime);
    IndentDepthLimits(i) = FunctionOutPut.DepthLimit;
    PreValueData = cat(3,PreValueData,FunctionOutPut.IndentsArray);
    fileNameList(i,1) = SpreadSheetName;
end

% Removes the first layer of zeros, which is created when we
% preallocate PreValueData.
PreValueData(:,:,1) = [];

% This means the data to produce the values and their associated errors
[ValueData,ErrorData] = NanoImport_Agilent_Sample_Meaner(PreValueData,IndentDepthLimits,FunctionOutPut,w,ErrorPlotMode);

if NoOfSamples > 1
    % This plots the results of the meaned data, doesn't show if only one
    % file was loaded as that would be redundant.
    DLG = helpdlg('Now plotting the meaned data');
    waitfor(DLG);
    % The below plots the data as temporary figures.
    QuickPlotData(ValueData(:,1),ValueData(:,2:end),varNames,waitTime)
end

%% Final Stage

% This saves the data as a structure called dataToSave.

[~] = NanoImport_Saving(debugON,ValueData,ErrorData,w,ErrorPlotMode,varNames,XDataCol,cd_init,path);

fprintf('%s: Completed!\n\n',dlg_title);
end

%% Nested Functions


