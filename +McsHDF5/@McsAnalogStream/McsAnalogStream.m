classdef McsAnalogStream < McsHDF5.McsStream
% Holds the contents of an AnalogStream. 
%
% Fields:
%   ChannelData         -   (samples x channels) array of the sampled data.
%                           Samples are given in units of 10 ^ Info.Exponent 
%                           [Info.Unit]
%
%   ChannelDataTimeStamps - (samples x 1) vector of time stamps given in
%                           microseconds.
%
% The other fields and the Info field provide general information about the
% analog stream.

    properties (SetAccess = private)
        ChannelData = [];
        ChannelDataTimeStamps = int64([]);
        DataDimensions = 'channels x samples';
        DataUnit = {};
        DataType
        TimeStampDataType
    end
    
    methods
        
        function str = McsAnalogStream(filename, strStruct, varargin)
        % Constructs a McsAnalogStream object
        %
        % function str = McsAnalogStream(filename, strStruct)    
        % function str = McsAnalogStream(filename, strStruct, cfg)
        %
        % Reads the meta-information and the time stamps, not the analog
        % data. Reading the analog data is done the first time that
        % ChannelData is accessed.
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
        
            str = str@McsHDF5.McsStream(filename,strStruct,'Channel');
            
            timestamps = h5read(filename, [strStruct.Name '/ChannelDataTimeStamps']);
            if size(timestamps,1) ~= 3
                timestamps = timestamps';
            end
            
            if isempty(varargin) || ~isfield(varargin{1},'timeStampDataType') || strcmpi(varargin{1}.timeStampDataType,'int64')
                timestamps = bsxfun(@plus,timestamps,int64([0 1 1])');
                for tsi = 1:size(timestamps,2)
                    str.ChannelDataTimeStamps(timestamps(2,tsi):timestamps(3,tsi)) = ...
                        (int64(0:numel(timestamps(2,tsi):timestamps(3,tsi))-1) .* ...
                        str.Info.Tick(1)) + timestamps(1,tsi);
                end
                str.TimeStampDataType = 'int64';
            else
                type = varargin{1}.timeStampDataType;
                if ~strcmp(type,'double')
                    error('Only int64 and double are supported for timeStampDataType!');
                end
                str.ChannelDataTimeStamps = cast([],type);
                timestamps = bsxfun(@plus,double(timestamps),[0 1 1]');
                for tsi = 1:size(timestamps,2)
                    str.ChannelDataTimeStamps(timestamps(2,tsi):timestamps(3,tsi)) = ...
                        ((0:numel(timestamps(2,tsi):timestamps(3,tsi))-1) .* ...
                        cast(str.Info.Tick(1),type)) + timestamps(1,tsi);
                end
                str.TimeStampDataType = type;
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
        
        function data = get.ChannelData(str)
        % Accessor function for the ChannelData field.
        %
        % function data = get.ChannelData(str)
        %
        % Will read the channel data from file the first time this field is
        % accessed.
        
            if ~str.DataLoaded
                fprintf('Reading analog data...\n')
                str.ChannelData = h5read(str.FileName, [str.StructName '/ChannelData'])';
                str.DataLoaded = true;
                if ~strcmp(str.DataType,'raw')
                    for ch = 1:length(str.Info.Unit)
                        [~,unit_prefix] = McsHDF5.ExponentToUnit(str.Info.Exponent(ch),0);
                        str.DataUnit{ch} = [unit_prefix str.Info.Unit{ch}];
                    end
                    convert_from_raw(str);    
                else
                    for ch = 1:length(str.Info.Unit)
                        str.DataUnit{ch} = 'ADC';
                    end
                end
            end
            data = str.ChannelData;
        end
        
        function data = getConvertedData(str,cfg)
        % Returns the converted data
        %
        % function data = getConvertedData(str,cfg)
        %
        % If the DataType is 'raw', this will convert the data to
        % meaningful units and return it, but not change the internal
        % ChannelData field. If the DataType is 'single' or 'double' this
        % will either return the ChannelData field (if cfg.dataType equals
        % the DataType) or cast the ChannelData entry to the requested data
        % type in cfg.dataType.
        %
        % Input:
        %   cfg     -   A configuration structure. Can contain the field
        %               'dataType' which describes the requested data type.
        %               The default is 'double'. cfg.dataType has to be one
        %               of the built-in types.
        %
        % Output:
        %   data    -   The ChannelData converted to cfg.dataType. If the
        %               original DataType is 'raw', this includes the
        %               conversion from ADC units to units of 10 ^
        %               Info.Exponent [Info.Unit]
            
            if isempty(cfg)
                cfg.dataType = 'double';
            end
            
            if ~isfield(cfg,'dataType')
                cfg.dataType = 'double';
            end
            
            if ~strcmp(str.DataType,'raw')
                if ~strcmp(str.DataType,cfg.dataType)
                    data = cast(str.ChannelData,cfg.dataType);
                else
                    data = str.ChannelData;
                end
            else
                conv_factor = cast(str.Info.ConversionFactor,cfg.dataType);
                adzero = cast(str.Info.ADZero,cfg.dataType);
                data = cast(str.ChannelData,cfg.dataType);
                data = bsxfun(@minus,data,adzero);
                data = bsxfun(@times,data,conv_factor);
            end
        end
        
    end
    
    methods (Access = private)
        function convert_from_raw(str)
            % Converts the raw channel data to useful units.
            %
            % function out = convert_from_raw(str)
            %
            % This is performed directly after the data is loaded from the
            % hdf5 file.
            conv_factor = cast(str.Info.ConversionFactor,str.DataType);
            adzero = cast(str.Info.ADZero,str.DataType);
            str.ChannelData = cast(str.ChannelData,str.DataType);
            str.ChannelData = bsxfun(@minus,str.ChannelData,adzero);
            str.ChannelData = bsxfun(@times,str.ChannelData,conv_factor);
            
        end
        
    end
    
end