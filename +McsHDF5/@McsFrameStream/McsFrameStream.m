classdef McsFrameStream < McsHDF5.McsStream
% McsFrameStream
%
% Holds the contents of a FrameStream, i.e. one or more FrameDataEntities
    
    properties 
        FrameDataEntities = {}
    end
    
    methods
        
        function str = McsFrameStream(filename, strStruct)
        % function str = McsFrameStream(filename, strStruct)
        %
        % Constructs a McsFrameStream object.
        
            str = str@McsHDF5.McsStream(filename,strStruct,'Frame');
            
            % check if entities are present
            if ~isempty(strStruct.Groups)
                str.FrameDataEntities = cell(1,length(strStruct.Groups));
                for gidx = 1:length(strStruct.Groups)
                    info = structfun(@(x)(x(gidx)),str.Info,'UniformOutput',false);
                    str.FrameDataEntities{gidx} = McsHDF5.McsFrameDataEntity(filename,info,strStruct.Groups(gidx).Name);
                end
            end
         
            
        end
        
        
        
    end
    
end