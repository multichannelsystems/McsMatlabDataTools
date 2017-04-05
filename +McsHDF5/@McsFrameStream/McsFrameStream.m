classdef McsFrameStream < McsHDF5.McsStream
% Holds the contents of a FrameStream
%
% Contains one or more FrameDataEntity in a cell array. The other fields
% and the Info field provide general information about the frame stream.
%
% (c) 2016 by Multi Channel Systems MCS GmbH
    
    properties (SetAccess = private)
        FrameDataEntity = {} % (cell array) McsFrameDataEntity objects
    end
    
    methods
        
        function str = McsFrameStream(filename, strStruct, cfg)
        % Constructs a McsFrameStream object. 
        %
        % function str = McsFrameStream(filename, strStruct, cfg)
        %
        % Calls the constructors for the individual McsFrameDataEntity
        % objects. The FrameData from the individual FrameDataEntity is
        % not read directly from the file, but only once the FrameData
        % field is actually accessed.
        
            str = str@McsHDF5.McsStream(filename,strStruct,'Frame');
            
            % check if entities are present
            if ~isempty(strStruct.Groups)
                str.FrameDataEntity = cell(1,length(strStruct.Groups));
                for gidx = 1:length(strStruct.Groups)
                    info = structfun(@(x)(x(gidx)),str.Info,'UniformOutput',false);
                    str.FrameDataEntity{gidx} = McsHDF5.McsFrameDataEntity(filename,info,strStruct.Groups(gidx).Name,cfg);
                end
            end     
        end
    end
end