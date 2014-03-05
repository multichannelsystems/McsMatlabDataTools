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
    end
    
    methods
        function str = McsEventStream(filename, strStruct)
        % Constructs a McsEventStream object.
        %
        % function str = McsEventStream(filename, strStruct)
        %
        % Reads the meta-information from the file but does not read the
        % actual event data. This is performed the first time that the
        % Events field is accessed.
        
            str = str@McsHDF5.McsStream(filename,strStruct,'Event');
            evts = str.Info.EventID;
            str.Events = cell(1,length(evts)); 
        end
        
        function data = get.Events(str)
        % Accessor function for events.
        % 
        % function data = get.Events(str)
        %
        % Loads the events from the file the first time that the Events
        % field is requested.
        
            if ~str.DataLoaded
                fprintf('Reading event data...\n')
                for gidx = 1:length(str.Events)
                    str.Events{gidx} = ...
                        h5read(str.FileName,[str.StructName '/EventEntity_' num2str(str.Info.EventID(gidx))]);
                end
                str.DataLoaded = true;
            end
            data = str.Events;
        end
    end
end