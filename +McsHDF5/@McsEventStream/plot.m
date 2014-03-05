function plot(evtStream,cfg,varargin)
% Plot the contents of a McsEventStream object. 
%
% function plot(evtStream,cfg,varargin)
%
% Produces a plot in which the time stamp of each event is shown as a dot
% on a time scale.
%
% Input:
%
%   evtStream    -   A McsEventStream object
%
%   cfg          -   Reserved for future use, currently unused
%
%   Optional inputs in varargin are passed to the plot function.

    if isempty(varargin)
        varargin{1} = '.k';
    end

    for evti = 1:length(evtStream.Events)
        evts = McsHDF5.TickToSec(evtStream.Events{evti});
        if size(evts,2) == 1
            plot(evts,ones(1,length(evts))*evti,varargin{:});
        elseif size(evts,2) == 2
            plot(evts(:,1),ones(1,length(evts))*evti,varargin{:});
            warning('Event durations are not yet shown!');
        end
        hold on
    end
    hold off
    set(gca,'YTick',1:length(evtStream.Events));
    set(gca,'YTickLabel',strtrim(evtStream.Info.SourceChannelLabels));
    ylabel('Source Channel')
    xlabel('Time [s]')
end
