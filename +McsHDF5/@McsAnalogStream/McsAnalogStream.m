classdef McsAnalogStream < McsHDF5.McsStream
% McsAnalogStream
%
% Holds the contents of an AnalogStream

    properties (SetAccess = private)
        ChannelData = [];
        ChannelDataTimeStamps = [];
    end
    
    methods
        
        function str = McsAnalogStream(filename, strStruct)
        % function str = McsAnalogStream(filename, strStruct)    
        %
        % Constructs a McsAnalogStream object and reads the
        % meta-information and the time stamps, not the analog data. This
        % is done the first time that ChannelData is accessed.
        
            str = str@McsHDF5.McsStream(filename,strStruct,'Channel');
            
            timestamps = h5read(filename, [strStruct.Name '/ChannelDataTimeStamps']);
            timestamps = timestamps + int64([0 1 1]);
            for tsi = 1:size(timestamps,1)
                str.ChannelDataTimeStamps(timestamps(tsi,2):timestamps(tsi,3)) = ...
                    (int64(0:numel(timestamps(tsi,2):timestamps(tsi,3))-1) .* ...
                    str.Info.Tick(1)) + timestamps(tsi,1);
            end
            str.ChannelDataTimeStamps = str.ChannelDataTimeStamps';
            
        end
        
        function data = get.ChannelData(str)
        % function data = get.ChannelData(str)
        %
        % Accessor function for the ChannelData field. Will read the
        % channel data from file the first time this field is accessed.
        
            if ~str.DataFull
                fprintf('Reading analog data...\n')
                str.ChannelData = h5read(str.FileName, [str.StructName '/ChannelData']);
                str.DataFull = true;
                str.ChannelData = convert_from_raw(str);    
            end
            data = str.ChannelData;
        end
        
    end
    
    methods (Access = private)
        function out = convert_from_raw(str)
            % function out = convert_from_raw(str)
            %
            % Converts the raw channel data to useful units. This is
            % performed directly after the data is loaded from the hdf5
            % file.
            
            conv_factor = double(str.Info.ConversionFactor);
            adzero = double(str.Info.ADZero);
            out = double(str.ChannelData);
            out = bsxfun(@minus,out,adzero');
            out = bsxfun(@times,out,conv_factor');
            
        end
        
    end
    
end