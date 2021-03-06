%% NanoImport_QS_Bruker_bin_func
%
% This bin function is designed around the quasi-static method for Bruker
% nanoindentors.

function [OutPut2DArray,OutPut2DErrors,N] = NanoImport_QS_Bruker_bin_func(w,Table_Current,bins,bin_boundaries,TemplateArray,TemplateErrors,ProgressBar,IDName,currIndNum,NumOfIndents,RemainingTime)
%%

    % If the input indent depth but and the bin boundaries are not vectors
    % then this error dlg is produced.
    if ~isvector(Table_Current(:,1)) || ~isvector(bin_boundaries)
        errordlg('Table_Current and/or bin_boundaries is not a matrix!');
        disp(Table_Current(:,1));
        disp(bin_boundaries);
        return
    end

    % This bins the indent head displacement and counts how many in
    % each bin along with what bin each row belongs to.
    [N,~,binIndex] = histcounts(Table_Current(:,1),bin_boundaries);
    
%     disp('N =');
%     disp(N);

    OutPut2DArray = TemplateArray;
    OutPut2DErrors = TemplateErrors;

    % This will cycle through each of the bins
    for BinNum=1:bins
        % This finds the displacment data which are within the bin
        % range, and then selects the appropriate data.
        DataInBin = Table_Current(( binIndex == BinNum ),2:end);
        
        % The data is then mean averaged along each column (1) i.e.
        % along each type of measurement.
        Bin_Data = mean(DataInBin,1,'omitnan');
        Bin_StdDev = std(DataInBin,w,1,'omitnan');
        Bin_Error = Bin_StdDev/realsqrt(N(BinNum));
        
%         fprintf('Bin_Data = %g',Bin_Data);

        % This adds the data into the 3D array.
        OutPut2DArray(BinNum,:) = Bin_Data;
        OutPut2DErrors(BinNum,:) = Bin_Error;
        message = sprintf('%s - Indent %d/%d - Bin %d/%d\nTime Left ~ %.3g secs',IDName,currIndNum,NumOfIndents,BinNum,bins,RemainingTime);
        waitbar((currIndNum-1)/NumOfIndents,ProgressBar,message);
    end
end