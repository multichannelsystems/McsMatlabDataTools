classdef McsRecording
% McsRecording
%
% Stores a single recording.
    
    properties
        RecordingID = 0
        RecordingType
        TimeStamp
        Duration
        Label
        Comment
        AnalogStream = {};
        FrameStream = {};
        EventStream = {};
        SegmentStream = {};
    end
    
    methods
        
        function rec = McsRecording(filename, recStruct)
        % function rec = McsRecording(filename, recStruct)
        %
        % Reads a single recording inside a HDF5 file.
        %
        % Input:
        %   filename    -   (string) Name of the HDF5 file
        %   recStruct   -   The recording subtree of the structure 
        %                   generated by the h5info command
        %
        % Output:
        %   rec         -   A McsRecording object
        %
        
            dataAttributes = recStruct.Attributes;
            for fni = 1:length(dataAttributes)
                rec.(dataAttributes(fni).Name) = dataAttributes(fni).Value;
            end

            for gidx = 1:length(recStruct.Groups)
                groupname = recStruct.Groups(gidx).Name;
                
                if ~isempty(strfind(groupname,'AnalogStream'))
                    % read analog streams
                    for streams = 1:length(recStruct.Groups(gidx).Groups)
                        rec.AnalogStream{streams} = McsHDF5.McsAnalogStream(filename, recStruct.Groups(gidx).Groups(streams));
                    end
                    
                elseif ~isempty(strfind(groupname,'FrameStream'))
                    % read frame streams
                    for streams = 1:length(recStruct.Groups(gidx).Groups)
                        rec.FrameStream{streams} = McsHDF5.McsFrameStream(filename, recStruct.Groups(gidx).Groups(streams));
                    end
                    
                elseif ~isempty(strfind(groupname,'EventStream'))
                    % read event streams
                    for streams = 1:length(recStruct.Groups(gidx).Groups)
                        rec.EventStream{streams} = McsHDF5.McsEventStream(filename, recStruct.Groups(gidx).Groups(streams));
                    end
                    
                elseif ~isempty(strfind(groupname,'SegmentStream'))
                    % read segment streams
                    for streams = 1:length(recStruct.Groups(gidx).Groups)
                        rec.SegmentStream{streams} = McsHDF5.McsSegmentStream(filename, recStruct.Groups(gidx).Groups(streams));
                    end
                end 
                
            end
            
            
        end
        
    end
    
end