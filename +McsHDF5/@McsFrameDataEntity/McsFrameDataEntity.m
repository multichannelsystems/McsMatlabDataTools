classdef McsFrameDataEntity < handle
% Holds the contents of a single FrameDataEntity
%
% Fields:
%   FrameData       -   (samples x channels_y x channels_x) array of data
%                       values, given in units of 10 ^ Info.Exponent 
%                       [Info.Unit]
%
%   FrameDataTimeStamps - (samples x 1) vector of time stamps in
%                       microseconds.
%
%   The Info field provides general information about the frame stream.

    properties (SetAccess = private)
        FrameData = [];
        FrameDataTimeStamps = int64([]);
        Info
    end
    
    properties (Access = private)
        FileName
        StructName
        DataLoaded = false;
        Internal = false;
        ConversionFactors = [];
    end
    
    methods
        
        function fde = McsFrameDataEntity(filename, info, fdeStructName)
        % Reads the metadata, time stamps and conversion factors of the
        % frame data entity.
        %
        % function fde = McsFrameDataEntity(filename, info, fdeStructName)
        %
        % The frame data itself is loaded only if it is requested by
        % another function.
        
            fde.FileName = filename;
            fde.Info = info;
            fde.StructName = fdeStructName;
            fde.ConversionFactors = h5read(fde.FileName, ...
                                      [fde.StructName '/ConversionFactors']);
            fde.ConversionFactors = double(fde.ConversionFactors);        
            timestamps = h5read(fde.FileName, [fde.StructName '/FrameDataTimeStamps']);
            if size(timestamps,1) ~= 3
                timestamps = timestamps';
            end
            timestamps = bsxfun(@plus,timestamps,int64([0 1 1])');
            for tsi = 1:size(timestamps,2)
                fde.FrameDataTimeStamps(timestamps(2,tsi):timestamps(3,tsi)) = ...
                    (int64(0:numel(timestamps(2,tsi):timestamps(3,tsi))-1) .* ...
                    fde.Info.Tick(1)) + timestamps(1,tsi);
            end
            fde.FrameDataTimeStamps = fde.FrameDataTimeStamps';
        end
        
        function data = get.FrameData(fde)
        % Accessor function for FrameData
        %
        % function data = get.FrameData(fde) 
        %
        % Reads the data from the HDF5 file, but only for the first time
        % FrameData is accessed.
        
            if ~fde.Internal && ~fde.DataLoaded
                fprintf('Reading frame data...\n');
                fde.FrameData = h5read(fde.FileName, ...
                                      [fde.StructName '/FrameData']);
                fde.DataLoaded = true;

                convert_from_raw(fde);

            end
            data = fde.FrameData;
        end

        function out_fde = readPartialFrame(fde,cfg)
        % Read a hyperslab from the frame.
        %
        % function out_fde = readPartialFrame(fde,cfg)
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
        %                 'time': If empty, the whole time interval, otherwise
        %                   [start end] in seconds
        %                 'channel_x', 'channel_y': channel range in x and
        %                   y direction, given as [first last] channel index.
        %                   If empty, all channels are used.
        %
        % Output:
        %   out_fde     -   The FrameDataEntity with the requested data
        %                   segment
        
            ts = fde.FrameDataTimeStamps;
            defaultChannelX = 1:size(fde.FrameData,3);
            defaultChannelY = 1:size(fde.FrameData,2);
            defaultTime = 1:length(ts);
            
            if isempty(cfg)
                cfg.channel_x = [];
                cfg.channel_y = [];
                cfg.time = [];
            end
            
            if ~isfield(cfg,'channel_x') || isempty(cfg.channel_x)
                cfg.channel_x = defaultChannelX;
            else
                cfg.channel_x = cfg.channel_x(1):cfg.channel_x(2);
            end
            
            if ~isfield(cfg,'channel_y') || isempty(cfg.channel_y)
                cfg.channel_y = defaultChannelY;
            else
                cfg.channel_y = cfg.channel_y(1):cfg.channel_y(2);
            end
            
            if ~isfield(cfg,'time') || isempty(cfg.time)
                cfg.time = defaultTime;
            else
                t = find(ts >= McsHDF5.SecToTick(cfg.time(1)) & ts <= McsHDF5.SecToTick(cfg.time(2)));
                if McsHDF5.TickToSec(ts(t(1)) - fde.Info.Tick) > cfg.time(1) || ...
                        McsHDF5.TickToSec(ts(t(end)) + fde.Info.Tick) < cfg.time(2)
                    warning(['Using only time range between ' McsHDF5.TickToSec(ts(t(1))) ...
                        ' and ' McsHDF5.TickToSec(ts(t(end))) ' s!']);
                elseif isempty(t)
                    error('No time range found!');
                end
                cfg.time = t;
            end
            
            if any(cfg.channel_x < 1 | cfg.channel_x > size(fde.FrameData,3))
                cfg.channel_x = cfg.channel_x(cfg.channel_x >= 1 & cfg.channel_x <= size(fde.FrameData,3));
                if isempty(cfg.channel_x)
                    error('No channels found for channel_x!');
                else
                    warning(['Using only indices between ' num2str(cfg.channel_x(1)) ' and ' num2str(cfg.channel_x(end)) ' for channel_x!']);
                end
            end
            
            if any(cfg.channel_y < 1 | cfg.channel_y > size(fde.FrameData,2))
                cfg.channel_y = cfg.channel_y(cfg.channel_y >= 1 & cfg.channel_y <= size(fde.FrameData,2));
                if isempty(cfg.channel_y)
                    error('No channels found for channel_y!');
                else
                    warning(['Using only indices between ' num2str(cfg.channel_y(1)) ' and ' num2str(cfg.channel_y(end)) ' for channel_y!']);
                end
            end
            
            % read metadata
            out_fde = McsHDF5.McsFrameDataEntity(fde.FileName, fde.Info, fde.StructName);
            
            % read data segment
            fid = H5F.open(fde.FileName);
            gid = H5G.open(fid,fde.StructName);
            did = H5D.open(gid,'FrameData');
            dims = [length(cfg.channel_x) length(cfg.channel_y) length(cfg.time)];
            offset = [cfg.channel_x(1)-1 cfg.channel_y(1)-1 cfg.time(1)-1];
            mem_space_id = H5S.create_simple(3,dims,[]);
            file_space_id = H5D.get_space(did);
            H5S.select_hyperslab(file_space_id,'H5S_SELECT_SET',offset,[],[],dims);
            
            out_fde.Internal = true;

            out_fde.FrameData = H5D.read(did,'H5ML_DEFAULT',mem_space_id,file_space_id,'H5P_DEFAULT');

            out_fde.FrameDataTimeStamps = ts(cfg.time);
            out_fde.ConversionFactors = fde.ConversionFactors(cfg.channel_y,cfg.channel_x);
            out_fde.DataLoaded = true;
            convert_from_raw(out_fde);
            out_fde.Internal = false;
            
            
            H5D.close(did);
            H5G.close(gid);
            H5F.close(fid);
        end
        
    end
    
    methods (Access = private)
        function convert_from_raw(fde)
        % Converts the raw data to useful units.
        %
        % function out = convert_from_raw(fde)
        %
        % This is performed during loading of the data.
            
            fde.FrameData = double(fde.FrameData) - double(fde.Info.ADZero);

            % multiply FrameData with the conversion factors in a fast and
            % memory efficient way
            fde.FrameData = bsxfun(@times,fde.FrameData,shiftdim(fde.ConversionFactors,-1));            
        end
    end
    
end