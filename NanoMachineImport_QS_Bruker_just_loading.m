%% NanoMachineImport_QS_Bruker
% By Robert J Scales
%
% Currently this code only takes bins up to the maximum indent depth (i.e.
% the loading up path, and not the unloading stage; as this give me a
% headache trying to sort it out for both directions).
%
% Attempting to make it do loading and unloading

function [OutPut,IDName,filename] = NanoMachineImport_QS_Bruker(bins,StdDevWeightingMode,debugON)
%% Testing Initialisation

testON = false;

if testON == true
    bins = 100;
    debugON = true;
    StdDevWeightingMode = 'N-1';
end
%% Setup
    title = 'NanoMachineImport_QS_Bruker';
    
    % This allows to get the file name and location information for
    % multiple files, starting from the load location.
    msg = 'Select the ".txt" files for each of the indents to be imported';
    PopUp = helpdlg(msg,title);
    waitfor(PopUp);
    [file,path] = uigetfile({'*.txt'},'Select nanoindentation txt files for all the indents to import:','MultiSelect','on');
    
    if isa(file,'double') == true
        errordlg('No files selected! Code will terminate!')
        return
    end
    
    [w,ProgressBar,waitTime,IDName] = NanoMachineImport_first_stage(title,StdDevWeightingMode,file{1});
    
    LOC_load = path;
    
    % If one file is chosen its file type will be char and not cell, hence
    % this makes it into a 1x1 cell if true.
    if isa(file,'char') == true
        file = cellstr(file);
    end
    
    % This calculates the number of samples the user has chosen based on
    % the number of files chosen.
    NumOfIndents = length(file);
    
    MaxIndentDepth = nan;
    
    MasterTable = cell(NumOfIndents,1);
    
    % This fills in fileNameList
    for i =1:NumOfIndents
        fprintf('Current file loaded = %s\n',file{i});
        IndentFilename = fullfile(path,file{i});
        opts = detectImportOptions(IndentFilename,'VariableNamesLine',6,'Encoding','windows-1252','ExpectedNumVariables',5,'PreserveVariableNames',true);
%         currTable = readtable(filename,opts);
        currMatrix = readmatrix(IndentFilename,opts);
        NumOfRows = size(currMatrix,1);
        Depth = currMatrix(:,1); % Depth in nm which is good.
        Load = currMatrix(:,2)/1000; % Load is converted from uN to mN!
        Time = currMatrix(:,3); % Time in s which is good.
        HCS = nan(NumOfRows,1); % Fake HCS column.
        H = nan(NumOfRows,1); % Fake hardness column.
        E = nan(NumOfRows,1); % Fake Youngs modulus column.
        currMaxIndentDepth = max(Depth);
        fprintf('\tMax depth in file loaded = %gnm\n',currMaxIndentDepth);
        MaxIndentDepth = max([currMaxIndentDepth,MaxIndentDepth]);
        OutputTable = MakeTableForIndent(Depth,Load,Time,HCS,H,E);
        MasterTable{i} = OutputTable;
        clear currMaxIndentDepth
    end
    
%% Binning Set-up
% Deatils whic differ from NanoMachineImport_CSM_Aglient shall only be
% mentioned.
    
    DepthLimit = MaxIndentDepth; % in nm
    bin_boundaries = transpose(linspace(0,DepthLimit,bins+1));

    % This section generates the names of the bin boundaries, which will
    % pop up during debug if it can't compute a bin. The midpoints of the
    % bins which are used as the x-axis points are also calculated.
    bin_boundaries_text = strings(bins,1);
    bin_midpoints = zeros(bins,1);
    for BinNum=1:bins
        bin_boundaries_text(BinNum,1) = sprintf("%d:%d",bin_boundaries(BinNum),bin_boundaries(BinNum+1));
        bin_midpoints(BinNum,1) = mean([bin_boundaries(BinNum),bin_boundaries(BinNum+1)]);
    end
    PenultimateArray = zeros(bins,5,NumOfIndents);
    PenultimateErrors = zeros(bins,5,NumOfIndents);
    
%% Binning Main Body
    indProTime = nan(NumOfIndents,1);
    
    % This for loop cycles for each indent
    for currIndNum = 1:NumOfIndents
        tic
        % This updates the progress bar with required details.
        [indAvgTime,RemainingTime] = NanoMachineImport_avg_time_per_indent(ProgressBar,indProTime,currIndNum,NumOfIndents,IDName);
        
        if debugON == true
            fprintf("Current indent number = %d\n",currIndNum);
            fprintf('Cuurent Avg. time per indent is %.3g secs\n\n',indAvgTime(end))
        end
        
        % This selects only the data with reasonable magnitudes.
        Table_Current = table2array(MasterTable{currIndNum});
        Table_Current = Table_Current(Table_Current(:,1)>0,:);
        [~,RowOfMaxDepth] = max(Table_Current(:,1));
        Table_Current = Table_Current(1:RowOfMaxDepth,:);
        
        % This obtains arrays which are binned for both the value and
        % standard dev., along with producing an array of the bin counts.
        [PenultimateArray,PenultimateErrors,N] = NanoMachineImport_bin_func(w,Table_Current,bins,bin_boundaries,PenultimateArray,PenultimateErrors,ProgressBar,IDName,currIndNum,NumOfIndents,RemainingTime);
        
        indProTime(currIndNum,1) = toc;
    end
    
    
%% Final Compiling

    % This gets the penultimate array data and the other essential
    % information to produce an output structure containing all of the
    % information from the indent text files imported.
    OutPut = NanoMachineImport_final_stage(PenultimateArray,w,NumOfIndents,bin_midpoints,bin_boundaries,DepthLimit,N,debugON,waitTime);
    close(ProgressBar);
    
    % Sets filename to the last indent loaded. Just to identify what was
    % generally loaded to produce this data. The IDName should be a better
    % identifier though in purpose.
    filename = IndentFilename;
    
    fprintf('%s: Complete!\n',title);
end

%% Functions

function OutputTable = MakeTableForIndent(Depth,Load,Time,HCS,H,E)
    VariableNames = {'Depth (nm)','Load (mN)','Time (s)','Harmonic Contact Stiffness (N/m)','Hardness (GPa)','Youngs Modulus (GPa)'};
    OutputTable = table(Depth,Load,Time,HCS,H,E,'VariableNames',VariableNames);
end