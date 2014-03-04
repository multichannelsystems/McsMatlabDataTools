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
        DataLoaded = false;
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
            if size(timestamps,1) ~= 3
                timestamps = timestamps';
            end
            timestamps = bsxfun(@plus,timestamps,int64([0 1 1])');
            for tsi = 1:size(timestamps,2)
                fde.FrameDataTimeStamps(timestamps(2,tsi):timestamps(3,tsi)) = ...
                    (int64(0:numel(timestamps(2,tsi):timestamps(3,tsi))-1) .* ...
                    fde.InfoStruct.Tick(1)) + timestamps(1,tsi);
            end
            fde.FrameDataTimeStamps = fde.FrameDataTimeStamps';
        end
        
        function data = get.FrameData(fde)
        % function data = get.FrameData(fde) 
        %
        % Accessor function for FrameData, reads the data from the HDF5
        % file, but only for the first time FrameData is accessed.
        
            if ~fde.Internal && ~fde.DataLoaded
                fprintf('Reading frame data...\n');
                fde.FrameData = h5read(fde.FileName, ...
                                      [fde.StructName '/FrameData']);
                fde.DataLoaded = true;

                convert_from_raw(fde);

            end
            data = fde.FrameData;
        end

        function out_fde = readPartialFrame(fde,time,channel_y,channel_x)
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
                channel_x = 1:size(fde.FrameData,3);
            else
                channel_x = channel_x(1):channel_x(2);
            end
            if isempty(channel_y)
                channel_y = 1:size(fde.FrameData,2);
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
            dims = [length(channel_x) length(channel_y) length(time)];
            offset = [channel_x(1)-1 channel_y(1)-1 time(1)-1];
            mem_space_id = H5S.create_simple(3,dims,[]);
            file_space_id = H5D.get_space(did);
            H5S.select_hyperslab(file_space_id,'H5S_SELECT_SET',offset,[],[],dims);
            
            out_fde.Internal = true;

            out_fde.FrameData = H5D.read(did,'H5ML_DEFAULT',mem_space_id,file_space_id,'H5P_DEFAULT');
            ts = fde.FrameDataTimeStamps;

            out_fde.FrameDataTimeStamps = ts(time);
            out_fde.ConversionFactors = fde.ConversionFactors(channel_y,channel_x);
            out_fde.DataLoaded = true;
            out_fde.FrameData = convert_from_raw(out_fde);
            out_fde.Internal = false;
            
            
            H5D.close(did);
            H5G.close(gid);
            H5F.close(fid);
        end
        
    end
    
    methods (Access = private)
        function convert_from_raw(fde)
        % function out = convert_from_raw(fde)
        %
        % Converts the raw data to useful units. This is performed during
        % loading of the data. 
            
            fde.FrameData = double(fde.FrameData) - double(fde.InfoStruct.ADZero);

            % multiply FrameData with the conversion factors in a fast and
            % memory efficient way
            fde.FrameData = bsxfun(@times,fde.FrameData,shiftdim(fde.ConversionFactors,-1));            
        end
    end
    
end