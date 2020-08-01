%% Nanoindentation Data Loader
% Written by Robert J Scales

function NanoDataLoader(debugON,PlotAesthetics,DefaultDlg,ImageFormatType)
%Clear the command window
clc ; close all
fprintf('NanoDataLoader: Started!\n\n');


%% Pre-defined User Settings

dlg_title = 'Nanoindentation Data Loader';

% This is a list of all of the variables we have defined up here, used so
% that they won't be deleted when clearvars is used later.
InitialSettingsList = {'dlg_title','debugON','PlotAesthetics','DefaultDlg','USS','ImageFormatType'};

%% Initialisation

% This question dialogue box changes the course whether to select new files
% or to keep the ones previously selected if the code has been ran before.
LoadNewYS = questdlg('Do you need to load new data?','Nanoindentation Data Loader','Yes','No','Yes');
switch LoadNewYS
    case 'Yes'
        InitialSettingsList2 = {'LoadNewYS','SettingsDone','FormatAnswer'};
        InitialSettingsList = horzcat(InitialSettingsList,InitialSettingsList2);
        clearvars('-except',InitialSettingsList{:});
        
        uisetpref('clearall');
        
        LOC_init = cd;
        
        [FileStuctures,fileNameList,LOC_load] = YesModeLoading(debugON);
    case 'No'
        disp('Using the same data as before!')
    case ''
        errordlg('Exit button was pressed! Code will terminate!')
        return
end

%% Settings

[FormatAnswer] = FormattingChoosing(dlg_title,DefaultDlg);

%% Plotting
cd(LOC_init);

close all


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


%% Meaning the data across a depth range


cd(LOC_init);
ToMeanOrNotToMean = questdlg('Find a mean value within a range?',dlg_title,'Yes','No','No');
switch ToMeanOrNotToMean
    case 'Yes'
        NanoMeaner(FileStuctures,figHandles,DataTypeList,PlotDataTypes,LOC_init);
    otherwise
        disp('You have decided not to find the mean value within a range...');
end

%% Saving Results

LoadingMode = true;
cd(LOC_init);
[~,~,~,~] = NanoDataSave(ImageFormatType,LoadingMode,LOC_init,dlg_title,fileNameList);


fprintf('NanoDataLoader: Complete!\n\n');

end











    
%% Functions
function [FileStuctures,fileNameList,LOC_load] = YesModeLoading(debugON)
    % Change current directory to the directory to load the data from.
    
    % This allows to get the file name and location information for
    % multiple files, starting from the load location.
    
    [file,path] = uigetfile('*.mat','Select nanoindentation "mat" files made by "NanoDataCreater" to plot (must all be in one folder):','MultiSelect','on');

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
    NumberOfFiles = length(file);

    if debugON == true
        fprintf('Loading files from "%s"...\n',LOC_load);
        fprintf('Number of files detected = %d\n',NumberOfFiles);
    end
    
    % This prepares a string array to be filled in with the full filenames
    % and the name the user wished to label the data with.
    fileNameList = strings(NumberOfFiles,2);
    FileStuctures = cell(NumberOfFiles,1);
    
    % This fills in fileNameList
    for i =1:NumberOfFiles
        filename = fullfile(path,file{i});
        fileNameList(i,1) = file{i};
        fileNameList(i,2) = filename;
        %FileStuctures(i) = load(filename,'-mat');
        FileStucturesProto = load(filename,'-mat');
        FileStuctures{i} = FileStucturesProto.dataToSave;
        clear('FileStucturesProto','i','filename');
        if debugON == true
            fprintf('Loaded file named "%s"\n',file{i});
        end
    end
end


function [FormatAnswer] = FormattingChoosing(dlg_title,DefaultDlg)
    % This is how the data will be shown on the graph.
    FormatAnswer = questdlg('How do you want to present the data?',dlg_title,'Line + Error Region','Line + Error Bars','Line',DefaultDlg.FormatAnswer);

    switch FormatAnswer
        case 'Line'
            disp('No error bars will be shown on the graph');
        case ''
            errordlg('Exit button was pressed! Code will terminate!')
            return
    end
end

function PlotDataTypes = ChooseDataToPlot(DataTypeList)
    PromptString = {'Select what data to plot against depth:','Multiple can be selected at once.'};
    [PlotDataTypes,~] = listdlg('PromptString',PromptString,'SelectionMode','multiple','ListString',DataTypeList);
end





