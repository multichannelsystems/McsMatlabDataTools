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
%   The Info field and the other attributes provide general information
%   about the segment stream.
    
    properties (SetAccess = private)
        SegmentData = {};
        SegmentDataTimeStamps = {};
    end
    
    methods
        function str = McsSegmentStream(filename, strStruct)
        % Constructs a McsSegmentStream object.
        %
        % function str = McsSegmentStream(filename, strStruct)
        %
        % Reads the time stamps and the meta-information but does not read
        % the segment data. This is done the first time that the segment
        % data is accessed.
            
            str = str@McsHDF5.McsStream(filename,strStruct,'Segment');
            segments = str.Info.SegmentID;
            str.SegmentData = cell(1,length(segments));
            str.SegmentDataTimeStamps = cell(1,length(segments));
            
            for segi = 1:length(segments)   
                str.SegmentDataTimeStamps{segi} = ...
                    h5read(filename,[strStruct.Name '/SegmentData_ts_' num2str(segments(segi))]);
            end
            
            sourceInfo = h5read(filename,[strStruct.Name '/SourceInfoChannel']);
            fn = fieldnames(sourceInfo);
            for fields = 1:length(fn)
                str.Info.(fn{fields}) = sourceInfo.(fn{fields});
            end
        end
        
        function data = get.SegmentData(str)
        % Accessor function for the SegmentData field.
        %
        % function data = get.SegmentData(str)
        %
        % Reads the segment data from the file the first time that the
        % SegmentData field is accessed.
        
            if ~str.DataLoaded
                fprintf('Reading segment data...\n');
                for segi = 1:length(str.Info.SegmentID)
                    str.SegmentData{segi} = ...
                        h5read(str.FileName,[str.StructName '/SegmentData_' num2str(str.Info.SegmentID(segi))]);  
                end 
                str.DataLoaded = true;
                for segi = 1:length(str.Info.SegmentID)
                    str.SegmentData{segi} = convert_from_raw(str,segi);
                end
            end
            data = str.SegmentData;
        end
    end
    
    methods (Access = private)
        function out = convert_from_raw(seg,idx)
        % Converts the raw segment data to useful units.
        %
        % function out = convert_from_raw(seg,idx)
        %
        % This is done already the first time that the data is loaded
            
            conv_factor = double(seg.Info.ConversionFactor(idx));
            adzero = double(seg.Info.ADZero(idx));
            out = double(seg.SegmentData{idx});
            out = bsxfun(@minus,out,adzero');
            out = bsxfun(@times,out,conv_factor);
            
        end
    end
    
end