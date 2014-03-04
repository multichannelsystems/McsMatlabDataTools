classdef McsEventStream < McsHDF5.McsStream
% McsEventStream
%
% Holds the contents of an EventStream
    
    properties (SetAccess = private)
        Events = {};
    end
    
    methods
        function str = McsEventStream(filename, strStruct)
        % function str = McsEventStream(filename, strStruct)
        %
        % Constructs a McsEventStream object. Reads the meta-information
        % from the file but does not read the actual event data. This is
        % performed the first time that the Events field is accessed.
        
            str = str@McsHDF5.McsStream(filename,strStruct,'Event');
            evts = str.Info.EventID;
            str.Events = cell(1,length(evts)); 
        end
        
        function data = get.Events(str)
        % function data = get.Events(str)
        %
        % Accessor function for events. Loads the events from the file the
        % first time that the Events field is requested.
        
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