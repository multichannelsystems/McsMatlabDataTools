function plot(evtStream,cfg,varargin)
% Plot the contents of a McsEventStream object. 
%
% function plot(evtStream,cfg,varargin)
%
% Produces a plot in which the time stamp of each event is shown as a line
% on a time scale.
%
% Input:
%
%   evtStream    -   A McsEventStream object
%
%   cfg          -   Reserved for future use, currently unused
%
%   Optional inputs in varargin are passed to the plot function.

    lineLength = 0.3;
    M = cell(length(evtStream.Events),2);
    for evti = 1:length(evtStream.Events)
        if size(evtStream.Events{evti},1) == 1
            M{evti,1} = McsHDF5.TickToSec([evtStream.Events{evti} ; evtStream.Events{evti}]);
        else
            M{evti,1} = McsHDF5.TickToSec([evtStream.Events{evti}(1,:) ; sum(evtStream.Events{evti}) ; sum(evtStream.Events{evti}) ; evtStream.Events{evti}(1,:)]);
        end
        M{evti,2} = repmat([evti-lineLength ; evti+lineLength],1,size(M{evti,1},2));
    end
    for evti = 1:length(evtStream.Events)
        if size(evtStream.Events{evti},1) == 1
            if isempty(varargin)
                line(M{evti,1},M{evti,2},'Color','k')
            else
                line(M{evti,1},M{evti,2},varargin{:})
            end
        else
            if isempty(varargin)
                patch(M{evti,1},repmat(M{evti,2},2,1),'k')
            else
                patch(M{evti,1},repmat(M{evti,2},2,1),varargin{:})
            end
        end
    end
    set(gca,'YTick',1:length(evtStream.Events));
    set(gca,'YTickLabel',strtrim(evtStream.Info.SourceChannelLabels));
    ylabel('Source Channel')
    xlabel('Time [s]')
end
