%% Nanoindentation Data Creater
% Written by Robert J Scales
%
% To run this code just by itself, run the "NanoMainCode Settings" in
% NanoMainCode and then run this code in its entirety.

function NanoDataCreater(debugON,PlotAesthetics,DefaultDlg,USS,ImageFormatType)
%Clear the command window
clc ; close all
fprintf('NanoDataCreater: Started!\n\n');


%% Pre-defined User Settings

dlg_title = 'Nanoindentation Data Creater';

% This is a list of all of the variables we have defined up here, used so
% that they won't be deleted when clearvars is used later.
InitialSettingsList = {'dlg_title','debugON','PlotAesthetics','DefaultDlg','USS','ImageFormatType'};

%% Initialisation

% Clears all of the unneeded variables
InitialSettingsList2 = {'ImportNewYS','SettingsDone','bins','FormatAnswer','StdDevWeightingMode','ErrorPlotMode'};
InitialSettingsList = horzcat(InitialSettingsList,InitialSettingsList2);
clearvars('-except',InitialSettingsList{:});

% The below clears all of the 'Do Not Show This Again' for
% preference diaglogue boxes.
%     uisetpref('clearall');

% This saves the initial directory, i.e. where the script is stored
% in.
LOC_init = cd;

% The below selects the files to be imported and names each of
% them. NEED TO UPDATE THE FUNCTION TO BE MORE INCLUSIVE OF OTHER
% METHODS.
% [fileNameList,NumberOfSamples,LOC_load] = YesModeInitialisation;

prompt = 'Type in the number of samples to load';
NumberOfSamples = str2double(inputdlg(prompt,dlg_title));

% This prepares a string array to be filled in with the full filenames
% and the name the user wished to label the data with.
fileNameList = strings(NumberOfSamples,2);

%% Settings

if NumberOfSamples>1
    MeanSamples = questdlg('Do you want to take the mean over all of the indents in all of the selected files?',dlg_title,'Yes','No',DefaultDlg.MeanSamples);
else
    MeanSamples = 'No';
end

% SettingsViaDialogueYN = questdlg('Choose how to apply settings?','Settings','Dialogue Boxes','Use Scipt Settings','Dialogue Boxes');
quest = {'Choose the settings choice mode:'};
% This next bit checks to see if 'SettingsDone' exists, if not then the
% code hasn't been run before and so not previous settings exist.
if logical(exist('SettingsDone','var'))
    pbnts = {'Dialogue Boxes','Use Scipt Settings','Use Previously Used Settings'};
else
    pbnts = {'Dialogue Boxes','Use Scipt Settings'};
end

[SettingsViaDialogueYN,~] = uigetpref('Settings','Dialogue',dlg_title,quest,pbnts);
switch SettingsViaDialogueYN
    case 'dialogue boxes'
        [bins,FormatAnswer,StdDevWeightingMode,ErrorPlotMode] = FormattingChoosing(DefaultDlg);
        % This creates 'SettingsDone' i.e. settings have been chosen.
        SettingsDone = true; % This is used!
    case 'use scipt settings'
        bins = USS.bins;
        FormatAnswer = USS.FormatAnswer;
        StdDevWeightingMode = USS.StdDevWeightingMode;
        ErrorPlotMode = USS.ErrorPlotMode;
        SettingsDone = true; % This is used!

    case 'Use Previously Used Settings'
        disp('Using previously used settings!');
end

if debugON
    fprintf('SettingsDone = %s\n',string(SettingsDone));
end


%% Main Data Processing Section

switch MeanSamples
    case 'No'
        disp('NOT meaning samples!');
        % The prepares arrays for the data to be filled in with.
        ValueData = zeros(bins,6,NumberOfSamples);
        ErrorData = zeros(bins,6,NumberOfSamples);
        BinPopulations = zeros(bins,NumberOfSamples);

        for i=1:NumberOfSamples
            filename = fileNameList(i,2);
            cd(LOC_init);
            IDName = fileNameList(i,1);
            % WANT TO CHANGE THE BELOW TO MAKE IT MORE INCLUSIVE OF OTHER
            % METHODS. Works on just one sample.
            FunctionOutPut = NanoImporter(filename,IDName,bins,StdDevWeightingMode,LOC_load,debugON);
            %
            ValueData(:,:,i) = FunctionOutPut.FinalArray;
            switch ErrorPlotMode
                case 'Standard error'
                    ErrorData(:,:,i) = FunctionOutPut.FinalErrors;
                case 'Standard deviation'
                    ErrorData(:,:,i) = FunctionOutPut.FinalStdDev;
                case ''
                    ErrorData(:,:,i) = FunctionOutPut.FinalErrors;
            end
            BinPopulations(:,i) = FunctionOutPut.BinsPop;
        end
    case 'Yes'
        disp('Meaning samples!');
        % The prepares arrays for the data to be filled in with.
        PreValueData = zeros(bins,5,1);
        IndentDepthLimits = nan(NumberOfSamples,1);

        for i=1:NumberOfSamples
            filename = fileNameList(i,2);
            cd(LOC_init);
            IDName = fileNameList(i,1);
            FunctionOutPut = NanoImporter(filename,IDName,bins,StdDevWeightingMode,LOC_load,debugON);
            IndentDepthLimits(i) = FunctionOutPut.DepthLimit;
            PreValueData = cat(3,PreValueData,FunctionOutPut.IndentsArray);
        end
        PreValueData(:,:,1) = [];
        NumOfIndents = size(PreValueData,3);
        
        if all(IndentDepthLimits(:) == IndentDepthLimits(1))
            w = wGenerator(StdDevWeightingMode);
            ValueData = horzcat(FunctionOutPut.BinMidpoints,mean(PreValueData,3,'omitnan'));
            % This calculates the standard error using the above weighting choice.
            ErrorData_StdDev = std(PreValueData,w,3,'omitnan');
            % This is the standard error.
            ErrorData_StdError = ErrorData_StdDev/realsqrt(NumOfIndents);
            if strcmp(ErrorPlotMode,'Standard error') == true
                ErrorData = horzcat(FunctionOutPut.BinMidpoints,ErrorData_StdError);
            elseif strcmp(ErrorPlotMode,'Standard deviation') == true
                ErrorData = horzcat(FunctionOutPut.BinMidpoints,ErrorData_StdDev);
            end
        else
            errordlg('Indent termination depths are not the same!')
            return
        end
end


%% Plotting
cd(LOC_init);

close all

if strcmp(MeanSamples,'No') == true
    SampleNameList = fileNameList(:,1);
else
    message = 'Type in the name of the meaned data (e.g. the material name):';
    SampleNameList = string(inputdlg(message,dlg_title,[1,50]));
end

DataIDName = 'PlaceHolder-DataIDName';
FileStuctures{1} = struct('ValueData',ValueData,'ErrorData',ErrorData,'SampleNameList',SampleNameList,'DataIDName',DataIDName);

% Below here it works in a similar way to NanoData Loader
L_fig = figure('Name','LFigure','windowstate','maximized');
t_fig = figure('Name','tFigure','windowstate','maximized');
HCS_fig = figure('Name','HCSFigure','windowstate','maximized');
E_fig = figure('Name','EFigure','windowstate','maximized');
H_fig = figure('Name','HFigure','windowstate','maximized');

DataTypeList = {'Load (mN)','Time (s)','Harmonic Contact Stiffness (N/m)','Hardness (GPa)','Youngs Modulus (GPa)'};
PlotDataTypes = ChooseDataToPlot(DataTypeList);

figHandles = findobj('Type', 'figure');

PlottingInfo.DataTypeList = DataTypeList;
PlottingInfo.PlotDataTypes = PlotDataTypes;
PlottingInfo.X_Axis_Label = 'Indent Depth (nm)';
PlottingInfo.legendLocation = 'southeast';

cd(LOC_init);
NanoPlotter(FileStuctures,PlotAesthetics,FormatAnswer,figHandles,PlottingInfo);


%% Saving Results

LoadingMode = false;
cd(LOC_init);
[DataIDName,SaveTime,SavingData,LOC_save] = NanoDataSave(ImageFormatType,LoadingMode,LOC_init,dlg_title,fileNameList);    

dataToSave = FileStuctures{1};
dataToSave.DataIDName = DataIDName;
% dataToSave = struct('ValueData',ValueData,'ErrorData',ErrorData,'SampleNameList',SampleNameList,'DataIDName',DataIDName);

disp('Saving the processed nanoindentation data');
DataSaveName = sprintf('%s_%s_Data.mat',DataIDName,SaveTime);
cd(LOC_save);
switch SavingData
    case 'auto'
        save(DataSaveName,'dataToSave','-mat');
        fprintf('Auto-saved "%s" as "%s"\n',DataIDName,DataSaveName);
    case 'semi-auto'
        uisave('dataToSave',DataSaveName);
        fprintf('Semi-auto-saved "%s" as "%s"\n',DataIDName,DataSaveName);
    case 'manual'
        disp('You have to manually save the data');
    otherwise
        errordlg('Variable "SavingData" was not suitable!')
        fprintf('SavingData = "%s"\n\n',SavingData);
        cd(LOC_init);
        return
end

cd(LOC_init);
fprintf('NanoDataCreater: Complete!\n\n');
end
%%










    
%% Functions

function [fileNameList,NumberOfSamples,LOC_load] = YesModeInitialisation
    % Change current directory to the directory to load the data from.
    
    % This allows to get the file name and location information for
    % multiple files, starting from the load location.
    [file,path] = uigetfile({'*.xlsx;*.xls'},'Select nanoindentation Excel files to import:','MultiSelect','on');
    
    if isa(file,'double') == true
        errordlg('No files selected! Code will terminate!')
        return
    end
    
    LOC_load = path;
    
    % If one file is chosen its file type will be char and not cell, hence
    % this makes it into a 1x1 cell if true.
    if isa(file,'char') == true
        file = cellstr(file);
    end
    
    % This calculates the number of samples the user has chosen based on
    % the number of files chosen.
    NumberOfSamples = length(file);

    % This prepares a string array to be filled in with the full filenames
    % and the name the user wished to label the data with.
    fileNameList = strings(NumberOfSamples,2);

    % This fills in fileNameList
    for i =1:NumberOfSamples
        HeadingName = sprintf('Enter name for nanoindentation data titled "%s":',file{i});
        CurrName = inputdlg({HeadingName},'Type sample name here:',[1,100]);
        if ~isempty(CurrName)
            filename = fullfile(path,file{i});
            fileNameList(i,1) = string(CurrName);
            fileNameList(i,2) = filename;
        else
            errordlg('No name entered! Code will terminate!')
            return
        end
    end
end

function [bins,FormatAnswer,StdDevWeightingMode,ErrorPlotMode] = FormattingChoosing(DefaultDlg)
    dlg_title = 'Nanoindentation Data Creater';
    % This is the number of bins which it will group the data along the
    % x-axis with.
    bins = str2double(inputdlg({'How many bins do you want to use'},dlg_title,[1,50]));

    % This is how the data will be shown on the graph.
%     quest = {'Choose how to plot the data:'};
%     pbnts = {'Line + Error Region','Line + Error Bars','Line'};
%     [FormatAnswer,~] = uigetpref('Settings','PlotFormat',dlg_title,quest,pbnts,'DefaultButton','Line + Error Region');
    FormatAnswer = questdlg('How do you want to present the data?',dlg_title,'Line + Error Region','Line + Error Bars','Line',DefaultDlg.FormatAnswer);

    switch FormatAnswer
        case 'Line'
            disp('No error bars will be shown on the graph');
            StdDevWeightingMode = 'N-1';
        case ''
            errordlg('Exit button was pressed! Code will terminate!')
            return
        otherwise
            % This is the weighting mode to do for the standard deviation
            % and standard error, see Matlab documentation on std.
%             quest = {'Choose the error to show on the graph:'};
%             pbnts = {'Standard deviation','Standard error'};
%             [ErrorPlotMode,~] = uigetpref('Settings','Error',dlg_title,quest,pbnts,'DefaultButton','Standard deviation');
            ErrorPlotMode = questdlg('Choose to show standard error or standard deviation:',dlg_title,'Standard error','Standard deviation',DefaultDlg.ErrorPlotMode);
            
            % This chooses whether the standard deviation or standard error
            % will be plotted as the y-uncertainties in the graphs.
%             quest = {'Choose the standard deviation weighting to use:'};
%             pbnts = {'N-1','N','Using bin errors'};
%             [StdDevWeightingMode,~] = uigetpref('Settings','Weighting',dlg_title,quest,pbnts,'DefaultButton','N-1');
            StdDevWeightingMode = questdlg('Choose the standard deviation weighting to use:',dlg_title,'N-1','N','Using bin errors',DefaultDlg.StdDevWeightingMode);
            
            if strcmp(ErrorPlotMode,'') == true
                warndlg('No error choice was made, hence default will be shown!');
            end
            if strcmp(StdDevWeightingMode,'') == true
                warndlg('No weighting choice was made, hence default will be chosen!');
            end
    end
end




function w = wGenerator(StdDevWeightingMode)

    switch StdDevWeightingMode
        case 'N-1'
            w = 0;
        case 'N'
            w = 1;
        case 'Using bin errors'
            w = 0; % Need to update this!!
        case ''
            w = 0;
    end
    
end

function PlotDataTypes = ChooseDataToPlot(DataTypeList)
    PromptString = {'Select what data to plot against depth:','Multiple can be selected at once.'};
    [PlotDataTypes,~] = listdlg('PromptString',PromptString,'SelectionMode','multiple','ListString',DataTypeList);
end



