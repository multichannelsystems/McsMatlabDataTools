classdef McsStream < handle
% Superclass for the different streams.
%
% Reads and stores the Info struct and the other data attributes.
    
    properties (SetAccess = protected)
        StreamInfoVersion   % (scalar) Version of the stream protocol
        StreamGUID          % (string) The stream GUID
        StreamType          % (string) The stream type (Analog, Event,...)
        SourceStreamGUID    % (string) The GUID of the source stream
        Label               % (string) The stream label
        DataSubType         % (string) The type of data (Electrode, Auxiliary,...)
        
        % Info - (struct) Information about the stream
        % The fields depend on the stream type and hold information about
        % each channel/entity in the stream, such as their IDs, labels,
        % etc.
        Info                
    end
    
    properties (Access = protected)
        FileName            
        StructName          
        DataLoaded = false;
        Internal = false;
    end
    
    methods
        
        function str = McsStream(filename, strStruct, type)
        % Reads the Info attributes and the stream attributes.
        %
        % function str = McsStream(filename, strStruct, type)
        % 
            if exist('h5info')
                mode = 'h5';
            else
                mode = 'hdf5';
            end
            str.StructName = strStruct.Name;
            str.FileName = filename;
            
            if strcmp(mode,'h5')
                inf = h5read(filename, [strStruct.Name '/Info' type]);
            else
                fid = H5F.open(filename,'H5F_ACC_RDONLY','H5P_DEFAULT');
                did = H5D.open(fid, [strStruct.Name '/Info' type]);
                inf = H5D.read(did,'H5ML_DEFAULT','H5S_ALL','H5S_ALL','H5P_DEFAULT');
            end
            fn = fieldnames(inf);
            for fni = 1:length(fn)
                str.Info(1).(fn{fni}) = inf.(fn{fni});
            end
            
            if isfield(strStruct,'Attributes')
                dataAttributes = strStruct.Attributes;
                for fni = 1:length(dataAttributes)
                    if strcmp(mode,'h5')
                        str.(dataAttributes(fni).Name) = dataAttributes(fni).Value;
                    else
                        name = regexp(dataAttributes(fni).Name,'/\w+$','match');
                        if isa(dataAttributes(fni).Value,'hdf5.h5string')
                            str.(name{length(name)}(2:end)) = dataAttributes(fni).Value.Data;
                        else
                            str.(name{length(name)}(2:end)) = dataAttributes(fni).Value;
                        end
                    end
                end
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
    
    methods (Access = protected)
        function copyFields(to, from, index)
            to.StreamInfoVersion = from.StreamInfoVersion;
            to.StreamGUID = from.StreamGUID;
            to.StreamType = from.StreamType;
            to.SourceStreamGUID = from.SourceStreamGUID;
            to.Label = from.Label;
            to.DataSubType = from.DataSubType;
            fns = fieldnames(to.Info);
            for fni = 1:length(fns)
                info = from.Info.(fns{fni});
                to.Info.(fns{fni}) = info(index);
            end
        end
    end
end