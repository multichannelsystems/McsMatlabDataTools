classdef McsTimeStampStream < McsHDF5.McsStream
% Holds the contents of an TimeStampStream
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
        TimeStamps = {};
        TimeStampDataType
    end
    
    methods
        function str = McsTimeStampStream(filename, strStruct, varargin)
        % Constructs a McsTimeStampStream object.
        %
        % function str = McsTimeStampStream(filename, strStruct)
        % function str = McsTimeStampStream(filename, strStruct, cfg)
        %
        % Reads the meta-information from the file but does not read the
        % actual event data. This is performed the first time that the
        % TimeStamps field is accessed.
        %
        % % Optional input:
        %   cfg     -   configuration structure, can contain
        %               the following field:
        %               'timeStampDataType': The type of the time stamps,
        %               can be either 'int64' (default) or 'double'. Using
        %               'double' is useful for older Matlab version without
        %               int64 arithmetic.
        
            str = str@McsHDF5.McsStream(filename,strStruct,'TimeStamp');
            evts = str.Info.TimeStampEntityID;
            str.TimeStamps = cell(1,length(evts)); 
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
        
        function data = get.TimeStamps(str)
        % Accessor function for time stamps.
        % 
        % function data = get.TimeStamps(str)
        %
        % Loads the time stamps from the file the first time that the TimeStamps
        % field is requested.
            if exist('h5info','builtin')
                mode = 'h5';
            else
                mode = 'hdf5';
            end
            
            if ~str.DataLoaded
                fprintf('Reading time stamp data...\n')
                for gidx = 1:length(str.TimeStamps)
                    try
                        if strcmp(mode,'h5')
                            str.TimeStamps{gidx} = ...
                                h5read(str.FileName,[str.StructName '/TimeStampEntity_' num2str(str.Info.TimeStampEntityID(gidx))])';
                        else
                            str.TimeStamps{gidx} = ...
                                hdf5read(str.FileName,[str.StructName '/TimeStampEntity_' num2str(str.Info.TimeStampEntityID(gidx))])';
                        end
                    end
                    if ~strcmp(str.TimeStampDataType,'int64')
                        str.TimeStamps{gidx} = cast(str.TimeStamps{gidx},str.TimeStampDataType);
                    end
                end
                str.DataLoaded = true;
            end
            data = str.TimeStamps;
        end
    end
end