function plot(mr,cfg,varargin)
% Plot the contents of a McsRecording object.
%
% function plot(mr,cfg,varargin)
%
% Input:
%
%   mr      -   A McsRecording object
%
%   cfg     -   Either empty (for default parameters) or a structure with
%               (some of) the following fields:
%               'analog': Configuration structure for McsAnalogStream.plot:
%                   []: default parameters
%                   single config struct: replicated for all analog streams
%                   cell array of config structs: each cell contains a
%                   config struct for a specific stream.
%                   See help McsAnalogStream.plot for details on the config
%                   structure
%               'frame': Configuration structure for McsFrameStream.plot
%                   see 'analog' for options
%               'segment': Configuration structure for McsSegmentStream.plot
%                   see 'analog' for options
%               'event': Configuration structure for McsEventStream.plot
%                   see 'analog' for options
%               'timestamp': Configuration structure for McsTimeStampStream.plot
%                   see 'analog' for options
%               'analogstreams': empty for all analog streams, otherwise
%                   vector with indices of analog streams (default: all)
%               'framestreams': empty for all frame streams, otherwise
%                   vector with indices of frame streams (default: all)
%               'segmentstreams': empty for all segment streams, otherwise
%                   vector with indices of segment streams (default: all)
%               'eventstreams': empty for all event streams, otherwise
%                   vector with indices of event streams (default: all)
%               'timestampstreams': empty for all event streams, otherwise
%                   vector with indices of event streams (default: all)
%               If fields are missing, their default values are used.
%
%   Optional inputs in varargin are passed to the plot functions. Warning: 
%   might produce error if segments / frames are mixed with analog / event
%   streams.

    if isempty(cfg)
        cfg.analog = [];
        cfg.frame = [];
        cfg.segment = [];
        cfg.event = [];
        cfg.timestamp = [];
    end
    
    if ~isempty(mr.AnalogStream)
        
        if ~isfield(cfg,'analog') || isempty(cfg.analog)
            cfg.analog = repmat({[]},1,length(mr.AnalogStream));
        end
        
        if ~isfield(cfg,'analogstreams') || isempty(cfg.analogstreams)
            cfg.analogstreams = 1:length(mr.AnalogStream);
        end
        
        if ~iscell(cfg.analog)
            cfg.analog = repmat({cfg.analog},1,length(mr.AnalogStream));
        end
        
        for stri = 1:length(cfg.analogstreams)
            figure
            plot(mr.AnalogStream{cfg.analogstreams(stri)},cfg.analog{stri},varargin{:});
            set(gcf,'Name',['Analog Stream ' num2str(cfg.analogstreams(stri))]);
        end
    end
    
    if ~isempty(mr.FrameStream)
        
        if ~isfield(cfg,'frame') || isempty(cfg.frame)
            cfg.frame = repmat({[]},1,length(mr.FrameStream));
        end
        
        if ~isfield(cfg,'framestreams') || isempty(cfg.framestreams)
            cfg.framestreams = 1:length(mr.FrameStream);
        end
        
        if ~iscell(cfg.frame)
            cfg.frame = repmat({cfg.frame},1,length(mr.FrameStream));
        end
        
        for stri = 1:length(cfg.framestreams)
            figure
            plot(mr.FrameStream{cfg.framestreams(stri)},cfg.frame{stri},varargin{:});
            set(gcf,'Name',['Frame Stream ' num2str(cfg.framestreams(stri))]);
        end
    end
    
    if ~isempty(mr.SegmentStream)
        
        if ~isfield(cfg,'segment') || isempty(cfg.segment)
            cfg.segment = repmat({[]},1,length(mr.SegmentStream));
        end
        
        if ~isfield(cfg,'segmentstreams') || isempty(cfg.segmentstreams)
            cfg.segmentstreams = 1:length(mr.SegmentStream);
        end
        
        if ~iscell(cfg.segment)
            cfg.segment = repmat({cfg.segment},1,length(mr.SegmentStream));
        end
        
        for stri = 1:length(cfg.segmentstreams)
            figure
            plot(mr.SegmentStream{cfg.segmentstreams(stri)},cfg.segment{stri},varargin{:});
            set(gcf,'Name',['Segment Stream ' num2str(cfg.segmentstreams(stri))]);
        end
    end
    
    if ~isempty(mr.EventStream)
        
        if ~isfield(cfg,'event') || isempty(cfg.event)
            cfg.event = repmat({[]},1,length(mr.EventStream));
        end
        
        if ~isfield(cfg,'eventstreams') || isempty(cfg.eventstreams)
            cfg.eventstreams = 1:length(mr.EventStream);
        end
        
        if ~iscell(cfg.event)
            cfg.event = repmat({cfg.event},1,length(mr.EventStream));
        end
        
        for stri = 1:length(cfg.eventstreams)
            figure
            plot(mr.EventStream{cfg.eventstreams(stri)},cfg.event{stri},varargin{:});
            set(gcf,'Name',['Event Stream ' num2str(cfg.eventstreams(stri))]);
        end
    end
    
    if ~isempty(mr.TimeStampStream)
        
        if ~isfield(cfg,'timestamp') || isempty(cfg.timestamp)
            cfg.timestamp = repmat({[]},1,length(mr.TimeStampStream));
        end
        
        if ~isfield(cfg,'timestampstreams') || isempty(cfg.timestampstreams)
            cfg.timestampstreams = 1:length(mr.TimeStampStream);
        end
        
        if ~iscell(cfg.timestamp)
            cfg.timestamp = repmat({cfg.timestamp},1,length(mr.TimeStampStream));
        end
        
        for stri = 1:length(cfg.timestampstreams)
            figure
            plot(mr.TimeStampStream{cfg.timestampstreams(stri)},cfg.timestamp{stri},varargin{:});
            set(gcf,'Name',['Time Stamp Stream ' num2str(cfg.timestampstreams(stri))]);
        end
    end

end