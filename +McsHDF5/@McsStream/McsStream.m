classdef McsStream < handle
% Superclass for the different streams.
%
% Reads and stores the Info struct and the other data attributes.
    
    properties 
        StreamGUID
        StreamType
        SourceStreamGUID
        Label
        DataSubType
        Info
    end
    
    properties (Access = protected)
        FileName
        StructName
        DataLoaded = false;
    end
    
    methods
        
        function str = McsStream(filename, strStruct, type)
        % Reads the Info attributes and the stream attributes.
        %
        % function str = McsStream(filename, strStruct, type)
        % 
            
            str.StructName = strStruct.Name;
            str.FileName = filename;
            
            inf = h5read(filename, [strStruct.Name '/Info' type]);
            fn = fieldnames(inf);
            for fni = 1:length(fn)
                str.Info(1).(fn{fni}) = inf.(fn{fni});
            end
            
            dataAttributes = strStruct.Attributes;
            for fni = 1:length(dataAttributes)
                str.(dataAttributes(fni).Name) = dataAttributes(fni).Value;
            end
            
        end
        
        function Fs = getSamplingRate(str,varargin)
        % Returns the sampling rate in Hz
        %    
        % function Fs = getSamplingRate(str)
        %
        % Warning: Will not work for event channels!
        %
        % function Fs = getSamplingRate(str,i)
        %
        % Returns the sampling rate in Hz of channel i of a
        % McsStream.
        
            if isempty(varargin)
                Fs = 1 ./ double(str.Info.Tick(1)) * 1e6;
            else
                Fs = 1 / double(str.Info.Tick(varargin{1})) * 1e6;
            end
        end
        
    end
    
end