classdef McsFrameStream < McsHDF5.McsStream
% Holds the contents of a FrameStream
%
% Contains one or more FrameDataEntities in a cell array. The other fields
% and the Info field provide general information about the frame stream.
    
    properties (SetAccess = private)
        FrameDataEntity = {} % (cell array) McsFrameDataEntity objects
    end
    
    methods
        
        function str = McsFrameStream(filename, strStruct, varargin)
        % Constructs a McsFrameStream object. 
        %
        % function str = McsFrameStream(filename, strStruct)
        %
        % Calls the constructors for the individual McsFrameDataEntity
        % objects. The FrameData from the individual FrameDataEntities is
        % not read directly from the file, but only once the FrameData
        % field is actually accessed.
        
            str = str@McsHDF5.McsStream(filename,strStruct,'Frame');
            
            % check if entities are present
            if ~isempty(strStruct.Groups)
                str.FrameDataEntity = cell(1,length(strStruct.Groups));
                for gidx = 1:length(strStruct.Groups)
                    info = structfun(@(x)(x(gidx)),str.Info,'UniformOutput',false);
                    if isempty(varargin)
                        str.FrameDataEntity{gidx} = McsHDF5.McsFrameDataEntity(filename,info,strStruct.Groups(gidx).Name);
                    else
                        str.FrameDataEntity{gidx} = McsHDF5.McsFrameDataEntity(filename,info,strStruct.Groups(gidx).Name,varargin{:});
                    end
                end
            end     
        end
    end
end