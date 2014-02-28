classdef McsFrameDataEntity < handle
% McsFrameDataEntity   
%
% Holds the contents of a single FrameDataEntity

    properties (SetAccess = private)
        FrameData = [];
        FrameDataTimeStamps = [];
    end
    
    properties (Access = public)
        ConversionFactors = [];
    end
    
    properties (Access = private)
        FileName
        StructName
        InfoStruct
        DataAllocated = false;
        DataFull = false;
        Internal = false;
    end
    
    methods
        
        function fde = McsFrameDataEntity(filename, info, fdeStructName)
        % function fde = McsFrameDataEntity(filename, info, fdeStructName)
        %
        % Reads the metadata, time stamps and conversion factors of the
        % frame data entity. The frame data itself is loaded only if it is
        % requested by another function.
        
            fde.FileName = filename;
            fde.InfoStruct = info;
            fde.StructName = fdeStructName;
            fde.ConversionFactors = h5read(fde.FileName, ...
                                      [fde.StructName '/ConversionFactors']);
            fde.ConversionFactors = double(fde.ConversionFactors);        
            timestamps = h5read(fde.FileName, [fde.StructName '/FrameDataTimeStamps']);
            timestamps = timestamps + int64([0 1 1]);

            for tsi = 1:size(timestamps,1)
                fde.FrameDataTimeStamps(timestamps(tsi,2):timestamps(tsi,3)) = ...
                       (int64(0:numel(timestamps(tsi,2):timestamps(tsi,3))-1) .* ...
                        fde.InfoStruct.Tick(1)) + timestamps(tsi,1);
            end
            fde.FrameDataTimeStamps = fde.FrameDataTimeStamps';
        end
        
        function data = get.FrameData(fde)
        % function data = get.FrameData(fde) 
        %
        % Accessor function for FrameData, reads the data from the HDF5
        % file, but only for the first time FrameData is accessed.
        
            if ~fde.Internal && (~fde.DataAllocated || ~fde.DataFull)
                fprintf('Reading frame data...\n');
                fde.FrameData = h5read(fde.FileName, ...
                                      [fde.StructName '/FrameData']);
                fde.DataAllocated = true;
                fde.DataFull = true;
                fde.FrameData = convert_from_raw(fde);
            end
            data = fde.FrameData;
        end
        
        function out = convert_from_raw(fde,varargin)
        % function out = convert_from_raw(fde,varargin)
        %
        % Converts the raw data to useful units. This is performed during
        % loading of the data. Optionally, time points as well as channels
        % in x and in y direction can be used as parameters in the form of:
        %
        % function out = convert_from_raw(fde,time,chan_x,chan_y)
        %
        % If these optional parameters are present, the conversion is done
        % only for these data segments.
        
            switch (length(varargin))
                case 0
                    time = 1:size(fde.FrameData,1);
                    chan_x = 1:size(fde.FrameData,2);
                    chan_y = 1:size(fde.FrameData,3);
                case 1
                    time = varargin{1};
                    chan_x = 1:size(fde.FrameData,2);
                    chan_y = 1:size(fde.FrameData,3);
                case 2
                    time = varargin{1};
                    chan_x = varargin{2};
                    chan_y = 1:size(fde.FrameData,3);
                case 3
                    time = varargin{1};
                    chan_x = varargin{2};
                    chan_y = varargin{3};
                otherwise
                    error('no more than 3 arguments, please!');
            end
            
            adzero = double(fde.InfoStruct.ADZero);
            
            out = double(fde.FrameData(time,chan_x,chan_y));
            
            out = bsxfun(@minus,out,adzero');
            out = bsxfun(@times,out,shiftdim(fde.ConversionFactors(chan_x,chan_y),-1));
            
        end
        
        function [out,out_time] = readHyperSlab(fde,time,channel_x,channel_y)
        % function [out,out_time] = readHyperSlab(fde,time,channel_x,channel_y)
        %
        % Returns only a specific hyperslab, i.e. a cuboid part of the
        % frame as well as the associated time stamps. If this cuboid has
        % not yet been loaded into the current McsFrameDataEntity object,
        % it is added to it. If this is the first call to
        % fde.readHyperSlab() or fde.FrameData, a data cuboid with the same
        % dimensions of the FrameData is allocated and filled by NaN. Then,
        % the segment read within this function replaces the corresponding
        % segment in the FrameData.
        %
        % Input:
        %   time        -   If empty, the whole time interval, otherwise
        %                   [start end] in seconds
        %   
        %   channel_x, channel_y - channel range in x and y direction,
        %                   given as [first last] channel index. If empty,
        %                   all channels are used.
        %
        % Output:
        %   out         -   The requested data segment (3 D array)
        %
        %   out_time    -   The time stamps of each sample in the out array
        
            % the full data frame is requested -> read everything
            if isempty(channel_x) && isempty(channel_y) && isempty(time)
                out = fde.FrameData;
                return;
            end
            
            % the full data frame is already in memory -> return the
            % requested part
            if fde.DataFull
                ts = fde.FrameDataTimeStamps;
            
                if isempty(channel_x)
                    channel_x = 1:size(fde.FrameData,2);
                else
                    channel_x = channel_x(1):channel_x(2);
                end
                if isempty(channel_y)
                    channel_y = 1:size(fde.FrameData,3);
                else
                    channel_y = channel_y(1):channel_y(2);
                end
                if isempty(time)
                    time = 1:size(fde.FrameData,1);
                else
                    time = find(ts >= McsHDF5.SecToTick(time(1)) & ts <= McsHDF5.SecToTick(time(2)));
                end
                out = fde.FrameData(time,channel_x,channel_y);
                return
            end
            
            % the memory for the data frame is already allocated and the
            % segment requested here has already been read from the file ->
            % return the requested part
            fde.Internal = true;
            if fde.DataAllocated && ~any(any(any(isnan(fde.FrameData(time,channel_x,channel_y)))));
                out = fde.FrameData(time,channel_x,channel_y);
                return;
            end
            fde.Internal = false;
            
            % The data has not been allocated, yet -> do that and fill it
            % with NaNs.
            if ~fde.DataAllocated
                inf = h5info(fde.FileName,[fde.StructName '/FrameData']);
                sz = inf.Dataspace.Size;
                fde.FrameData = nan(sz);
                fde.DataAllocated = true;
            end
            
            % at this point, the data cuboid is allocated, but at least
            % parts of the requested segment have not yet been read from
            % the file -> read the requested segment from the file, store
            % the result in the data cuboid and return the segment
            ts = fde.FrameDataTimeStamps;
            if isempty(channel_x)
                channel_x = 1:size(fde.FrameData,2);
            else
                channel_x = channel_x(1):channel_x(2);
            end
            if isempty(channel_y)
                channel_y = 1:size(fde.FrameData,3);
            else
                channel_y = channel_y(1):channel_y(2);
            end
            if isempty(time)
                time = 1:size(fde.FrameData,1);
            else
                time = find(ts >= McsHDF5.SecToTick(time(1)) & ts <= McsHDF5.SecToTick(time(2)));
            end
            fde.Internal = true;
            if ~any(any(any(isnan(fde.FrameData(time,channel_x,channel_y)))))
                out = fde.FrameData(time,channel_x,channel_y);
                return
            end
            fde.Internal = false;

            fid = H5F.open(fde.FileName);
            gid = H5G.open(fid,fde.StructName);
            did = H5D.open(gid,'FrameData');
            dims = [length(channel_y) length(channel_x) length(time)];
            offset = [channel_y(1)-1 channel_x(1)-1 time(1)-1];
            mem_space_id = H5S.create_simple(3,dims,[]);
            file_space_id = H5D.get_space(did);
            H5S.select_hyperslab(file_space_id,'H5S_SELECT_SET',offset,[],[],dims);
            fde.Internal = true;
            fde.FrameData(time,channel_x,channel_y) = H5D.read(did,'H5ML_DEFAULT',mem_space_id,file_space_id,'H5P_DEFAULT');
            fde.FrameData(time,channel_x,channel_y) = convert_from_raw(fde,time,channel_x,channel_y);
            out = fde.FrameData(time,channel_x,channel_y);
            fde.Internal = false;
            H5D.close(did);
            H5G.close(gid);
            H5F.close(fid);
            out_time = ts(time);
        end
        
        function out_fde = readPartialFrame(fde,time,channel_x,channel_y)
        % function out_fde = readPartialFrame(fde,time,channel_x,channel_y)
        %
        % Reads a segment of the frame fro mthe HDF5 file and returns the
        % FrameDataEntity object containing only the specific segment.
        % Useful, if the data has not yet been read from the file and the
        % user is only interested in a specific segment.
        %
        % Input:
        %   time        -   If empty, the whole time interval, otherwise
        %                   [start end] in seconds
        %   
        %   channel_x, channel_y - channel range in x and y direction,
        %                   given as [first last] channel index. If empty,
        %                   all channels are used.
        %
        % Output:
        %   out_fde     -   The FrameDataEntity with the requested data
        %                   segment
        
            ts = fde.FrameDataTimeStamps;
            
            if isempty(channel_x)
                channel_x = 1:size(fde.FrameData,2);
            else
                channel_x = channel_x(1):channel_x(2);
            end
            if isempty(channel_y)
                channel_y = 1:size(fde.FrameData,3);
            else
                channel_y = channel_y(1):channel_y(2);
            end
            if isempty(time)
                time = 1:length(fde.FrameDataTimeStamps);
            else
                time = find(ts >= McsHDF5.SecToTick(time(1)) & ts <= McsHDF5.SecToTick(time(2)));
            end
            
            % read metadata
            out_fde = McsHDF5.McsFrameDataEntity(fde.FileName, fde.InfoStruct, fde.StructName);
            
            % read data segment
            fid = H5F.open(fde.FileName);
            gid = H5G.open(fid,fde.StructName);
            did = H5D.open(gid,'FrameData');
            dims = [length(channel_y) length(channel_x) length(time)];
            offset = [channel_y(1)-1 channel_x(1)-1 time(1)-1];
            mem_space_id = H5S.create_simple(3,dims,[]);
            file_space_id = H5D.get_space(did);
            H5S.select_hyperslab(file_space_id,'H5S_SELECT_SET',offset,[],[],dims);
            out_fde.Internal = true;

            out_fde.FrameData = H5D.read(did,'H5ML_DEFAULT',mem_space_id,file_space_id,'H5P_DEFAULT');
            ts = fde.FrameDataTimeStamps;

            out_fde.FrameDataTimeStamps = ts(time);
            out_fde.ConversionFactors = fde.ConversionFactors(channel_x,channel_y);
            out_fde.DataAllocated = true;
            out_fde.DataFull = true;
            out_fde.FrameData = convert_from_raw(out_fde);
            out_fde.Internal = false;
            H5D.close(did);
            H5G.close(gid);
            H5F.close(fid);
        end
        
    end
    
end