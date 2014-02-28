function plot(analogStream,cfg,varargin)
% function plot(analogStream,cfg,varargin)
%
% Function to plot the contents of a McsAnalogStream object.
%
% Input:
%
%   analogStream    -   A McsAnalogStream object
%
%   cfg             -   Either empty (for default parameters) or a
%                       structure with (some of) the following fields:
%                       'channels': empty for all channels, otherwise a
%                           vector of channel indices (default: all)
%                       'window': empty for the whole time range, otherwise
%                           a vector with two entries: [start end] of the 
%                           time range, both in seconds.
%                       If fields are missing, their default values are used.
%
%   optional inputs in varargin are passed to the plot function.
    
    clf

    if isempty(cfg)
        cfg.channels = [];
        cfg.window = [];
    end
    
    if ~isfield(cfg,'channels') 
        cfg.channels = []; 
    end
    
    if ~isfield(cfg,'window') 
        cfg.window = []; 
    end
    
    if isempty(cfg.channels)
        cfg.channels = 1:size(analogStream.ChannelData,2);
    end
    
    if isempty(cfg.window)
        cfg.window = McsHDF5.TickToSec([analogStream.ChannelDataTimeStamps(1) ...
                      analogStream.ChannelDataTimeStamps(end)]);
    end
    
    if any(cfg.channels < 1 | cfg.channels > size(analogStream.ChannelData,2))
        warning(['Using only channel indices between 1 and ' num2str(size(analogStream.ChannelData,2)) '!']);
        cfg.channels = cfg.channels(cfg.channels >= 1 & cfg.channels <= size(analogStream.ChannelData,2));
    end

    start_index = find(analogStream.ChannelDataTimeStamps > McsHDF5.SecToTick(cfg.window(1)),1,'first');
    end_index = find(analogStream.ChannelDataTimeStamps < McsHDF5.SecToTick(cfg.window(2)),1,'last');
    
    if end_index < start_index
        warning('No time range found')
        return
    end
    
    data_to_plot = analogStream.ChannelData(start_index:end_index,cfg.channels);
    
    orig_exp = log10(max(abs(data_to_plot(:))));
    unit_exp = double(analogStream.Info.Exponent(1));
    
    [fact,unit_string] = McsHDF5.ExponentToUnit(orig_exp+unit_exp,orig_exp);
    
    data_to_plot = data_to_plot * fact;
    
    timestamps = McsHDF5.TickToSec(analogStream.ChannelDataTimeStamps(start_index:end_index));
    
    if isempty([varargin{:}])
        plot(timestamps,data_to_plot);
    else
        plot(timestamps,data_to_plot,varargin{:});
    end
    
    chan_names = analogStream.Info.Label(cfg.channels);
    legend(chan_names);
    
    title([analogStream.Label]);
    xlabel('Time [s]')
    ylabel([unit_string analogStream.Info.Unit{1}],'Interpreter','tex')
    
end
