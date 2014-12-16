classdef McsEventStream < McsHDF5.McsStream
% Holds the contents of an EventStream
%
% Fields:
%   Events      -   (1xn) cell array, each cell holding either a (events x
%                   1) vector of time stamps for each event or a (events x
%                   2) matrix, where the first column are time stamps and
%                   the second column are durations. Both are given in
%                   microseconds.
%
%   The Info field and the other attributes provide general information
%   about the event stream.
    
    properties (SetAccess = private)
        Events = {};
        TimeStampDataType
    end
    
    methods
        function str = McsEventStream(filename, strStruct, varargin)
        % Constructs a McsEventStream object.
        %
        % function str = McsEventStream(filename, strStruct)
        % function str = McsEventStream(filename, strStruct, cfg)
        %
        % Reads the meta-information from the file but does not read the
        % actual event data. This is performed the first time that the
        % Events field is accessed.
        %
        % % Optional input:
        %   cfg     -   configuration structure, can contain
        %               the following field:
        %               'timeStampDataType': The type of the time stamps,
        %               can be either 'int64' (default) or 'double'. Using
        %               'double' is useful for older Matlab version without
        %               int64 arithmetic.
        
            str = str@McsHDF5.McsStream(filename,strStruct,'Event');
            evts = str.Info.EventID;
            str.Events = cell(1,length(evts)); 
            if isempty(varargin) || ~isfield(varargin{1},'timeStampDataType') || strcmpi(varargin{1}.timeStampDataType,'int64')
                str.TimeStampDataType = 'int64';
            else
                type = varargin{1}.timeStampDataType;
                if ~strcmp(type,'double')
                    error('Only int64 and double are supported for timeStampDataType!');
                end
                str.TimeStampDataType = type;
            end
        end
        
        function data = get.Events(str)
        % Accessor function for events.
        % 
        % function data = get.Events(str)
        %
        % Loads the events from the file the first time that the Events
        % field is requested.
            if exist('h5info')
                mode = 'h5';
            else
                mode = 'hdf5';
            end
            
            if ~str.DataLoaded
                fprintf('Reading event data...')
                for gidx = 1:length(str.Events)
                    try
                        if strcmp(mode,'h5')
                            str.Events{gidx} = ...
                                h5read(str.FileName,[str.StructName '/EventEntity_' num2str(str.Info.EventID(gidx))])';
                        else
                            str.Events{gidx} = ...
                                hdf5read(str.FileName,[str.StructName '/EventEntity_' num2str(str.Info.EventID(gidx))])';
                        end
                    end
                    if ~strcmp(str.TimeStampDataType,'int64')
                        str.Events{gidx} = cast(str.Events{gidx},str.TimeStampDataType);
                    end
                end
                fprintf('done!\n');
                str.DataLoaded = true;
            end
            data = str.Events;
        end
        
        function s = disp(str)
            s = 'McsEventStream object\n\n';
            s = [s 'Properties:\n'];
            s = [s '\tStream Label:\t\t\t ' strtrim(str.Label) '\n'];
            s = [s '\tNumber of Events:\t\t ' num2str(length(str.Info.EventID)) '\n'];
            s = [s '\tData Loaded:\t\t\t '];
            if str.DataLoaded
                s = [s 'true\n'];
            else
                s = [s 'false\n'];
            end
            s = [s '\n'];
            
            s = [s 'Available Fields:\n'];
            s = [s '\tEvents:\t\t\t\t\t {1x' num2str(length(str.Info.EventID))];
            if str.DataLoaded
                s = [s ' ' class(str.Events) '}'];
            else
                s = [s ', not loaded}'];
            end
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
    end
end