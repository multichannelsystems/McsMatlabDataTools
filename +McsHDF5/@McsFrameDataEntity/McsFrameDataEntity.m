classdef McsFrameDataEntity < handle
% Holds the contents of a single FrameDataEntity
%
% Important fields:
%   FrameData       -   (channels_x x channels_y x samples) array of data
%                       values.
%
%   FrameDataTimeStamps - (1 x samples) vector of time stamps in
%                       microseconds.
%
%   ConversionFactors   - (channels_x x channels_y) matrix of conversion 
%                         factors. If the FrameData has DataType 'raw',
%                         multiplying these to FrameData after subtracting
%                         Info.ADZero will convert the raw data to units of
%                         10 ^ Info.Exponent [Info.Unit]. Note: this is
%                         unnecessary if the FrameData has DataType
%                         'single' or 'double' as it has been converted
%                         already in this case.
%
%   The Info field provides general information about the frame stream,
%   while the other fields describe data types, units and dimensions.

    properties (SetAccess = private)
        FrameData = []; % (channels_x x channels_y x samples) Data array
        FrameDataTimeStamps = int64([]); % (1 x samples) Vector of time stamps in microseconds
        Info % (struct) Information about the frame entity
        DataDimensions = 'channels_x x channels_y x samples'; % (string) The data dimensions
        
        % DataUnit - (1 x channels) Cell array with the unit of each sample (e.g. 'nV'). 
        % 'ADC', if the data is not yet converted to voltages.
        DataUnit 
        DataType % (string) The data type, e.g. 'double', 'single' or 'raw'
        TimeStampDataType % (string) The type of the time stamps, 'double' or 'int64'
        
        % ConversionFactors - (channels_x x channels_y) Matrix of conversion factors
        % If the DataType is 'raw', conversion from ADC steps to voltages
        % can be perfomed by
        %
        %   (FrameData(i,j,t) - Info.ADZero) * ConversionFactors(i,j)
        %
        % Note: This is unnecessary if the DataType is not 'raw' as the
        % FrameData has been converted already in this case.
        ConversionFactors = []; 
    end
    
    properties (Access = private)
        FileName
        StructName
        DataLoaded = false;
        Internal = false;
    end
    
    methods
        
        function fde = McsFrameDataEntity(filename, info, fdeStructName, varargin)
        % Reads the metadata, time stamps and conversion factors of the
        % frame data entity.
        %
        % function fde = McsFrameDataEntity(filename, info, fdeStructName)
        % function fde = McsFrameDataEntity(filename, info, fdeStructName, cfg)
        %
        % The frame data itself is loaded only if it is requested by
        % another function.
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
            
            fde.FileName = filename;
            fde.Info = info;
            fde.StructName = fdeStructName;
            
            if strcmp(mode,'h5')
                fde.ConversionFactors = h5read(fde.FileName, ...
                                      [fde.StructName '/ConversionFactors'])';
                timestamps = h5read(fde.FileName, [fde.StructName '/FrameDataTimeStamps']);
            else
                fde.ConversionFactors = hdf5read(fde.FileName, ...
                                      [fde.StructName '/ConversionFactors'])';
                timestamps = hdf5read(fde.FileName, [fde.StructName '/FrameDataTimeStamps']);
            end
            fde.ConversionFactors = double(fde.ConversionFactors);        
            
            if size(timestamps,1) ~= 3
                timestamps = timestamps';
            end
            if isempty(varargin) || ~isfield(varargin{1},'timeStampDataType') || strcmpi(varargin{1}.timeStampDataType,'int64')
                timestamps = bsxfun(@plus,timestamps,int64([0 1 1])');
                for tsi = 1:size(timestamps,2)
                    fde.FrameDataTimeStamps(timestamps(2,tsi):timestamps(3,tsi)) = ...
                        (int64(0:numel(timestamps(2,tsi):timestamps(3,tsi))-1) .* ...
                        fde.Info.Tick) + timestamps(1,tsi);
                end
                fde.TimeStampDataType = 'int64';
            else
                type = varargin{1}.timeStampDataType;
                if ~strcmp(type,'double')
                    error('Only int64 and double are supported for timeStampDataType!');
                end
                fde.FrameDataTimeStamps = cast([],type);
                timestamps = bsxfun(@plus,double(timestamps),[0 1 1]');
                for tsi = 1:size(timestamps,2)
                    fde.FrameDataTimeStamps(timestamps(2,tsi):timestamps(3,tsi)) = ...
                        ((0:numel(timestamps(2,tsi):timestamps(3,tsi))-1) .* ...
                        cast(fde.Info.Tick,type)) + timestamps(1,tsi);
                end
                fde.TimeStampDataType = type;
            end
            
            if isempty(varargin) || ~isfield(varargin{1},'dataType') || strcmpi(varargin{1}.dataType,'double')
                fde.DataType = 'double';
            else
                type = varargin{1}.dataType;
                if ~strcmpi(type,'double') && ~strcmpi(type,'single') && ~strcmpi(type,'raw')
                    error('Only double, single and raw are allowed as data types!');
                end
                fde.DataType = varargin{1}.dataType;
            end
        end
        
        function data = get.FrameData(fde)
        % Accessor function for FrameData
        %
        % function data = get.FrameData(fde) 
        %
        % Reads the data from the HDF5 file, but only for the first time
        % FrameData is accessed.
            if exist('h5info')
                mode = 'h5';
            else
                mode = 'hdf5';
            end
            
            if ~fde.Internal && ~fde.DataLoaded
                fprintf('Reading frame data...');
                if strcmp(mode,'h5')
                    fde.FrameData = h5read(fde.FileName, ...
                                      [fde.StructName '/FrameData']);
                else
                    fde.FrameData = hdf5read(fde.FileName, ...
                                      [fde.StructName '/FrameData']);
                end
                fde.FrameData = permute(fde.FrameData,[3 2 1]);
                fprintf('done!\n');
                fde.DataLoaded = true;
                
                if ~strcmp(fde.DataType,'raw')
                    [ignore,unit_prefix] = McsHDF5.ExponentToUnit(fde.Info.Exponent,0);
                    fde.DataUnit = [unit_prefix fde.Info.Unit{1}];
                    convert_from_raw(fde);    
                else
                    fde.DataUnit = 'ADC';
                end

            end
            data = fde.FrameData;
        end
        
        function s = disp(str)
            s = 'McsFrameDataEntity object\n\n';
            s = [s 'Properties:\n'];
            s = [s '\tNumber of Channels:\t\t ' num2str(str.Info.FrameBottom - str.Info.FrameTop + 1) ...
                'x' num2str(str.Info.FrameRight - str.Info.FrameLeft + 1) '\n'];
            s = [s '\tTime Range:\t\t\t\t ' num2str(McsHDF5.TickToSec(str.FrameDataTimeStamps(1))) ...
                ' - ' num2str(McsHDF5.TickToSec(str.FrameDataTimeStamps(end))) ' s\n'];
            s = [s '\tData Loaded:\t\t\t '];
            if str.DataLoaded
                s = [s 'true\n'];
            else
                s = [s 'false\n'];
            end
            s = [s '\n'];
            
            s = [s 'Available Fields:\n'];
            s = [s '\tFrameData:\t\t\t\t [' num2str(str.Info.FrameBottom - str.Info.FrameTop + 1) ...
                'x' num2str(str.Info.FrameRight - str.Info.FrameLeft + 1) ...
                'x' num2str(length(str.FrameDataTimeStamps))];
            if str.DataLoaded
                s = [s ' ' class(str.FrameData) ']'];
            else
                s = [s ', not loaded]'];
            end
            s = [s '\n'];
            s = [s '\tFrameDataTimeStamps:\t [' num2str(size(str.FrameDataTimeStamps,1))...
                'x' num2str(size(str.FrameDataTimeStamps,2)) ' ' class(str.FrameDataTimeStamps) ']'];
            s = [s '\n'];
            s = [s '\tDataDimensions:\t\t\t ' str.DataDimensions];
            s = [s '\n'];
            s = [s '\tDataUnit:\t\t\t\t ' str.DataUnit];
            s = [s '\n'];
            s = [s '\tDataType:\t\t\t\t ' str.DataType];
            s = [s '\n'];
            s = [s '\tTimeStampDataType:\t\t ' str.TimeStampDataType];
            s = [s '\n'];
            s = [s '\tConversionFactors:\t\t [' num2str(size(str.ConversionFactors,1)) ...
                'x' num2str(size(str.ConversionFactors,2)) ' ' class(str.ConversionFactors) ']'];
            s = [s '\n'];
            s = [s '\tInfo:\t\t\t\t\t [' num2str(size(str.Info,1)) 'x' num2str(size(str.Info,2)) ' struct]'];
            s = [s '\n\n'];
            fprintf(s);
        end
        
        function data = getConvertedData(fde,cfg)
        %
        % Returns the conversion of FrameData into units of 10 ^
        % Info.Exponent [Info.Unit].
        %
        % function data = getConvertedData(fde,cfg)
        %
        % Converts 'raw' data into meaningful units and returns it with the
        % specified dataType. If FrameData already has DataType 'single' or
        % 'double' (i.e. has already been converted), either the FrameData
        % values are returned directly, or, if cfg.dataType differs from
        % the DataType field, the FrameData is cast to cfg.dataType. The
        % values in the FrameData field are not altered by this function.
        %
        % Input:
        %   fde     -   A FrameDataEntity
        %   cfg     -   A configuration structure which may contain the
        %               field 'dataType'. 'dataType' has to be one of the
        %               built-in data types, the default is 'double'.
        %
        % Output:
        %   data    -   (channels_x x channels_y x samples) array with the
        %               same size as FrameData. Its values are of type
        %               cfg.dataType and it contains the FrameData values
        %               in units of 10 ^ Info.Exponent [Info.Unit]
            
            cfg = McsHDF5.checkParameter(cfg, 'dataType', 'double');

            if ~strcmp(fde.DataType,'raw')
                if ~strcmp(fde.DataType,cfg.dataType)
                    data = cast(fde.FrameData,cfg.dataType);
                else
                    data = fde.FrameData;
                end
            else
                conv_factor = cast(fde.ConversionFactors,cfg.dataType);
                adzero = cast(fde.Info.ADZero,cfg.dataType);
                data = cast(fde.FrameData,cfg.dataType) - adzero;
                data = bsxfun(@times,data,conv_factor);
            end
        end

        function out_fde = readPartialFrameData(fde,cfg)
        % Read a hyperslab from the fde.
        %
        % function out_fde = readPartialFrameData(fde,cfg)
        %
        % Reads a segment of the frame from the HDF5 file and returns the
        % FrameDataEntity object containing only the specific segment.
        % Useful, if the data has not yet been read from the file and the
        % user is only interested in a specific segment.
        %
        % Input:
        %   fde       -   A McsFrameDataEntity object
        %
        %   cfg       -   Either empty (for default parameters) or a
        %                 structure with (some of) the following fields:
        %                 'window': If empty, the whole time interval, otherwise
        %                   [start end] in seconds
        %                 'channel_x', 'channel_y': channel range in x and
        %                   y direction, given as [first last] channel index.
        %                   If empty, all channels are used.
        %
        % Output:
        %   out_fde     -   The FrameDataEntity with the requested data
        %                   segment
        
            ts = fde.FrameDataTimeStamps;
            defaultChannelX = double(1:(fde.Info.FrameRight - fde.Info.FrameLeft + 1));
            defaultChannelY = double(1:(fde.Info.FrameBottom - fde.Info.FrameTop + 1));
            defaultWindow = 1:length(ts);
            
            [cfg, isDefault] = McsHDF5.checkParameter(cfg, 'channel_x', defaultChannelX);
            if ~isDefault
                cfg.channel_x = min(cfg.channel_x):max(cfg.channel_x);
                if any(cfg.channel_x < 1 | cfg.channel_x > length(defaultChannelX))
                    cfg.channel_x = cfg.channel_x(cfg.channel_x >= 1 & cfg.channel_x <= length(defaultChannelX));
                    if isempty(cfg.channel_x)
                        error('No channels found for channel_x!');
                    else
                        warning(['Using only indices between ' num2str(cfg.channel_x(1)) ' and ' num2str(cfg.channel_x(end)) ' for channel_x!']);
                    end
                end
            end
            
            [cfg, isDefault] = McsHDF5.checkParameter(cfg, 'channel_y', defaultChannelY);
            if ~isDefault
                cfg.channel_y = min(cfg.channel_y):max(cfg.channel_y);
                if any(cfg.channel_y < 1 | cfg.channel_y > length(defaultChannelY))
                    cfg.channel_y = cfg.channel_y(cfg.channel_y >= 1 & cfg.channel_y <= length(defaultChannelY));
                    if isempty(cfg.channel_y)
                        error('No channels found for channel_y!');
                    else
                        warning(['Using only indices between ' num2str(cfg.channel_y(1)) ' and ' num2str(cfg.channel_y(end)) ' for channel_y!']);
                    end
                end
            end
            
            [cfg, isDefault] = McsHDF5.checkParameter(cfg, 'window', defaultWindow);
            if ~isDefault
                t = find(ts >= McsHDF5.SecToTick(cfg.window(1)) & ts <= McsHDF5.SecToTick(cfg.window(2)));
                if McsHDF5.TickToSec(ts(t(1)) - fde.Info.Tick) > cfg.window(1) || ...
                        McsHDF5.TickToSec(ts(t(end)) + fde.Info.Tick) < cfg.window(2)
                    warning(['Using only time range between ' McsHDF5.TickToSec(ts(t(1))) ...
                        ' and ' McsHDF5.TickToSec(ts(t(end))) ' s!']);
                elseif isempty(t)
                    error('No time range found!');
                end
                cfg.window = t;
            end
            
            % read metadata
            out_fde = McsHDF5.McsFrameDataEntity(fde.FileName, fde.Info, fde.StructName);
            
            out_fde.Internal = true;
            if fde.DataLoaded
                out_fde.FrameData = fde.FrameData(cfg.channel_x, cfg.channel_y, cfg.window);
            else
                % read data segment
                fid = H5F.open(fde.FileName);
                gid = H5G.open(fid,fde.StructName);
                did = H5D.open(gid,'FrameData');
                dims = [length(cfg.channel_x) length(cfg.channel_y) length(cfg.window)];
                offset = [cfg.channel_x(1)-1 cfg.channel_y(1)-1 cfg.window(1)-1];
                mem_space_id = H5S.create_simple(3,dims,[]);
                file_space_id = H5D.get_space(did);
                H5S.select_hyperslab(file_space_id,'H5S_SELECT_SET',offset,[],[],dims);

                fprintf('Reading partial frame data...');
                out_fde.FrameData = H5D.read(did,'H5ML_DEFAULT',mem_space_id,file_space_id,'H5P_DEFAULT');
                out_fde.FrameData = permute(out_fde.FrameData,[3 2 1]);
                fprintf('done!\n');
                
                H5D.close(did);
                H5G.close(gid);
                H5F.close(fid);
            end
            out_fde.Info.FrameRight = out_fde.Info.FrameLeft + cfg.channel_x(end) - 1;
            out_fde.Info.FrameBottom = out_fde.Info.FrameTop + cfg.channel_y(end) - 1;
            out_fde.Info.FrameLeft = out_fde.Info.FrameLeft + cfg.channel_x(1) - 1;
            out_fde.Info.FrameTop = out_fde.Info.FrameTop + cfg.channel_y(1) - 1;
            
            out_fde.FrameDataTimeStamps = ts(cfg.window);
            out_fde.ConversionFactors = fde.ConversionFactors(cfg.channel_x,cfg.channel_y);
            out_fde.DataLoaded = true;
            out_fde.TimeStampDataType = fde.TimeStampDataType;
            type = fde.DataType;
            out_fde.DataType = type;
            if ~strcmp(type,'raw')
                convert_from_raw(out_fde);
            end
            out_fde.Internal = false;
            if ~isempty(fde.DataUnit)
                out_fde.DataUnit = fde.DataUnit;
            elseif strcmp(type,'raw')
                out_fde.DataUnit = 'ADC';
            else
                [ignore,unit_prefix] = McsHDF5.ExponentToUnit(out_fde.Info.Exponent,0);
                out_fde.DataUnit = [unit_prefix out_fde.Info.Unit{1}];
            end
        end
        
    end
    
    methods (Access = private)
        function convert_from_raw(fde)
        % Converts the raw data to useful units.
        %
        % function out = convert_from_raw(fde)
        %
        % This is performed during loading of the data.
            
            fde.FrameData = cast(fde.FrameData,fde.DataType) - cast(fde.Info.ADZero,fde.DataType);

            % multiply FrameData with the conversion factors in a fast and
            % memory efficient way
            fde.FrameData = bsxfun(@times,fde.FrameData,cast(fde.ConversionFactors,fde.DataType));            
        end
    end
    
end