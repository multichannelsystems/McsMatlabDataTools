function plot(frameStream,cfg,varargin)
% Plot the contents of a McsFrameStream object.
%
% function plot(frameStream,cfg,varargin)
%
% Produces plots of the individual FrameDataEntities (one figure per
% entity).
%
% Input:
%
%   frameStream     -   A McsFrameStream object
%
%   cfg             -   Either empty (for default parameters) or a
%                       structure with (some of) the following fields:
%                       'entities': empty for all frame data entities,
%                           otherwise a vector of entity indices (default:
%                           all)
%                       'window': Specifies the displayed time range:
%                           []: Total time range
%                           single value or [start end]: replicated for all
%                           entities
%                           cell array of single values or [start end]:
%                           each cell is applied for its corresponding
%                           entity (default: [])
%                       'channelMatrix': Specifies the displayed channels:
%                           []: All channels
%                           nxm matrix: replicated for all entities
%                           cell array of matrices: each cell contains a
%                           matrix which is applied for its corresponding
%                           entity. (default: [])
%                       If fields are missing, their default values are
%                       used.
%
%                       See help McsFrameDataEntity.plot for more details
%                       on the 'window' and the 'channelMatrix' parameter
%
%   Optional inputs in varargin are passed to the plot function.

    if isempty(cfg)
        cfg.entities = [];
        cfg.window = [];
        cfg.channelMatrix = [];
    end
    
    if ~isfield(cfg,'entities')
        cfg.entities = [];
    end
    
    if ~isfield(cfg,'window')
        cfg.window = [];
    end
    
    if ~isfield(cfg,'channelMatrix')
        cfg.channelMatrix = [];
    end
    
    if isempty(cfg.entities)
        cfg.entities = 1:length(frameStream.FrameDataEntities);
    end
    
    if length(cfg.window) <= 2 && ~iscell(cfg.window)
        cfg.window = repmat({cfg.window},1,length(cfg.entities));
    end
    
    if length(cfg.window) ~= length(cfg.entities) && ~iscell(cfg.window)
        error('cfg.window not specified properly');
    end
    
    if isempty(cfg.channelMatrix)
        cfg.channelMatrix = repmat({[]},1,length(cfg.entities));
    end
    
    if ~iscell(cfg.channelMatrix)
        cfg.channelMatrix = repmat({cfg.channelMatrix},1,length(cfg.entities));
    end
    
    if length(cfg.channelMatrix) ~= length(cfg.entities) && ~iscell(cfg.channelMatrix)
        error('cfg.channelMatrix not specified properly');
    end
    
    for enti = 1:length(cfg.entities)
        id = cfg.entities(enti);
        figure
        
        cfg_ent = [];
        cfg_ent.window = cfg.window{enti};
        cfg_ent.channelMatrix = cfg.channelMatrix{enti};
        
        plot(frameStream.FrameDataEntities{id},cfg_ent,varargin);
    end

end