function plot(segStream,cfg,varargin)
% function plot(segStream,cfg,varargin)
%
% Function to plot the contents of a McsSegmentStream object.
%
% Input:
%
%   segStream     -   A McsSegmentStream object
%
%   cfg           -   Either empty (for default parameters) or a
%                     structure with (some of) the following fields:
%                     'segments': empty for all segments, otherwise a
%                       vector of segment indices (default: all)
%                     If fields are missing, their default values are used.
%
%   optional inputs in varargin are passed to the plot function.

    clf
    
    if isempty(cfg) || ~isfield(cfg,'segments')
        cfg.segments = [];
    end
    
    if isempty(cfg.segments)
        cfg.segments = 1:length(segStream.SegmentData);
    end
    
    if any(cfg.segments < 1 | cfg.segments > length(segStream.SegmentData))
        warning(['Using only segment indices between 1 and ' num2str(length(segStream.SegmentData)) '!'])
        cfg.segments = cfg.segments(cfg.segments >= 1 & cfg.segments <= length(segStream.SegmentData));
    end
    
    for segi = 1:length(cfg.segments)
        id = cfg.segments(segi);
        subplot(2,length(cfg.segments),segi);
        
        data_to_plot = segStream.SegmentData{id};
        
        orig_exp = log10(max(abs(data_to_plot(:))));
        unit_exp = double(segStream.Info.Exponent(1));

        [fact,unit_string] = McsHDF5.ExponentToUnit(orig_exp+unit_exp,orig_exp);

        data_to_plot = data_to_plot * fact;
        
        [X,Y] = meshgrid(1:size(data_to_plot,2),1:size(data_to_plot,1));
        if isempty([varargin{:}])
            surfl(X,Y,data_to_plot);
        else
            surfl(X,Y,data_to_plot,varargin{:});
        end
        shading interp
        xlabel('samples')
        ylabel('events')
        zlabel([unit_string segStream.Info.Unit{id}],'Interpreter','tex')
        title(['Segment label ' segStream.Info.Label{id}])
        
        
        subplot(2,length(cfg.segments),segi+length(cfg.segments));
        
        pre = double(segStream.Info.PreInterval(id));
        post = double(segStream.Info.PostInterval(id));
        ts = (1:size(data_to_plot,2)).*double(segStream.Info.Tick(id));
        %ts = -pre:double(segStream.Info.Tick(id)):post;
        ts = McsHDF5.TickToSec(ts);
        plot(ts,data_to_plot');
        axis tight
        xlabel('Time [s]');
        ylabel([unit_string segStream.Info.Unit{1}],'Interpreter','tex')
        
    end
end
        