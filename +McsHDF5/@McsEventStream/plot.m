function plot(evtStream,cfg,varargin)
% function plot(evtStream,cfg,varargin)
%
% Function to plot the contents of a McsEventStream object.
%
% Input:
%
%   evtStream    -   A McsEventStream object
%
%   cfg          -   Reserved for future use, currently unused
%
%   optional inputs in varargin are passed to the plot function.

    if isempty(varargin)
        varargin{1} = '.k';
    end

    for evti = 1:length(evtStream.Events)
        evts = McsHDF5.TickToSec(evtStream.Events{evti});
        plot(evts,ones(1,length(evts))*evti,varargin{:});
        hold on
    end
    hold off
    set(gca,'YTick',1:length(evtStream.Events));
    set(gca,'YTickLabel',strtrim(evtStream.Info.SourceChannelLabels));
    ylabel('Source Channel')
    xlabel('Time [s]')
end
