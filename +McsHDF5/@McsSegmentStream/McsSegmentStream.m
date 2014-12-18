classdef McsSegmentStream < McsHDF5.McsStream
% Holds the contents of a SegmentStream.
%
% Fields:
%   SegmentData     -   (1xn) cell array, each cell holding arrays of
%                       (events x samples) values, where 'samples' is the
%                       time range between Pre- and PostInterval of the
%                       cutout. The values are in units of 10 ^ Info.Exponent 
%                       [Info.Unit].
%
%   SegmentDataTimeStamps-(1xn) cell array, each cell holding a (events x 1)
%                       vector of time stamps for each event. The time
%                       stamps are given in microseconds.
%
%   Info            -   Structure containing information about the
%                       segments. Particularly interesting is the
%                       'SourceChannelIDs' field with a list of channel
%                       IDs. Information about these channels can be found
%                       in the 'SourceInfoChannel' field for their
%                       corresponding IDs. In addition, the 'PreInterval'
%                       and 'PostInterval' fields contain the time interval
%                       before and after the segment defining event in
%                       microseconds.
%
%   SourceInfoChannel-  Structure containing information about the source
%                       channels. It has the same format as the Info
%                       structure of AnalogStreams.
%
%   The other attributes provide information about the data types and the
%   data dimensions.
    
    properties (SetAccess = private)
        SegmentData = {};
        SegmentDataTimeStamps = {};
        SourceInfoChannel
        DataDimensions = {};
        DataUnit = {};
        DataType
        TimeStampDataType
    end
    
    methods
        function str = McsSegmentStream(filename, strStruct, varargin)
        % Constructs a McsSegmentStream object.
        %
        % function str = McsSegmentStream(filename, strStruct)
        % function str = McsSegmentStream(filename, strStruct, cfg)
        %
        % Reads the time stamps and the meta-information but does not read
        % the segment data. This is done the first time that the segment
        % data is accessed.
        %
        % Optional input:
        %   cfg     -   configuration structure, contains one or more of
        %               the following fields:
        %               'dataType': The type of the data, can be one of
        %               'double' (default), 'single' or 'raw'. For 'double'
        %               and 'single' the data is converted to meaningful
        %               units, while for 'raw' no conversion is done and
        %               the data is kept in ADC units. This uses less
        %               memory than the conversion to double, but you might
        %               have to convert the data prior to analysis, for
        %               example by using the getConvertedData function.
        %               'timeStampDataType': The type of the time stamps,
        %               can be either 'int64' (default) or 'double'. Using
        %               'double' is useful for older Matlab version without
        %               int64 arithmetic.
            if exist('h5info')
                mode = 'h5';
            else
                mode = 'hdf5';
            end
            
            str = str@McsHDF5.McsStream(filename,strStruct,'Segment');
            segments = str.Info.SegmentID;
            str.SegmentData = cell(1,length(segments));
            str.SegmentDataTimeStamps = cell(1,length(segments));
            if isempty(varargin) || ~isfield(varargin{1},'timeStampDataType') || strcmpi(varargin{1}.timeStampDataType,'int64')
                for segi = 1:length(segments)
                    try
                        if strcmp(mode,'h5')
                            str.SegmentDataTimeStamps{segi} = ...
                                h5read(filename,[strStruct.Name '/SegmentData_ts_' num2str(segments(segi))]);
                        else
                            str.SegmentDataTimeStamps{segi} = ...
                                hdf5read(filename,[strStruct.Name '/SegmentData_ts_' num2str(segments(segi))]);
                        end
                    end
                end
                str.TimeStampDataType = 'int64';
            else
                type = varargin{1}.timeStampDataType;
                if ~strcmp(type,'double')
                    error('Only int64 and double are supported for timeStampDataType!');
                end
                for segi = 1:length(segments)
                    try
                        if strcmp(mode,'h5')
                            str.SegmentDataTimeStamps{segi} = ...
                                cast(h5read(filename,[strStruct.Name '/SegmentData_ts_' num2str(segments(segi))]),type);
                        else
                            str.SegmentDataTimeStamps{segi} = ...
                                cast(hdf5read(filename,[strStruct.Name '/SegmentData_ts_' num2str(segments(segi))]),type);
                        end
                    end
                end
                str.TimeStampDataType = type;
            end

            if strcmp(mode,'h5')
                sourceInfo = h5read(filename, [strStruct.Name '/SourceInfoChannel']);
            else
                fid = H5F.open(filename,'H5F_ACC_RDONLY','H5P_DEFAULT');
                did = H5D.open(fid, [strStruct.Name '/SourceInfoChannel']);
                sourceInfo = H5D.read(did,'H5ML_DEFAULT','H5S_ALL','H5S_ALL','H5P_DEFAULT');
            end
            fn = fieldnames(sourceInfo);
            for fni = 1:length(fn)
                str.SourceInfoChannel.(fn{fni}) = sourceInfo.(fn{fni});
            end
            
            if isempty(varargin) || ~isfield(varargin{1},'dataType') || strcmpi(varargin{1}.dataType,'double')
                str.DataType = 'double';
            else
                type = varargin{1}.dataType;
                if ~strcmpi(type,'double') && ~strcmpi(type,'single') && ~strcmpi(type,'raw')
                    error('Only double, single and raw are allowed as data types!');
                end
                str.DataType = varargin{1}.dataType;
            end
        end
        
        function data = get.SegmentData(str)
        % Accessor function for the SegmentData field.
        %
        % function data = get.SegmentData(str)
        %
        % Reads the segment data from the file the first time that the
        % SegmentData field is accessed.
            if exist('h5info')
                mode = 'h5';
            else
                mode = 'hdf5';
            end
            
            if ~str.DataLoaded
                fprintf('Reading segment data...');
                emptySegments = false(1,length(str.Info.SegmentID));
                for segi = 1:length(str.Info.SegmentID)
                    try
                        if strcmp(mode,'h5')
                            str.SegmentData{segi} = ...
                                h5read(str.FileName,[str.StructName '/SegmentData_' num2str(str.Info.SegmentID(segi))]);  
                        else
                            str.SegmentData{segi} = ...
                                hdf5read(str.FileName,[str.StructName '/SegmentData_' num2str(str.Info.SegmentID(segi))]);  
                        end
                    catch
                        emptySegments(segi) = true;
                    end
                end 
                fprintf('done!\n');
                str.DataLoaded = true;
                for segi = 1:length(str.Info.SegmentID)
                    if emptySegments(segi)
                        str.DataUnit{segi} = [];
                        str.DataDimensions{segi} = [];
                        continue
                    end
                    if strcmp(str.DataType,'raw')
                        sourceChan = str2double(str.Info.SourceChannelIDs{segi});
                        if length(sourceChan) == 1
                            str.DataUnit{segi} = 'ADC';
                            str.DataDimensions{segi} = 'samples x segments';
                        else
                            str.DataUnit{segi} = repmat({'ADC'},length(sourceChan),1);
                            str.DataDimensions{segi} = 'samples x segments x multisegments';
                        end
                    else
                        convert_from_raw(str,segi);
                        sourceChan = str2double(str.Info.SourceChannelIDs{segi});
                        if length(sourceChan) == 1
                            chanidx = str.SourceInfoChannel.ChannelID == sourceChan;
                            [ignore,unit_prefix] = McsHDF5.ExponentToUnit(str.SourceInfoChannel.Exponent(chanidx),0);
                            str.DataUnit{segi} = [unit_prefix str.SourceInfoChannel.Unit{chanidx}];
                            str.DataDimensions{segi} = 'samples x segments';
                        else
                            chanidx = arrayfun(@(x)(find(str.SourceInfoChannel.ChannelID == x)),sourceChan);
                            str.DataUnit{segi} = [];
                            for ch = chanidx
                                [ignore,unit_prefix] = McsHDF5.ExponentToUnit(str.SourceInfoChannel.Exponent(ch),0);
                                str.DataUnit{segi} = [str.DataUnit{segi} {unit_prefix str.SourceInfoChannel.Unit{ch}}];
                            end
                            str.DataDimensions{segi} = 'samples x segments x multisegments';
                        end
                        
                    end
                end
            end
            data = str.SegmentData;
        end
        
        function s = disp(str)
            s = 'McsSegmentStream object\n\n';
            s = [s 'Properties:\n'];
            s = [s '\tStream Label:\t\t\t ' strtrim(str.Label) '\n'];
            s = [s '\tNumber of Segments:\t\t ' num2str(length(str.Info.SegmentID)) '\n'];
            s = [s '\tData Loaded:\t\t\t '];
            if str.DataLoaded
                s = [s 'true\n'];
            else
                s = [s 'false\n'];
            end
            s = [s '\n'];
            
            s = [s 'Available Fields:\n'];
            s = [s '\tSegmentData:\t\t\t [1x' num2str(length(str.Info.SegmentID))];
            if str.DataLoaded
                s = [s ' ' class(str.SegmentData) '}'];
            else
                s = [s ', not loaded}'];
            end
            s = [s '\n'];
            s = [s '\tSegmentDataTimeStamps:\t {' num2str(size(str.SegmentDataTimeStamps,1))...
                'x' num2str(size(str.SegmentDataTimeStamps,2)) ' cell}'];
            s = [s '\n'];
            s = [s '\tSourceInfoChannel:\t\t [1x1 struct]'];
            s = [s '\n'];
            s = [s '\tDataDimensions:\t\t\t {' num2str(size(str.DataDimensions,1)) 'x' num2str(size(str.DataDimensions,2)) ' cell}'];
            s = [s '\n'];
            s = [s '\tDataUnit:\t\t\t\t {' num2str(size(str.DataUnit,1)) 'x' num2str(size(str.DataUnit,2)) ' cell}'];
            s = [s '\n'];
            s = [s '\tDataType:\t\t\t\t ' str.DataType];
            s = [s '\n'];
            s = [s '\tTimeStampDataType:\t\t ' str.TimeStampDataType];
            s = [s '\n'];
            s = [s '\tStreamInfoVersion:\t\t ' num2str(str.StreamInfoVersion)];
            s = [s '\n'];
            s = [s '\tStreamGUID:\t\t\t\t ' str.StreamGUID];
            s = [s '\n'];
            s = [s '\tStreamType:\t\t\t\t ' str.StreamType];
            s = [s '\n'];
            s = [s '\tSourceStreamGUID:\t\t ' str.SourceStreamGUID];
            s = [s '\n'];
            s = [s '\tLabel:\t\t\t\t\t ' str.Label];
            s = [s '\n'];
            s = [s '\tDataSubType:\t\t\t ' str.DataSubType];
            s = [s '\n'];
            s = [s '\tInfo:\t\t\t\t\t [1x1 struct]'];
            s = [s '\n\n'];
            fprintf(s);
        end
        
        function data = getConvertedData(seg,idx,cfg)
            cfg = McsHDF5.checkParameter(cfg, 'dataType', 'double');
            
            if ~strcmp(seg.DataType,'raw')
                if ~strcmp(seg.DataType,cfg.dataType)
                    data = cast(seg.SegmentData{idx},cfg.dataType);
                else
                    data = seg.SegmentData{idx};
                end
            else
                sourceChan = str2double(seg.Info.SourceChannelIDs{idx});
                if length(sourceChan) == 1
                    chanidx = seg.SourceInfoChannel.ChannelID == sourceChan;
                    conv_factor = cast(seg.SourceInfoChannel.ConversionFactor(chanidx),cfg.dataType);
                    adzero = cast(seg.SourceInfoChannel.ADZero(chanidx),cfg.dataType);
                    data = cast(seg.SegmentData{idx},cfg.dataType);
                    data = bsxfun(@minus,data,adzero);
                    data = bsxfun(@times,data,conv_factor);
                else
                    chanidx = arrayfun(@(x)(find(seg.SourceInfoChannel.ChannelID == x)),sourceChan);
                    conv_factor = cast(seg.SourceInfoChannel.ConversionFactor(chanidx),cfg.dataType);
                    adzero = cast(seg.SourceInfoChannel.ADZero(chanidx),cfg.dataType);
                    data = cast(seg.SegmentData{idx},cfg.dataType);
                    data = bsxfun(@minus,data,adzero);
                    data = bsxfun(@times,data,conv_factor);
                end
            end
        end
    end
    
    methods (Access = private)
        function convert_from_raw(seg,idx)
        % Converts the raw segment data to useful units.
        %
        % function out = convert_from_raw(seg,idx)
        %
        % This is done already the first time that the data is loaded
            sourceChan = str2double(seg.Info.SourceChannelIDs{idx});
            if length(sourceChan) == 1
                chanidx = seg.SourceInfoChannel.ChannelID == sourceChan;
                conv_factor = cast(seg.SourceInfoChannel.ConversionFactor(chanidx),seg.DataType);
                adzero = cast(seg.SourceInfoChannel.ADZero(chanidx),seg.DataType);
                seg.SegmentData{idx} = cast(seg.SegmentData{idx},seg.DataType);
                seg.SegmentData{idx} = bsxfun(@minus,seg.SegmentData{idx},adzero);
                seg.SegmentData{idx} = bsxfun(@times,seg.SegmentData{idx},conv_factor);
            else
                chanidx = arrayfun(@(x)(find(seg.SourceInfoChannel.ChannelID == x)),sourceChan);
                conv_factor = cast(seg.SourceInfoChannel.ConversionFactor(chanidx),seg.DataType);
                adzero = cast(seg.SourceInfoChannel.ADZero(chanidx),seg.DataType);
                seg.SegmentData{idx} = cast(seg.SegmentData{idx},seg.DataType);
                seg.SegmentData{idx} = bsxfun(@minus,seg.SegmentData{idx},adzero);
                seg.SegmentData{idx} = bsxfun(@times,seg.SegmentData{idx},conv_factor);
            end
            
        end
    end
    
end