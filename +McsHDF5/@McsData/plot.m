function plot(md,cfg,varargin)
%function plot(md,cfg,varargin)
%
% Function to plot the contents of a McsData object.
%
% Input:
%
%   md      -   A McsData object
%
%   cfg     -   Either empty (for default parameters) or a structure with
%               (some of) the following fields:
%               'recordings': empty for all recordings, otherwise a vector
%                   with indices of recordings (default: all)
%               'conf': Configuration structure for McsRecording.plot:
%                   []: default parameters
%                   single config struct: replicated for all recordings
%                   cell array of config structs: each cell contains a
%                   config struct for a specific recording.
%                   See help McsRecording.plot for details on the config
%                   structure
%               If fields are missing, their default values are used.
%
%   optional inputs in varargin are passed to the plot functions. warning: 
%   might produce error if segments / frames are mixed with analog streams.

    if isempty(cfg) || ~isfield(cfg,'recordings')
        cfg.recordings = [];
    end
    
    if isempty(cfg.recordings)
        cfg.recordings = 1:length(md.Recording);
    end
    
    if ~isfield(cfg,'conf')
        cfg.conf = [];
    end
    
    if ~iscell(cfg.conf)
        cfg.conf = repmat({cfg.conf},1,length(cfg.recordings));
    end
    
    for reci = 1:length(cfg.recordings)
        id = cfg.recordings(reci);
        plot(md.Recording{id},cfg.conf{id},varargin{:});
    end

end