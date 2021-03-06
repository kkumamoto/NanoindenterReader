%% NanoImport_Agilent_General
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
    w = 0; % 'N-1' weighting for stdev
    ErrorPlotMode = 'Standard deviation';
    mode = 'qs'; % Testing mode is defined in here
    clearvars('-except','dlg_title','debugON','bins','w','ErrorPlotMode','mode');
end

cd_init = cd; % Initial directory
waitTime = 2; % The time spent on each figure.

% Configs the code based on whether the data to import is CSM or QS
switch mode
    case 'csm'
        NoYCols = 6-1; % The total number of columns - the XData column.
        XDataCol = 1; % The location of the XData in the spreadsheet.
        % This is the order in which the final data will be presented in
        % column wise!
        varNames = {'Depth (nm)','Load (mN)','Time (s)','HCS (N/m)','Hardness (GPa)','Modulus (GPa)'};
    case 'qs'
        NoYCols = 7-1;
        XDataCol = 2;
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
if isnan(NoOfSamples) == true
    return
end

% The below has an initial look through all of the indent depth values
% reached for each indent in each sample, finds the maximum and generates
% the appropriate values dependent on that. It also allows the user to
% change these values!
[DepthLimit,bin_boundaries,binWidth,bin_boundaries_text,bin_midpoints,bins,InvalidChoiceTF] = changeBinBoundaries(debugON,NoOfSamples,fileNameList,bins,mode,XDataCol);
changeBBsStruct = struct('InvalidChoiceTF',InvalidChoiceTF,'DepthLimit',DepthLimit,'bin_boundaries',bin_boundaries,'binWidth',binWidth,'bin_boundaries_text',bin_boundaries_text,'bin_midpoints',bin_midpoints,'bins',bins);
if InvalidChoiceTF == true
    DLG = errordlg('You exited the changing bin boundaries option!',dlg_title);
    waitfor(DLG);
    return
end
if debugON == true
    fprintf('DepthLimit = %d \t binWidth = %d \t Num of bins = %d \t \n',DepthLimit,binWidth,bins);
    disp('bin_boundaries_text...'); disp(bin_boundaries_text);
end

% The prepares arrays for the data to be filled in with.
PreValueData = zeros(bins,NoYCols,1);

%% Main Data Gathering

% Goes through each sample and runs NanoImport_Agilent_LoadData on each.
% PreValueData is then concatenated in the 3rd dimension by the indents
% from each sample.
for i=1:NoOfSamples
    fprintf("Currently on sample number %d/%d\n",i,NoOfSamples);
    filename = fileNameList(i,2);
    [FunctionOutPut,SpreadSheetName] = NanoImport_Agilent_LoadData(debugON,file{i},filename,changeBBsStruct,w,XDataCol,NoYCols,mode,varNames,waitTime);
    PreValueData = cat(3,PreValueData,FunctionOutPut.IndentsArray); % 3rd dimension concatenation of the data from the binned indents
    fileNameList(i,1) = SpreadSheetName;
end

% Removes the first layer of zeros, which is created when we
% preallocate PreValueData.
PreValueData(:,:,1) = [];

% This means the data to produce the values and their associated errors
[ValueData,ErrorData] = NanoImport_Agilent_Sample_Meaner(PreValueData,FunctionOutPut,w,ErrorPlotMode);

if NoOfSamples > 1
    % This plots the results of the meaned data, doesn't show if only one
    % file was loaded as that would be redundant.
    DLG = helpdlg('Now plotting the meaned data');
    waitfor(DLG);
    % The below plots the data as temporary figures.
    QuickPlotData(ValueData(:,1),ValueData(:,2:end),varNames,waitTime)
end

%% Final Stage

method_name = string(sprintf('Agilent-%s',upper(mode)));
% This saves the data as a structure called dataToSave.
[~] = NanoImport_Saving(debugON,ValueData,ErrorData,w,ErrorPlotMode,varNames,XDataCol,method_name,cd_init,path);

fprintf('%s: Completed!\n\n',dlg_title);
end

%% InBuilt Functions


